import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../features/expenses/presentation/bloc/expense_bloc.dart';
import '../../domain/models/group_models.dart';
import '../bloc/group_bloc.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({
    super.key,
    required this.groupBloc,
    required this.expenseBloc,
  });

  final GroupBloc groupBloc;
  final ExpenseBloc expenseBloc;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: groupBloc,
      builder: (context, _) {
        final groups = groupBloc.groups;
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
                CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 140),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _GroupsHeader(
                            activeGroupCount: groups.length,
                            onCreateGroup: () => _openGroupForm(context),
                          ),
                          const SizedBox(height: 18),
                          _HeroSummary(groupBloc: groupBloc),
                          const SizedBox(height: 24),
                          if (groups.isEmpty)
                            _EmptyGroupsState(
                              onCreateGroup: () => _openGroupForm(context),
                            )
                          else
                            ...groups.map((group) {
                              final summary = groupBloc.groupSummary(group.id);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _GroupCard(
                                  summary: summary,
                                  groupBloc: groupBloc,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => GroupDetailScreen(
                                        groupId: group.id,
                                        groupBloc: groupBloc,
                                        expenseBloc: expenseBloc,
                                      ),
                                    ),
                                  ),
                                  onEdit: () => _openGroupForm(
                                    context,
                                    group: group,
                                  ),
                                ),
                              );
                            }),
                        ]),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  right: 20,
                  bottom: 92,
                  child: _GroupsQuickActions(
                    hasGroups: groups.isNotEmpty,
                    onAddExpense: groups.isNotEmpty
                        ? () => _openExpenseEditor(context, preselectedGroupId: groups.first.id)
                        : () => _openGroupForm(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openGroupForm(
    BuildContext context, {
    ExpenseGroup? group,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _GroupFormSheet(
          groupBloc: groupBloc,
          group: group,
        );
      },
    );
  }

  Future<void> _openExpenseEditor(
    BuildContext context, {
    required String preselectedGroupId,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SharedExpenseEditorScreen(
          groupBloc: groupBloc,
          expenseBloc: expenseBloc,
          preselectedGroupId: preselectedGroupId,
        ),
      ),
    );
  }
}

class GroupDetailScreen extends StatefulWidget {
  const GroupDetailScreen({
    super.key,
    required this.groupId,
    required this.groupBloc,
    required this.expenseBloc,
  });

