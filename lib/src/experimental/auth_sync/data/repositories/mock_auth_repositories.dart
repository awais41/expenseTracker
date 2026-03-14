import '../../../../core/data/mock_cloud_store.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/result/app_result.dart';
import '../../domain/models/auth_models.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import '../dto/auth_dtos.dart';

class MockAuthRepository implements AuthRepository {
  MockAuthRepository(this._store);

  final MockCloudStore _store;

  @override
  Future<AppResult<AuthSession?>> getSession() async {
    await _store.hydrate();
    final sessionUserId = await _store.loadSessionUserId();
    if (sessionUserId == null) {
      return const AppSuccess<AuthSession?>(null);
    }
    final users = await _store.loadUsers();
    final user = users.where((item) => item.id == sessionUserId).firstOrNull;
    if (user == null) {
      await _store.saveSessionUserId(null);
      return const AppSuccess<AuthSession?>(null);
    }
    return AppSuccess(
      AuthSession(
        userId: user.id,
        email: user.email,
        createdAt: user.createdAt,
      ),
    );
  }

  @override
  Future<AppResult<AuthSession>> signIn({
    required String email,
    required String password,
  }) async {
    final users = await _store.loadUsers();
    final user = users.where((item) => item.email.toLowerCase() == email.trim().toLowerCase()).firstOrNull;
    if (user == null || user.password != password) {
      return const AppFailureResult<AuthSession>(
        ValidationFailure('Invalid email or password.'),
      );
    }
    await _store.saveSessionUserId(user.id);
    return AppSuccess(
      AuthSession(userId: user.id, email: user.email, createdAt: user.createdAt),
    );
  }

  @override
  Future<AppResult<AuthSession>> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (name.trim().isEmpty || !normalizedEmail.contains('@') || password.trim().length < 6) {
      return const AppFailureResult<AuthSession>(
        ValidationFailure('Use a valid name, email, and a password with at least 6 characters.'),
      );
    }
    final users = await _store.loadUsers();
    final exists = users.any((item) => item.email.toLowerCase() == normalizedEmail);
    if (exists) {
      return const AppFailureResult<AuthSession>(
        ConflictFailure('This email is already registered.'),
      );
    }
    final dto = AuthUserDto(
      id: _store.createId('user'),
      email: normalizedEmail,
      password: password,
      createdAt: DateTime.now(),
    );
    users.add(dto);
    await _store.saveUsers(users);
    await _store.saveSessionUserId(dto.id);
    return AppSuccess(
      AuthSession(userId: dto.id, email: dto.email, createdAt: dto.createdAt),
    );
  }

  @override
  Future<AppResult<void>> signOut() async {
    await _store.saveSessionUserId(null);
    return const AppSuccess(null);
  }
}

class MockProfileRepository implements ProfileRepository {
  MockProfileRepository(this._store);

  final MockCloudStore _store;

  static const _palette = <int>[
    0xFF10B981,
    0xFF22D3EE,
    0xFFF59E0B,
    0xFFF472B6,
    0xFF60A5FA,
    0xFFA78BFA,
  ];

  @override
  Future<AppResult<bool>> checkUsernameAvailability(String username) async {
    final normalized = _normalizeUsername(username);
    if (normalized == null) {
      return const AppFailureResult<bool>(
        ValidationFailure('Username must be 3-20 letters, numbers, underscores, or dots.'),
      );
    }
    final profiles = await _store.loadProfiles();
    final exists = profiles.any((profile) => profile.usernameNormalized == normalized);
    return AppSuccess(!exists);
  }

  @override
  Future<AppResult<AppUser>> createProfile({
    required String userId,
    required String email,
    required String displayName,
    required String username,
    required int avatarColorValue,
  }) async {
    final normalizedUsername = _normalizeUsername(username);
    final normalizedName = displayName.trim();
    if (normalizedName.isEmpty) {
      return const AppFailureResult<AppUser>(
        ValidationFailure('Display name is required.'),
      );
    }
    if (normalizedUsername == null) {
      return const AppFailureResult<AppUser>(
        ValidationFailure('Username must be 3-20 letters, numbers, underscores, or dots.'),
      );
    }
    final profiles = await _store.loadProfiles();
    final exists = profiles.any((profile) => profile.usernameNormalized == normalizedUsername);
    if (exists) {
      return const AppFailureResult<AppUser>(
        ConflictFailure('This username is already taken.'),
      );
    }
    final dto = ProfileDto(
      id: userId,
      email: email,
      username: username.trim(),
      usernameNormalized: normalizedUsername,
      displayName: normalizedName,
      avatarColorValue: avatarColorValue,
      createdAt: DateTime.now(),
    );
    profiles.removeWhere((profile) => profile.id == userId);
    profiles.add(dto);
    await _store.saveProfiles(profiles);
    return AppSuccess(dto.toDomain());
  }

  @override
  Future<AppResult<AppUser?>> getMyProfile(String userId) async {
    final profiles = await _store.loadProfiles();
    final profile = profiles.where((item) => item.id == userId).firstOrNull;
    return AppSuccess(profile?.toDomain());
  }

  @override
  Future<AppResult<List<AppUser>>> searchUsersByUsername(String query) async {
    final normalized = query.trim().toLowerCase();
    final profiles = await _store.loadProfiles();
    final results = profiles
        .where((profile) => profile.usernameNormalized.contains(normalized))
        .take(12)
        .map((profile) => profile.toDomain())
        .toList();
    return AppSuccess(results);
  }

  int nextAvatarColorValue(int seed) => _palette[seed % _palette.length];

  String? _normalizeUsername(String username) {
    final normalized = username.trim().toLowerCase();
    final valid = RegExp(r'^[a-z0-9._]{3,20}$');
    if (!valid.hasMatch(normalized)) {
      return null;
    }
    return normalized;
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
