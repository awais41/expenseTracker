import 'package:flutter/material.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/result/app_result.dart';
import '../../../../core/state/async_state.dart';
import '../../../auth_sync/domain/models/auth_models.dart';
import '../../domain/models/online_group_models.dart';
import '../../domain/repositories/activity_repository.dart';
import '../../domain/repositories/balances_repository.dart';
import '../../domain/repositories/expenses_repository.dart';
import '../../domain/repositories/groups_repository.dart';
import '../../domain/repositories/settlements_repository.dart';

class GroupDetailData {
  const GroupDetailData({
    required this.group,
    required this.members,
    required this.outgoingInvites,
    required this.joinRequests,
    required this.expenses,
    required this.settlements,
    required this.balances,
    required this.transfers,
    required this.activity,
  });

  final Group group;
  final List<GroupMember> members;
  final List<GroupInvite> outgoingInvites;
  final List<GroupJoinRequest> joinRequests;
  final List<GroupExpense> expenses;
  final List<Settlement> settlements;
  final List<GroupBalanceSummary> balances;
  final List<GroupTransfer> transfers;
  final List<ActivityItem> activity;
}

class GroupDetailBloc extends ChangeNotifier {
  GroupDetailBloc({
    required this.currentUser,
    required this.groupsRepository,
    required this.expensesRepository,
    required this.settlementsRepository,
    required this.balancesRepository,
    required this.activityRepository,
    required this.group,
  });

  final AppUser currentUser;
  final GroupsRepository groupsRepository;
  final ExpensesRepository expensesRepository;
  final SettlementsRepository settlementsRepository;
  final BalancesRepository balancesRepository;
  final ActivityRepository activityRepository;
  Group group;

  AsyncState<GroupDetailData> _state = const AsyncState.initial();

  AsyncState<GroupDetailData> get state => _state;

  bool get canManageGroup {
    final members = _state.data?.members ?? const <GroupMember>[];
    final me = members
        .where((member) => member.userId == currentUser.id)
        .firstOrNull;
    return me != null && (me.role == GroupRole.owner || me.role == GroupRole.admin);
  }

  Future<void> load() async {
    _state = AsyncState.loading(data: _state.data);
    notifyListeners();
    final membersResult = await groupsRepository.getGroupMembers(group.id);
    final outgoingResult = await groupsRepository.getOutgoingInvites(group.id);
    final requestsResult = await groupsRepository.getPendingJoinRequests(group.id);
    final expensesResult = await expensesRepository.getGroupExpenses(group.id);
    final settlementsResult = await settlementsRepository.getSettlements(group.id);
    final balancesResult = await balancesRepository.getGroupBalances(group.id);
    final transfersResult = await balancesRepository.getGroupTransfers(group.id);
    final activityResult = await activityRepository.getGroupActivity(group.id);

    final data = GroupDetailData(
      group: group,
      members: membersResult.when(
        success: (value) => value,
        failure: (_) => const <GroupMember>[],
      ),
      outgoingInvites: outgoingResult.when(
        success: (value) => value,
        failure: (_) => const <GroupInvite>[],
      ),
      joinRequests: requestsResult.when(
        success: (value) => value,
        failure: (_) => const <GroupJoinRequest>[],
      ),
      expenses: expensesResult.when(
        success: (value) => value,
        failure: (_) => const <GroupExpense>[],
      ),
      settlements: settlementsResult.when(
        success: (value) => value,
        failure: (_) => const <Settlement>[],
      ),
      balances: balancesResult.when(
        success: (value) => value,
        failure: (_) => const <GroupBalanceSummary>[],
      ),
      transfers: transfersResult.when(
        success: (value) => value,
        failure: (_) => const <GroupTransfer>[],
      ),
      activity: activityResult.when(
        success: (value) => value,
        failure: (_) => const <ActivityItem>[],
      ),
    );
    final failure = _firstFailure([
      membersResult,
      outgoingResult,
      requestsResult,
      expensesResult,
      settlementsResult,
      balancesResult,
      transfersResult,
      activityResult,
    ]);
    _state = failure == null
        ? AsyncState.success(data)
        : (_state.data == null ? AsyncState.failure(failure, data: data) : AsyncState.stale(data, error: failure));
    notifyListeners();
  }

  Future<AppFailure?> inviteUser(AppUser invitee) async {
    final result = await groupsRepository.inviteUser(
      currentUserId: currentUser.id,
      groupId: group.id,
      invitee: invitee,
    );
    await load();
    return result.when(
      success: (_) => null,
      failure: (failure) => failure,
    );
  }

  Future<AppFailure?> respondToJoinRequest({
    required String requestId,
    required bool accept,
  }) async {
    final result = await groupsRepository.respondToJoinRequest(
      currentUserId: currentUser.id,
      requestId: requestId,
      accept: accept,
    );
    await load();
    return result.when(
      success: (_) => null,
      failure: (failure) => failure,
    );
  }

  Future<AppFailure?> saveExpense(GroupExpense expense) async {
    final result = expense.createdAt == expense.updatedAt
        ? await expensesRepository.createExpense(currentUserId: currentUser.id, expense: expense)
        : await expensesRepository.updateExpense(currentUserId: currentUser.id, expense: expense);
    await load();
    return result.when(success: (_) => null, failure: (failure) => failure);
  }

  Future<AppFailure?> deleteExpense(String expenseId) async {
    final result = await expensesRepository.deleteExpense(
      currentUserId: currentUser.id,
      groupId: group.id,
      expenseId: expenseId,
    );
    await load();
    return result.when(success: (_) => null, failure: (failure) => failure);
  }

  Future<AppFailure?> saveSettlement(Settlement settlement) async {
    final result = settlement.createdAt == settlement.updatedAt
        ? await settlementsRepository.createSettlement(
            currentUserId: currentUser.id,
            settlement: settlement,
          )
        : await settlementsRepository.updateSettlement(
            currentUserId: currentUser.id,
            settlement: settlement,
          );
    await load();
    return result.when(success: (_) => null, failure: (failure) => failure);
  }

  Future<AppFailure?> deleteSettlement(String settlementId) async {
    final result = await settlementsRepository.deleteSettlement(
      currentUserId: currentUser.id,
      groupId: group.id,
      settlementId: settlementId,
    );
    await load();
    return result.when(success: (_) => null, failure: (failure) => failure);
  }

  AppFailure? _firstFailure(List<AppResult<dynamic>> results) {
    for (final result in results) {
      if (result is AppFailureResult<dynamic>) {
        return result.error;
      }
    }
    return null;
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
