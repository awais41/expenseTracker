import 'package:flutter/material.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/result/app_result.dart';
import '../../domain/models/auth_models.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileSetupCubit extends ChangeNotifier {
  ProfileSetupCubit(this._repository);

  final ProfileRepository _repository;

  bool _isSubmitting = false;
  bool _isCheckingUsername = false;
  bool? _usernameAvailable;
  AppFailure? _error;
  AppUser? _user;

  bool get isSubmitting => _isSubmitting;
  bool get isCheckingUsername => _isCheckingUsername;
  bool? get usernameAvailable => _usernameAvailable;
  AppFailure? get error => _error;
  AppUser? get user => _user;

  Future<void> checkUsername(String username) async {
    _isCheckingUsername = true;
    notifyListeners();
    final result = await _repository.checkUsernameAvailability(username);
    result.when(
      success: (value) {
        _usernameAvailable = value;
        _error = null;
      },
      failure: (failure) {
        _usernameAvailable = false;
        _error = failure;
      },
    );
    _isCheckingUsername = false;
    notifyListeners();
  }

  Future<AppResult<AppUser>> createProfile({
    required String userId,
    required String email,
    required String displayName,
    required String username,
    required int avatarColorValue,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();
    final result = await _repository.createProfile(
      userId: userId,
      email: email,
      displayName: displayName,
      username: username,
      avatarColorValue: avatarColorValue,
    );
    result.when(
      success: (value) => _user = value,
      failure: (failure) => _error = failure,
    );
    _isSubmitting = false;
    notifyListeners();
    return result;
  }
}
