import 'package:flutter/material.dart';

import '../../../../core/state/async_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../auth_sync/domain/models/auth_models.dart';
import '../../../auth_sync/domain/repositories/profile_repository.dart';
import '../../domain/models/online_group_models.dart';
import '../../domain/repositories/activity_repository.dart';
import '../../domain/repositories/balances_repository.dart';
import '../../domain/repositories/expenses_repository.dart';
import '../../domain/repositories/groups_repository.dart';
import '../../domain/repositories/settlements_repository.dart';
import '../bloc/group_detail_bloc.dart';
import '../bloc/groups_bloc.dart';

class OnlineGroupsScreen extends StatefulWidget {
  const OnlineGroupsScreen({
    super.key,
    required this.currentUser,
    required this.profileRepository,
    required this.groupsRepository,
    required this.expensesRepository,
    required this.settlementsRepository,
    required this.balancesRepository,
    required this.activityRepository,
  });

  final AppUser currentUser;
  final ProfileRepository profileRepository;
  final GroupsRepository groupsRepository;
  final ExpensesRepository expensesRepository;
  final SettlementsRepository settlementsRepository;
  final BalancesRepository balancesRepository;
  final ActivityRepository activityRepository;

  @override
  State<OnlineGroupsScreen> createState() => _OnlineGroupsScreenState();
}

