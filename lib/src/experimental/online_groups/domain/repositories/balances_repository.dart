import '../../../../core/result/app_result.dart';
import '../models/online_group_models.dart';

abstract class BalancesRepository {
  Future<AppResult<List<GroupBalanceSummary>>> getGroupBalances(String groupId);
  Future<AppResult<List<GroupTransfer>>> getGroupTransfers(String groupId);
}
