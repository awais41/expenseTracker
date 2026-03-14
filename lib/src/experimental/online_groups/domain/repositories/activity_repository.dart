import '../../../../core/result/app_result.dart';
import '../models/online_group_models.dart';

abstract class ActivityRepository {
  Future<AppResult<List<ActivityItem>>> getGroupActivity(String groupId);
}
