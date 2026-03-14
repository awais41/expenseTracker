import '../../domain/models/online_group_models.dart';

class CreateGroupRequestDto {
  const CreateGroupRequestDto({
    required this.name,
    required this.currencyCode,
    required this.isDiscoverable,
    this.description,
  });

  final String name;
  final String currencyCode;
  final String? description;
  final bool isDiscoverable;

  Map<String, dynamic> toMap() => {
    'name': name,
    'currencyCode': currencyCode,
    'description': description,
    'isDiscoverable': isDiscoverable,
  };
}

class UpdateGroupRequestDto {
  const UpdateGroupRequestDto({
    required this.name,
    required this.isDiscoverable,
    this.description,
  });

  final String name;
  final String? description;
  final bool isDiscoverable;

  Map<String, dynamic> toMap() => {
    'name': name,
    'description': description,
    'isDiscoverable': isDiscoverable,
  };
}

class AddGroupMemberRequestDto {
  const AddGroupMemberRequestDto({
    required this.userId,
    this.role = 'MEMBER',
  });

  final String userId;
  final String role;

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'role': role,
  };
}

class ExpenseParticipantRequestDto {
  const ExpenseParticipantRequestDto({
    required this.userId,
    required this.amountMinor,
    this.shareValue,
    this.shareType,
  });

  final String userId;
  final double? shareValue;
  final String? shareType;
  final int amountMinor;

  Map<String, dynamic> toMap() => {
    'userId': userId,
    if (shareType == 'percent' && shareValue != null) 'percentValue': shareValue,
    if (shareType == 'shares' && shareValue != null) 'sharesValue': shareValue,
    if (shareType != 'percent' && shareType != 'shares') 'amountMinor': amountMinor,
  };
}

class ExpenseUpsertRequestDto {
  const ExpenseUpsertRequestDto({
    required this.title,
    required this.amountMinor,
    required this.currencyCode,
    required this.paidByUserId,
    required this.expenseDate,
    required this.splitMethod,
    required this.includePayerInSplit,
    this.description,
    this.category,
    this.notes,
    this.participantUserIds,
    this.participants,
  });

  final String title;
  final String? description;
  final int amountMinor;
  final String currencyCode;
  final String paidByUserId;
  final DateTime expenseDate;
  final String splitMethod;
  final bool includePayerInSplit;
  final String? category;
  final String? notes;
  final List<String>? participantUserIds;
  final List<ExpenseParticipantRequestDto>? participants;

  Map<String, dynamic> toMap() => {
    'title': title,
    'description': description,
    'amountMinor': amountMinor,
    'currencyCode': currencyCode,
    'paidByUserId': paidByUserId,
    'expenseDate': expenseDate.toUtc().toIso8601String(),
    'splitMethod': splitMethod,
    'includePayerInSplit': includePayerInSplit,
    'category': category,
    'notes': notes,
    if (participantUserIds != null) 'participantUserIds': participantUserIds,
    if (participants != null)
      'participants': participants!.map((item) => item.toMap()).toList(),
  };
}

class CreateSettlementRequestDto {
  const CreateSettlementRequestDto({
    required this.fromUserId,
    required this.toUserId,
    required this.amountMinor,
    required this.currencyCode,
    required this.settledAt,
    this.note,
  });

  final String fromUserId;
  final String toUserId;
  final int amountMinor;
  final String currencyCode;
  final DateTime settledAt;
  final String? note;

  Map<String, dynamic> toMap() => {
    'fromUserId': fromUserId,
    'toUserId': toUserId,
    'amountMinor': amountMinor,
    'currencyCode': currencyCode,
    'settledAt': settledAt.toUtc().toIso8601String(),
    'note': note,
  };
}

class GroupDto {
  const GroupDto({
    required this.id,
    required this.name,
    required this.createdByUserId,
    required this.isDiscoverable,
    required this.createdAt,
    required this.updatedAt,
    this.description,
  });

