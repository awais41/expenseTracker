abstract final class ApiRoutes {
  static const register = '/auth/register';
  static const login = '/auth/login';
  static const refresh = '/auth/refresh';
  static const me = '/auth/me';

  static const userSummary = '/users/me/summary';
  static const userTotals = '/users/me/totals';
  static const userCharts = '/users/me/charts';

  static const groups = '/groups';

  static String group(String groupId) => '/groups/$groupId';
  static String groupMembers(String groupId) => '/groups/$groupId/members';
  static String groupMember(String groupId, String memberUserId) =>
      '/groups/$groupId/members/$memberUserId';

  static String groupExpenses(String groupId) => '/groups/$groupId/expenses';
  static String groupExpense(String groupId, String expenseId) =>
      '/groups/$groupId/expenses/$expenseId';

  static String groupBalances(String groupId) => '/groups/$groupId/balances';
  static String groupBalanceSummary(String groupId) =>
      '/groups/$groupId/balances/summary';
  static String groupBalanceTotals(String groupId) =>
      '/groups/$groupId/balances/totals';
  static String groupBalanceCharts(String groupId) =>
      '/groups/$groupId/balances/charts';

  static String groupSettlements(String groupId) =>
      '/groups/$groupId/settlements';

  static String groupActivity(String groupId) => '/groups/$groupId/activity';
}
