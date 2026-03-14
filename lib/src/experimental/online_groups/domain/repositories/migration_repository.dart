import '../../../../core/result/app_result.dart';
import '../models/online_group_models.dart';

abstract class MigrationRepository {
  Future<AppResult<MigrationState>> checkImportNeeded(String userId);
  Future<AppResult<void>> importLocalDataOnce(String userId);
}
