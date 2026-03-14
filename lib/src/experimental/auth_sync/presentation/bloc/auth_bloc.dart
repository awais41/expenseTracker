import 'package:flutter/material.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/result/app_result.dart';
import '../../domain/models/auth_models.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthBloc extends ChangeNotifier {
  AuthBloc(this._repository);

  final AuthRepository _repository;

  AuthSession? _session;
  bool _isSubmitting = false;
  AppFailure? _error;

  AuthSession? get session => _session;
  bool get isAuthenticated => _session != null;
  bool get isSubmitting => _isSubmitting;
  AppFailure? get error => _error;

  Future<void> restore() async {
    final result = await _repository.getSession();
    result.when(
      success: (value) {
        _session = value;
        _error = null;
      },
      failure: (failure) {
        _session = null;
        _error = failure;
      },
    );
    notifyListeners();
  }

  Future<AppResult<AuthSession>> signIn({
    required String email,
    required String password,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();
    final result = await _repository.signIn(email: email, password: password);
    result.when(
      success: (value) {
        _session = value;
        _error = null;
      },
      failure: (failure) => _error = failure,
    );
    _isSubmitting = false;
    notifyListeners();
    return result;
  }

  Future<AppResult<AuthSession>> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();
    final result = await _repository.signUp(
      name: name,
      email: email,
      password: password,
    );
    result.when(
      success: (value) {
        _session = value;
        _error = null;
      },
      failure: (failure) => _error = failure,
    );
    _isSubmitting = false;
    notifyListeners();
    return result;
  }

  Future<void> signOut() async {
    _isSubmitting = true;
    notifyListeners();
    await _repository.signOut();
    _session = null;
    _error = null;
    _isSubmitting = false;
    notifyListeners();
  }
}