  final String groupId;
  final GroupBloc groupBloc;
  final ExpenseBloc expenseBloc;

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.groupBloc,
      builder: (context, _) {
        final group = widget.groupBloc.groupById(widget.groupId);
        if (group == null) {
          return Scaffold(
            body: Center(
              child: Text(
                'Group not found',
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ),
          );
        }

        final computation = widget.groupBloc.computeGroup(group.id);
        final members = widget.groupBloc.membersForGroup(group.id);
        final activities = widget.groupBloc.groupActivity(group.id);

        return Scaffold(
          body: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.background, AppColors.screenGradientEnd],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                group.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${members.length} members',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_horiz, color: AppColors.textPrimary),
                          onSelected: (value) async {
                            switch (value) {
                              case 'edit':
                                await showModalBottomSheet<void>(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => _GroupFormSheet(
                                    groupBloc: widget.groupBloc,
                                    group: group,
                                  ),
                                );
                                return;
                              case 'archive':
                                await widget.groupBloc.archiveGroup(group.id);
                                if (!context.mounted) {
                                  return;
                                }
                                if (mounted) {
                                  Navigator.of(context).pop();
                                }
                                return;
                              case 'delete':
                                try {
                                  await widget.groupBloc.deleteGroup(group.id);
                                  if (!context.mounted) {
                                    return;
                                  }
                                  if (mounted) {
                                    Navigator.of(context).pop();
                                  }
                                } catch (error) {
                                  if (!context.mounted) {
                                    return;
                                  }
                                  _showMessage(context, error.toString());
                                }
                                return;
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit group')),
                            PopupMenuItem(value: 'archive', child: Text('Archive group')),
                            PopupMenuItem(value: 'delete', child: Text('Delete empty group')),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                    child: Column(
                      children: [
                        _GroupSummaryHero(
                          groupBloc: widget.groupBloc,
                          computation: computation,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => SharedExpenseEditorScreen(
                                      groupBloc: widget.groupBloc,
                                      expenseBloc: widget.expenseBloc,
                                      preselectedGroupId: group.id,
                                    ),
                                  ),
                                ),
                                icon: const Icon(Icons.receipt_long_rounded),
                                label: const Text('Add expense'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: computation.transfers.isEmpty
                                    ? null
                                    : () => _openSettlementSheet(
                                          context,
                                          group.id,
                                          initialTransfer: computation.transfers.first,
                                        ),
                                icon: const Icon(Icons.handshake_outlined),
                                label: const Text('Settle up'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.overlay,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      labelColor: AppColors.textPrimary,
                      unselectedLabelColor: AppColors.textSecondary,
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'Balances'),
                        Tab(text: 'Activity'),
                        Tab(text: 'Totals'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _BalancesTab(
                          groupBloc: widget.groupBloc,
                          groupId: group.id,
                          computation: computation,
                          onSettle: computation.transfers.isEmpty
                              ? null
                              : () => _openSettlementSheet(
                                    context,
                                    group.id,
                                    initialTransfer: computation.transfers.first,
                                  ),
                        ),
                        _ActivityTab(
                          groupBloc: widget.groupBloc,
                          groupId: group.id,
                          activities: activities,
                          expenseBloc: widget.expenseBloc,
                        ),
                        _TotalsTab(
                          groupBloc: widget.groupBloc,
                          groupId: group.id,
                          computation: computation,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openSettlementSheet(
    BuildContext context,
    String groupId, {
    GroupTransfer? initialTransfer,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SettlementSheet(
        groupBloc: widget.groupBloc,
        groupId: groupId,
        initialTransfer: initialTransfer,
      ),
    );
  }
}

class SharedExpenseEditorScreen extends StatefulWidget {
  const SharedExpenseEditorScreen({
    super.key,
    required this.groupBloc,
    required this.expenseBloc,
    required this.preselectedGroupId,
    this.expense,
  });

  final GroupBloc groupBloc;
  final ExpenseBloc expenseBloc;
  final String preselectedGroupId;
  final SharedExpense? expense;

  @override
  State<SharedExpenseEditorScreen> createState() => _SharedExpenseEditorScreenState();
}

class _SharedExpenseEditorScreenState extends State<SharedExpenseEditorScreen> {
  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;
  late String _groupId;
  late String _payerId;
  late DateTime _date;
  late GroupSplitMode _splitMode;
  late final Map<GroupSplitMode, Map<String, TextEditingController>> _splitControllers;
  late List<String> _participantIds;
  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    final initialGroupId = expense?.groupId ?? widget.preselectedGroupId;
    final members = widget.groupBloc.membersForGroup(initialGroupId);
    _groupId = initialGroupId;
    _payerId = expense?.paidByProfileId ??
        (members.isNotEmpty ? members.first.id : GroupBloc.selfProfileId);
    _date = expense?.date ?? DateTime.now();
    _splitMode = expense?.splitMode ?? GroupSplitMode.equal;
    _participantIds = expense?.participantIds.toList() ??
        members.map((member) => member.id).toList();
    _descriptionController = TextEditingController(text: expense?.description ?? '');
    _amountController = TextEditingController(
      text: expense == null ? '' : expense.amount.toStringAsFixed(2),
    );
    _splitControllers = {
      for (final mode in GroupSplitMode.values) mode: <String, TextEditingController>{},
    };
    if (expense != null) {
      for (final entry in expense.splitInput.entries) {
        _splitControllers[expense.splitMode]![entry.key] = TextEditingController(
          text: _formatInput(entry.value),
        );
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    for (final controllerMap in _splitControllers.values) {
      for (final controller in controllerMap.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.groupBloc.groupById(_groupId);
    final members = widget.groupBloc.membersForGroup(_groupId);
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final splitInput = _currentSplitInput();

    ExpenseSplitPreview? preview;
    String? error;
    if (group != null && _participantIds.isNotEmpty && amount > 0) {
      try {
        preview = widget.groupBloc.previewSplit(
          totalAmount: amount,
          participantIds: _participantIds,
          splitMode: _splitMode,
          splitInput: splitInput,
          payerId: _payerId,
        );
      } catch (exception) {
        error = exception.toString();
      }
    }

    final canSave = group != null &&
        _descriptionController.text.trim().isNotEmpty &&
        amount > 0 &&
        _participantIds.isNotEmpty &&
        preview != null &&
        error == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.expense == null ? 'Shared Expense' : 'Edit Shared Expense'),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.background, AppColors.screenGradientEnd],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel('Group'),
                    const SizedBox(height: 10),
                    _GroupSelector(
                      groups: widget.groupBloc.groups,
                      selectedGroupId: _groupId,
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        final nextMembers = widget.groupBloc.membersForGroup(value);
                        setState(() {
                          _groupId = value;
                          _payerId = nextMembers.first.id;
                          _participantIds = nextMembers.map((member) => member.id).toList();
                          _validationMessage = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _FieldLabel('Description'),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _descriptionController,
                      onChanged: (_) => setState(() => _validationMessage = null),
                      decoration: _inputDecoration('Dinner, taxi, groceries...'),
                    ),
                    const SizedBox(height: 16),
                    _FieldLabel('Amount'),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() => _validationMessage = null),
                      decoration: _inputDecoration('0.00'),
                    ),
                    const SizedBox(height: 16),
                    _FieldLabel('Date'),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(18),
                      child: Ink(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: _inputBoxDecoration(),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.emerald),
                            const SizedBox(width: 12),
                            Text(
                              _friendlyDate(_date),
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _FieldLabel('Paid by'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: members.map((member) {
                        final selected = member.id == _payerId;
                        return ChoiceChip(
                          label: Text(member.displayName),
                          selected: selected,
                          onSelected: (_) => setState(() => _payerId = member.id),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        _FieldLabel('Participants'),
                        const Spacer(),
                        Text(
                          widget.groupBloc.participantSummary(_groupId, _participantIds),
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: members.map((member) {
                        final selected = _participantIds.contains(member.id);
                        return FilterChip(
                          label: Text(member.displayName),
                          selected: selected,
                          onSelected: (value) {
                            setState(() {
                              if (value) {
                                _participantIds = [..._participantIds, member.id];
                              } else {
                                _participantIds = _participantIds.where((id) => id != member.id).toList();
                              }
                              _validationMessage = null;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel('Split mode'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: GroupSplitMode.values.map((mode) {
                        return ChoiceChip(
                          label: Text(mode.label),
                          selected: _splitMode == mode,
                          onSelected: (_) => setState(() {
                            _splitMode = mode;
                            _validationMessage = null;
                          }),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    if (_splitMode != GroupSplitMode.equal)
                      ..._participantIds.map((participantId) {
                        final member = widget.groupBloc.profileById(participantId);
                        final controller = _controllerFor(_splitMode, participantId);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  member?.displayName ?? 'Member',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 110,
                                child: TextField(
                                  controller: controller,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  onChanged: (_) => setState(() => _validationMessage = null),
                                  textAlign: TextAlign.right,
                                  decoration: _inputDecoration(
                                    _splitMode == GroupSplitMode.percentage ? '0%' : '0.00',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      })
                    else
                      Text(
                        'Equal split will divide the total safely and assign any rounding remainder deterministically.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    const SizedBox(height: 16),
                    _SplitPreviewCard(
                      groupBloc: widget.groupBloc,
                      participantIds: _participantIds,
                      preview: preview,
                      error: error,
                    ),
                  ],
                ),
              ),
              if ((_validationMessage ?? error) != null) ...[
                const SizedBox(height: 14),
                Text(
                  _validationMessage ?? error!,
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: canSave
                          ? () => _save(preview!)
                          : null,
                      child: Text(widget.expense == null ? 'Save expense' : 'Update expense'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, double> _currentSplitInput() {
    final result = <String, double>{};
    if (_splitMode == GroupSplitMode.equal) {
      return result;
    }
    final controllers = _splitControllers[_splitMode]!;
    for (final participantId in _participantIds) {
      final raw = controllers[participantId]?.text.trim() ?? '';
      if (raw.isEmpty) {
        continue;
      }
      result[participantId] = double.tryParse(raw.replaceAll('%', '')) ?? 0;
    }
    return result;
  }

  TextEditingController _controllerFor(GroupSplitMode mode, String participantId) {
    final controllerMap = _splitControllers[mode]!;
    return controllerMap.putIfAbsent(participantId, () {
      final existing = widget.expense;
      final initialValue = existing != null && existing.splitMode == mode
          ? existing.splitInput[participantId]
          : null;
      return TextEditingController(
        text: initialValue == null ? '' : _formatInput(initialValue),
      );
    });
  }

  Future<void> _pickDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (result != null) {
      setState(() => _date = result);
    }
  }

  Future<void> _save(ExpenseSplitPreview preview) async {
    try {
      final now = DateTime.now();
      final expense = SharedExpense(
        id: widget.expense?.id ?? 'shared-expense-${now.microsecondsSinceEpoch}',
        groupId: _groupId,
        description: _descriptionController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        currencyCode: widget.groupBloc.currencyCode,
        paidByProfileId: _payerId,
        participantIds: _participantIds,
        splitMode: _splitMode,
        splitInput: _currentSplitInput(),
        splitAmounts: preview.splitAmounts,
        date: _date,
        createdAt: widget.expense?.createdAt ?? now,
        updatedAt: now,
      );
      if (widget.expense == null) {
        await widget.groupBloc.addExpense(expense);
      } else {
        await widget.groupBloc.updateExpense(expense);
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      setState(() => _validationMessage = error.toString());
    }
  }
}

class _GroupFormSheet extends StatefulWidget {
  const _GroupFormSheet({
    required this.groupBloc,
    this.group,
  });

  final GroupBloc groupBloc;
  final ExpenseGroup? group;

  @override
  State<_GroupFormSheet> createState() => _GroupFormSheetState();
}

class _GroupFormSheetState extends State<_GroupFormSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _membersController;
  String? _error;

  @override
  void initState() {
    super.initState();
    final group = widget.group;
    _nameController = TextEditingController(text: group?.name ?? '');
    _membersController = TextEditingController(
      text: group == null
          ? ''
          : widget.groupBloc
              .membersForGroup(group.id)
              .where((member) => !member.isSelf)
              .map((member) => member.displayName)
              .join('\n'),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _membersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 24, 16, inset + 20),
      child: GlassCard(
        radius: 28,
        gradient: LinearGradient(
          colors: [AppColors.surfaceAlt, AppColors.surface],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.group == null ? 'Create Group' : 'Edit Group',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            const _FieldLabel('Group name'),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              decoration: _inputDecoration('Trip to Hunza'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const _FieldLabel('Members'),
                const SizedBox(width: 8),
                Text(
                  'You is included automatically',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _membersController,
              minLines: 4,
              maxLines: 6,
              decoration: _inputDecoration('One member per line'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: Text(widget.group == null ? 'Save group' : 'Update group'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final members = _membersController.text
        .split(RegExp(r'[\n,]'))
        .map((value) => value.trim())
        .toList();
    try {
      if (widget.group == null) {
        await widget.groupBloc.createGroup(
          name: _nameController.text,
          memberNames: members,
        );
      } else {
        await widget.groupBloc.updateGroup(
          groupId: widget.group!.id,
          name: _nameController.text,
          memberNames: members,
        );
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      setState(() => _error = error.toString());
    }
  }
}

class _SettlementSheet extends StatefulWidget {
  const _SettlementSheet({
    required this.groupBloc,
    required this.groupId,
    this.initialTransfer,
    this.record,
  });

  final GroupBloc groupBloc;
  final String groupId;
  final GroupTransfer? initialTransfer;
  final SettlementRecord? record;

  @override
  State<_SettlementSheet> createState() => _SettlementSheetState();
}

class _SettlementSheetState extends State<_SettlementSheet> {
  late final TextEditingController _amountController;
  late DateTime _date;
  late String _fromId;
  late String _toId;
  String? _error;

  @override
  void initState() {
    super.initState();
    final transfer = widget.record == null ? widget.initialTransfer : null;
    _date = widget.record?.date ?? DateTime.now();
    _fromId = widget.record?.fromProfileId ??
        transfer?.fromProfileId ??
        GroupBloc.selfProfileId;
    _toId = widget.record?.toProfileId ?? transfer?.toProfileId ?? '';
    _amountController = TextEditingController(
      text: widget.record != null
          ? widget.record!.amount.toStringAsFixed(2)
          : transfer?.amount.toStringAsFixed(2) ?? '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final members = widget.groupBloc.membersForGroup(widget.groupId);
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 24, 16, inset + 20),
      child: GlassCard(
        radius: 28,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.record == null ? 'Settle Up' : 'Edit Settlement',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            const _FieldLabel('From'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: members.map((member) {
                return ChoiceChip(
                  label: Text(member.displayName),
                  selected: _fromId == member.id,
                  onSelected: (_) => setState(() => _fromId = member.id),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const _FieldLabel('To'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: members.map((member) {
                return ChoiceChip(
                  label: Text(member.displayName),
                  selected: _toId == member.id,
                  onSelected: (_) => setState(() => _toId = member.id),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const _FieldLabel('Amount'),
            const SizedBox(height: 10),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _inputDecoration('0.00'),
            ),
            const SizedBox(height: 16),
            const _FieldLabel('Settlement date'),
            const SizedBox(height: 10),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(18),
              child: Ink(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: _inputBoxDecoration(),
                child: Row(
                  children: [
                    Icon(Icons.event_available_outlined, color: AppColors.emerald),
                    const SizedBox(width: 12),
                    Text(
                      _friendlyDate(_date),
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: Text(widget.record == null ? 'Save settlement' : 'Update settlement'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (result != null) {
      setState(() => _date = result);
    }
  }

  Future<void> _save() async {
    try {
      final now = DateTime.now();
      final record = SettlementRecord(
        id: widget.record?.id ?? 'settlement-${now.microsecondsSinceEpoch}',
        groupId: widget.groupId,
        fromProfileId: _fromId,
        toProfileId: _toId,
        amount: double.tryParse(_amountController.text.trim()) ?? 0,
        currencyCode: widget.groupBloc.currencyCode,
        date: _date,
        createdAt: widget.record?.createdAt ?? now,
        updatedAt: now,
      );
      if (widget.record == null) {
        await widget.groupBloc.addSettlement(record);
      } else {
        await widget.groupBloc.updateSettlement(record);
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      setState(() => _error = error.toString());
    }
  }
}

class _BalancesTab extends StatelessWidget {
  const _BalancesTab({
    required this.groupBloc,
    required this.groupId,
    required this.computation,
    this.onSettle,
  });

  final GroupBloc groupBloc;
  final String groupId;
  final GroupComputation computation;
  final VoidCallback? onSettle;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
      children: [
        Text(
          'Who owes whom',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        if (computation.transfers.isEmpty)
          GlassCard(
            child: Column(
              children: [
                Icon(Icons.task_alt_rounded, size: 38, color: AppColors.emerald),
                const SizedBox(height: 10),
                Text(
                  'Everything is settled up',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'New expenses will appear here when someone owes someone else.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          )
        else
          ...computation.transfers.map((transfer) {
            final from = groupBloc.profileById(transfer.fromProfileId)?.displayName ?? 'Member';
            final to = groupBloc.profileById(transfer.toProfileId)?.displayName ?? 'Member';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                          children: [
                            TextSpan(
                              text: from,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const TextSpan(text: ' owes '),
                            TextSpan(
                              text: to,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      groupBloc.formatCurrency(transfer.amount),
                      style: const TextStyle(
                        color: AppColors.emerald,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: 18),
        Row(
          children: [
            Text(
              'Member balances',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            if (onSettle != null)
              TextButton(
                onPressed: onSettle,
                child: const Text('Settle up'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ...computation.balances.map((balance) {
          final member = groupBloc.profileById(balance.profileId);
          final value = balance.netAmount;
          final label = value > 0.009
              ? 'gets back'
              : value < -0.009
              ? 'owes'
              : 'settled up';
          final color = value > 0.009
              ? AppColors.emerald
              : value < -0.009
              ? AppColors.danger
              : AppColors.textSecondary;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  _MemberAvatar(profile: member),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member?.displayName ?? 'Member',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          label,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    value.abs() < 0.009 ? 'Settled' : groupBloc.formatCurrency(value.abs()),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _ActivityTab extends StatelessWidget {
  const _ActivityTab({
    required this.groupBloc,
    required this.groupId,
    required this.activities,
    required this.expenseBloc,
  });

  final GroupBloc groupBloc;
  final String groupId;
  final List<GroupActivityItem> activities;
  final ExpenseBloc expenseBloc;

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        children: [
          GlassCard(
            child: Column(
              children: [
                Icon(Icons.history_toggle_off_rounded, size: 40, color: AppColors.emerald),
                SizedBox(height: 10),
                Text(
                  'No activity yet',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Add a shared expense or settlement to start the feed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final grouped = <String, List<GroupActivityItem>>{};
    for (final item in activities) {
      final key = _dateHeading(item.timestamp);
      grouped.putIfAbsent(key, () => <GroupActivityItem>[]).add(item);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.key,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            ...entry.value.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () => _openActivitySheet(context, item),
                  borderRadius: BorderRadius.circular(24),
                  child: GlassCard(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: item.expense != null
                                ? AppColors.emerald.withValues(alpha: 0.12)
                                : AppColors.cyan.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            item.expense != null
                                ? Icons.receipt_long_rounded
                                : Icons.handshake_outlined,
                            color: item.expense != null ? AppColors.emerald : AppColors.cyan,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _activityTitle(item),
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _activitySubtitle(groupBloc, item),
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          groupBloc.formatCurrency(_activityAmount(item)),
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }

  Future<void> _openActivitySheet(BuildContext context, GroupActivityItem item) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ActivityDetailSheet(
        groupBloc: groupBloc,
        groupId: groupId,
        item: item,
        expenseBloc: expenseBloc,
      ),
    );
  }
}

class _TotalsTab extends StatelessWidget {
  const _TotalsTab({
    required this.groupBloc,
    required this.groupId,
    required this.computation,
  });

  final GroupBloc groupBloc;
  final String groupId;
  final GroupComputation computation;

  @override
  Widget build(BuildContext context) {
    final expenses = groupBloc.expensesForGroup(groupId);
    final byMember = <String, double>{};
    for (final expense in expenses) {
      byMember.update(
        expense.paidByProfileId,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    final rankedMembers = byMember.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Total spend',
                value: groupBloc.formatCurrency(computation.totalExpenseAmount),
                accent: AppColors.emerald,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: 'Settlements',
                value: groupBloc.formatCurrency(computation.totalSettlementAmount),
                accent: AppColors.cyan,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _MetricCard(
          label: 'Expense count',
          value: '${expenses.length}',
          accent: AppColors.pink,
        ),
        const SizedBox(height: 18),
        Text(
          'Top contributors',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        if (rankedMembers.isEmpty)
          GlassCard(
            child: Text(
              'No totals yet. Add your first shared expense to see contributions.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          ...rankedMembers.map((entry) {
            final member = groupBloc.profileById(entry.key);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    _MemberAvatar(profile: member),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        member?.displayName ?? 'Member',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      groupBloc.formatCurrency(entry.value),
                      style: const TextStyle(
                        color: AppColors.emerald,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _ActivityDetailSheet extends StatelessWidget {
  const _ActivityDetailSheet({
    required this.groupBloc,
    required this.groupId,
    required this.item,
    required this.expenseBloc,
  });

  final GroupBloc groupBloc;
  final String groupId;
  final GroupActivityItem item;
  final ExpenseBloc expenseBloc;

  @override
  Widget build(BuildContext context) {
    final settlement = item.settlement;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        24,
        16,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: GlassCard(
        radius: 28,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.expense != null ? 'Expense details' : 'Settlement details',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            if (item.expense case final expense?) ...[
              _DetailRow(label: 'Description', value: expense.description),
              _DetailRow(
                label: 'Paid by',
                value: groupBloc.profileById(expense.paidByProfileId)?.displayName ?? 'Member',
              ),
              _DetailRow(label: 'Date', value: _friendlyDate(expense.date)),
              _DetailRow(
                label: 'Split mode',
                value: expense.splitMode.label,
              ),
              _DetailRow(
                label: 'Participants',
                value: groupBloc.participantSummary(groupId, expense.participantIds),
              ),
              const SizedBox(height: 10),
              Text(
                'Per-person split',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ...expense.splitAmounts.entries.map((entry) {
                final member = groupBloc.profileById(entry.key);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          member?.displayName ?? 'Member',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                      Text(
                        groupBloc.formatCurrency(entry.value),
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => SharedExpenseEditorScreen(
                              groupBloc: groupBloc,
                              expenseBloc: expenseBloc,
                              preselectedGroupId: groupId,
                              expense: expense,
                            ),
                          ),
                        );
                      },
                      child: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        await groupBloc.deleteExpense(expense.id);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              _DetailRow(
                label: 'From',
                value: groupBloc.profileById(settlement!.fromProfileId)?.displayName ?? 'Member',
              ),
              _DetailRow(
                label: 'To',
                value: groupBloc.profileById(settlement.toProfileId)?.displayName ?? 'Member',
              ),
              _DetailRow(label: 'Date', value: _friendlyDate(settlement.date)),
              _DetailRow(
                label: 'Amount',
                value: groupBloc.formatCurrency(settlement.amount),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await showModalBottomSheet<void>(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          builder: (_) => _SettlementSheet(
                            groupBloc: groupBloc,
                            groupId: groupId,
                            record: settlement,
                          ),
                        );
                      },
                      child: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        await groupBloc.deleteSettlement(settlement.id);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeroSummary extends StatelessWidget {
  const _HeroSummary({required this.groupBloc});

  final GroupBloc groupBloc;

  @override
  Widget build(BuildContext context) {
    final groups = groupBloc.groups;
    final totalSpend = groups.fold<double>(
      0,
      (sum, group) => sum + groupBloc.computeGroup(group.id).totalExpenseAmount,
    );
    final totalOutstanding = groups.fold<double>(
      0,
      (sum, group) => sum + groupBloc.computeGroup(group.id).transfers.fold<double>(
            0,
            (transferSum, transfer) => transferSum + transfer.amount,
          ),
    );
    return Row(
      children: [
        Expanded(
          flex: 6,
          child: GlassCard(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0BD875), Color(0xFF06965A)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.groups_2_rounded, color: Colors.white, size: 28),
                const SizedBox(height: 18),
                const Text(
                  'Shared groups',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${groups.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  groups.isEmpty ? 'Create your first group' : 'Local-first sharing',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 5,
          child: Column(
            children: [
              _MetricCard(
                label: 'Total shared',
                value: groupBloc.formatCurrency(totalSpend),
                accent: AppColors.emerald,
                compact: true,
              ),
              const SizedBox(height: 12),
              _MetricCard(
                label: 'Outstanding',
                value: groupBloc.formatCurrency(totalOutstanding),
                accent: AppColors.cyan,
                compact: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GroupSummaryHero extends StatelessWidget {
  const _GroupSummaryHero({
    required this.groupBloc,
    required this.computation,
  });

  final GroupBloc groupBloc;
  final GroupComputation computation;

  @override
  Widget build(BuildContext context) {
    final youBalance = computation.balanceFor(GroupBloc.selfProfileId);
    final balanceText = youBalance > 0.009
        ? 'You should receive ${groupBloc.formatCurrency(youBalance)}'
        : youBalance < -0.009
        ? 'You owe ${groupBloc.formatCurrency(youBalance.abs())}'
        : 'You are settled up';
    return GlassCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: AppColors.isDarkMode
            ? const [Color(0xFF121C18), Color(0xFF0A1110)]
            : const [Color(0xFFFFFFFF), Color(0xFFF2F7F4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Group balance',
            style: TextStyle(
              color: AppColors.textSecondary,
              letterSpacing: 1.4,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            groupBloc.formatCurrency(computation.totalExpenseAmount),
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 30,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            balanceText,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.accent,
    this.compact = false,
  });

  final String label;
  final String value;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.all(compact ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: compact ? 10 : 14),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: compact ? 18 : 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: compact ? 10 : 14),
          Container(
            height: 4,
            width: compact ? 42 : 56,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyGroupsState extends StatelessWidget {
  const _EmptyGroupsState({required this.onCreateGroup});

  final VoidCallback onCreateGroup;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: AppColors.emerald.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.group_add_rounded, size: 34, color: AppColors.emerald),
          ),
          const SizedBox(height: 18),
          Text(
            'Start splitting shared expenses',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Create a local group, add members, and track who owes whom without sign-in or sync.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onCreateGroup,
            icon: const Icon(Icons.add),
            label: const Text('Create group'),
          ),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.summary,
    required this.groupBloc,
    required this.onTap,
    required this.onEdit,
  });

  final GroupListSummary summary;
  final GroupBloc groupBloc;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final yourBalance = summary.yourNetBalance;
    final balanceLabel = yourBalance > 0.009
        ? 'You are owed'
        : yourBalance < -0.009
        ? 'You owe'
        : 'Settled';
    final balanceColor = yourBalance > 0.009
        ? AppColors.emerald
        : yourBalance < -0.009
        ? AppColors.danger
        : AppColors.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    summary.groupName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz, color: AppColors.textSecondary),
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit group')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${summary.memberCount} members',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _SmallStat(
                    label: 'TOTAL',
                    value: groupBloc.formatCurrency(summary.totalSpend),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SmallStat(
                    label: balanceLabel.toUpperCase(),
                    value: groupBloc.formatCurrency(summary.yourNetBalance.abs()),
                    valueColor: balanceColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              summary.latestActivityLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupsHeader extends StatelessWidget {
  const _GroupsHeader({
    required this.activeGroupCount,
    required this.onCreateGroup,
  });

  final int activeGroupCount;
  final VoidCallback onCreateGroup;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Groups',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                activeGroupCount == 0
                    ? 'Split bills locally and keep balances clear.'
                    : 'Track balances, activity, and settlements.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: onCreateGroup,
          icon: const Icon(Icons.group_add_rounded),
          label: const Text('New'),
        ),
      ],
    );
  }
}

class _GroupsQuickActions extends StatelessWidget {
  const _GroupsQuickActions({
    required this.hasGroups,
    required this.onAddExpense,
  });

  final bool hasGroups;
  final VoidCallback onAddExpense;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _QuickActionButton(
          icon: Icons.document_scanner_outlined,
          label: 'Scan',
          enabled: false,
          onTap: null,
        ),
        const SizedBox(height: 10),
        _QuickActionButton(
          icon: hasGroups ? Icons.add_card_rounded : Icons.group_add_rounded,
          label: hasGroups ? 'Add expense' : 'Create group',
          enabled: true,
          onTap: onAddExpense,
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.enabled,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: enabled ? AppColors.surface : AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: enabled
                    ? AppColors.textPrimary
                    : AppColors.textSecondary.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: enabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupSelector extends StatelessWidget {
  const _GroupSelector({
    required this.groups,
    required this.selectedGroupId,
    required this.onChanged,
  });

  final List<ExpenseGroup> groups;
  final String selectedGroupId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _inputBoxDecoration(),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          value: groups.any((group) => group.id == selectedGroupId)
              ? selectedGroupId
              : null,
          dropdownColor: AppColors.surface,
          iconEnabledColor: AppColors.textSecondary,
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          items: groups
              .map(
                (group) => DropdownMenuItem(
                  value: group.id,
                  child: Text(group.name),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _SplitPreviewCard extends StatelessWidget {
  const _SplitPreviewCard({
    required this.groupBloc,
    required this.participantIds,
    required this.preview,
    required this.error,
  });

  final GroupBloc groupBloc;
  final List<String> participantIds;
  final ExpenseSplitPreview? preview;
  final String? error;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          error!,
          style: const TextStyle(
            color: AppColors.danger,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    if (preview == null) {
      return Text(
        'Enter an amount and participants to preview each member share.',
        style: TextStyle(color: AppColors.textSecondary),
      );
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.overlay,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Per-person preview',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...participantIds.map((participantId) {
            final member = groupBloc.profileById(participantId);
            final amount = preview!.splitAmounts[participantId] ?? 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      member?.displayName ?? 'Member',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  Text(
                    groupBloc.formatCurrency(amount),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }),
          const Divider(height: 22),
          Text(
            'Payer reimbursement preview: ${groupBloc.formatCurrency(preview!.payerReimbursement)}',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _SmallStat extends StatelessWidget {
  const _SmallStat({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.profile});

  final LocalProfile? profile;

  @override
  Widget build(BuildContext context) {
    final color = profile?.avatarColor ?? AppColors.emerald;
    final initials = _initials(profile?.displayName ?? 'M');
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: AppColors.textMuted),
    filled: true,
    fillColor: AppColors.surfaceAlt,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: AppColors.border),
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(18)),
      borderSide: BorderSide(color: AppColors.emerald),
    ),
  );
}

BoxDecoration _inputBoxDecoration() {
  return BoxDecoration(
    color: AppColors.surfaceAlt,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: AppColors.border),
  );
}

String _friendlyDate(DateTime date) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

String _dateHeading(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  final difference = today.difference(target).inDays;
  if (difference == 0) {
    return 'TODAY';
  }
  if (difference == 1) {
    return 'YESTERDAY';
  }
  return _friendlyDate(date).toUpperCase();
}

String _activityTitle(GroupActivityItem item) {
  return item.expense?.description ??
      '${item.settlement?.amount.toStringAsFixed(2)} settlement';
}

String _activitySubtitle(GroupBloc bloc, GroupActivityItem item) {
  if (item.expense case final expense?) {
    final payer = bloc.profileById(expense.paidByProfileId)?.displayName ?? 'Member';
    return '$payer paid • ${bloc.participantSummary(expense.groupId, expense.participantIds)}';
  }
  final settlement = item.settlement!;
  final from = bloc.profileById(settlement.fromProfileId)?.displayName ?? 'Member';
  final to = bloc.profileById(settlement.toProfileId)?.displayName ?? 'Member';
  return '$from paid $to';
}

double _activityAmount(GroupActivityItem item) {
  return item.expense?.amount ?? item.settlement!.amount;
}

String _initials(String value) {
  final parts = value.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
  if (parts.isEmpty) {
    return 'M';
  }
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
}

String _formatInput(double value) {
  if (value == value.roundToDouble()) {
    return value.round().toString();
  }
  return value.toStringAsFixed(2);
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
