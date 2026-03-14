enum GroupRole {
  owner,
  admin,
  member;

  static GroupRole fromName(String? value) {
    final normalized = value?.trim().toLowerCase();
    return GroupRole.values.firstWhere(
      (role) => role.name == normalized,
      orElse: () => GroupRole.member,
    );
  }
}

enum MembershipStatus {
  active,
  invited,
  requested;

  static MembershipStatus fromName(String? value) {
    final normalized = value?.trim().toLowerCase();
    return MembershipStatus.values.firstWhere(
      (status) => status.name == normalized,
      orElse: () => MembershipStatus.active,
    );
  }
}

enum InviteStatus {
  pending,
  accepted,
  rejected;

  static InviteStatus fromName(String? value) {
    final normalized = value?.trim().toLowerCase();
    return InviteStatus.values.firstWhere(
      (status) => status.name == normalized,
      orElse: () => InviteStatus.pending,
    );
  }
}

enum GroupSplitMode {
  equal,
  exact,
  percentage,
  shares,
  adjustment;

  String get label => switch (this) {
    GroupSplitMode.equal => 'Equal',
    GroupSplitMode.exact => 'Exact',
    GroupSplitMode.percentage => 'Percent',
    GroupSplitMode.shares => 'Shares',
    GroupSplitMode.adjustment => 'Adjust',
  };

  static GroupSplitMode fromName(String? value) {
    final normalized = value?.trim().toLowerCase();
    return GroupSplitMode.values.firstWhere(
      (mode) => mode.name == normalized,
      orElse: () => GroupSplitMode.equal,
    );
  }
}

class Group {
  const Group({
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
}

class GroupMember {
  const GroupMember({
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
  final GroupRole role;
  final MembershipStatus status;
  final DateTime joinedAt;
}

class GroupInvite {
  const GroupInvite({
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
  final InviteStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;
}

class GroupJoinRequest {
  const GroupJoinRequest({
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
  final InviteStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;
}

class ExpenseParticipant {
  const ExpenseParticipant({
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

  double get amountOwed => amountOwedMinor / 100;
}

class GroupExpense {
  const GroupExpense({
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
    required this.participants,
    this.notes,
    this.description,
    this.category,
  });

  final String id;
  final String groupId;
  final String createdByUserId;
  final String title;
  final String? description;
  final String? notes;
  final int amountMinor;
  final String currencyCode;
  final GroupSplitMode splitMode;
  final String paidByUserId;
  final bool includePayerInSplit;
  final String? category;
  final DateTime expenseDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ExpenseParticipant> participants;

  double get amount => amountMinor / 100;
}

class Settlement {
  const Settlement({
    required this.id,
    required this.groupId,
    required this.fromUserId,
    required this.toUserId,
    required this.amountMinor,
    required this.currencyCode,
    required this.settlementDate,
    required this.createdByUserId,
    required this.createdAt,
    required this.updatedAt,
    this.note,
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

  double get amount => amountMinor / 100;
}

class GroupBalanceSummary {
  const GroupBalanceSummary({
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

  double get totalOwed => totalOwedMinor / 100;
  double get totalReceivable => totalReceivableMinor / 100;
  double get netAmount => netAmountMinor / 100;
}

class ActivityItem {
  const ActivityItem({
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
}

class MigrationState {
  const MigrationState({
    required this.accountDataImported,
    this.importedAt,
    this.sourceDeviceId,
  });

  final bool accountDataImported;
  final DateTime? importedAt;
  final String? sourceDeviceId;
}

class GroupTransfer {
  const GroupTransfer({
    required this.fromUserId,
    required this.toUserId,
    required this.amountMinor,
  });

  final String fromUserId;
  final String toUserId;
  final int amountMinor;

  double get amount => amountMinor / 100;
}