class _OnlineGroupsScreenState extends State<OnlineGroupsScreen> {
  late final GroupsBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = GroupsBloc(
      repository: widget.groupsRepository,
      currentUser: widget.currentUser,
    )..load();
  }

  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bloc,
      builder: (context, _) {
        final state = _bloc.state;
        final data = state.data;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.background, AppColors.screenGradientEnd],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                RefreshIndicator(
                  onRefresh: _bloc.load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 140),
                    children: [
                      _Header(user: widget.currentUser),
                      const SizedBox(height: 18),
                      if (data == null && state.status == SyncStatus.loading)
                        const Center(child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 60),
                          child: CircularProgressIndicator(),
                        ))
                      else ...[
                        if (state.error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              state.error!.message,
                              style: const TextStyle(color: AppColors.danger),
                            ),
                          ),
                        if ((data?.incomingInvites ?? const <GroupInvite>[]).isNotEmpty)
                          _IncomingInvitesCard(
                            invites: data!.incomingInvites,
                            onRespond: (inviteId, accept) async {
                              final failure = await _bloc.respondToInvite(
                                inviteId: inviteId,
                                accept: accept,
                              );
                              if (failure != null && context.mounted) {
                                _showMessage(context, failure.message);
                              }
                            },
                          ),
                        if ((data?.discoverableGroups ?? const <Group>[]).isNotEmpty)
                          _DiscoverableGroupsCard(
                            groups: data!.discoverableGroups,
                            onRequest: (groupId) async {
                              final failure = await _bloc.requestToJoin(groupId);
                              if (failure != null && context.mounted) {
                                _showMessage(context, failure.message);
                              }
                            },
                          ),
                        const SizedBox(height: 16),
                        Text(
                          'Your Groups',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if ((data?.groups ?? const <Group>[]).isEmpty)
                          GlassCard(
                            child: Column(
                              children: [
                                Icon(Icons.group_add_rounded, size: 40, color: AppColors.emerald),
                                SizedBox(height: 10),
                                Text(
                                  'No groups yet',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Create an online group and invite real users by username.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          )
                        else
                          ...data!.groups.map((group) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => OnlineGroupDetailScreen(
                                      currentUser: widget.currentUser,
                                      profileRepository: widget.profileRepository,
                                      groupsRepository: widget.groupsRepository,
                                      expensesRepository: widget.expensesRepository,
                                      settlementsRepository: widget.settlementsRepository,
                                      balancesRepository: widget.balancesRepository,
                                      activityRepository: widget.activityRepository,
                                      group: group,
                                    ),
                                  ),
                                ),
                                borderRadius: BorderRadius.circular(24),
                                child: GlassCard(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              group.name,
                                              style: TextStyle(
                                                color: AppColors.textPrimary,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          if (group.isDiscoverable)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: AppColors.emerald.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(999),
                                              ),
                                              child: const Text(
                                                'Discoverable',
                                                style: TextStyle(
                                                  color: AppColors.emerald,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      if ((group.description ?? '').isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          group.description!,
                                          style: TextStyle(color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                      ],
                    ],
                  ),
                ),
                Positioned(
                  right: 20,
                  bottom: 92,
                  child: FloatingActionButton.extended(
                    onPressed: () => _openCreateGroupSheet(context),
                    icon: const Icon(Icons.group_add_rounded),
                    label: const Text('Create group'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openCreateGroupSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CreateGroupSheet(
        onSave: (name, description, isDiscoverable) async {
          final failure = await _bloc.createGroup(
            name: name,
            description: description,
            isDiscoverable: isDiscoverable,
          );
          if (failure != null && context.mounted) {
            _showMessage(context, failure.message);
            return false;
          }
          return true;
        },
      ),
    );
  }
}

class OnlineGroupDetailScreen extends StatefulWidget {
  const OnlineGroupDetailScreen({
    super.key,
    required this.currentUser,
    required this.profileRepository,
    required this.groupsRepository,
    required this.expensesRepository,
    required this.settlementsRepository,
    required this.balancesRepository,
    required this.activityRepository,
    required this.group,
  });

  final AppUser currentUser;
  final ProfileRepository profileRepository;
  final GroupsRepository groupsRepository;
  final ExpensesRepository expensesRepository;
  final SettlementsRepository settlementsRepository;
  final BalancesRepository balancesRepository;
  final ActivityRepository activityRepository;
  final Group group;

  @override
  State<OnlineGroupDetailScreen> createState() => _OnlineGroupDetailScreenState();
}

class _OnlineGroupDetailScreenState extends State<OnlineGroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late final GroupDetailBloc _bloc;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _bloc = GroupDetailBloc(
      currentUser: widget.currentUser,
      groupsRepository: widget.groupsRepository,
      expensesRepository: widget.expensesRepository,
      settlementsRepository: widget.settlementsRepository,
      balancesRepository: widget.balancesRepository,
      activityRepository: widget.activityRepository,
      group: widget.group,
    )..load();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bloc,
      builder: (context, _) {
        final state = _bloc.state;
        final data = state.data;
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.group.name),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: const [
                Tab(text: 'Members'),
                Tab(text: 'Expenses'),
                Tab(text: 'Balances'),
                Tab(text: 'Activity'),
                Tab(text: 'Settlements'),
              ],
            ),
          ),
          body: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.background, AppColors.screenGradientEnd],
              ),
            ),
            child: data == null && state.status == SyncStatus.loading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _MembersTab(
                        currentUser: widget.currentUser,
                        profileRepository: widget.profileRepository,
                        bloc: _bloc,
                        data: data,
                      ),
                      _ExpensesTab(
                        bloc: _bloc,
                        data: data,
                        currentUser: widget.currentUser,
                      ),
                      _BalancesTab(data: data, currentUser: widget.currentUser),
                      _ActivityTab(data: data, currentUser: widget.currentUser),
                      _SettlementsTab(
                        bloc: _bloc,
                        data: data,
                        currentUser: widget.currentUser,
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: user.avatarColor.withValues(alpha: 0.16),
          child: Text(
            user.displayName.substring(0, 1).toUpperCase(),
            style: TextStyle(
              color: user.avatarColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Groups',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '@${user.username}',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IncomingInvitesCard extends StatelessWidget {
  const _IncomingInvitesCard({
    required this.invites,
    required this.onRespond,
  });

  final List<GroupInvite> invites;
  final Future<void> Function(String inviteId, bool accept) onRespond;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Incoming Invites',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ...invites.map((invite) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        invite.groupId,
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                    ),
                    TextButton(
                      onPressed: () => onRespond(invite.id, false),
                      child: const Text('Reject'),
                    ),
                    FilledButton(
                      onPressed: () => onRespond(invite.id, true),
                      child: const Text('Accept'),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _DiscoverableGroupsCard extends StatelessWidget {
  const _DiscoverableGroupsCard({
    required this.groups,
    required this.onRequest,
  });

  final List<Group> groups;
  final Future<void> Function(String groupId) onRequest;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Discoverable Groups',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ...groups.map((group) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.name,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if ((group.description ?? '').isNotEmpty)
                            Text(
                              group.description!,
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: () => onRequest(group.id),
                      child: const Text('Request'),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _CreateGroupSheet extends StatefulWidget {
  const _CreateGroupSheet({required this.onSave});

  final Future<bool> Function(String name, String description, bool isDiscoverable) onSave;

  @override
  State<_CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends State<_CreateGroupSheet> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _discoverable = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 24, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: GlassCard(
        radius: 28,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Create Group', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(controller: _nameController, decoration: _inputDecoration('Group name')),
            const SizedBox(height: 12),
            TextField(controller: _descriptionController, decoration: _inputDecoration('Description (optional)')),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _discoverable,
              onChanged: (value) => setState(() => _discoverable = value),
              title: const Text('Allow join requests'),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: const Text('Save group'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await widget.onSave(
      _nameController.text,
      _descriptionController.text,
      _discoverable,
    );
    setState(() => _saving = false);
    if (ok && mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _MembersTab extends StatelessWidget {
  const _MembersTab({
    required this.currentUser,
    required this.profileRepository,
    required this.bloc,
    required this.data,
  });

  final AppUser currentUser;
  final ProfileRepository profileRepository;
  final GroupDetailBloc bloc;
  final GroupDetailData? data;

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return const SizedBox.shrink();
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        if (bloc.canManageGroup)
          FilledButton.icon(
            onPressed: () => _openInviteSheet(context),
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('Invite by username'),
          ),
        if (bloc.canManageGroup) const SizedBox(height: 14),
        Text('Members', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        ...data!.members.map((member) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Text(member.userId == currentUser.id ? '${currentUser.displayName} (You)' : member.userId,
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
                ),
                Text(member.role.name.toUpperCase(), style: TextStyle(color: AppColors.emerald)),
              ],
            ),
          ),
        )),
        if (data!.outgoingInvites.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Pending invites', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ...data!.outgoingInvites.map((invite) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              padding: const EdgeInsets.all(18),
              child: Text('Invite sent to ${invite.inviteeUserId}', style: TextStyle(color: AppColors.textSecondary)),
            ),
          )),
        ],
        if (data!.joinRequests.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Join requests', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ...data!.joinRequests.map((request) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Expanded(child: Text(request.requesterUserId, style: TextStyle(color: AppColors.textPrimary))),
                  TextButton(
                    onPressed: () async {
                      final failure = await bloc.respondToJoinRequest(requestId: request.id, accept: false);
                      if (failure != null && context.mounted) {
                        _showMessage(context, failure.message);
                      }
                    },
                    child: const Text('Reject'),
                  ),
                  FilledButton(
                    onPressed: () async {
                      final failure = await bloc.respondToJoinRequest(requestId: request.id, accept: true);
                      if (failure != null && context.mounted) {
                        _showMessage(context, failure.message);
                      }
                    },
                    child: const Text('Approve'),
                  ),
                ],
              ),
            ),
          )),
        ],
      ],
    );
  }

  Future<void> _openInviteSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _InviteUserSheet(
        profileRepository: profileRepository,
        onInvite: (user) async {
          final failure = await bloc.inviteUser(user);
          if (failure != null && context.mounted) {
            _showMessage(context, failure.message);
            return false;
          }
          return true;
        },
      ),
    );
  }
}

