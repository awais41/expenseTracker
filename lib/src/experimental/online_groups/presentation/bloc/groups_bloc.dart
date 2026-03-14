import 'package:flutter/material.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/state/async_state.dart';
import '../../../auth_sync/domain/models/auth_models.dart';
import '../../domain/models/online_group_models.dart';
import '../../domain/repositories/groups_repository.dart';

class GroupsHomeData {
  const GroupsHomeData({
    required this.groups,
    required this.incomingInvites,
    required this.discoverableGroups,
  });

  final List<Group> groups;
  final List<GroupInvite> incomingInvites;
  final List<Group> discoverableGroups;
}

class GroupsBloc extends ChangeNotifier {
  GroupsBloc({
    required this.repository,
    required this.currentUser,
  });

  final GroupsRepository repository;
  final AppUser currentUser;

  AsyncState<GroupsHomeData> _state = const AsyncState.initial();

  AsyncState<GroupsHomeData> get state => _state;

  Future<void> load() async {
    _state = AsyncState.loading(data: _state.data);
    notifyListeners();
    final groupsResult = await repository.getGroups(currentUser.id);
    final invitesResult = await repository.getIncomingInvites(currentUser.id);
    final discoverableResult = await repository.getDiscoverableGroups(currentUser.id);
    final data = groupsResult.when(
      success: (groups) => GroupsHomeData(
        groups: groups,
        incomingInvites: invitesResult.when(
          success: (value) => value,
          failure: (_) => const <GroupInvite>[],
        ),
        discoverableGroups: discoverableResult.when(
          success: (value) => value,
          failure: (_) => const <Group>[],
        ),
      ),
      failure: (_) => const GroupsHomeData(
        groups: <Group>[],
        incomingInvites: <GroupInvite>[],
        discoverableGroups: <Group>[],
      ),
    );
    AppFailure? failure;
    groupsResult.when(success: (_) {}, failure: (value) => failure = value);
    failure ??= invitesResult.when(success: (_) => null, failure: (value) => value);
    failure ??= discoverableResult.when(success: (_) => null, failure: (value) => value);
    if (failure != null && _state.data != null) {
      _state = AsyncState.stale(data, error: failure);
    } else if (failure != null) {
      _state = AsyncState.failure(failure!, data: data);
    } else {
      _state = AsyncState.success(data);
    }
    notifyListeners();
  }

  Future<AppFailure?> createGroup({
    required String name,
    String? description,
    required bool isDiscoverable,
  }) async {
    final result = await repository.createGroup(
      currentUserId: currentUser.id,
      name: name,
      description: description,
      isDiscoverable: isDiscoverable,
    );
    await load();
    return result.when(
      success: (_) => null,
      failure: (failure) => failure,
    );
  }

  Future<AppFailure?> respondToInvite({
    required String inviteId,
    required bool accept,
  }) async {
    final result = await repository.respondToInvite(
      currentUserId: currentUser.id,
      inviteId: inviteId,
      accept: accept,
    );
    await load();
    return result.when(
      success: (_) => null,
      failure: (failure) => failure,
    );
  }

  Future<AppFailure?> requestToJoin(String groupId) async {
    final result = await repository.requestToJoinGroup(
      currentUserId: currentUser.id,
      groupId: groupId,
    );
    await load();
    return result.when(
      success: (_) => null,
      failure: (failure) => failure,
    );
  }
}
