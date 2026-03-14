import '../../../../experimental/api/api_client.dart';
import '../../../../experimental/api/api_routes.dart';
import '../../../../experimental/api/auth_token_store.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/result/app_result.dart';
import '../../domain/models/auth_models.dart';
import '../../domain/models/user_insights_models.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/repositories/users_repository.dart';
import '../dto/auth_dtos.dart';
import '../dto/user_insights_dtos.dart';

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository({
    required ApiClient apiClient,
    required AuthTokenStore tokenStore,
  }) : _apiClient = apiClient,
       _tokenStore = tokenStore {
    _apiClient.onRefreshToken = _refreshTokens;
    _apiClient.onUnauthorized = () => signOut();
  }

  final ApiClient _apiClient;
  final AuthTokenStore _tokenStore;

  @override
  Future<AppResult<AuthSession?>> getSession() async {
    final tokens = await _tokenStore.read();
    if (tokens == null) {
      return const AppSuccess<AuthSession?>(null);
    }
    final me = await _apiClient.get(
      ApiRoutes.me,
      decoder: (data) => ProfileDto.fromMap(
        Map<String, dynamic>.from(data as Map? ?? const <String, dynamic>{}),
      ),
    );
    return me.when(
      success: (profile) => AppSuccess<AuthSession?>(
        AuthSession(
          userId: profile.id,
          email: profile.email,
          createdAt: profile.createdAt,
        ),
      ),
      failure: (failure) async {
        if (failure is UnauthorizedFailure) {
          await _tokenStore.clear();
          return const AppSuccess<AuthSession?>(null);
        }
        return AppFailureResult<AuthSession?>(failure);
      },
    );
  }

  @override
  Future<AppResult<AuthSession>> signIn({
    required String email,
    required String password,
  }) async {
    final result = await _apiClient.post(
      ApiRoutes.login,
      requiresAuth: false,
      body: SignInRequestDto(email: email, password: password).toMap(),
      decoder: (data) => AuthTokensDto.fromMap(
        Map<String, dynamic>.from(data as Map? ?? const <String, dynamic>{}),
      ),
    );
    return _handleAuthTokensResult(result);
  }

  @override
  Future<AppResult<AuthSession>> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final result = await _apiClient.post(
      ApiRoutes.register,
      requiresAuth: false,
      body: RegisterRequestDto(
        name: name,
        email: email,
        password: password,
      ).toMap(),
      decoder: (data) => AuthTokensDto.fromMap(
        Map<String, dynamic>.from(data as Map? ?? const <String, dynamic>{}),
      ),
    );
    return _handleAuthTokensResult(result);
  }

  @override
  Future<AppResult<void>> signOut() async {
    await _tokenStore.clear();
    return const AppSuccess(null);
  }

  Future<AuthTokens?> _refreshTokens(String refreshToken) async {
    final result = await _apiClient.post(
      ApiRoutes.refresh,
      requiresAuth: false,
      body: RefreshTokenRequestDto(refreshToken: refreshToken).toMap(),
      decoder: (data) => AuthTokensDto.fromMap(
        Map<String, dynamic>.from(data as Map? ?? const <String, dynamic>{}),
      ),
    );
    return result.when(
      success: (dto) => AuthTokens(
        accessToken: dto.accessToken,
        refreshToken: dto.refreshToken,
      ),
      failure: (_) => null,
    );
  }

  Future<AppResult<AuthSession>> _handleAuthTokensResult(
    AppResult<AuthTokensDto> result,
  ) async {
    return result.when(
      success: (dto) async {
        await _tokenStore.write(
          AuthTokens(
            accessToken: dto.accessToken,
            refreshToken: dto.refreshToken,
          ),
        );
        if (dto.user != null) {
          return AppSuccess(
            AuthSession(
              userId: dto.user!.id,
              email: dto.user!.email,
              createdAt: dto.user!.createdAt,
            ),
          );
        }
        final sessionResult = await getSession();
        return sessionResult.when(
          success: (session) {
            if (session == null) {
              return AppFailureResult<AuthSession>(
                const ServerFailure('Auth session was created but the user profile could not be loaded.'),
              );
            }
            return AppSuccess(session);
          },
          failure: (failure) => AppFailureResult<AuthSession>(failure),
        );
      },
      failure: (failure) => AppFailureResult<AuthSession>(failure),
    );
  }
}

class ApiProfileRepository implements ProfileRepository {
  ApiProfileRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<AppResult<bool>> checkUsernameAvailability(String username) async {
    return const AppFailureResult<bool>(
      ValidationFailure('Username availability endpoint is not exposed by this backend yet.'),
    );
  }

  @override
  Future<AppResult<AppUser>> createProfile({
    required String userId,
    required String email,
    required String displayName,
    required String username,
    required int avatarColorValue,
  }) async {
    return const AppFailureResult<AppUser>(
      ValidationFailure('Profile creation endpoint is not exposed by this backend yet.'),
    );
  }

  @override
  Future<AppResult<AppUser?>> getMyProfile(String userId) async {
    final result = await _apiClient.get(
      ApiRoutes.me,
      decoder: (data) => ProfileDto.fromMap(
        Map<String, dynamic>.from(data as Map? ?? const <String, dynamic>{}),
      ),
    );
    return result.when(
      success: (dto) => AppSuccess(dto.toDomain()),
      failure: (failure) => AppFailureResult<AppUser?>(failure),
    );
  }

  @override
  Future<AppResult<List<AppUser>>> searchUsersByUsername(String query) async {
    return const AppFailureResult<List<AppUser>>(
      ValidationFailure('User search endpoint is not exposed by this backend yet.'),
    );
  }
}

class ApiUsersRepository implements UsersRepository {
  ApiUsersRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<AppResult<List<UserChartPoint>>> getMyCharts() async {
    final result = await _apiClient.get(
      ApiRoutes.userCharts,
      decoder: (data) => (data as List<dynamic>? ?? const <dynamic>[])
          .cast<Map<dynamic, dynamic>>()
          .map((item) => UserChartPointDto.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
    );
    return result.when(
      success: (dtos) => AppSuccess(dtos.map((item) => item.toDomain()).toList()),
      failure: (failure) => AppFailureResult<List<UserChartPoint>>(failure),
    );
  }

  @override
  Future<AppResult<UserSummary>> getMySummary() async {
    final result = await _apiClient.get(
      ApiRoutes.userSummary,
      decoder: (data) => UserSummaryDto.fromMap(
        Map<String, dynamic>.from(data as Map? ?? const <String, dynamic>{}),
      ),
    );
    return result.when(
      success: (dto) => AppSuccess(dto.toDomain()),
      failure: (failure) => AppFailureResult<UserSummary>(failure),
    );
  }

  @override
  Future<AppResult<UserTotals>> getMyTotals() async {
    final result = await _apiClient.get(
      ApiRoutes.userTotals,
      decoder: (data) => UserTotalsDto.fromMap(
        Map<String, dynamic>.from(data as Map? ?? const <String, dynamic>{}),
      ),
    );
    return result.when(
      success: (dto) => AppSuccess(dto.toDomain()),
      failure: (failure) => AppFailureResult<UserTotals>(failure),
    );
  }
}
