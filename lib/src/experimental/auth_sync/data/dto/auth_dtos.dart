import '../../domain/models/auth_models.dart';

class SignInRequestDto {
  const SignInRequestDto({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  Map<String, dynamic> toMap() => {
    'email': email.trim(),
    'password': password,
  };
}

class RegisterRequestDto {
  const RegisterRequestDto({
    required this.name,
    required this.email,
    required this.password,
  });

  final String name;
  final String email;
  final String password;

  Map<String, dynamic> toMap() => {
    'name': name.trim(),
    'email': email.trim(),
    'password': password,
  };
}

class RefreshTokenRequestDto {
  const RefreshTokenRequestDto({
    required this.refreshToken,
  });

  final String refreshToken;

  Map<String, dynamic> toMap() => {
    'refreshToken': refreshToken,
  };
}

class AuthUserDto {
  const AuthUserDto({
    required this.id,
    required this.email,
    required this.password,
    required this.createdAt,
  });

  final String id;
  final String email;
  final String password;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
    'id': id,
    'email': email,
    'password': password,
    'createdAt': createdAt.toIso8601String(),
  };

  factory AuthUserDto.fromMap(Map<String, dynamic> map) {
    return AuthUserDto(
      id: map['id'] as String,
      email: map['email'] as String? ?? '',
      password: map['password'] as String? ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class AuthTokensDto {
  const AuthTokensDto({
    required this.accessToken,
    required this.refreshToken,
    this.user,
  });

  final String accessToken;
  final String refreshToken;
  final ProfileDto? user;

  factory AuthTokensDto.fromMap(Map<String, dynamic> map) {
    return AuthTokensDto(
      accessToken: map['accessToken'] as String? ?? '',
      refreshToken: map['refreshToken'] as String? ?? '',
      user: map['user'] is Map
          ? ProfileDto.fromMap(
              Map<String, dynamic>.from(map['user'] as Map),
            )
          : null,
    );
  }
}

class ProfileDto {
  const ProfileDto({
    required this.id,
    required this.email,
    required this.username,
    required this.usernameNormalized,
    required this.displayName,
    required this.avatarColorValue,
    required this.createdAt,
  });

  final String id;
  final String email;
  final String username;
  final String usernameNormalized;
  final String displayName;
  final int avatarColorValue;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
    'id': id,
    'email': email,
    'username': username,
    'usernameNormalized': usernameNormalized,
    'displayName': displayName,
    'avatarColorValue': avatarColorValue,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ProfileDto.fromMap(Map<String, dynamic> map) {
    final email = map['email'] as String? ?? '';
    final displayName = map['displayName'] as String? ?? map['name'] as String? ?? '';
    final username = map['username'] as String? ?? _usernameFromEmail(email);
    final normalized = map['usernameNormalized'] as String? ?? username.trim().toLowerCase();
    return ProfileDto(
      id: map['id'] as String? ?? map['userId'] as String? ?? '',
      email: email,
      username: username,
      usernameNormalized: normalized,
      displayName: displayName.isEmpty ? username : displayName,
      avatarColorValue: map['avatarColorValue'] as int? ?? 0xFF10B981,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  AppUser toDomain() {
    return AppUser(
      id: id,
      email: email,
      username: username,
      usernameNormalized: usernameNormalized,
      displayName: displayName,
      avatarColorValue: avatarColorValue,
      createdAt: createdAt,
    );
  }
}

String _usernameFromEmail(String email) {
  final localPart = email.split('@').first.trim();
  return localPart.isEmpty ? 'user' : localPart;
}
