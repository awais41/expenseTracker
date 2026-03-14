import '../../../../core/result/app_result.dart';
import '../models/online_group_models.dart';

abstract class ExpensesRepository {
  Future<AppResult<List<GroupExpense>>> getGroupExpenses(String groupId);
  Future<AppResult<GroupExpense>> createExpense({
    required String currentUserId,
    required GroupExpense expense,
  });
  Future<AppResult<GroupExpense>> updateExpense({
    required String currentUserId,
    required GroupExpense expense,
  });
  Future<AppResult<void>> deleteExpense({
    required String currentUserId,
    required String groupId,
    required String expenseId,
  });
}
