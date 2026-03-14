import '../../domain/models/user_insights_models.dart';

class UserSummaryDto {
  const UserSummaryDto({
    required this.currencyCode,
    required this.totalSpentMinor,
    required this.activeGroupsCount,
  });

  final String currencyCode;
  final int totalSpentMinor;
  final int activeGroupsCount;

  factory UserSummaryDto.fromMap(Map<String, dynamic> map) {
    return UserSummaryDto(
      currencyCode: map['currencyCode'] as String? ?? 'USD',
      totalSpentMinor: map['totalSpentMinor'] as int? ?? 0,
      activeGroupsCount: map['activeGroupsCount'] as int? ?? 0,
    );
  }

  UserSummary toDomain() => UserSummary(
    currencyCode: currencyCode,
    totalSpentMinor: totalSpentMinor,
    activeGroupsCount: activeGroupsCount,
  );
}

class UserTotalsDto {
  const UserTotalsDto({
    required this.currencyCode,
    required this.totalSpentMinor,
    required this.totalSettledMinor,
    required this.netBalanceMinor,
  });

  final String currencyCode;
  final int totalSpentMinor;
  final int totalSettledMinor;
  final int netBalanceMinor;

  factory UserTotalsDto.fromMap(Map<String, dynamic> map) {
    return UserTotalsDto(
      currencyCode: map['currencyCode'] as String? ?? 'USD',
      totalSpentMinor: map['totalSpentMinor'] as int? ?? 0,
      totalSettledMinor: map['totalSettledMinor'] as int? ?? 0,
      netBalanceMinor: map['netBalanceMinor'] as int? ?? 0,
    );
  }

  UserTotals toDomain() => UserTotals(
    currencyCode: currencyCode,
    totalSpentMinor: totalSpentMinor,
    totalSettledMinor: totalSettledMinor,
    netBalanceMinor: netBalanceMinor,
  );
}

class UserChartPointDto {
  const UserChartPointDto({
    required this.label,
    required this.amountMinor,
  });

  final String label;
  final int amountMinor;

  factory UserChartPointDto.fromMap(Map<String, dynamic> map) {
    return UserChartPointDto(
      label: map['label'] as String? ?? '',
      amountMinor: map['amountMinor'] as int? ?? 0,
    );
  }

  UserChartPoint toDomain() => UserChartPoint(
    label: label,
    amountMinor: amountMinor,
  );
}
