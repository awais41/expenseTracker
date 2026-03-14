import 'dart:math' as math;

import '../../../../core/data/mock_cloud_store.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/result/app_result.dart';
import '../../../auth_sync/domain/models/auth_models.dart';
import '../../domain/models/online_group_models.dart';
import '../../domain/repositories/activity_repository.dart';
import '../../domain/repositories/balances_repository.dart';
import '../../domain/repositories/expenses_repository.dart';
import '../../domain/repositories/groups_repository.dart';
import '../../domain/repositories/migration_repository.dart';
import '../../domain/repositories/settlements_repository.dart';
import 'online_group_dtos.dart';

class MockOnlineGroupsRepository
    implements
        GroupsRepository,
        ExpensesRepository,
        SettlementsRepository,
        BalancesRepository,
        ActivityRepository,
        MigrationRepository {
  MockOnlineGroupsRepository(this._store);

  final MockCloudStore _store;

  @override
  Future<AppResult<Group>> createGroup({
    required String currentUserId,
    required String name,
    String? description,
    required bool isDiscoverable,
  }) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      return const AppFailureResult<Group>(
        ValidationFailure('Group name is required.'),
      );
    }
    final groups = await _store.loadGroups();
    final members = await _store.loadMembers();
    final dto = GroupDto(
      id: _store.createId('group'),
      name: normalizedName,
      description: description?.trim().isEmpty == true ? null : description?.trim(),
      createdByUserId: currentUserId,
      isDiscoverable: isDiscoverable,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    groups.add(dto);
    members.add(
      GroupMemberDto(
        id: _store.createId('membership'),
        groupId: dto.id,
        userId: currentUserId,
        role: GroupRole.owner.name,
        status: MembershipStatus.active.name,
        joinedAt: DateTime.now(),
      ),
    );
    await _store.saveGroups(groups);
    await _store.saveMembers(members);
    await _appendActivity(
      groupId: dto.id,
      actorUserId: currentUserId,
      type: 'group_created',
      referenceId: dto.id,
      message: 'created the group ${dto.name}',
    );
    return AppSuccess(dto.toDomain());
  }

  @override
  Future<AppResult<List<Group>>> getGroups(String userId) async {
    final groups = await _store.loadGroups();
    final members = await _store.loadMembers();
    final memberGroupIds = members
        .where((item) => item.userId == userId && item.status == MembershipStatus.active.name)
        .map((item) => item.groupId)
        .toSet();
    final result = groups
        .where((item) => memberGroupIds.contains(item.id))
        .map((item) => item.toDomain())
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return AppSuccess(result);
  }

  @override
  Future<AppResult<List<Group>>> getDiscoverableGroups(String userId) async {
    final groups = await _store.loadGroups();
    final members = await _store.loadMembers();
    final joined = members
        .where((item) => item.userId == userId && item.status == MembershipStatus.active.name)
        .map((item) => item.groupId)
        .toSet();
    final result = groups
        .where((item) => item.isDiscoverable && !joined.contains(item.id))
        .map((item) => item.toDomain())
        .toList();
    return AppSuccess(result);
  }

  @override
  Future<AppResult<List<GroupMember>>> getGroupMembers(String groupId) async {
    final members = await _store.loadMembers();
    return AppSuccess(
      members
          .where((item) => item.groupId == groupId && item.status == MembershipStatus.active.name)
          .map((item) => item.toDomain())
          .toList(),
    );
  }

  @override
  Future<AppResult<List<GroupInvite>>> getIncomingInvites(String userId) async {
    final invites = await _store.loadInvites();
    return AppSuccess(
      invites
          .where((item) => item.inviteeUserId == userId && item.status == InviteStatus.pending.name)
          .map((item) => item.toDomain())
          .toList(),
    );
  }

  @override
  Future<AppResult<List<GroupInvite>>> getOutgoingInvites(String groupId) async {
    final invites = await _store.loadInvites();
    return AppSuccess(
      invites
          .where((item) => item.groupId == groupId && item.status == InviteStatus.pending.name)
          .map((item) => item.toDomain())
          .toList(),
    );
  }

  @override
  Future<AppResult<List<GroupJoinRequest>>> getPendingJoinRequests(String groupId) async {
    final requests = await _store.loadRequests();
    return AppSuccess(
      requests
          .where((item) => item.groupId == groupId && item.status == InviteStatus.pending.name)
          .map((item) => item.toDomain())
          .toList(),
    );
  }

  @override
  Future<AppResult<GroupInvite>> inviteUser({
    required String currentUserId,
    required String groupId,
    required AppUser invitee,
  }) async {
    final permission = await _canManageGroup(currentUserId, groupId);
    if (permission != null) {
      return AppFailureResult(permission);
    }
    final invites = await _store.loadInvites();
    final members = await _store.loadMembers();
    final requests = await _store.loadRequests();
    final alreadyMember = members.any(
      (item) =>
          item.groupId == groupId &&
          item.userId == invitee.id &&
          item.status == MembershipStatus.active.name,
    );
    if (alreadyMember) {
      return const AppFailureResult<GroupInvite>(
        ConflictFailure('That user is already in the group.'),
      );
    }
    final duplicateInvite = invites.any(
      (item) =>
          item.groupId == groupId &&
          item.inviteeUserId == invitee.id &&
          item.status == InviteStatus.pending.name,
    );
    if (duplicateInvite) {
      return const AppFailureResult<GroupInvite>(
        ConflictFailure('There is already a pending invite for this user.'),
      );
    }
    final hasPendingRequest = requests.any(
      (item) =>
          item.groupId == groupId &&
          item.requesterUserId == invitee.id &&
          item.status == InviteStatus.pending.name,
    );
    if (hasPendingRequest) {
      return const AppFailureResult<GroupInvite>(
        ConflictFailure('This user already requested to join the group.'),
      );
    }

    final invite = GroupInviteDto(
      id: _store.createId('invite'),
      groupId: groupId,
      inviterUserId: currentUserId,
      inviteeUserId: invitee.id,
      status: InviteStatus.pending.name,
      createdAt: DateTime.now(),
    );
    invites.add(invite);
    await _store.saveInvites(invites);
    await _appendActivity(
      groupId: groupId,
      actorUserId: currentUserId,
      type: 'invite_sent',
      referenceId: invite.id,
      message: 'sent a group invite',
    );
    return AppSuccess(invite.toDomain());
  }

  @override
  Future<AppResult<GroupJoinRequest>> requestToJoinGroup({
    required String currentUserId,
    required String groupId,
  }) async {
    final groups = await _store.loadGroups();
    final group = groups.where((item) => item.id == groupId).firstOrNull;
    if (group == null) {
      return const AppFailureResult<GroupJoinRequest>(NotFoundFailure());
    }
    if (!group.isDiscoverable) {
      return const AppFailureResult<GroupJoinRequest>(
        ForbiddenFailure('This group is invite-only.'),
      );
    }
    final invites = await _store.loadInvites();
    final requests = await _store.loadRequests();
    final members = await _store.loadMembers();
    final activeMember = members.any(
      (item) => item.groupId == groupId && item.userId == currentUserId && item.status == MembershipStatus.active.name,
    );
    if (activeMember) {
      return const AppFailureResult<GroupJoinRequest>(
        ConflictFailure('You are already in this group.'),
      );
    }
    final pendingInvite = invites.any(
      (item) =>
          item.groupId == groupId &&
          item.inviteeUserId == currentUserId &&
          item.status == InviteStatus.pending.name,
    );
    if (pendingInvite) {
      return const AppFailureResult<GroupJoinRequest>(
        ConflictFailure('You already have a pending invite for this group.'),
      );
    }
    final duplicateRequest = requests.any(
      (item) =>
          item.groupId == groupId &&
          item.requesterUserId == currentUserId &&
          item.status == InviteStatus.pending.name,
    );
    if (duplicateRequest) {
      return const AppFailureResult<GroupJoinRequest>(
        ConflictFailure('You already requested to join this group.'),
      );
    }

    final request = GroupJoinRequestDto(
      id: _store.createId('join-request'),
      groupId: groupId,
      requesterUserId: currentUserId,
      status: InviteStatus.pending.name,
      createdAt: DateTime.now(),
    );
    requests.add(request);
    await _store.saveRequests(requests);
    await _appendActivity(
      groupId: groupId,
      actorUserId: currentUserId,
      type: 'join_request',
      referenceId: request.id,
      message: 'requested to join the group',
    );
    return AppSuccess(request.toDomain());
  }

  @override
  Future<AppResult<void>> respondToInvite({
    required String currentUserId,
    required String inviteId,
    required bool accept,
  }) async {
    final invites = await _store.loadInvites();
    final index = invites.indexWhere((item) => item.id == inviteId);
    if (index == -1) {
      return const AppFailureResult<void>(NotFoundFailure());
    }
    final invite = invites[index];
    if (invite.inviteeUserId != currentUserId) {
      return const AppFailureResult<void>(ForbiddenFailure());
    }
    invites[index] = GroupInviteDto(
      id: invite.id,
      groupId: invite.groupId,
      inviterUserId: invite.inviterUserId,
      inviteeUserId: invite.inviteeUserId,
      status: accept ? InviteStatus.accepted.name : InviteStatus.rejected.name,
      createdAt: invite.createdAt,
      respondedAt: DateTime.now(),
    );
    await _store.saveInvites(invites);
    if (accept) {
      final members = await _store.loadMembers();
      members.add(
        GroupMemberDto(
          id: _store.createId('membership'),
          groupId: invite.groupId,
          userId: currentUserId,
          role: GroupRole.member.name,
          status: MembershipStatus.active.name,
          joinedAt: DateTime.now(),
        ),
      );
      await _store.saveMembers(members);
    }
    await _appendActivity(
      groupId: invite.groupId,
      actorUserId: currentUserId,
      type: accept ? 'invite_accepted' : 'invite_rejected',
      referenceId: invite.id,
      message: accept ? 'accepted a group invite' : 'rejected a group invite',
    );
    return const AppSuccess(null);
  }

  @override
  Future<AppResult<void>> respondToJoinRequest({
    required String currentUserId,
    required String requestId,
    required bool accept,
  }) async {
    final requests = await _store.loadRequests();
    final index = requests.indexWhere((item) => item.id == requestId);
    if (index == -1) {
      return const AppFailureResult<void>(NotFoundFailure());
    }
    final request = requests[index];
    final permission = await _canManageGroup(currentUserId, request.groupId);
    if (permission != null) {
      return AppFailureResult(permission);
    }
    requests[index] = GroupJoinRequestDto(
      id: request.id,
      groupId: request.groupId,
      requesterUserId: request.requesterUserId,
      status: accept ? InviteStatus.accepted.name : InviteStatus.rejected.name,
      createdAt: request.createdAt,
      respondedAt: DateTime.now(),
    );
    await _store.saveRequests(requests);
    if (accept) {
      final members = await _store.loadMembers();
      members.add(
        GroupMemberDto(
          id: _store.createId('membership'),
          groupId: request.groupId,
          userId: request.requesterUserId,
          role: GroupRole.member.name,
          status: MembershipStatus.active.name,
          joinedAt: DateTime.now(),
        ),
      );
      await _store.saveMembers(members);
    }
    await _appendActivity(
      groupId: request.groupId,
      actorUserId: currentUserId,
      type: accept ? 'join_request_approved' : 'join_request_rejected',
      referenceId: request.id,
      message: accept ? 'approved a join request' : 'rejected a join request',
    );
    return const AppSuccess(null);
  }

  @override
  Future<AppResult<Group>> updateGroup({
    required String currentUserId,
    required String groupId,
    required String name,
    String? description,
    required bool isDiscoverable,
  }) async {
    final permission = await _canManageGroup(currentUserId, groupId);
    if (permission != null) {
      return AppFailureResult(permission);
    }
    final groups = await _store.loadGroups();
    final index = groups.indexWhere((item) => item.id == groupId);
    if (index == -1) {
      return const AppFailureResult<Group>(NotFoundFailure());
    }
    final current = groups[index];
    final updated = GroupDto(
      id: current.id,
      name: name.trim(),
      description: description?.trim().isEmpty == true ? null : description?.trim(),
      createdByUserId: current.createdByUserId,
      isDiscoverable: isDiscoverable,
      createdAt: current.createdAt,
      updatedAt: DateTime.now(),
    );
    groups[index] = updated;
    await _store.saveGroups(groups);
    return AppSuccess(updated.toDomain());
  }

  @override
  Future<AppResult<List<GroupExpense>>> getGroupExpenses(String groupId) async {
    final expenses = await _store.loadExpenses();
    final result = expenses
        .where((item) => item.groupId == groupId)
        .map((item) => item.toDomain())
        .toList()
      ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
    return AppSuccess(result);
  }

  @override
  Future<AppResult<GroupExpense>> createExpense({
    required String currentUserId,
    required GroupExpense expense,
  }) async {
    final validation = await _validateExpense(currentUserId, expense);
    if (validation != null) {
      return AppFailureResult(validation);
    }
    final items = await _store.loadExpenses();
    final dto = GroupExpenseDto(
      id: expense.id,
      groupId: expense.groupId,
      createdByUserId: currentUserId,
      title: expense.title,
      description: expense.description,
      notes: expense.notes,
      amountMinor: expense.amountMinor,
      currencyCode: expense.currencyCode,
      splitMode: expense.splitMode.name,
      paidByUserId: expense.paidByUserId,
      includePayerInSplit: expense.includePayerInSplit,
      category: expense.category,
      expenseDate: expense.expenseDate,
      createdAt: expense.createdAt,
      updatedAt: expense.updatedAt,
      participants: expense.participants
          .map(
            (item) => ExpenseParticipantDto(
              id: item.id,
              expenseId: expense.id,
              userId: item.userId,
              shareValue: item.shareValue,
              shareType: item.shareType,
              amountOwedMinor: item.amountOwedMinor,
            ),
          )
          .toList(),
    );
    items.add(dto);
    await _store.saveExpenses(items);
    await _appendActivity(
      groupId: expense.groupId,
      actorUserId: currentUserId,
      type: 'expense_created',
      referenceId: expense.id,
      message: 'added "${expense.title}"',
    );
    return AppSuccess(dto.toDomain());
  }

  @override
  Future<AppResult<void>> deleteExpense({
    required String currentUserId,
    required String groupId,
    required String expenseId,
  }) async {
    final items = await _store.loadExpenses();
    final expense = items.where((item) => item.id == expenseId).firstOrNull;
    if (expense == null) {
      return const AppFailureResult<void>(NotFoundFailure());
    }
    final permission = await _canEditFinancialRecord(
      currentUserId: currentUserId,
      groupId: expense.groupId,
      createdByUserId: expense.createdByUserId,
    );
    if (permission != null) {
      return AppFailureResult(permission);
    }
    items.removeWhere((item) => item.id == expenseId);
    await _store.saveExpenses(items);
    await _appendActivity(
      groupId: expense.groupId,
      actorUserId: currentUserId,
      type: 'expense_deleted',
      referenceId: expense.id,
      message: 'deleted "${expense.title}"',
    );
    return const AppSuccess(null);
  }

  @override
  Future<AppResult<GroupExpense>> updateExpense({
    required String currentUserId,
    required GroupExpense expense,
  }) async {
    final validation = await _validateExpense(currentUserId, expense);
    if (validation != null) {
      return AppFailureResult(validation);
    }
    final items = await _store.loadExpenses();
    final index = items.indexWhere((item) => item.id == expense.id);
    if (index == -1) {
      return const AppFailureResult<GroupExpense>(NotFoundFailure());
    }
    final permission = await _canEditFinancialRecord(
      currentUserId: currentUserId,
      groupId: expense.groupId,
      createdByUserId: items[index].createdByUserId,
    );
    if (permission != null) {
      return AppFailureResult(permission);
    }
    final updated = GroupExpenseDto(
      id: expense.id,
      groupId: expense.groupId,
      createdByUserId: items[index].createdByUserId,
      title: expense.title,
      description: expense.description,
      notes: expense.notes,
      amountMinor: expense.amountMinor,
      currencyCode: expense.currencyCode,
      splitMode: expense.splitMode.name,
      paidByUserId: expense.paidByUserId,
      includePayerInSplit: expense.includePayerInSplit,
      category: expense.category,
      expenseDate: expense.expenseDate,
      createdAt: items[index].createdAt,
      updatedAt: DateTime.now(),
      participants: expense.participants
          .map(
            (item) => ExpenseParticipantDto(
              id: item.id,
              expenseId: expense.id,
              userId: item.userId,
              shareValue: item.shareValue,
              shareType: item.shareType,
              amountOwedMinor: item.amountOwedMinor,
            ),
          )
          .toList(),
    );
    items[index] = updated;
    await _store.saveExpenses(items);
    await _appendActivity(
      groupId: expense.groupId,
      actorUserId: currentUserId,
      type: 'expense_updated',
      referenceId: expense.id,
      message: 'updated "${expense.title}"',
    );
    return AppSuccess(updated.toDomain());
  }

  @override
  Future<AppResult<List<Settlement>>> getSettlements(String groupId) async {
    final items = await _store.loadSettlements();
    final result = items
        .where((item) => item.groupId == groupId)
        .map((item) => item.toDomain())
        .toList()
      ..sort((a, b) => b.settlementDate.compareTo(a.settlementDate));
    return AppSuccess(result);
  }

  @override
  Future<AppResult<Settlement>> createSettlement({
    required String currentUserId,
    required Settlement settlement,
  }) async {
    final validation = await _validateSettlement(currentUserId, settlement);
    if (validation != null) {
      return AppFailureResult(validation);
    }
    final items = await _store.loadSettlements();
    final dto = SettlementDto(
      id: settlement.id,
      groupId: settlement.groupId,
      fromUserId: settlement.fromUserId,
      toUserId: settlement.toUserId,
      amountMinor: settlement.amountMinor,
      currencyCode: settlement.currencyCode,
      note: settlement.note,
      settlementDate: settlement.settlementDate,
      createdByUserId: currentUserId,
      createdAt: settlement.createdAt,
      updatedAt: settlement.updatedAt,
    );
    items.add(dto);
    await _store.saveSettlements(items);
    await _appendActivity(
      groupId: settlement.groupId,
      actorUserId: currentUserId,
      type: 'settlement_created',
      referenceId: settlement.id,
      message: 'recorded a settlement',
    );
    return AppSuccess(dto.toDomain());
  }

  @override
  Future<AppResult<void>> deleteSettlement({
    required String currentUserId,
    required String groupId,
    required String settlementId,
  }) async {
    final items = await _store.loadSettlements();
    final settlement = items.where((item) => item.id == settlementId).firstOrNull;
    if (settlement == null) {
      return const AppFailureResult<void>(NotFoundFailure());
    }
    final permission = await _canEditFinancialRecord(
      currentUserId: currentUserId,
      groupId: settlement.groupId,
      createdByUserId: settlement.createdByUserId,
    );
    if (permission != null) {
      return AppFailureResult(permission);
    }
    items.removeWhere((item) => item.id == settlementId);
    await _store.saveSettlements(items);
    await _appendActivity(
      groupId: settlement.groupId,
      actorUserId: currentUserId,
      type: 'settlement_deleted',
      referenceId: settlementId,
      message: 'deleted a settlement',
    );
    return const AppSuccess(null);
  }

  @override
  Future<AppResult<Settlement>> updateSettlement({
    required String currentUserId,
    required Settlement settlement,
  }) async {
    final validation = await _validateSettlement(currentUserId, settlement);
    if (validation != null) {
      return AppFailureResult(validation);
    }
    final items = await _store.loadSettlements();
    final index = items.indexWhere((item) => item.id == settlement.id);
    if (index == -1) {
      return const AppFailureResult<Settlement>(NotFoundFailure());
    }
    final permission = await _canEditFinancialRecord(
      currentUserId: currentUserId,
      groupId: settlement.groupId,
      createdByUserId: items[index].createdByUserId,
    );
    if (permission != null) {
      return AppFailureResult(permission);
    }
    final updated = SettlementDto(
      id: settlement.id,
      groupId: settlement.groupId,
      fromUserId: settlement.fromUserId,
      toUserId: settlement.toUserId,
      amountMinor: settlement.amountMinor,
      currencyCode: settlement.currencyCode,
      note: settlement.note,
      settlementDate: settlement.settlementDate,
      createdByUserId: items[index].createdByUserId,
      createdAt: items[index].createdAt,
      updatedAt: DateTime.now(),
    );
    items[index] = updated;
    await _store.saveSettlements(items);
    await _appendActivity(
      groupId: settlement.groupId,
      actorUserId: currentUserId,
      type: 'settlement_updated',
      referenceId: settlement.id,
      message: 'updated a settlement',
    );
    return AppSuccess(updated.toDomain());
  }

  @override
  Future<AppResult<List<GroupBalanceSummary>>> getGroupBalances(String groupId) async {
    final summaries = await _computeBalances(groupId);
    return AppSuccess(summaries);
  }

  @override
  Future<AppResult<List<GroupTransfer>>> getGroupTransfers(String groupId) async {
    final balances = await _computeBalances(groupId);
    final cents = <String, int>{
      for (final item in balances) item.userId: item.netAmountMinor,
    };
    return AppSuccess(_simplifyTransfers(cents));
  }

  @override
  Future<AppResult<List<ActivityItem>>> getGroupActivity(String groupId) async {
    final items = await _store.loadActivity();
    return AppSuccess(
      items
          .where((item) => item.groupId == groupId)
          .map((item) => item.toDomain())
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    );
  }

  @override
  Future<AppResult<MigrationState>> checkImportNeeded(String userId) async {
    final state = await _store.loadMigrationState();
    final users = Set<String>.from(state['importedUsers'] as List<dynamic>? ?? const <dynamic>[]);
    if (users.contains(userId)) {
      return AppSuccess(
        MigrationState(
          accountDataImported: true,
          importedAt: DateTime.tryParse(state['importedAt_$userId'] as String? ?? ''),
          sourceDeviceId: state['sourceDeviceId'] as String?,
        ),
      );
    }
    return const AppSuccess(MigrationState(accountDataImported: false));
  }

  @override
  Future<AppResult<void>> importLocalDataOnce(String userId) async {
    final state = await _store.loadMigrationState();
    final users = Set<String>.from(state['importedUsers'] as List<dynamic>? ?? const <dynamic>[]);
    if (users.contains(userId)) {
      return const AppSuccess(null);
    }
    final importedAt = DateTime.now().toIso8601String();
    users.add(userId);
    state['importedUsers'] = users.toList();
    state['importedAt_$userId'] = importedAt;
    state['sourceDeviceId'] = 'local-device';
    await _store.saveMigrationState(state);
    return const AppSuccess(null);
  }

  Future<AppFailure?> _validateExpense(String currentUserId, GroupExpense expense) async {
    if (expense.title.trim().isEmpty) {
      return const ValidationFailure('Expense title is required.');
    }
    if (expense.amountMinor <= 0) {
      return const ValidationFailure('Expense amount must be greater than 0.');
    }
    final members = await getGroupMembers(expense.groupId);
    final activeMembers = members.when(
      success: (value) => value,
      failure: (_) => const <GroupMember>[],
    );
    final isCurrentMember = activeMembers.any((item) => item.userId == currentUserId);
    if (!isCurrentMember) {
      return const ForbiddenFailure('Only active group members can create expenses.');
    }
    final payerExists = activeMembers.any((item) => item.userId == expense.paidByUserId);
    if (!payerExists) {
      return const ValidationFailure('Payer must be an active group member.');
    }
    final participantTotalMinor = expense.participants.fold<int>(
      0,
      (sum, participant) => sum + participant.amountOwedMinor,
    );
    if (participantTotalMinor != expense.amountMinor) {
      return const ValidationFailure('Split totals must match the full expense amount.');
    }
    return null;
  }

  Future<AppFailure?> _validateSettlement(String currentUserId, Settlement settlement) async {
    if (settlement.amountMinor <= 0) {
      return const ValidationFailure('Settlement amount must be greater than 0.');
    }
    final members = await getGroupMembers(settlement.groupId);
    final activeMembers = members.when(
      success: (value) => value,
      failure: (_) => const <GroupMember>[],
    );
    if (!activeMembers.any((item) => item.userId == currentUserId)) {
      return const ForbiddenFailure('Only active group members can record settlements.');
    }
    return null;
  }

  Future<AppFailure?> _canManageGroup(String currentUserId, String groupId) async {
    final members = await _store.loadMembers();
    final membership = members.where((item) {
      return item.groupId == groupId &&
          item.userId == currentUserId &&
          item.status == MembershipStatus.active.name;
    }).firstOrNull;
    if (membership == null) {
      return const ForbiddenFailure('You do not belong to this group.');
    }
    final role = GroupRole.fromName(membership.role);
    if (role != GroupRole.owner && role != GroupRole.admin) {
      return const ForbiddenFailure('Only owner or admin can manage this group.');
    }
    return null;
  }

  Future<AppFailure?> _canEditFinancialRecord({
    required String currentUserId,
    required String groupId,
    required String createdByUserId,
  }) async {
    if (createdByUserId == currentUserId) {
      return null;
    }
    return _canManageGroup(currentUserId, groupId);
  }

  Future<void> _appendActivity({
    required String groupId,
    required String actorUserId,
    required String type,
    required String referenceId,
    required String message,
  }) async {
    final items = await _store.loadActivity();
    items.add(
      ActivityDto(
        id: _store.createId('activity'),
        groupId: groupId,
        type: type,
        actorUserId: actorUserId,
        referenceId: referenceId,
        message: message,
        createdAt: DateTime.now(),
      ),
    );
    await _store.saveActivity(items);
  }

  Future<List<GroupBalanceSummary>> _computeBalances(String groupId) async {
    final members = await _store.loadMembers();
    final expenses = await _store.loadExpenses();
    final settlements = await _store.loadSettlements();
    final activeUsers = members
        .where((item) => item.groupId == groupId && item.status == MembershipStatus.active.name)
        .map((item) => item.userId)
        .toSet();
    final netCents = <String, int>{for (final userId in activeUsers) userId: 0};

    for (final expense in expenses.where((item) => item.groupId == groupId)) {
      final cents = expense.amountMinor;
      netCents.update(expense.paidByUserId, (value) => value + cents, ifAbsent: () => cents);
      for (final participant in expense.participants) {
        final owed = participant.amountOwedMinor;
        netCents.update(participant.userId, (value) => value - owed, ifAbsent: () => -owed);
      }
    }

    for (final settlement in settlements.where((item) => item.groupId == groupId)) {
      final cents = settlement.amountMinor;
      netCents.update(settlement.fromUserId, (value) => value + cents, ifAbsent: () => cents);
      netCents.update(settlement.toUserId, (value) => value - cents, ifAbsent: () => -cents);
    }

    return netCents.entries.map((entry) {
      return GroupBalanceSummary(
        groupId: groupId,
        userId: entry.key,
        totalOwedMinor: entry.value < 0 ? entry.value.abs() : 0,
        totalReceivableMinor: entry.value > 0 ? entry.value : 0,
        netAmountMinor: entry.value,
      );
    }).toList()
      ..sort((a, b) => b.netAmount.compareTo(a.netAmount));
  }

  List<GroupTransfer> _simplifyTransfers(Map<String, int> netCents) {
    final creditors = <({String userId, int amount})>[];
    final debtors = <({String userId, int amount})>[];
    for (final entry in netCents.entries) {
      if (entry.value > 0) {
        creditors.add((userId: entry.key, amount: entry.value));
      } else if (entry.value < 0) {
        debtors.add((userId: entry.key, amount: -entry.value));
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
      final amount = math.min(creditor.amount, debtor.amount);
      transfers.add(
        GroupTransfer(
          fromUserId: debtor.userId,
          toUserId: creditor.userId,
          amountMinor: amount,
        ),
      );
      creditors[creditorIndex] = (
        userId: creditor.userId,
        amount: creditor.amount - amount,
      );
      debtors[debtorIndex] = (
        userId: debtor.userId,
        amount: debtor.amount - amount,
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

}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
