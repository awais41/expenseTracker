import '../../../../core/result/app_result.dart';
import '../models/online_group_models.dart';

abstract class SettlementsRepository {
  Future<AppResult<List<Settlement>>> getSettlements(String groupId);
  Future<AppResult<Settlement>> createSettlement({
    required String currentUserId,
    required Settlement settlement,
  });
  Future<AppResult<Settlement>> updateSettlement({
    required String currentUserId,
    required Settlement settlement,
  });
  Future<AppResult<void>> deleteSettlement({
    required String currentUserId,
    required String groupId,
    required String settlementId,
  });
}
