import '../../../../experimental/api/api_client.dart';
import '../../../../experimental/api/api_routes.dart';
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

class ApiOnlineGroupsRepository
    implements
        GroupsRepository,
        ExpensesRepository,
        SettlementsRepository,
        BalancesRepository,
        ActivityRepository,
        MigrationRepository {
  ApiOnlineGroupsRepository(this._apiClient);

  final ApiClient _apiClient;
  static const _defaultGroupCurrencyCode = String.fromEnvironment(
    'GROUP_DEFAULT_CURRENCY',
    defaultValue: 'PKR',
  );

  @override
  Future<AppResult<Group>> createGroup({
    required String currentUserId,
    required String name,
    String? description,
    required bool isDiscoverable,
  }) async {
    final result = await _apiClient.post(
      ApiRoutes.groups,
      body: CreateGroupRequestDto(
        name: name,
        currencyCode: _defaultGroupCurrencyCode,
        description: description,
        isDiscoverable: isDiscoverable,
      ).toMap(),
      decoder: (data) => GroupDto.fromMap(
        Map<String, dynamic>.from(data as Map? ?? const <String, dynamic>{}),
      ),
    );
    return result.when(
      success: (dto) => AppSuccess(dto.toDomain()),
      failure: (failure) => AppFailureResult<Group>(failure),
    );
  }

  @override
  Future<AppResult<List<Group>>> getGroups(String userId) async {
    final result = await _apiClient.get(
      ApiRoutes.groups,
      decoder: (data) => (data as List<dynamic>? ?? const <dynamic>[])
          .cast<Map<dynamic, dynamic>>()
          .map((item) => GroupDto.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
    );
    return result.when(
      success: (dtos) => AppSuccess(dtos.map((item) => item.toDomain()).toList()),
      failure: (failure) => AppFailureResult<List<Group>>(failure),
    );
  }

  @override
  Future<AppResult<List<Group>>> getDiscoverableGroups(String userId) async {
    return const AppSuccess(<Group>[]);
  }

  @override
  Future<AppResult<List<GroupMember>>> getGroupMembers(String groupId) async {
    final result = await _apiClient.get(
      ApiRoutes.groupMembers(groupId),
      decoder: (data) => (data as List<dynamic>? ?? const <dynamic>[])
          .cast<Map<dynamic, dynamic>>()
          .map((item) => GroupMemberDto.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
    );
    return result.when(
      success: (dtos) => AppSuccess(dtos.map((item) => item.toDomain()).toList()),
      failure: (failure) => AppFailureResult<List<GroupMember>>(failure),
    );
  }

  @override
  Future<AppResult<List<GroupInvite>>> getIncomingInvites(String userId) async {
    return const AppSuccess(<GroupInvite>[]);
  }

  @override
  Future<AppResult<List<GroupInvite>>> getOutgoingInvites(String groupId) async {
    return const AppSuccess(<GroupInvite>[]);
  }

  @override
  Future<AppResult<List<GroupJoinRequest>>> getPendingJoinRequests(String groupId) async {
    return const AppSuccess(<GroupJoinRequest>[]);
  }

  @override
  Future<AppResult<GroupInvite>> inviteUser({
    required String currentUserId,
    required String groupId,
    required AppUser invitee,
  }) async {
    final result = await _apiClient.post(
      ApiRoutes.groupMembers(groupId),
      body: AddGroupMemberRequestDto(userId: invitee.id).toMap(),
      decoder: (data) => GroupMemberDto.fromMap(
        Map<String, dynamic>.from(data as Map? ?? const <String, dynamic>{}),
      ),
    );
    return result.when(
      success: (member) => AppSuccess(
        GroupInvite(
          id: member.id,
          groupId: member.groupId,
          inviterUserId: currentUserId,
          inviteeUserId: member.userId,
          status: InviteStatus.accepted,
          createdAt: member.joinedAt,
          respondedAt: member.joinedAt,
        ),
      ),
      failure: (failure) => AppFailureResult<GroupInvite>(failure),
    );
  }

  @override
  Future<AppResult<GroupJoinRequest>> requestToJoinGroup({
    required String currentUserId,
    required String groupId,
  }) async {
    return const AppFailureResult<GroupJoinRequest>(
      ValidationFailure('Join request endpoint is not available in the current backend contract.'),
    );
  }

  @override
  Future<AppResult<void>> respondToInvite({
    required String currentUserId,
    required String inviteId,
    required bool accept,
  }) async {
    return const AppFailureResult<void>(
      ValidationFailure('Invite response endpoint is not available in the current backend contract.'),
    );
  }

  @override
  Future<AppResult<void>> respondToJoinRequest({
    required String currentUserId,
    required String requestId,
    required bool accept,
  }) async {
    return const AppFailureResult<void>(
      ValidationFailure('Join request response endpoint is not available in the current backend contract.'),
    );
  }

  @override
  Future<AppResult<Group>> updateGroup({
    required String currentUserId,
    required String groupId,
    required String name,
    String? description,
    required bool isDiscoverable,
  }) async {
    final result = await _apiClient.patch(
      ApiRoutes.group(groupId),
      body: UpdateGroupRequestDto(
        name: name,
        description: description,
        isDiscoverable: isDiscoverable,
      ).toMap(),
      decoder: (data) => GroupDto.fromMap(
        Map<String, dynamic>.from(data as Map? ?? const <String, dynamic>{}),
      ),
    );
    return result.when(
      success: (dto) => AppSuccess(dto.toDomain()),
      failure: (failure) => AppFailureResult<Group>(failure),
    );
  }

  @override
  Future<AppResult<GroupExpense>> createExpense({
    required String currentUserId,
    required GroupExpense expense,
  }) async {
    final result = await _apiClient.post(
      ApiRoutes.groupExpenses(expense.groupId),
      body: _expenseBody(expense),
      decoder: (data) => GroupExpenseDto.fromMap(
        Map<String, dynamic>.from(data as Map? ?? const <String, dynamic>{}),
      ),
    );
    return result.when(
      success: (dto) => AppSuccess(dto.toDomain()),
      failure: (failure) => AppFailureResult<GroupExpense>(failure),
    );
  }

  @override
  Future<AppResult<void>> deleteExpense({
    required String currentUserId,
    required String groupId,
    required String expenseId,
  }) async {
    final result = await _apiClient.delete(
      ApiRoutes.groupExpense(groupId, expenseId),
      decoder: (_) => null,
    );
    return result.when(
      success: (_) => const AppSuccess(null),
      failure: (failure) => AppFailureResult<void>(failure),
    );
  }

  @override
  Future<AppResult<List<GroupExpense>>> getGroupExpenses(String groupId) async {
    final result = await _apiClient.get(
      ApiRoutes.groupExpenses(groupId),
      decoder: (data) => (data as List<dynamic>? ?? const <dynamic>[])
          .cast<Map<dynamic, dynamic>>()
          .map((item) => GroupExpenseDto.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
    );
    return result.when(
      success: (dtos) => AppSuccess(dtos.map((item) => item.toDomain()).toList()),
      failure: (failure) => AppFailureResult<List<GroupExpense>>(failure),
    );
  }

  @override
  Future<AppResult<GroupExpense>> updateExpense({
    required String currentUserId,
    required GroupExpense expense,
  }) async {
    final result = await _apiClient.patch(
      ApiRoutes.groupExpense(expense.groupId, expense.id),
      body: _expenseBody(expense),
      decoder: (data) => GroupExpenseDto.fromMap(
        Map<String, dynamic>.from(data as Map? ?? const <String, dynamic>{}),
      ),
    );
    return result.when(
      success: (dto) => AppSuccess(dto.toDomain()),
      failure: (failure) => AppFailureResult<GroupExpense>(failure),
    );
  }

  @override
  Future<AppResult<List<Settlement>>> getSettlements(String groupId) async {
    final result = await _apiClient.get(
      ApiRoutes.groupSettlements(groupId),
      decoder: (data) => (data as List<dynamic>? ?? const <dynamic>[])
          .cast<Map<dynamic, dynamic>>()
          .map((item) => SettlementDto.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
    );
    return result.when(
      success: (dtos) => AppSuccess(dtos.map((item) => item.toDomain()).toList()),
      failure: (failure) => AppFailureResult<List<Settlement>>(failure),
    );
  }

  @override
  Future<AppResult<Settlement>> createSettlement({
    required String currentUserId,
    required Settlement settlement,
  }) async {
    final result = await _apiClient.post(
      ApiRoutes.groupSettlements(settlement.groupId),
      body: CreateSettlementRequestDto(
        fromUserId: settlement.fromUserId,
        toUserId: settlement.toUserId,
        amountMinor: settlement.amountMinor,
        currencyCode: settlement.currencyCode,
        settledAt: settlement.settlementDate,
        note: settlement.note,
      ).toMap(),
      decoder: (data) => SettlementDto.fromMap(
        Map<String, dynamic>.from(data as Map? ?? const <String, dynamic>{}),
      ),
    );
    return result.when(
      success: (dto) => AppSuccess(dto.toDomain()),
      failure: (failure) => AppFailureResult<Settlement>(failure),
    );
  }

  @override
  Future<AppResult<void>> deleteSettlement({
    required String currentUserId,
    required String groupId,
    required String settlementId,
  }) {
    return Future.value(const AppFailureResult<void>(
      ValidationFailure('Delete settlement endpoint is not exposed by this backend contract.'),
    ));
  }

  @override
  Future<AppResult<Settlement>> updateSettlement({
    required String currentUserId,
    required Settlement settlement,
  }) {
    return Future.value(const AppFailureResult<Settlement>(
      ValidationFailure('Update settlement endpoint is not exposed by this backend contract.'),
    ));
  }

  @override
  Future<AppResult<List<ActivityItem>>> getGroupActivity(String groupId) async {
    final result = await _apiClient.get(
      ApiRoutes.groupActivity(groupId),
      decoder: (data) => (data as List<dynamic>? ?? const <dynamic>[])
          .cast<Map<dynamic, dynamic>>()
          .map((item) => ActivityDto.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
    );
    return result.when(
      success: (dtos) => AppSuccess(dtos.map((item) => item.toDomain()).toList()),
      failure: (failure) => AppFailureResult<List<ActivityItem>>(failure),
    );
  }

  @override
  Future<AppResult<List<GroupBalanceSummary>>> getGroupBalances(String groupId) async {
    final result = await _apiClient.get(
      ApiRoutes.groupBalances(groupId),
      decoder: (data) => GroupBalancesEnvelopeDto.fromMap(
        Map<String, dynamic>.from(data as Map? ?? const <String, dynamic>{}),
      ),
    );
    return result.when(
      success: (dto) => AppSuccess(dto.netBalances.map((item) => item.toDomain()).toList()),
      failure: (failure) => AppFailureResult<List<GroupBalanceSummary>>(failure),
    );
  }

  @override
  Future<AppResult<List<GroupTransfer>>> getGroupTransfers(String groupId) async {
    final result = await _apiClient.get(
      ApiRoutes.groupBalances(groupId),
      decoder: (data) => GroupBalancesEnvelopeDto.fromMap(
        Map<String, dynamic>.from(data as Map? ?? const <String, dynamic>{}),
      ),
    );
    return result.when(
      success: (dto) => AppSuccess(dto.simplifiedDebts),
      failure: (failure) => AppFailureResult<List<GroupTransfer>>(failure),
    );
  }

  @override
  Future<AppResult<MigrationState>> checkImportNeeded(String userId) async {
    return const AppSuccess(MigrationState(accountDataImported: false));
  }

  @override
  Future<AppResult<void>> importLocalDataOnce(String userId) async {
    return const AppSuccess(null);
  }

  Map<String, dynamic> _expenseBody(GroupExpense expense) {
    final includePayer = expense.includePayerInSplit;
    final equal = expense.splitMode == GroupSplitMode.equal;
    final participants = switch (expense.splitMode) {
      GroupSplitMode.equal => null,
      GroupSplitMode.exact || GroupSplitMode.adjustment => expense.participants
          .map(
            (item) => ExpenseParticipantRequestDto(
              userId: item.userId,
              amountMinor: item.amountOwedMinor,
            ),
          )
          .toList(),
      GroupSplitMode.percentage => expense.participants
          .map(
            (item) => ExpenseParticipantRequestDto(
              userId: item.userId,
              shareValue: item.shareValue,
              shareType: 'percent',
              amountMinor: item.amountOwedMinor,
            ),
          )
          .toList(),
      GroupSplitMode.shares => expense.participants
          .map(
            (item) => ExpenseParticipantRequestDto(
              userId: item.userId,
              shareValue: item.shareValue,
              shareType: 'shares',
              amountMinor: item.amountOwedMinor,
            ),
          )
          .toList(),
    };
    return ExpenseUpsertRequestDto(
      title: expense.title,
      description: expense.description,
      amountMinor: expense.amountMinor,
      currencyCode: expense.currencyCode,
      paidByUserId: expense.paidByUserId,
      expenseDate: expense.expenseDate,
      splitMethod: expense.splitMode.name.toUpperCase(),
      includePayerInSplit: includePayer,
      category: expense.category,
      notes: expense.notes,
      participantUserIds: equal
          ? expense.participants.map((item) => item.userId).toList()
          : null,
      participants: participants,
    ).toMap();
  }
}
