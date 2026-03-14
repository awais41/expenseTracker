import 'package:flutter/material.dart';

import '../../domain/models/auth_models.dart';
import '../../domain/repositories/profile_repository.dart';
import 'auth_bloc.dart';
import '../../../online_groups/domain/repositories/migration_repository.dart';

enum AppBootstrapStage {
  loading,
  unauthenticated,
  authenticatedProfileIncomplete,
  migrating,
  authenticatedReady;
}

class AppBootstrapController extends ChangeNotifier {
  AppBootstrapController({
    required this.authBloc,
    required this.profileRepository,
    required this.migrationRepository,
  }) {
    authBloc.addListener(_handleAuthChanged);
  }

  final AuthBloc authBloc;
  final ProfileRepository profileRepository;
  final MigrationRepository migrationRepository;

  AppBootstrapStage _stage = AppBootstrapStage.loading;
  AppUser? _user;

  AppBootstrapStage get stage => _stage;
  AppUser? get user => _user;

  Future<void> bootstrap() async {
    _stage = AppBootstrapStage.loading;
    notifyListeners();
    await authBloc.restore();
    await _refreshStage();
  }

  Future<void> onProfileCompleted() async {
    await _refreshStage(forceMigration: true);
  }

  @override
  void dispose() {
    authBloc.removeListener(_handleAuthChanged);
    super.dispose();
  }

  Future<void> _handleAuthChanged() async {
    await _refreshStage();
  }

  Future<void> _refreshStage({bool forceMigration = false}) async {
    final session = authBloc.session;
    if (session == null) {
      _user = null;
      _stage = AppBootstrapStage.unauthenticated;
      notifyListeners();
      return;
    }
    final profileResult = await profileRepository.getMyProfile(session.userId);
    await profileResult.when(
      success: (profile) async {
        if (profile == null) {
          _user = null;
          _stage = AppBootstrapStage.authenticatedProfileIncomplete;
          notifyListeners();
          return;
        }
        _user = profile;
        final migrationResult = await migrationRepository.checkImportNeeded(profile.id);
        await migrationResult.when(
          success: (state) async {
            if (!state.accountDataImported || forceMigration) {
              _stage = AppBootstrapStage.migrating;
              notifyListeners();
              await migrationRepository.importLocalDataOnce(profile.id);
            }
            _stage = AppBootstrapStage.authenticatedReady;
            notifyListeners();
          },
          failure: (_) {
            _stage = AppBootstrapStage.authenticatedReady;
            notifyListeners();
          },
        );
      },
      failure: (_) {
        _user = null;
        _stage = AppBootstrapStage.authenticatedProfileIncomplete;
        notifyListeners();
      },
    );
  }
}
