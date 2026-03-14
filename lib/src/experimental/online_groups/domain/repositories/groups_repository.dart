import '../../../../core/result/app_result.dart';
import '../../../auth_sync/domain/models/auth_models.dart';
import '../models/online_group_models.dart';

abstract class GroupsRepository {
  Future<AppResult<List<Group>>> getGroups(String userId);
  Future<AppResult<List<GroupInvite>>> getIncomingInvites(String userId);
  Future<AppResult<List<Group>>> getDiscoverableGroups(String userId);
  Future<AppResult<Group>> createGroup({
    required String currentUserId,
    required String name,
    String? description,
    required bool isDiscoverable,
  });
  Future<AppResult<Group>> updateGroup({
    required String currentUserId,
    required String groupId,
    required String name,
    String? description,
    required bool isDiscoverable,
  });
  Future<AppResult<List<GroupMember>>> getGroupMembers(String groupId);
  Future<AppResult<List<GroupInvite>>> getOutgoingInvites(String groupId);
  Future<AppResult<List<GroupJoinRequest>>> getPendingJoinRequests(String groupId);
  Future<AppResult<GroupInvite>> inviteUser({
    required String currentUserId,
    required String groupId,
    required AppUser invitee,
  });
  Future<AppResult<GroupJoinRequest>> requestToJoinGroup({
    required String currentUserId,
    required String groupId,
  });
  Future<AppResult<void>> respondToInvite({
    required String currentUserId,
    required String inviteId,
    required bool accept,
  });
  Future<AppResult<void>> respondToJoinRequest({
    required String currentUserId,
    required String requestId,
    required bool accept,
  });
}
