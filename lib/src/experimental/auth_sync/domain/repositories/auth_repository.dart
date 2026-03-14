import '../../../../core/result/app_result.dart';
import '../models/auth_models.dart';

abstract class AuthRepository {
  Future<AppResult<AuthSession?>> getSession();
  Future<AppResult<AuthSession>> signIn({
    required String email,
    required String password,
  });
  Future<AppResult<AuthSession>> signUp({
    required String name,
    required String email,
    required String password,
  });
  Future<AppResult<void>> signOut();
}
