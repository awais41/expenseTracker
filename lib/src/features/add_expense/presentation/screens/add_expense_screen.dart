import 'package:flutter/material.dart';

import '../../../../core/currency/app_currency.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../expenses/domain/models/expense.dart';
import '../../../expenses/presentation/bloc/expense_bloc.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({
    super.key,
    required this.expenseBloc,
    required this.initialCurrency,
    required this.onCurrencyChanged,
    required this.onSaved,
    required this.onClose,
  });

  final ExpenseBloc expenseBloc;
  final AppCurrency? initialCurrency;
  final Future<void> Function(AppCurrency currency) onCurrencyChanged;
  final ValueChanged<Expense> onSaved;
  final VoidCallback onClose;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  static const paymentMethods = <String>[
    'Cash',
    'Apple Pay',
    'Debit Card',
    'Bank Transfer',
  ];

  final TextEditingController _notesController = TextEditingController();
  double _amount = 0;
  String? _selectedCategory;
  String _paymentMethod = paymentMethods.first;
  DateTime _selectedDate = DateTime.now();
  late AppCurrency? _selectedCurrency;

  @override
  void initState() {
    super.initState();
    _selectedCurrency = widget.initialCurrency;
    if (_selectedCurrency == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showCurrencyPicker(forceSelection: true);
        }
      });
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = _selectedCurrency ?? AppCurrency.values.first;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final showCurrencySetup = widget.initialCurrency == null && _selectedCurrency == null;
    final categories = widget.expenseBloc.availableCategories();
    final selectedCategory = categories.contains(_selectedCategory)
        ? _selectedCategory!
        : categories.first;
    _selectedCategory = selectedCategory;

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
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: keyboardInset),
          child: Stack(
            children: [
              CustomScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      14,
                      24,
                      keyboardInset > 0 ? 150 : 210,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _ExpenseHeader(
                          onClose: widget.onClose,
                          onSave: _saveExpense,
                        ),
                        const SizedBox(height: 22),
                        _AmountSection(
                          amount: _amount,
                          currencySymbol: currency.symbol,
                          onTap: _editAmount,
                        ),
                        if (showCurrencySetup) ...[
                          const SizedBox(height: 18),
                          _FieldCard(
                            label: 'CURRENCY',
                            value: '${currency.code} • ${currency.name}',
                            icon: Icons.attach_money_rounded,
                            onTap: _showCurrencyPicker,
                          ),
                          const SizedBox(height: 30),
                        ] else
                          const SizedBox(height: 24),
                        const _SectionHeader(
                          title: 'CATEGORY',
                          action: 'Tap to choose',
                        ),
                        const SizedBox(height: 14),
                        _CategoryRow(
                          categories: categories,
                          expenseBloc: widget.expenseBloc,
                          selectedCategory: selectedCategory,
                          onSelected: (category) =>
                              setState(() => _selectedCategory = category),
                          onAddCategory: _showAddCategoryDialog,
                        ),
                        const SizedBox(height: 26),
                        Row(
                          children: [
                            Expanded(
                              child: _FieldCard(
                                label: 'DATE',
                                value: _formatDate(_selectedDate),
                                icon: Icons.calendar_today_outlined,
                                onTap: _pickDate,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _FieldCard(
                                label: 'PAYMENT',
                                value: _paymentMethod,
                                icon: Icons.account_balance_wallet_outlined,
                                onTap: _pickPaymentMethod,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        const _SectionLabel('NOTES'),
                        const SizedBox(height: 10),
                        _NotesCard(controller: _notesController),
                        const SizedBox(height: 22),
                        const _SectionLabel('RECEIPT'),
                        const SizedBox(height: 10),
                        const _ReceiptCard(),
                      ]),
                    ),
                  ),
                ],
              ),
              if (keyboardInset == 0)
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 110,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.background.withValues(alpha: 0),
                          AppColors.background.withValues(alpha: AppColors.isDarkMode ? 0.92 : 0.75),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 18),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _saveExpense,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF1FD5A3),
                            foregroundColor: AppColors.textPrimary,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text(
                            'Save Expense',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editAmount() async {
    final currency = _selectedCurrency ?? AppCurrency.values.first;
    final controller = TextEditingController(
      text: _amount == 0 ? '' : _amount.toStringAsFixed(2),
    );
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Edit Amount'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: '0.00',
            prefixText: '${currency.symbol} ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = double.tryParse(controller.text.trim());
              if (parsed == null) {
                return;
              }
              Navigator.of(context).pop(parsed);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() => _amount = result);
    }
  }

  Future<void> _showCurrencyPicker({bool forceSelection = false}) async {
    final result = await showDialog<AppCurrency>(
      context: context,
      barrierDismissible: !forceSelection,
      builder: (context) => CurrencyPickerDialog(
        selectedCurrency: _selectedCurrency,
        forceSelection: forceSelection,
      ),
    );

    if (result == null) {
      return;
    }

    try {
      await widget.onCurrencyChanged(result);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() => _selectedCurrency = result);
  }

  Future<void> _pickDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (result != null) {
      setState(() => _selectedDate = result);
    }
  }

  Future<void> _pickPaymentMethod() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: paymentMethods
              .map(
                (method) => ListTile(
                  title: Text(
                    method,
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  onTap: () => Navigator.of(context).pop(method),
                ),
              )
              .toList(),
        ),
      ),
    );

    if (result != null) {
      setState(() => _paymentMethod = result);
    }
  }

  void _saveExpense() {
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter an amount greater than zero.')),
      );
      return;
    }

    final category = _selectedCategory ?? widget.expenseBloc.availableCategories().first;
    widget.onSaved(
      Expense(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        amount: _amount,
        currencyCode: (_selectedCurrency ?? AppCurrency.values.first).code,
        category: category,
        note: _notesController.text.trim(),
        paymentMethod: _paymentMethod,
        date: _selectedDate,
        icon: widget.expenseBloc.categoryIcon(category),
      ),
    );

    setState(() {
      _amount = 0;
      _selectedCategory = widget.expenseBloc.availableCategories().first;
      _paymentMethod = paymentMethods.first;
      _selectedDate = DateTime.now();
      _notesController.clear();
    });
  }

  Future<void> _showAddCategoryDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Add Category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(hintText: 'Category name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isEmpty) {
                return;
              }
              Navigator.of(context).pop(value);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    await widget.expenseBloc.addCustomCategory(result);
    if (!mounted) {
      return;
    }
    setState(() => _selectedCategory = result);
  }
}

