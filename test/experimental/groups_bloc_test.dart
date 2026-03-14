import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:expense_tracker/src/core/data/mock_cloud_store.dart';
import 'package:expense_tracker/src/experimental/auth_sync/data/repositories/mock_auth_repositories.dart';
import 'package:expense_tracker/src/experimental/online_groups/data/repositories/mock_online_groups_repository.dart';
import 'package:expense_tracker/src/experimental/online_groups/domain/models/online_group_models.dart';

void main() {
  test('profile usernames are globally unique', () async {
    SharedPreferences.setMockInitialValues({});
    final store = MockCloudStore();
    final profiles = MockProfileRepository(store);

    final first = await profiles.createProfile(
      userId: 'user-1',
      email: 'one@example.com',
      displayName: 'One',
      username: 'awais41',
      avatarColorValue: 0xFF10B981,
    );
    final second = await profiles.createProfile(
      userId: 'user-2',
      email: 'two@example.com',
      displayName: 'Two',
      username: 'awais41',
      avatarColorValue: 0xFF22D3EE,
    );

    expect(first.isSuccess, isTrue);
    expect(second.isFailure, isTrue);
  });

  test('group invite can be sent and then accepted into membership', () async {
    SharedPreferences.setMockInitialValues({});
    final store = MockCloudStore();
    final profiles = MockProfileRepository(store);
    final groups = MockOnlineGroupsRepository(store);

    await profiles.createProfile(
      userId: 'owner',
      email: 'owner@example.com',
      displayName: 'Owner',
      username: 'owner',
      avatarColorValue: 0xFF10B981,
    );
    final inviteeResult = await profiles.createProfile(
      userId: 'member',
      email: 'member@example.com',
      displayName: 'Member',
      username: 'member',
      avatarColorValue: 0xFF22D3EE,
    );
    final invitee = inviteeResult.when(success: (value) => value, failure: (_) => throw StateError('missing invitee'));

    final groupResult = await groups.createGroup(
      currentUserId: 'owner',
      name: 'Dinner Club',
      description: 'Friends',
      isDiscoverable: false,
    );
    final group = groupResult.when(success: (value) => value, failure: (_) => throw StateError('missing group'));

    final inviteResult = await groups.inviteUser(
      currentUserId: 'owner',
      groupId: group.id,
      invitee: invitee,
    );
    final invite = inviteResult.when(success: (value) => value, failure: (_) => throw StateError('missing invite'));

    final beforeMembers = await groups.getGroupMembers(group.id);
    expect(beforeMembers.when(success: (value) => value.length, failure: (_) => 0), 1);

    await groups.respondToInvite(
      currentUserId: 'member',
      inviteId: invite.id,
      accept: true,
    );

    final afterMembers = await groups.getGroupMembers(group.id);
    expect(afterMembers.when(success: (value) => value.length, failure: (_) => 0), 2);
  });

  test('group balances update after expense and settlement changes', () async {
    SharedPreferences.setMockInitialValues({});
    final store = MockCloudStore();
    final profiles = MockProfileRepository(store);
    final groups = MockOnlineGroupsRepository(store);

    await profiles.createProfile(
      userId: 'owner',
      email: 'owner@example.com',
      displayName: 'Owner',
      username: 'owner',
      avatarColorValue: 0xFF10B981,
    );
    final guestResult = await profiles.createProfile(
      userId: 'guest',
      email: 'guest@example.com',
      displayName: 'Guest',
      username: 'guest',
      avatarColorValue: 0xFF22D3EE,
    );
    final guest = guestResult.when(success: (value) => value, failure: (_) => throw StateError('missing guest'));

    final group = await groups.createGroup(
      currentUserId: 'owner',
      name: 'Trip',
      isDiscoverable: false,
    ).then((result) => result.when(success: (value) => value, failure: (_) => throw StateError('missing group')));

    final invite = await groups.inviteUser(
      currentUserId: 'owner',
      groupId: group.id,
      invitee: guest,
    ).then((result) => result.when(success: (value) => value, failure: (_) => throw StateError('missing invite')));

    await groups.respondToInvite(
      currentUserId: 'guest',
      inviteId: invite.id,
      accept: true,
    );

    await groups.createExpense(
      currentUserId: 'owner',
      expense: GroupExpense(
        id: 'expense-1',
        groupId: group.id,
        createdByUserId: 'owner',
        title: 'Dinner',
        description: null,
        amountMinor: 9000,
        currencyCode: 'USD',
        splitMode: GroupSplitMode.equal,
        paidByUserId: 'owner',
        includePayerInSplit: true,
        category: null,
        expenseDate: DateTime(2026, 3, 10),
        createdAt: DateTime(2026, 3, 10),
        updatedAt: DateTime(2026, 3, 10),
        participants: const [
          ExpenseParticipant(
            id: 'p1',
            expenseId: 'expense-1',
            userId: 'owner',
            shareValue: 45,
            shareType: 'amount',
            amountOwedMinor: 4500,
          ),
          ExpenseParticipant(
            id: 'p2',
            expenseId: 'expense-1',
            userId: 'guest',
            shareValue: 45,
            shareType: 'amount',
            amountOwedMinor: 4500,
          ),
        ],
      ),
    );

    final balancesAfterExpense = await groups.getGroupBalances(group.id);
    final expenseBalances = balancesAfterExpense.when(success: (value) => value, failure: (_) => <GroupBalanceSummary>[]);
    expect(expenseBalances.firstWhere((item) => item.userId == 'owner').netAmount, 45);
    expect(expenseBalances.firstWhere((item) => item.userId == 'guest').netAmount, -45);

    await groups.createSettlement(
      currentUserId: 'guest',
      settlement: Settlement(
        id: 'settlement-1',
        groupId: group.id,
        fromUserId: 'guest',
        toUserId: 'owner',
        amountMinor: 2000,
        currencyCode: 'USD',
        note: 'cash',
        settlementDate: DateTime(2026, 3, 10),
        createdByUserId: 'guest',
        createdAt: DateTime(2026, 3, 10),
        updatedAt: DateTime(2026, 3, 10),
      ),
    );

    final balancesAfterSettlement = await groups.getGroupBalances(group.id);
    final settlementBalances = balancesAfterSettlement.when(success: (value) => value, failure: (_) => <GroupBalanceSummary>[]);
    expect(settlementBalances.firstWhere((item) => item.userId == 'owner').netAmount, 25);
    expect(settlementBalances.firstWhere((item) => item.userId == 'guest').netAmount, -25);
  });
}
