import '../../../../core/result/app_result.dart';
import '../models/user_insights_models.dart';

abstract class UsersRepository {
  Future<AppResult<UserSummary>> getMySummary();
  Future<AppResult<UserTotals>> getMyTotals();
  Future<AppResult<List<UserChartPoint>>> getMyCharts();
}