class _ExpenseHeader extends StatelessWidget {
  const _ExpenseHeader({required this.onClose, required this.onSave});

  final VoidCallback onClose;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onClose,
          icon: Icon(Icons.close, color: AppColors.textPrimary),
        ),
        const Spacer(),
        Text(
          'New Expense',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: onSave,
          icon: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.emerald.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: AppColors.emerald),
          ),
        ),
      ],
    );
  }
}

class _AmountSection extends StatelessWidget {
  const _AmountSection({
    required this.amount,
    required this.currencySymbol,
    required this.onTap,
  });

  final double amount;
  final String currencySymbol;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Column(
        children: [
          Text(
            'AMOUNT',
            style: TextStyle(
              color: AppColors.emerald,
              fontSize: 11,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text.rich(
          TextSpan(
              children: [
                TextSpan(
                  text: currencySymbol,
                  style: const TextStyle(
                    color: Color(0xFF4A6776),
                    fontSize: 26,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextSpan(
                  text: amount.toStringAsFixed(2),
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 62,
                    fontWeight: FontWeight.w800,
                    height: 0.9,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to edit amount',
            style: TextStyle(color: Color(0xFF4A6776), fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.action});

  final String title;
  final String action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const Spacer(),
        Text(
          action,
          style: TextStyle(
            color: AppColors.emerald,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.categories,
    required this.expenseBloc,
    required this.selectedCategory,
    required this.onSelected,
    required this.onAddCategory,
  });

  final List<String> categories;
  final ExpenseBloc expenseBloc;
  final String selectedCategory;
  final ValueChanged<String> onSelected;
  final Future<void> Function() onAddCategory;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...categories.map((category) {
            final selected = selectedCategory == category;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: InkWell(
                onTap: () => onSelected(category),
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 52,
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF1FD5A3)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected ? Colors.transparent : AppColors.border,
                        ),
                      ),
                      child: Icon(
                        expenseBloc.categoryIcon(category),
                        color: selected ? AppColors.textPrimary : Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      category.toUpperCase(),
                      style: TextStyle(
                        color: selected ? AppColors.textPrimary : Colors.white38,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: onAddCategory,
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Icon(Icons.add, color: AppColors.emerald),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ADD',
                    style: TextStyle(
                      color: AppColors.emerald,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldCard extends StatelessWidget {
  const _FieldCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: GlassCard(
            radius: 16,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            child: Row(
              children: [
                Icon(icon, color: AppColors.emerald, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      gradient: LinearGradient(
        colors: [AppColors.notesCardStart, AppColors.notesCardEnd],
      ),
      radius: 16,
      child: TextField(
        controller: controller,
        maxLines: 4,
        style: TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Add details about this expense...',
          hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 15),
          border: InputBorder.none,
          isCollapsed: true,
        ),
      ),
    );
  }
}

class CurrencyPickerDialog extends StatefulWidget {
  const CurrencyPickerDialog({
    super.key,
    required this.selectedCurrency,
    required this.forceSelection,
  });

  final AppCurrency? selectedCurrency;
  final bool forceSelection;

  @override
  State<CurrencyPickerDialog> createState() => _CurrencyPickerDialogState();
}

class _CurrencyPickerDialogState extends State<CurrencyPickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = AppCurrency.values.where((currency) {
      final query = _query.trim().toLowerCase();
      if (query.isEmpty) {
        return true;
      }
      return currency.code.toLowerCase().contains(query) ||
          currency.name.toLowerCase().contains(query) ||
          currency.symbol.toLowerCase().contains(query);
    }).toList();

    return AlertDialog(
      backgroundColor: AppColors.surface,
      titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      title: Row(
        children: [
          Expanded(
            child: Text(
              'Select Currency',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ),
          if (!widget.forceSelection)
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.close, color: AppColors.textPrimary),
            ),
        ],
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search currency',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.background.withValues(alpha: 0.55),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, color: AppColors.border),
                  itemBuilder: (context, index) {
                    final currency = filtered[index];
                    final selected =
                        widget.selectedCurrency?.code == currency.code;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        currency.displayLabel,
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                      subtitle: Text(
                        currency.symbol,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      trailing: selected
                          ? const Icon(
                              Icons.check_circle,
                              color: AppColors.emerald,
                            )
                          : null,
                      onTap: () => Navigator.of(context).pop(currency),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.55,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: const Color(0xFF01231C),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.emerald.withValues(alpha: 0.18)),
        ),
        child: Column(
          children: [
            Icon(Icons.cloud_upload_outlined, color: AppColors.emerald, size: 30),
            SizedBox(height: 10),
            Text(
              'Receipt Upload',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Coming soon',
              style: TextStyle(color: Color(0xFF6C8590), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
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
