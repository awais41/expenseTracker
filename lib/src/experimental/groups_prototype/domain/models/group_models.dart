import 'package:flutter/material.dart';

enum GroupSplitMode {
  equal,
  exact,
  percentage,
  shares;

  String get label => switch (this) {
    GroupSplitMode.equal => 'Equal',
    GroupSplitMode.exact => 'Exact',
    GroupSplitMode.percentage => 'Percent',
    GroupSplitMode.shares => 'Shares',
  };

  static GroupSplitMode fromName(String? value) {
    return GroupSplitMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => GroupSplitMode.equal,
    );
  }
}

class LocalProfile {
  const LocalProfile({
    required this.id,
    required this.displayName,
    required this.avatarColorValue,
    required this.isSelf,
    required this.createdAt,
  });

  final String id;
  final String displayName;
  final int avatarColorValue;
  final bool isSelf;
  final DateTime createdAt;

  Color get avatarColor => Color(avatarColorValue);

  Map<String, dynamic> toMap() => {
    'id': id,
    'displayName': displayName,
    'avatarColorValue': avatarColorValue,
    'isSelf': isSelf,
    'createdAt': createdAt.toIso8601String(),
  };

  factory LocalProfile.fromMap(Map<String, dynamic> map) {
    return LocalProfile(
      id: map['id'] as String,
      displayName: map['displayName'] as String,
      avatarColorValue: map['avatarColorValue'] as int,
      isSelf: map['isSelf'] as bool? ?? false,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class ExpenseGroup {
  const ExpenseGroup({
    required this.id,
    required this.name,
    required this.memberIds,
    required this.createdAt,
    required this.updatedAt,
    this.archivedAt,
  });

  final String id;
  final String name;
  final List<String> memberIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;

  bool get isArchived => archivedAt != null;

  ExpenseGroup copyWith({
    String? id,
    String? name,
    List<String>? memberIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? archivedAt,
    bool clearArchivedAt = false,
  }) {
    return ExpenseGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      memberIds: memberIds ?? this.memberIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archivedAt: clearArchivedAt ? null : archivedAt ?? this.archivedAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'memberIds': memberIds,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'archivedAt': archivedAt?.toIso8601String(),
  };

  factory ExpenseGroup.fromMap(Map<String, dynamic> map) {
    return ExpenseGroup(
      id: map['id'] as String,
      name: map['name'] as String,
      memberIds: (map['memberIds'] as List<dynamic>? ?? const <dynamic>[])
          .map((value) => value as String)
          .toList(),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ?? DateTime.now(),
      archivedAt: DateTime.tryParse(map['archivedAt'] as String? ?? ''),
    );
  }
}

class SharedExpense {
  const SharedExpense({
    required this.id,
    required this.groupId,
    required this.description,
    required this.amount,
    required this.currencyCode,
    required this.paidByProfileId,
    required this.participantIds,
    required this.splitMode,
    required this.splitInput,
    required this.splitAmounts,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.note = '',
    this.deletedAt,
  });

  final String id;
  final String groupId;
  final String description;
  final double amount;
  final String currencyCode;
  final String paidByProfileId;
  final List<String> participantIds;
  final GroupSplitMode splitMode;
  final Map<String, double> splitInput;
  final Map<String, double> splitAmounts;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String note;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  SharedExpense copyWith({
    String? id,
    String? groupId,
    String? description,
    double? amount,
    String? currencyCode,
    String? paidByProfileId,
    List<String>? participantIds,
    GroupSplitMode? splitMode,
    Map<String, double>? splitInput,
    Map<String, double>? splitAmounts,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? note,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return SharedExpense(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      currencyCode: currencyCode ?? this.currencyCode,
      paidByProfileId: paidByProfileId ?? this.paidByProfileId,
      participantIds: participantIds ?? this.participantIds,
      splitMode: splitMode ?? this.splitMode,
      splitInput: splitInput ?? this.splitInput,
      splitAmounts: splitAmounts ?? this.splitAmounts,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      note: note ?? this.note,
      deletedAt: clearDeletedAt ? null : deletedAt ?? this.deletedAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'groupId': groupId,
    'description': description,
    'amount': amount,
    'currencyCode': currencyCode,
    'paidByProfileId': paidByProfileId,
    'participantIds': participantIds,
    'splitMode': splitMode.name,
    'splitInput': splitInput,
    'splitAmounts': splitAmounts,
    'date': date.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'note': note,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory SharedExpense.fromMap(Map<String, dynamic> map) {
    return SharedExpense(
      id: map['id'] as String,
      groupId: map['groupId'] as String,
      description: map['description'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      currencyCode: map['currencyCode'] as String? ?? 'USD',
      paidByProfileId: map['paidByProfileId'] as String,
      participantIds: (map['participantIds'] as List<dynamic>? ?? const <dynamic>[])
          .map((value) => value as String)
          .toList(),
      splitMode: GroupSplitMode.fromName(map['splitMode'] as String?),
      splitInput: _decodeDoubleMap(map['splitInput']),
      splitAmounts: _decodeDoubleMap(map['splitAmounts']),
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ?? DateTime.now(),
      note: map['note'] as String? ?? '',
      deletedAt: DateTime.tryParse(map['deletedAt'] as String? ?? ''),
    );
  }
}

class SettlementRecord {
  const SettlementRecord({
    required this.id,
    required this.groupId,
    required this.fromProfileId,
    required this.toProfileId,
    required this.amount,
    required this.currencyCode,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.note = '',
    this.deletedAt,
  });

  final String id;
  final String groupId;
  final String fromProfileId;
  final String toProfileId;
  final double amount;
  final String currencyCode;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String note;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  SettlementRecord copyWith({
    String? id,
    String? groupId,
    String? fromProfileId,
    String? toProfileId,
    double? amount,
    String? currencyCode,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? note,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return SettlementRecord(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      fromProfileId: fromProfileId ?? this.fromProfileId,
      toProfileId: toProfileId ?? this.toProfileId,
      amount: amount ?? this.amount,
      currencyCode: currencyCode ?? this.currencyCode,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      note: note ?? this.note,
      deletedAt: clearDeletedAt ? null : deletedAt ?? this.deletedAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'groupId': groupId,
    'fromProfileId': fromProfileId,
    'toProfileId': toProfileId,
    'amount': amount,
    'currencyCode': currencyCode,
    'date': date.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'note': note,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory SettlementRecord.fromMap(Map<String, dynamic> map) {
    return SettlementRecord(
      id: map['id'] as String,
      groupId: map['groupId'] as String,
      fromProfileId: map['fromProfileId'] as String,
      toProfileId: map['toProfileId'] as String,
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      currencyCode: map['currencyCode'] as String? ?? 'USD',
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ?? DateTime.now(),
      note: map['note'] as String? ?? '',
      deletedAt: DateTime.tryParse(map['deletedAt'] as String? ?? ''),
    );
  }
}

class GroupMemberBalance {
  const GroupMemberBalance({
    required this.profileId,
    required this.netAmount,
  });

  final String profileId;
  final double netAmount;
}

class GroupTransfer {
  const GroupTransfer({
    required this.fromProfileId,
    required this.toProfileId,
    required this.amount,
  });

  final String fromProfileId;
  final String toProfileId;
  final double amount;
}

class GroupActivityItem {
  const GroupActivityItem.expense(this.expense)
    : settlement = null,
      typeLabel = 'expense';

  const GroupActivityItem.settlement(this.settlement)
    : expense = null,
      typeLabel = 'settlement';

  final SharedExpense? expense;
  final SettlementRecord? settlement;
  final String typeLabel;

  DateTime get timestamp => expense?.date ?? settlement!.date;
  String get id => expense?.id ?? settlement!.id;
}

Map<String, double> _decodeDoubleMap(Object? source) {
  final map = source as Map<dynamic, dynamic>? ?? const <dynamic, dynamic>{};
  return map.map<String, double>(
    (key, value) => MapEntry(
      key as String,
      (value as num?)?.toDouble() ?? 0,
    ),
  );
}
