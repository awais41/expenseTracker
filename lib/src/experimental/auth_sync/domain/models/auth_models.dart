import 'package:flutter/material.dart';

class AuthSession {
  const AuthSession({
    required this.userId,
    required this.email,
    required this.createdAt,
  });

  final String userId;
  final String email;
  final DateTime createdAt;
}

class AppUser {
  const AppUser({
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

  Color get avatarColor => Color(avatarColorValue);

  AppUser copyWith({
    String? displayName,
    int? avatarColorValue,
  }) {
    return AppUser(
      id: id,
      email: email,
      username: username,
      usernameNormalized: usernameNormalized,
      displayName: displayName ?? this.displayName,
      avatarColorValue: avatarColorValue ?? this.avatarColorValue,
      createdAt: createdAt,
    );
  }
}
