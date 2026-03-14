import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/currency/app_currency.dart';
import '../../../../core/currency/exchange_rate_service.dart';
import '../../domain/models/group_models.dart';

class GroupValidationException implements Exception {
  const GroupValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GroupBloc extends ChangeNotifier {
  GroupBloc({ExchangeRateService? exchangeRateService})
    : _exchangeRateService = exchangeRateService ?? const ExchangeRateService();

  static const selfProfileId = 'local-self';
  static const _profilesKey = 'group_profiles';
  static const _groupsKey = 'expense_groups';
  static const _expensesKey = 'group_expenses';
  static const _settlementsKey = 'group_settlements';
  static const _groupPalette = <int>[
    0xFF10B981,
    0xFF22D3EE,
    0xFFF59E0B,
    0xFFF472B6,
    0xFF60A5FA,
    0xFFA78BFA,
    0xFFFB7185,
    0xFF34D399,
  ];

  final ExchangeRateService _exchangeRateService;
  final List<LocalProfile> _profiles = <LocalProfile>[];
  final List<ExpenseGroup> _groups = <ExpenseGroup>[];
  final List<SharedExpense> _expenses = <SharedExpense>[];
  final List<SettlementRecord> _settlements = <SettlementRecord>[];
  SharedPreferences? _preferences;
  String _currencyCode = 'USD';

  List<LocalProfile> get profiles => List.unmodifiable(_profiles);
  List<ExpenseGroup> get groups =>
      List.unmodifiable(_groups.where((group) => !group.isArchived));
  List<ExpenseGroup> get archivedGroups =>
      List.unmodifiable(_groups.where((group) => group.isArchived));
  List<SharedExpense> get expenses =>
      List.unmodifiable(_expenses.where((expense) => !expense.isDeleted));
  List<SettlementRecord> get settlements =>
      List.unmodifiable(_settlements.where((item) => !item.isDeleted));
  String get currencyCode => _currencyCode;

  Future<void> hydrate() async {
    _preferences ??= await SharedPreferences.getInstance();
    _currencyCode =
        AppCurrency.fromCode(_preferences!.getString('selected_currency_code'))?.code ?? 'USD';

    final profileJson = _preferences!.getString(_profilesKey);
    final groupJson = _preferences!.getString(_groupsKey);
    final expenseJson = _preferences!.getString(_expensesKey);
    final settlementJson = _preferences!.getString(_settlementsKey);

    _profiles
      ..clear()
      ..addAll(_decodeList(profileJson, LocalProfile.fromMap));
    _groups
      ..clear()
      ..addAll(_decodeList(groupJson, ExpenseGroup.fromMap));
    _expenses
      ..clear()
      ..addAll(_decodeList(expenseJson, SharedExpense.fromMap));
    _settlements
      ..clear()
      ..addAll(_decodeList(settlementJson, SettlementRecord.fromMap));

    _ensureSelfProfile();
    await _persistProfiles();
    notifyListeners();
  }

  LocalProfile get selfProfile => profileById(selfProfileId)!;

  LocalProfile? profileById(String id) {
    for (final profile in _profiles) {
      if (profile.id == id) {
        return profile;
      }
    }
    return null;
  }

  ExpenseGroup? groupById(String id) {
    for (final group in _groups) {
      if (group.id == id) {
        return group;
      }
    }
    return null;
  }

  List<LocalProfile> membersForGroup(String groupId) {
    final group = groupById(groupId);
    if (group == null) {
      return const <LocalProfile>[];
    }
    return group.memberIds
        .map(profileById)
        .whereType<LocalProfile>()
        .toList(growable: false);
  }

  List<SharedExpense> expensesForGroup(String groupId) {
    return expenses
        .where((expense) => expense.groupId == groupId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<SettlementRecord> settlementsForGroup(String groupId) {
    return settlements
        .where((item) => item.groupId == groupId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> createGroup({
    required String name,
    required List<String> memberNames,
  }) async {
    final normalizedName = name.trim();
    final normalizedMembers = _normalizeMemberNames(memberNames);
    if (normalizedName.isEmpty) {
      throw const GroupValidationException('Group name is required.');
    }
    if (normalizedMembers.isEmpty) {
      throw const GroupValidationException(
        'Add at least one member besides you.',
      );
    }

    final now = DateTime.now();
    final members = <String>[selfProfileId];
    for (final memberName in normalizedMembers) {
      final existing = _findProfileByName(memberName);
      if (existing != null) {
        members.add(existing.id);
        continue;
      }
      final profile = LocalProfile(
        id: _createId('profile'),
        displayName: memberName,
        avatarColorValue: _nextProfileColorValue(),
        isSelf: false,
        createdAt: now,
      );
      _profiles.add(profile);
      members.add(profile.id);
    }

    _groups.insert(
      0,
      ExpenseGroup(
        id: _createId('group'),
        name: normalizedName,
        memberIds: members,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await _persistAll();
    notifyListeners();
  }

  Future<void> updateGroup({
    required String groupId,
    required String name,
    required List<String> memberNames,
  }) async {
    final group = groupById(groupId);
    if (group == null) {
      throw const GroupValidationException('Group not found.');
    }

    final normalizedName = name.trim();
    final normalizedMembers = _normalizeMemberNames(memberNames);
    if (normalizedName.isEmpty) {
      throw const GroupValidationException('Group name is required.');
    }
    if (normalizedMembers.isEmpty) {
      throw const GroupValidationException(
        'Add at least one member besides you.',
      );
    }

    final currentMembers = membersForGroup(groupId)
        .where((profile) => !profile.isSelf)
        .toList();
    final currentByName = {
      for (final profile in currentMembers) profile.displayName.toLowerCase(): profile,
    };

    final nextMemberIds = <String>[selfProfileId];
    for (final memberName in normalizedMembers) {
      final current = currentByName[memberName.toLowerCase()] ?? _findProfileByName(memberName);
      if (current != null) {
        nextMemberIds.add(current.id);
        continue;
      }

      final profile = LocalProfile(
        id: _createId('profile'),
        displayName: memberName,
        avatarColorValue: _nextProfileColorValue(),
        isSelf: false,
        createdAt: DateTime.now(),
      );
      _profiles.add(profile);
      nextMemberIds.add(profile.id);
    }

    final removedMemberIds = group.memberIds
        .where((id) => id != selfProfileId && !nextMemberIds.contains(id))
        .toList();
    for (final memberId in removedMemberIds) {
      if (_memberHasGroupHistory(groupId, memberId) || _memberOutstandingBalance(groupId, memberId).abs() > 0.009) {
        final profile = profileById(memberId);
        throw GroupValidationException(
          'Cannot remove ${profile?.displayName ?? 'member'} while balances or history still exist.',
        );
      }
    }

    _replaceGroup(
      group.copyWith(
        name: normalizedName,
        memberIds: nextMemberIds,
        updatedAt: DateTime.now(),
      ),
    );
    await _persistAll();
    notifyListeners();
  }

  Future<void> archiveGroup(String groupId) async {
    final group = groupById(groupId);
    if (group == null) {
      return;
    }
    _replaceGroup(group.copyWith(archivedAt: DateTime.now(), updatedAt: DateTime.now()));
    await _persistGroups();
    notifyListeners();
  }

  Future<void> deleteGroup(String groupId) async {
    final group = groupById(groupId);
    if (group == null) {
      return;
    }
    final hasHistory =
        expensesForGroup(groupId).isNotEmpty || settlementsForGroup(groupId).isNotEmpty;
    if (hasHistory) {
      throw const GroupValidationException(
        'Groups with activity can only be archived.',
      );
    }
    _groups.removeWhere((item) => item.id == groupId);
    await _persistGroups();
    notifyListeners();
  }

  Future<void> addExpense(SharedExpense expense) async {
    _validateExpense(expense);
    _expenses.insert(0, expense.copyWith(currencyCode: _currencyCode));
    _touchGroup(expense.groupId);
    await _persistExpenses();
    await _persistGroups();
    notifyListeners();
  }

  Future<void> updateExpense(SharedExpense expense) async {
    _validateExpense(expense);
    final index = _expenses.indexWhere((item) => item.id == expense.id);
    if (index == -1) {
      throw const GroupValidationException('Expense not found.');
    }
    _expenses[index] = expense.copyWith(
      currencyCode: _currencyCode,
      updatedAt: DateTime.now(),
    );
    _touchGroup(expense.groupId);
    await _persistExpenses();
    await _persistGroups();
    notifyListeners();
  }

  Future<void> deleteExpense(String expenseId) async {
    final index = _expenses.indexWhere((item) => item.id == expenseId);
    if (index == -1) {
      return;
    }
    final expense = _expenses[index];
    _expenses[index] = expense.copyWith(
      deletedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _touchGroup(expense.groupId);
    await _persistExpenses();
    await _persistGroups();
    notifyListeners();
  }

  Future<void> addSettlement(SettlementRecord record) async {
    _validateSettlement(record);
    _settlements.insert(0, record.copyWith(currencyCode: _currencyCode));
    _touchGroup(record.groupId);
    await _persistSettlements();
    await _persistGroups();
    notifyListeners();
  }

  Future<void> updateSettlement(SettlementRecord record) async {
    _validateSettlement(record);
    final index = _settlements.indexWhere((item) => item.id == record.id);
    if (index == -1) {
      throw const GroupValidationException('Settlement not found.');
    }
    _settlements[index] = record.copyWith(
      currencyCode: _currencyCode,
      updatedAt: DateTime.now(),
    );
    _touchGroup(record.groupId);
    await _persistSettlements();
    await _persistGroups();
    notifyListeners();
  }

  Future<void> deleteSettlement(String settlementId) async {
    final index = _settlements.indexWhere((item) => item.id == settlementId);
    if (index == -1) {
      return;
    }
    final settlement = _settlements[index];
    _settlements[index] = settlement.copyWith(
      deletedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _touchGroup(settlement.groupId);
    await _persistSettlements();
    await _persistGroups();
    notifyListeners();
  }

  Future<void> syncCurrency(AppCurrency currency) async {
    _preferences ??= await SharedPreferences.getInstance();
    if (_currencyCode == currency.code) {
      return;
    }

    final rateResult = await _exchangeRateService.latestRate(
      base: _currencyCode,
      target: currency.code,
      preferences: _preferences!,
    );
    final rate = rateResult.rate;
    for (var index = 0; index < _expenses.length; index++) {
      final expense = _expenses[index];
      _expenses[index] = expense.copyWith(
        amount: _round(expense.amount * rate),
        splitInput: expense.splitInput.map(
          (key, value) => MapEntry(
            key,
            expense.splitMode == GroupSplitMode.exact ? _round(value * rate) : value,
          ),
        ),
        splitAmounts: expense.splitAmounts.map(
          (key, value) => MapEntry(key, _round(value * rate)),
        ),
        currencyCode: currency.code,
        updatedAt: DateTime.now(),
      );
    }
    for (var index = 0; index < _settlements.length; index++) {
      final settlement = _settlements[index];
      _settlements[index] = settlement.copyWith(
        amount: _round(settlement.amount * rate),
        currencyCode: currency.code,
        updatedAt: DateTime.now(),
      );
    }
    _currencyCode = currency.code;
    await _persistExpenses();
    await _persistSettlements();
    notifyListeners();
  }

  GroupComputation computeGroup(String groupId) {
    final group = groupById(groupId);
    final members = membersForGroup(groupId);
    if (group == null) {
      return GroupComputation.empty();
    }

    final netCents = <String, int>{for (final member in members) member.id: 0};
    var totalExpenseCents = 0;
    var totalSettlementCents = 0;

    for (final expense in expensesForGroup(groupId)) {
      final expenseCents = _toCents(expense.amount);
      totalExpenseCents += expenseCents;
      netCents.update(expense.paidByProfileId, (value) => value + expenseCents, ifAbsent: () => expenseCents);
      for (final entry in expense.splitAmounts.entries) {
        final cents = _toCents(entry.value);
        netCents.update(entry.key, (value) => value - cents, ifAbsent: () => -cents);
      }
    }

    for (final settlement in settlementsForGroup(groupId)) {
      final cents = _toCents(settlement.amount);
      totalSettlementCents += cents;
      netCents.update(settlement.fromProfileId, (value) => value + cents, ifAbsent: () => cents);
      netCents.update(settlement.toProfileId, (value) => value - cents, ifAbsent: () => -cents);
    }

    final transfers = _simplifyTransfers(netCents);
    final balances = members
        .map(
          (member) => GroupMemberBalance(
            profileId: member.id,
            netAmount: _fromCents(netCents[member.id] ?? 0),
          ),
        )
        .toList()
      ..sort((a, b) => b.netAmount.compareTo(a.netAmount));

    return GroupComputation(
      group: group,
      balances: balances,
      transfers: transfers,
      totalExpenseAmount: _fromCents(totalExpenseCents),
      totalSettlementAmount: _fromCents(totalSettlementCents),
      totalMembers: members.length,
    );
  }

  GroupListSummary groupSummary(String groupId) {
    final group = groupById(groupId);
    final computation = computeGroup(groupId);
    final activities = groupActivity(groupId);
    final you = computation.balanceFor(selfProfileId);
    return GroupListSummary(
      groupId: groupId,
      groupName: group?.name ?? '',
      memberCount: computation.totalMembers,
      totalSpend: computation.totalExpenseAmount,
      yourNetBalance: you,
      latestActivityAt: activities.isEmpty ? group?.updatedAt : activities.first.timestamp,
      latestActivityLabel: activities.isEmpty
          ? 'No activity yet'
          : _activityTitle(activities.first),
    );
  }

  List<GroupActivityItem> groupActivity(String groupId) {
    final items = <GroupActivityItem>[
      ...expensesForGroup(groupId).map(GroupActivityItem.expense),
      ...settlementsForGroup(groupId).map(GroupActivityItem.settlement),
    ]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  String participantSummary(String groupId, List<String> participantIds) {
    final members = participantIds.map(profileById).whereType<LocalProfile>().toList();
    if (members.isEmpty) {
      return 'No participants selected';
    }
    final includesYou = participantIds.contains(selfProfileId);
    if (includesYou && members.length == 1) {
      return 'With you';
    }
    if (includesYou) {
      return 'With you and +${members.length - 1}';
    }
    if (members.length == 1) {
      return 'With ${members.first.displayName}';
    }
    return 'With ${members.first.displayName} and +${members.length - 1}';
  }

  ExpenseSplitPreview previewSplit({
    required double totalAmount,
    required List<String> participantIds,
    required GroupSplitMode splitMode,
    required Map<String, double> splitInput,
    required String payerId,
  }) {
    if (totalAmount <= 0) {
      throw const GroupValidationException('Expense amount must be greater than 0.');
    }
    if (participantIds.isEmpty) {
      throw const GroupValidationException('Select at least one participant.');
    }

    final allocations = switch (splitMode) {
      GroupSplitMode.equal => _equalSplit(totalAmount, participantIds),
      GroupSplitMode.exact => _exactSplit(totalAmount, participantIds, splitInput),
      GroupSplitMode.percentage => _percentageSplit(totalAmount, participantIds, splitInput),
      GroupSplitMode.shares => _sharesSplit(totalAmount, participantIds, splitInput),
    };

    final totalCents = allocations.values.fold<int>(0, (sum, value) => sum + _toCents(value));
    if (totalCents != _toCents(totalAmount)) {
      throw const GroupValidationException('Split values must add up exactly to the expense total.');
    }

    final payerReimbursement = allocations.entries
        .where((entry) => entry.key != payerId)
        .fold<double>(0, (sum, entry) => sum + entry.value);

    return ExpenseSplitPreview(
      splitAmounts: allocations,
      payerId: payerId,
      payerReimbursement: _round(payerReimbursement),
      totalAmount: _round(totalAmount),
    );
  }

  String formatCurrency(double value, {String? symbol}) {
    final resolvedSymbol = switch (_currencyCode) {
      'EUR' => '€',
      'GBP' => '£',
      'PKR' => 'Rs',
      _ => symbol ?? r'$',
    };
    return '$resolvedSymbol${value.toStringAsFixed(2)}';
  }

  void _validateExpense(SharedExpense expense) {
    if (expense.description.trim().isEmpty) {
      throw const GroupValidationException('Expense description is required.');
    }
    if (expense.amount <= 0) {
      throw const GroupValidationException('Expense amount must be greater than 0.');
    }
    final group = groupById(expense.groupId);
    if (group == null || group.isArchived) {
      throw const GroupValidationException('Choose an active group.');
    }
    if (!group.memberIds.contains(expense.paidByProfileId)) {
      throw const GroupValidationException('Payer must belong to the selected group.');
    }
    if (expense.participantIds.isEmpty) {
      throw const GroupValidationException('Select at least one participant.');
    }
    for (final id in expense.participantIds) {
      if (!group.memberIds.contains(id)) {
        throw const GroupValidationException('All participants must belong to the group.');
      }
    }
    final preview = previewSplit(
      totalAmount: expense.amount,
      participantIds: expense.participantIds,
      splitMode: expense.splitMode,
      splitInput: expense.splitInput,
      payerId: expense.paidByProfileId,
    );
    if (!_sameAmounts(preview.splitAmounts, expense.splitAmounts)) {
      throw const GroupValidationException('Split preview is out of date. Review the amounts and save again.');
    }
  }

  void _validateSettlement(SettlementRecord record) {
    if (record.amount <= 0) {
      throw const GroupValidationException('Settlement amount must be greater than 0.');
    }
    final group = groupById(record.groupId);
    if (group == null || group.isArchived) {
      throw const GroupValidationException('Choose an active group.');
    }
    if (record.fromProfileId == record.toProfileId) {
      throw const GroupValidationException('Settlement requires two different members.');
    }
    if (!group.memberIds.contains(record.fromProfileId) || !group.memberIds.contains(record.toProfileId)) {
      throw const GroupValidationException('Settlement members must belong to the group.');
    }
    final pair = computeGroup(record.groupId).transfers.where(
      (transfer) => transfer.fromProfileId == record.fromProfileId && transfer.toProfileId == record.toProfileId,
    );
    final current = pair.isEmpty ? 0 : pair.first.amount;
    if (record.amount - current > 0.009) {
      throw const GroupValidationException(
        'Settlement cannot exceed the current payable amount.',
      );
    }
  }

  void _touchGroup(String groupId) {
    final group = groupById(groupId);
    if (group == null) {
      return;
    }
    _replaceGroup(group.copyWith(updatedAt: DateTime.now()));
  }

  void _replaceGroup(ExpenseGroup group) {
    final index = _groups.indexWhere((item) => item.id == group.id);
    if (index >= 0) {
      _groups[index] = group;
    }
  }

  List<GroupTransfer> _simplifyTransfers(Map<String, int> netCents) {
    final creditors = <({String id, int amount})>[];
    final debtors = <({String id, int amount})>[];
    for (final entry in netCents.entries) {
      if (entry.value > 0) {
        creditors.add((id: entry.key, amount: entry.value));
      } else if (entry.value < 0) {
        debtors.add((id: entry.key, amount: -entry.value));
      }
    }

    creditors.sort((a, b) => b.amount.compareTo(a.amount));
    debtors.sort((a, b) => b.amount.compareTo(a.amount));

    final transfers = <GroupTransfer>[];
    var creditorIndex = 0;
    var debtorIndex = 0;
    while (creditorIndex < creditors.length && debtorIndex < debtors.length) {
      final creditor = creditors[creditorIndex];
      final debtor = debtors[debtorIndex];
      final settledCents = math.min(creditor.amount, debtor.amount);
      transfers.add(
        GroupTransfer(
          fromProfileId: debtor.id,
          toProfileId: creditor.id,
          amount: _fromCents(settledCents),
        ),
      );
      creditors[creditorIndex] = (
        id: creditor.id,
        amount: creditor.amount - settledCents,
      );
      debtors[debtorIndex] = (
        id: debtor.id,
        amount: debtor.amount - settledCents,
      );
      if (creditors[creditorIndex].amount == 0) {
        creditorIndex++;
      }
      if (debtors[debtorIndex].amount == 0) {
        debtorIndex++;
      }
    }
    return transfers;
  }

  LocalProfile? _findProfileByName(String name) {
    final normalized = name.trim().toLowerCase();
    for (final profile in _profiles) {
      if (profile.displayName.trim().toLowerCase() == normalized) {
        return profile;
      }
    }
    return null;
  }

  bool _memberHasGroupHistory(String groupId, String memberId) {
    return expensesForGroup(groupId).any(
          (expense) =>
              expense.paidByProfileId == memberId ||
              expense.participantIds.contains(memberId),
        ) ||
        settlementsForGroup(groupId).any(
          (item) => item.fromProfileId == memberId || item.toProfileId == memberId,
        );
  }

  double _memberOutstandingBalance(String groupId, String memberId) {
    return computeGroup(groupId).balanceFor(memberId);
  }

  void _ensureSelfProfile() {
    final existingIndex = _profiles.indexWhere((profile) => profile.id == selfProfileId);
    final self = LocalProfile(
      id: selfProfileId,
      displayName: 'You',
      avatarColorValue: 0xFF10B981,
      isSelf: true,
      createdAt: DateTime.now(),
    );
    if (existingIndex == -1) {
      _profiles.insert(0, self);
      return;
    }
    _profiles[existingIndex] = self;
  }

  List<String> _normalizeMemberNames(List<String> input) {
    final names = <String>[];
    final seen = <String>{};
    for (final raw in input) {
      final normalized = raw.trim();
      if (normalized.isEmpty) {
        continue;
      }
      final lower = normalized.toLowerCase();
      if (lower == 'you') {
        continue;
      }
      if (!seen.add(lower)) {
        throw GroupValidationException('Duplicate member name: $normalized');
      }
      names.add(normalized);
    }
    return names;
  }

  int _nextProfileColorValue() {
    final index = _profiles.where((profile) => !profile.isSelf).length;
    return _groupPalette[index % _groupPalette.length];
  }

  String _createId(String prefix) {
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}-${math.Random().nextInt(9999)}';
  }

  Map<String, double> _equalSplit(double totalAmount, List<String> participantIds) {
    final totalCents = _toCents(totalAmount);
    final count = participantIds.length;
    final base = totalCents ~/ count;
    final remainder = totalCents % count;
    final result = <String, double>{};
    for (var index = 0; index < participantIds.length; index++) {
      final cents = base + (index < remainder ? 1 : 0);
      result[participantIds[index]] = _fromCents(cents);
    }
    return result;
  }

  Map<String, double> _exactSplit(
    double totalAmount,
    List<String> participantIds,
    Map<String, double> splitInput,
  ) {
    final result = <String, double>{};
    var totalCents = 0;
    for (final participantId in participantIds) {
      final value = splitInput[participantId];
      if (value == null) {
        throw const GroupValidationException('Enter every exact split amount.');
      }
      if (value < 0) {
        throw const GroupValidationException('Exact split amounts cannot be negative.');
      }
      final rounded = _round(value);
      result[participantId] = rounded;
      totalCents += _toCents(rounded);
    }
    if (totalCents != _toCents(totalAmount)) {
      throw const GroupValidationException('Exact split amounts must match the total expense.');
    }
    return result;
  }

  Map<String, double> _percentageSplit(
    double totalAmount,
    List<String> participantIds,
    Map<String, double> splitInput,
  ) {
    final percentages = <String, double>{};
    var total = 0.0;
    for (final participantId in participantIds) {
      final value = splitInput[participantId];
      if (value == null) {
        throw const GroupValidationException('Enter every participant percentage.');
      }
      if (value < 0 || value > 100) {
        throw const GroupValidationException('Percentages must stay between 0 and 100.');
      }
      percentages[participantId] = value;
      total += value;
    }
    if ((total - 100).abs() > 0.001) {
      throw const GroupValidationException('Percentages must add up to 100.');
    }
    return _allocateWithWeights(totalAmount, participantIds, percentages);
  }

  Map<String, double> _sharesSplit(
    double totalAmount,
    List<String> participantIds,
    Map<String, double> splitInput,
  ) {
    final shares = <String, double>{};
    var total = 0.0;
    for (final participantId in participantIds) {
      final value = splitInput[participantId];
      if (value == null) {
        throw const GroupValidationException('Enter shares for every participant.');
      }
      if (value < 0) {
        throw const GroupValidationException('Shares cannot be negative.');
      }
      shares[participantId] = value;
      total += value;
    }
    if (total <= 0) {
      throw const GroupValidationException('Total shares must be greater than 0.');
    }
    return _allocateWithWeights(totalAmount, participantIds, shares);
  }

  Map<String, double> _allocateWithWeights(
    double totalAmount,
    List<String> participantIds,
    Map<String, double> weights,
  ) {
    final totalCents = _toCents(totalAmount);
    final totalWeight = participantIds.fold<double>(
      0,
      (sum, id) => sum + (weights[id] ?? 0),
    );
    final base = <String, int>{};
    final remainders = <({String id, double remainder})>[];
    var assigned = 0;
    for (final participantId in participantIds) {
      final raw = totalCents * ((weights[participantId] ?? 0) / totalWeight);
      final floorValue = raw.floor();
      base[participantId] = floorValue;
      assigned += floorValue;
      remainders.add((id: participantId, remainder: raw - floorValue));
    }
    remainders.sort((a, b) => b.remainder.compareTo(a.remainder));
    for (var index = 0; index < totalCents - assigned; index++) {
      final id = remainders[index % remainders.length].id;
      base[id] = (base[id] ?? 0) + 1;
    }
    return base.map<String, double>((key, value) => MapEntry(key, _fromCents(value)));
  }

  Future<void> _persistAll() async {
    await _persistProfiles();
    await _persistGroups();
    await _persistExpenses();
    await _persistSettlements();
  }

  Future<void> _persistProfiles() async {
    _preferences ??= await SharedPreferences.getInstance();
    await _preferences!.setString(
      _profilesKey,
      jsonEncode(_profiles.map((item) => item.toMap()).toList()),
    );
  }

  Future<void> _persistGroups() async {
    _preferences ??= await SharedPreferences.getInstance();
    await _preferences!.setString(
      _groupsKey,
      jsonEncode(_groups.map((item) => item.toMap()).toList()),
    );
  }

  Future<void> _persistExpenses() async {
    _preferences ??= await SharedPreferences.getInstance();
    await _preferences!.setString(
      _expensesKey,
      jsonEncode(_expenses.map((item) => item.toMap()).toList()),
    );
  }

  Future<void> _persistSettlements() async {
    _preferences ??= await SharedPreferences.getInstance();
    await _preferences!.setString(
      _settlementsKey,
      jsonEncode(_settlements.map((item) => item.toMap()).toList()),
    );
  }

  bool _sameAmounts(Map<String, double> left, Map<String, double> right) {
    if (left.length != right.length) {
      return false;
    }
    for (final entry in left.entries) {
      if ((right[entry.key] ?? double.nan).isNaN) {
        return false;
      }
      if ((_toCents(right[entry.key]!) - _toCents(entry.value)).abs() > 0) {
        return false;
      }
    }
    return true;
  }

  List<T> _decodeList<T>(
    String? encoded,
    T Function(Map<String, dynamic>) factory,
  ) {
    if (encoded == null || encoded.isEmpty) {
      return <T>[];
    }
    final decoded = jsonDecode(encoded) as List<dynamic>;
    return decoded
        .cast<Map<dynamic, dynamic>>()
        .map((item) => factory(Map<String, dynamic>.from(item)))
        .toList();
  }

  int _toCents(double value) => (value * 100).round();
  double _fromCents(int cents) => cents / 100;
  double _round(double value) => _fromCents(_toCents(value));

  String _activityTitle(GroupActivityItem item) {
    if (item.expense case final expense?) {
      return expense.description;
    }
    final settlement = item.settlement!;
    final from = profileById(settlement.fromProfileId)?.displayName ?? 'Member';
    final to = profileById(settlement.toProfileId)?.displayName ?? 'Member';
    return '$from settled with $to';
  }
}

class ExpenseSplitPreview {
  const ExpenseSplitPreview({
    required this.splitAmounts,
    required this.payerId,
    required this.payerReimbursement,
    required this.totalAmount,
  });

  final Map<String, double> splitAmounts;
  final String payerId;
  final double payerReimbursement;
  final double totalAmount;
}

class GroupComputation {
  const GroupComputation({
    required this.group,
    required this.balances,
    required this.transfers,
    required this.totalExpenseAmount,
    required this.totalSettlementAmount,
    required this.totalMembers,
  });

  factory GroupComputation.empty() {
    return const GroupComputation(
      group: null,
      balances: <GroupMemberBalance>[],
      transfers: <GroupTransfer>[],
      totalExpenseAmount: 0,
      totalSettlementAmount: 0,
      totalMembers: 0,
    );
  }

  final ExpenseGroup? group;
  final List<GroupMemberBalance> balances;
  final List<GroupTransfer> transfers;
  final double totalExpenseAmount;
  final double totalSettlementAmount;
  final int totalMembers;

  double balanceFor(String profileId) {
    for (final balance in balances) {
      if (balance.profileId == profileId) {
        return balance.netAmount;
      }
    }
    return 0;
  }
}

class GroupListSummary {
  const GroupListSummary({
    required this.groupId,
    required this.groupName,
    required this.memberCount,
    required this.totalSpend,
    required this.yourNetBalance,
    required this.latestActivityAt,
    required this.latestActivityLabel,
  });

  final String groupId;
  final String groupName;
  final int memberCount;
  final double totalSpend;
  final double yourNetBalance;
  final DateTime? latestActivityAt;
  final String latestActivityLabel;
}