class _InviteUserSheet extends StatefulWidget {
  const _InviteUserSheet({
    required this.profileRepository,
    required this.onInvite,
  });

  final ProfileRepository profileRepository;
  final Future<bool> Function(AppUser user) onInvite;

  @override
  State<_InviteUserSheet> createState() => _InviteUserSheetState();
}

class _InviteUserSheetState extends State<_InviteUserSheet> {
  final _controller = TextEditingController();
  List<AppUser> _results = const <AppUser>[];
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 24, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: GlassCard(
        radius: 28,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Invite User', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              decoration: _inputDecoration('Search username'),
              onChanged: (_) => _search(),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_results.isEmpty)
              Text('Search users by username to send an invite.', style: TextStyle(color: AppColors.textSecondary))
            else
              ..._results.map((user) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.displayName, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
                          Text('@${user.username}', style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: () async {
                        final ok = await widget.onInvite(user);
                        if (ok && context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text('Invite'),
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.length < 2) {
      setState(() => _results = const <AppUser>[]);
      return;
    }
    setState(() => _loading = true);
    final result = await widget.profileRepository.searchUsersByUsername(query);
    result.when(
      success: (value) => _results = value,
      failure: (_) => _results = const <AppUser>[],
    );
    if (mounted) {
      setState(() => _loading = false);
    }
  }
}

class _ExpensesTab extends StatelessWidget {
  const _ExpensesTab({
    required this.bloc,
    required this.data,
    required this.currentUser,
  });

  final GroupDetailBloc bloc;
  final GroupDetailData? data;
  final AppUser currentUser;

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return const SizedBox.shrink();
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        FilledButton.icon(
          onPressed: () => _openExpenseSheet(context),
          icon: const Icon(Icons.add),
          label: const Text('Add expense'),
        ),
        const SizedBox(height: 14),
        ...data!.expenses.map((expense) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(expense.title, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
                    ),
                    Text(_currency(expense.currencyCode, expense.amount), style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Paid by ${expense.paidByUserId} • ${expense.splitMode.label}', style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => _openExpenseSheet(context, expense: expense),
                      child: const Text('Edit'),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () async {
                        final failure = await bloc.deleteExpense(expense.id);
                        if (failure != null && context.mounted) {
                          _showMessage(context, failure.message);
                        }
                      },
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Future<void> _openExpenseSheet(BuildContext context, {GroupExpense? expense}) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ExpenseSheet(
        bloc: bloc,
        data: data!,
        currentUser: currentUser,
        expense: expense,
      ),
    );
  }
}

class _ExpenseSheet extends StatefulWidget {
  const _ExpenseSheet({
    required this.bloc,
    required this.data,
    required this.currentUser,
    this.expense,
  });

  final GroupDetailBloc bloc;
  final GroupDetailData data;
  final AppUser currentUser;
  final GroupExpense? expense;

  @override
  State<_ExpenseSheet> createState() => _ExpenseSheetState();
}

class _ExpenseSheetState extends State<_ExpenseSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late GroupSplitMode _splitMode;
  late String _paidByUserId;
  late DateTime _date;
  late final Map<String, bool> _included;
  late final Map<String, TextEditingController> _splitControllers;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.expense?.title ?? '');
    _amountController = TextEditingController(text: widget.expense?.amount.toStringAsFixed(2) ?? '');
    _splitMode = widget.expense?.splitMode ?? GroupSplitMode.equal;
    _paidByUserId = widget.expense?.paidByUserId ?? widget.currentUser.id;
    _date = widget.expense?.expenseDate ?? DateTime.now();
    _included = {
      for (final member in widget.data.members)
        member.userId: widget.expense?.participants.any((item) => item.userId == member.userId) ?? true,
    };
    _splitControllers = {
      for (final member in widget.data.members)
        member.userId: TextEditingController(
          text: widget.expense?.participants
                  .where((item) => item.userId == member.userId)
                  .firstOrNull
                  ?.shareValue
                  .toString() ??
              '',
        ),
    };
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    for (final controller in _splitControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 24, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: GlassCard(
        radius: 28,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.expense == null ? 'Add Expense' : 'Edit Expense', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              TextField(controller: _titleController, decoration: _inputDecoration('Title')),
              const SizedBox(height: 12),
              TextField(controller: _amountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: _inputDecoration('Amount')),
              const SizedBox(height: 12),
              Text('Paid by', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: widget.data.members.map((member) {
                  return ChoiceChip(
                    label: Text(member.userId == widget.currentUser.id ? '${widget.currentUser.displayName} (You)' : member.userId),
                    selected: _paidByUserId == member.userId,
                    onSelected: (_) => setState(() => _paidByUserId = member.userId),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Text('Split mode', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: GroupSplitMode.values.map((mode) {
                  return ChoiceChip(
                    label: Text(mode.label),
                    selected: _splitMode == mode,
                    onSelected: (_) => setState(() => _splitMode = mode),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Text('Participants', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              ...widget.data.members.map((member) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: CheckboxListTile(
                          value: _included[member.userId] ?? false,
                          onChanged: (value) => setState(() => _included[member.userId] = value ?? false),
                          title: Text(member.userId == widget.currentUser.id ? '${widget.currentUser.displayName} (You)' : member.userId),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      if (_splitMode != GroupSplitMode.equal)
                        SizedBox(
                          width: 100,
                          child: TextField(
                            controller: _splitControllers[member.userId],
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: _inputDecoration(
                              _splitMode == GroupSplitMode.percentage ? '%' : '0',
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  child: Text(widget.expense == null ? 'Save expense' : 'Update expense'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final participants = widget.data.members.where((member) => _included[member.userId] ?? false).toList();
    final breakdown = _buildParticipants(amount, participants.map((item) => item.userId).toList());
    if (breakdown == null) {
      _showMessage(context, 'Split values are invalid.');
      return;
    }
    final now = DateTime.now();
    final expense = GroupExpense(
      id: widget.expense?.id ?? 'expense-${now.microsecondsSinceEpoch}',
      groupId: widget.data.group.id,
      createdByUserId: widget.expense?.createdByUserId ?? widget.currentUser.id,
      title: _titleController.text.trim(),
      description: null,
      notes: null,
      amountMinor: _toMinor(amount),
      currencyCode: 'USD',
      splitMode: _splitMode,
      paidByUserId: _paidByUserId,
      includePayerInSplit: true,
      category: null,
      expenseDate: _date,
      createdAt: widget.expense?.createdAt ?? now,
      updatedAt: widget.expense == null ? now : DateTime.now(),
      participants: breakdown,
    );
    final failure = await widget.bloc.saveExpense(expense);
    if (failure != null && mounted) {
      _showMessage(context, failure.message);
      return;
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  List<ExpenseParticipant>? _buildParticipants(double amount, List<String> userIds) {
    if (amount <= 0 || userIds.isEmpty) {
      return null;
    }
    switch (_splitMode) {
      case GroupSplitMode.equal:
        final cents = (amount * 100).round();
        final base = cents ~/ userIds.length;
        final remainder = cents % userIds.length;
        return List.generate(userIds.length, (index) {
          final owed = (base + (index < remainder ? 1 : 0)) / 100;
          return ExpenseParticipant(
            id: 'participant-${DateTime.now().microsecondsSinceEpoch}-$index',
            expenseId: widget.expense?.id ?? 'draft',
            userId: userIds[index],
            shareValue: owed,
            shareType: 'amount',
            amountOwedMinor: _toMinor(owed),
          );
        });
      case GroupSplitMode.exact:
      case GroupSplitMode.adjustment:
        final parts = <ExpenseParticipant>[];
        var total = 0.0;
        for (final userId in userIds) {
          final value = double.tryParse(_splitControllers[userId]!.text.trim()) ?? -1;
          if (value < 0) {
            return null;
          }
          total += value;
          parts.add(ExpenseParticipant(
            id: 'participant-$userId',
            expenseId: widget.expense?.id ?? 'draft',
            userId: userId,
            shareValue: value,
            shareType: 'amount',
            amountOwedMinor: _toMinor(value),
          ));
        }
        return (total - amount).abs() <= 0.009 ? parts : null;
      case GroupSplitMode.percentage:
        final percentages = <double>[];
        var total = 0.0;
        for (final userId in userIds) {
          final value = double.tryParse(_splitControllers[userId]!.text.trim()) ?? -1;
          if (value < 0) {
            return null;
          }
          percentages.add(value);
          total += value;
        }
        if ((total - 100).abs() > 0.009) {
          return null;
        }
        return List.generate(userIds.length, (index) {
          final owed = double.parse((amount * (percentages[index] / 100)).toStringAsFixed(2));
          return ExpenseParticipant(
            id: 'participant-${userIds[index]}',
            expenseId: widget.expense?.id ?? 'draft',
            userId: userIds[index],
            shareValue: percentages[index],
            shareType: 'percentage',
            amountOwedMinor: _toMinor(owed),
          );
        });
      case GroupSplitMode.shares:
        final shares = <double>[];
        var total = 0.0;
        for (final userId in userIds) {
          final value = double.tryParse(_splitControllers[userId]!.text.trim()) ?? -1;
          if (value < 0) {
            return null;
          }
          shares.add(value);
          total += value;
        }
        if (total <= 0) {
          return null;
        }
        return List.generate(userIds.length, (index) {
          final owed = double.parse((amount * (shares[index] / total)).toStringAsFixed(2));
          return ExpenseParticipant(
            id: 'participant-${userIds[index]}',
            expenseId: widget.expense?.id ?? 'draft',
            userId: userIds[index],
            shareValue: shares[index],
            shareType: 'shares',
            amountOwedMinor: _toMinor(owed),
          );
        });
    }
  }
}

class _BalancesTab extends StatelessWidget {
  const _BalancesTab({
    required this.data,
    required this.currentUser,
  });

  final GroupDetailData? data;
  final AppUser currentUser;

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return const SizedBox.shrink();
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text('Who owes whom', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        if (data!.transfers.isEmpty)
          GlassCard(
            child: Text('Everything is settled up.', style: TextStyle(color: AppColors.textSecondary)),
          )
        else
          ...data!.transfers.map((transfer) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              padding: const EdgeInsets.all(18),
              child: Text(
                '${transfer.fromUserId} owes ${transfer.toUserId} ${_currency('USD', transfer.amount)}',
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
              ),
            ),
          )),
        const SizedBox(height: 16),
        Text('Member balances', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        ...data!.balances.map((balance) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    balance.userId == currentUser.id ? '${currentUser.displayName} (You)' : balance.userId,
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  _currency('USD', balance.netAmount.abs()),
                  style: TextStyle(
                    color: balance.netAmount >= 0 ? AppColors.emerald : AppColors.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }
}

class _ActivityTab extends StatelessWidget {
  const _ActivityTab({
    required this.data,
    required this.currentUser,
  });

  final GroupDetailData? data;
  final AppUser currentUser;

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return const SizedBox.shrink();
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: data!.activity.isEmpty
          ? [
              GlassCard(
                child: Text('No activity yet.', style: TextStyle(color: AppColors.textSecondary)),
              ),
            ]
          : data!.activity.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.message, style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(item.createdAt.toIso8601String(), style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
              );
            }).toList(),
    );
  }
}

class _SettlementsTab extends StatelessWidget {
  const _SettlementsTab({
    required this.bloc,
    required this.data,
    required this.currentUser,
  });

  final GroupDetailBloc bloc;
  final GroupDetailData? data;
  final AppUser currentUser;

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return const SizedBox.shrink();
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        FilledButton.icon(
          onPressed: () => _openSettlementSheet(context),
          icon: const Icon(Icons.handshake_outlined),
          label: const Text('Add settlement'),
        ),
        const SizedBox(height: 14),
        ...data!.settlements.map((settlement) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${settlement.fromUserId} paid ${settlement.toUserId}',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(_currency(settlement.currencyCode, settlement.amount), style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => _openSettlementSheet(context, settlement: settlement),
                      child: const Text('Edit'),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () async {
                        final failure = await bloc.deleteSettlement(settlement.id);
                        if (failure != null && context.mounted) {
                          _showMessage(context, failure.message);
                        }
                      },
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Future<void> _openSettlementSheet(BuildContext context, {Settlement? settlement}) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SettlementSheet(
        bloc: bloc,
        data: data!,
        currentUser: currentUser,
        settlement: settlement,
      ),
    );
  }
}

class _SettlementSheet extends StatefulWidget {
  const _SettlementSheet({
    required this.bloc,
    required this.data,
    required this.currentUser,
    this.settlement,
  });

  final GroupDetailBloc bloc;
  final GroupDetailData data;
  final AppUser currentUser;
  final Settlement? settlement;

  @override
  State<_SettlementSheet> createState() => _SettlementSheetState();
}

class _SettlementSheetState extends State<_SettlementSheet> {
  late final TextEditingController _amountController;
  late String _fromUserId;
  late String _toUserId;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.settlement?.amount.toStringAsFixed(2) ?? '');
    _fromUserId = widget.settlement?.fromUserId ?? widget.currentUser.id;
    _toUserId = widget.settlement?.toUserId ??
        widget.data.members.where((member) => member.userId != _fromUserId).first.userId;
    _date = widget.settlement?.settlementDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 24, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: GlassCard(
        radius: 28,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.settlement == null ? 'Add Settlement' : 'Edit Settlement', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            TextField(controller: _amountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: _inputDecoration('Amount')),
            const SizedBox(height: 12),
            Text('From', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: widget.data.members.map((member) => ChoiceChip(
                label: Text(member.userId),
                selected: _fromUserId == member.userId,
                onSelected: (_) => setState(() => _fromUserId = member.userId),
              )).toList(),
            ),
            const SizedBox(height: 12),
            Text('To', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: widget.data.members.map((member) => ChoiceChip(
                label: Text(member.userId),
                selected: _toUserId == member.userId,
                onSelected: (_) => setState(() => _toUserId = member.userId),
              )).toList(),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: Text(widget.settlement == null ? 'Save settlement' : 'Update settlement'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final now = DateTime.now();
    final settlement = Settlement(
      id: widget.settlement?.id ?? 'settlement-${now.microsecondsSinceEpoch}',
      groupId: widget.data.group.id,
      fromUserId: _fromUserId,
      toUserId: _toUserId,
      amountMinor: _toMinor(double.tryParse(_amountController.text.trim()) ?? 0),
      currencyCode: 'USD',
      note: null,
      settlementDate: _date,
      createdByUserId: widget.settlement?.createdByUserId ?? widget.currentUser.id,
      createdAt: widget.settlement?.createdAt ?? now,
      updatedAt: widget.settlement == null ? now : DateTime.now(),
    );
    final failure = await widget.bloc.saveSettlement(settlement);
    if (failure != null && mounted) {
      _showMessage(context, failure.message);
      return;
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

String _currency(String code, double value) {
  final symbol = switch (code) {
    'PKR' => 'Rs',
    'EUR' => '€',
    'GBP' => '£',
    _ => r'$',
  };
  return '$symbol${value.toStringAsFixed(2)}';
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

int _toMinor(double value) => (value * 100).round();

InputDecoration _inputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: AppColors.surfaceAlt,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: AppColors.emerald),
    ),
  );
}
