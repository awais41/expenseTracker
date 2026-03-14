import '../../../../core/result/app_result.dart';
import '../models/auth_models.dart';

abstract class ProfileRepository {
  Future<AppResult<AppUser?>> getMyProfile(String userId);
  Future<AppResult<AppUser>> createProfile({
    required String userId,
    required String email,
    required String displayName,
    required String username,
    required int avatarColorValue,
  });
  Future<AppResult<bool>> checkUsernameAvailability(String username);
  Future<AppResult<List<AppUser>>> searchUsersByUsername(String query);
}