  final String id;
  final String name;
  final String? description;
  final String createdByUserId;
  final bool isDiscoverable;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory GroupDto.fromMap(Map<String, dynamic> map) {
    final createdBy = map['createdByUserId'] as String? ??
        map['ownerUserId'] as String? ??
        map['createdBy'] as String? ??
        '';
    return GroupDto(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
      createdByUserId: createdBy,
      isDiscoverable: map['isDiscoverable'] as bool? ?? false,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'createdByUserId': createdByUserId,
    'isDiscoverable': isDiscoverable,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  Group toDomain() => Group(
    id: id,
    name: name,
    description: description,
    createdByUserId: createdByUserId,
    isDiscoverable: isDiscoverable,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

class GroupMemberDto {
  const GroupMemberDto({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.role,
    required this.status,
    required this.joinedAt,
  });

  final String id;
  final String groupId;
  final String userId;
  final String role;
  final String status;
  final DateTime joinedAt;

  factory GroupMemberDto.fromMap(Map<String, dynamic> map) {
    final role = (map['role'] as String? ?? GroupRole.member.name).toLowerCase();
    final status = (map['status'] as String? ?? MembershipStatus.active.name).toLowerCase();
    return GroupMemberDto(
      id: map['id'] as String,
      groupId: map['groupId'] as String? ?? '',
      userId: map['userId'] as String? ?? map['memberUserId'] as String? ?? '',
      role: role,
      status: status,
      joinedAt: DateTime.tryParse(map['joinedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'groupId': groupId,
    'userId': userId,
    'role': role,
    'status': status,
    'joinedAt': joinedAt.toIso8601String(),
  };

  GroupMember toDomain() => GroupMember(
    id: id,
    groupId: groupId,
    userId: userId,
    role: GroupRole.fromName(role),
    status: MembershipStatus.fromName(status),
    joinedAt: joinedAt,
  );
}

class GroupInviteDto {
  const GroupInviteDto({
    required this.id,
    required this.groupId,
    required this.inviterUserId,
    required this.inviteeUserId,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  final String id;
  final String groupId;
  final String inviterUserId;
  final String inviteeUserId;
  final String status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  factory GroupInviteDto.fromMap(Map<String, dynamic> map) {
    return GroupInviteDto(
      id: map['id'] as String,
      groupId: map['groupId'] as String? ?? '',
      inviterUserId: map['inviterUserId'] as String? ?? '',
      inviteeUserId: map['inviteeUserId'] as String? ?? '',
      status: map['status'] as String? ?? InviteStatus.pending.name,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      respondedAt: DateTime.tryParse(map['respondedAt'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'groupId': groupId,
    'inviterUserId': inviterUserId,
    'inviteeUserId': inviteeUserId,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
    'respondedAt': respondedAt?.toIso8601String(),
  };

  GroupInvite toDomain() => GroupInvite(
    id: id,
    groupId: groupId,
    inviterUserId: inviterUserId,
    inviteeUserId: inviteeUserId,
    status: InviteStatus.fromName(status),
    createdAt: createdAt,
    respondedAt: respondedAt,
  );
}

class GroupJoinRequestDto {
  const GroupJoinRequestDto({
    required this.id,
    required this.groupId,
    required this.requesterUserId,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  final String id;
  final String groupId;
  final String requesterUserId;
  final String status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  factory GroupJoinRequestDto.fromMap(Map<String, dynamic> map) {
    return GroupJoinRequestDto(
      id: map['id'] as String,
      groupId: map['groupId'] as String? ?? '',
      requesterUserId: map['requesterUserId'] as String? ?? '',
      status: map['status'] as String? ?? InviteStatus.pending.name,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      respondedAt: DateTime.tryParse(map['respondedAt'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'groupId': groupId,
    'requesterUserId': requesterUserId,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
    'respondedAt': respondedAt?.toIso8601String(),
  };

  GroupJoinRequest toDomain() => GroupJoinRequest(
    id: id,
    groupId: groupId,
    requesterUserId: requesterUserId,
    status: InviteStatus.fromName(status),
    createdAt: createdAt,
    respondedAt: respondedAt,
  );
}

class ExpenseParticipantDto {
  const ExpenseParticipantDto({
    required this.id,
    required this.expenseId,
    required this.userId,
    required this.shareValue,
    required this.shareType,
    required this.amountOwedMinor,
  });

  final String id;
  final String expenseId;
  final String userId;
  final double shareValue;
  final String shareType;
  final int amountOwedMinor;

  factory ExpenseParticipantDto.fromMap(Map<String, dynamic> map) {
    final amountMinor =
        map['amountMinor'] as int? ?? map['amountOwedMinor'] as int? ?? 0;
    final shareType = map['shareType'] as String? ??
        (map.containsKey('percentValue')
            ? 'percentage'
            : map.containsKey('sharesValue')
                ? 'shares'
                : 'amount');
    final shareValue = (map['shareValue'] as num?)?.toDouble() ??
        (map['percentValue'] as num?)?.toDouble() ??
        (map['sharesValue'] as num?)?.toDouble() ??
        (amountMinor / 100);
    return ExpenseParticipantDto(
      id: map['id'] as String,
      expenseId: map['expenseId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      shareValue: shareValue,
      shareType: shareType,
      amountOwedMinor: amountMinor,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'expenseId': expenseId,
    'userId': userId,
    'shareValue': shareValue,
    'shareType': shareType,
    'amountMinor': amountOwedMinor,
  };

  ExpenseParticipant toDomain() => ExpenseParticipant(
    id: id,
    expenseId: expenseId,
    userId: userId,
    shareValue: shareValue,
    shareType: shareType,
    amountOwedMinor: amountOwedMinor,
  );
}

class GroupExpenseDto {
  const GroupExpenseDto({
    required this.id,
    required this.groupId,
    required this.createdByUserId,
    required this.title,
    required this.amountMinor,
    required this.currencyCode,
    required this.splitMode,
    required this.paidByUserId,
    required this.includePayerInSplit,
    required this.expenseDate,
    required this.createdAt,
    required this.updatedAt,
    required this.description,
    required this.category,
    required this.notes,
    required this.participants,
  });

  final String id;
  final String groupId;
  final String createdByUserId;
  final String title;
  final String? description;
  final String? notes;
  final int amountMinor;
  final String currencyCode;
  final String splitMode;
  final String paidByUserId;
  final bool includePayerInSplit;
  final String? category;
  final DateTime expenseDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ExpenseParticipantDto> participants;

  factory GroupExpenseDto.fromMap(Map<String, dynamic> map) {
    final participants = (map['participants'] as List<dynamic>? ?? const <dynamic>[])
        .cast<Map<dynamic, dynamic>>()
        .map((item) => ExpenseParticipantDto.fromMap(Map<String, dynamic>.from(item)))
        .toList();
    return GroupExpenseDto(
      id: map['id'] as String,
      groupId: map['groupId'] as String? ?? '',
      createdByUserId: map['createdByUserId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String?,
      notes: map['notes'] as String?,
      amountMinor: map['amountMinor'] as int? ?? 0,
      currencyCode: map['currencyCode'] as String? ?? 'USD',
      splitMode: map['splitMode'] as String? ?? map['splitMethod'] as String? ?? GroupSplitMode.equal.name,
      paidByUserId: map['paidByUserId'] as String? ?? '',
      includePayerInSplit: map['includePayerInSplit'] as bool? ?? true,
      category: map['category'] as String?,
      expenseDate: DateTime.tryParse(map['expenseDate'] as String? ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ?? DateTime.now(),
      participants: participants,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'groupId': groupId,
    'createdByUserId': createdByUserId,
    'title': title,
    'description': description,
    'notes': notes,
    'amountMinor': amountMinor,
    'currencyCode': currencyCode,
    'splitMode': splitMode,
    'paidByUserId': paidByUserId,
    'includePayerInSplit': includePayerInSplit,
    'category': category,
    'expenseDate': expenseDate.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'participants': participants.map((item) => item.toMap()).toList(),
  };

  GroupExpense toDomain() => GroupExpense(
    id: id,
    groupId: groupId,
    createdByUserId: createdByUserId,
    title: title,
    description: description,
    notes: notes,
    amountMinor: amountMinor,
    currencyCode: currencyCode,
    splitMode: GroupSplitMode.fromName(splitMode),
    paidByUserId: paidByUserId,
    includePayerInSplit: includePayerInSplit,
    category: category,
    expenseDate: expenseDate,
    createdAt: createdAt,
    updatedAt: updatedAt,
    participants: participants.map((item) => item.toDomain()).toList(),
  );
}

class SettlementDto {
  const SettlementDto({
    required this.id,
    required this.groupId,
    required this.fromUserId,
    required this.toUserId,
    required this.amountMinor,
    required this.currencyCode,
    required this.note,
    required this.settlementDate,
    required this.createdByUserId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String groupId;
  final String fromUserId;
  final String toUserId;
  final int amountMinor;
  final String currencyCode;
  final String? note;
  final DateTime settlementDate;
  final String createdByUserId;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory SettlementDto.fromMap(Map<String, dynamic> map) {
    return SettlementDto(
      id: map['id'] as String,
      groupId: map['groupId'] as String? ?? '',
      fromUserId: map['fromUserId'] as String? ?? '',
      toUserId: map['toUserId'] as String? ?? '',
      amountMinor: map['amountMinor'] as int? ?? 0,
      currencyCode: map['currencyCode'] as String? ?? 'USD',
      note: map['note'] as String?,
      settlementDate:
          DateTime.tryParse(
                map['settlementDate'] as String? ??
                    map['settledAt'] as String? ??
                    '',
              ) ??
              DateTime.now(),
      createdByUserId: map['createdByUserId'] as String? ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'groupId': groupId,
    'fromUserId': fromUserId,
    'toUserId': toUserId,
    'amountMinor': amountMinor,
    'currencyCode': currencyCode,
    'note': note,
    'settlementDate': settlementDate.toIso8601String(),
    'createdByUserId': createdByUserId,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  Settlement toDomain() => Settlement(
    id: id,
    groupId: groupId,
    fromUserId: fromUserId,
    toUserId: toUserId,
    amountMinor: amountMinor,
    currencyCode: currencyCode,
    note: note,
    settlementDate: settlementDate,
    createdByUserId: createdByUserId,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

class ActivityDto {
  const ActivityDto({
    required this.id,
    required this.groupId,
    required this.type,
    required this.actorUserId,
    required this.referenceId,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final String groupId;
  final String type;
  final String actorUserId;
  final String referenceId;
  final String message;
  final DateTime createdAt;

  factory ActivityDto.fromMap(Map<String, dynamic> map) {
    final metadata = Map<String, dynamic>.from(
      map['metadata'] as Map? ?? const <String, dynamic>{},
    );
    final eventType = map['eventType'] as String? ?? map['type'] as String? ?? '';
    final entityType = map['entityType'] as String? ?? '';
    final entityId = map['entityId'] as String? ?? map['referenceId'] as String? ?? '';
    final explicitMessage = map['message'] as String?;
    final metadataMessage = metadata['message'] as String?;
    return ActivityDto(
      id: map['id'] as String,
      groupId: map['groupId'] as String? ?? '',
      type: eventType,
      actorUserId: map['actorUserId'] as String? ?? '',
      referenceId: entityId,
      message: explicitMessage ?? metadataMessage ?? '$eventType ${entityType.trim()}'.trim(),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'groupId': groupId,
    'type': type,
    'actorUserId': actorUserId,
    'referenceId': referenceId,
    'message': message,
    'createdAt': createdAt.toIso8601String(),
  };

  ActivityItem toDomain() => ActivityItem(
    id: id,
    groupId: groupId,
    type: type,
    actorUserId: actorUserId,
    referenceId: referenceId,
    message: message,
    createdAt: createdAt,
  );
}

class GroupBalanceSummaryDto {
  const GroupBalanceSummaryDto({
    required this.groupId,
    required this.userId,
    required this.totalOwedMinor,
    required this.totalReceivableMinor,
    required this.netAmountMinor,
  });

  final String groupId;
  final String userId;
  final int totalOwedMinor;
  final int totalReceivableMinor;
  final int netAmountMinor;

  factory GroupBalanceSummaryDto.fromMap(Map<String, dynamic> map) {
    return GroupBalanceSummaryDto(
      groupId: map['groupId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      totalOwedMinor: map['totalOwedMinor'] as int? ?? 0,
      totalReceivableMinor: map['totalReceivableMinor'] as int? ?? 0,
      netAmountMinor: map['netAmountMinor'] as int? ?? 0,
    );
  }

  GroupBalanceSummary toDomain() => GroupBalanceSummary(
    groupId: groupId,
    userId: userId,
    totalOwedMinor: totalOwedMinor,
    totalReceivableMinor: totalReceivableMinor,
    netAmountMinor: netAmountMinor,
  );
}

class GroupBalancesEnvelopeDto {
  const GroupBalancesEnvelopeDto({
    required this.groupId,
    required this.currencyCode,
    required this.netBalances,
    required this.simplifiedDebts,
    required this.asOf,
  });

  final String groupId;
  final String currencyCode;
  final List<GroupBalanceSummaryDto> netBalances;
  final List<GroupTransfer> simplifiedDebts;
  final DateTime asOf;

  factory GroupBalancesEnvelopeDto.fromMap(Map<String, dynamic> map) {
    final netBalances = (map['netBalances'] as List<dynamic>? ?? const <dynamic>[])
        .cast<Map<dynamic, dynamic>>()
        .map((item) => GroupBalanceSummaryDto.fromMap(Map<String, dynamic>.from(item)))
        .toList();
    final simplifiedDebts = (map['simplifiedDebts'] as List<dynamic>? ?? const <dynamic>[])
        .cast<Map<dynamic, dynamic>>()
        .map(
          (item) => GroupTransfer(
            fromUserId: item['fromUserId'] as String? ?? '',
            toUserId: item['toUserId'] as String? ?? '',
            amountMinor: item['amountMinor'] as int? ?? 0,
          ),
        )
        .toList();
    return GroupBalancesEnvelopeDto(
      groupId: map['groupId'] as String? ?? '',
      currencyCode: map['currencyCode'] as String? ?? 'USD',
      netBalances: netBalances,
      simplifiedDebts: simplifiedDebts,
      asOf: DateTime.tryParse(map['asOf'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
