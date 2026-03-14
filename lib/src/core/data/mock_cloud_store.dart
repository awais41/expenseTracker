import 'dart:convert';
import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

import '../../experimental/auth_sync/data/dto/auth_dtos.dart';
import '../../experimental/online_groups/data/repositories/online_group_dtos.dart';

class MockCloudStore {
  MockCloudStore();

  static const _usersKey = 'mock_cloud_users';
  static const _profilesKey = 'mock_cloud_profiles';
  static const _groupsKey = 'mock_cloud_groups_v2';
  static const _membersKey = 'mock_cloud_group_members_v2';
  static const _invitesKey = 'mock_cloud_group_invites_v2';
  static const _requestsKey = 'mock_cloud_group_requests_v2';
  static const _expensesKey = 'mock_cloud_group_expenses_v2';
  static const _settlementsKey = 'mock_cloud_settlements_v2';
  static const _activityKey = 'mock_cloud_activity_v2';
  static const _sessionUserKey = 'mock_cloud_session_user';
  static const _migrationKey = 'mock_cloud_migration_state_v2';

  SharedPreferences? _preferences;

  Future<void> hydrate() async {
    _preferences ??= await SharedPreferences.getInstance();
  }

  Future<List<AuthUserDto>> loadUsers() async {
    final decoded = _decodeList(await _getString(_usersKey));
    return decoded.map(AuthUserDto.fromMap).toList();
  }

  Future<void> saveUsers(List<AuthUserDto> users) async {
    await _setString(_usersKey, jsonEncode(users.map((item) => item.toMap()).toList()));
  }

  Future<List<ProfileDto>> loadProfiles() async {
    final decoded = _decodeList(await _getString(_profilesKey));
    return decoded.map(ProfileDto.fromMap).toList();
  }

  Future<void> saveProfiles(List<ProfileDto> items) async {
    await _setString(_profilesKey, jsonEncode(items.map((item) => item.toMap()).toList()));
  }

  Future<List<GroupDto>> loadGroups() async {
    final decoded = _decodeList(await _getString(_groupsKey));
    return decoded.map(GroupDto.fromMap).toList();
  }

  Future<void> saveGroups(List<GroupDto> items) async {
    await _setString(_groupsKey, jsonEncode(items.map((item) => item.toMap()).toList()));
  }

  Future<List<GroupMemberDto>> loadMembers() async {
    final decoded = _decodeList(await _getString(_membersKey));
    return decoded.map(GroupMemberDto.fromMap).toList();
  }

  Future<void> saveMembers(List<GroupMemberDto> items) async {
    await _setString(_membersKey, jsonEncode(items.map((item) => item.toMap()).toList()));
  }

  Future<List<GroupInviteDto>> loadInvites() async {
    final decoded = _decodeList(await _getString(_invitesKey));
    return decoded.map(GroupInviteDto.fromMap).toList();
  }

  Future<void> saveInvites(List<GroupInviteDto> items) async {
    await _setString(_invitesKey, jsonEncode(items.map((item) => item.toMap()).toList()));
  }

  Future<List<GroupJoinRequestDto>> loadRequests() async {
    final decoded = _decodeList(await _getString(_requestsKey));
    return decoded.map(GroupJoinRequestDto.fromMap).toList();
  }

  Future<void> saveRequests(List<GroupJoinRequestDto> items) async {
    await _setString(_requestsKey, jsonEncode(items.map((item) => item.toMap()).toList()));
  }

  Future<List<GroupExpenseDto>> loadExpenses() async {
    final decoded = _decodeList(await _getString(_expensesKey));
    return decoded.map(GroupExpenseDto.fromMap).toList();
  }

  Future<void> saveExpenses(List<GroupExpenseDto> items) async {
    await _setString(_expensesKey, jsonEncode(items.map((item) => item.toMap()).toList()));
  }

  Future<List<SettlementDto>> loadSettlements() async {
    final decoded = _decodeList(await _getString(_settlementsKey));
    return decoded.map(SettlementDto.fromMap).toList();
  }

  Future<void> saveSettlements(List<SettlementDto> items) async {
    await _setString(_settlementsKey, jsonEncode(items.map((item) => item.toMap()).toList()));
  }

  Future<List<ActivityDto>> loadActivity() async {
    final decoded = _decodeList(await _getString(_activityKey));
    return decoded.map(ActivityDto.fromMap).toList();
  }

  Future<void> saveActivity(List<ActivityDto> items) async {
    await _setString(_activityKey, jsonEncode(items.map((item) => item.toMap()).toList()));
  }

  Future<String?> loadSessionUserId() async {
    await hydrate();
    return _preferences!.getString(_sessionUserKey);
  }

  Future<void> saveSessionUserId(String? userId) async {
    await hydrate();
    if (userId == null) {
      await _preferences!.remove(_sessionUserKey);
    } else {
      await _preferences!.setString(_sessionUserKey, userId);
    }
  }

  Future<Map<String, dynamic>> loadMigrationState() async {
    final encoded = await _getString(_migrationKey);
    if (encoded == null || encoded.isEmpty) {
      return <String, dynamic>{};
    }
    return Map<String, dynamic>.from(jsonDecode(encoded) as Map);
  }

  Future<void> saveMigrationState(Map<String, dynamic> value) async {
    await _setString(_migrationKey, jsonEncode(value));
  }

  String createId(String prefix) {
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}-${math.Random().nextInt(999999)}';
  }

  Future<String?> _getString(String key) async {
    await hydrate();
    return _preferences!.getString(key);
  }

  Future<void> _setString(String key, String value) async {
    await hydrate();
    await _preferences!.setString(key, value);
  }

  List<Map<String, dynamic>> _decodeList(String? encoded) {
    if (encoded == null || encoded.isEmpty) {
      return const <Map<String, dynamic>>[];
    }
    final decoded = jsonDecode(encoded) as List<dynamic>;
    return decoded
        .cast<Map<dynamic, dynamic>>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
