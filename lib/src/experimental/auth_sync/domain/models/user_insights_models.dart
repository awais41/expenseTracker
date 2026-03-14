class UserSummary {
  const UserSummary({
    required this.currencyCode,
    required this.totalSpentMinor,
    required this.activeGroupsCount,
  });

  final String currencyCode;
  final int totalSpentMinor;
  final int activeGroupsCount;
}

class UserTotals {
  const UserTotals({
    required this.currencyCode,
    required this.totalSpentMinor,
    required this.totalSettledMinor,
    required this.netBalanceMinor,
  });

  final String currencyCode;
  final int totalSpentMinor;
  final int totalSettledMinor;
  final int netBalanceMinor;
}

class UserChartPoint {
  const UserChartPoint({
    required this.label,
    required this.amountMinor,
  });

  final String label;
  final int amountMinor;
}
