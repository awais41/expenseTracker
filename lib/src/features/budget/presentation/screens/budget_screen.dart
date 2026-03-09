import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../expenses/presentation/bloc/expense_bloc.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key, required this.expenseBloc});

  final ExpenseBloc expenseBloc;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthlySpent = expenseBloc.totalSpendingThisMonth(now);
    final currentBalance = expenseBloc.remainingMonthlyBudget(now);
    final totalSaved = expenseBloc.totalSaved(now);
    final monthlyBudget = expenseBloc.monthlyBudget;
    final categories = expenseBloc.budgetCategories(now);
    final progress = monthlyBudget <= 0
        ? 0.0
        : (monthlySpent / monthlyBudget).clamp(0.0, 1.0);

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
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 122),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BUDGET',
                            style: TextStyle(
                              color: AppColors.emerald.withValues(alpha: 0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Current Balance',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            expenseBloc.formatCurrency(currentBalance),
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Icon(
                          Icons.notifications_none_rounded,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _TopBudgetCard(
                            title: 'Monthly Budget',
                            value: monthlyBudget > 0
                                ? expenseBloc.formatCurrency(monthlyBudget)
                                : 'Set now',
                            icon: Icons.account_balance_wallet_outlined,
                            bright: true,
                            onTap: () => _showBudgetDialog(context),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _TopBudgetCard(
                            title: 'Total Saved',
                            value: expenseBloc.formatCurrency(totalSaved),
                            icon: Icons.savings_outlined,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _GoalCard(
                    progress: progress,
                    onTap: () => _showBudgetDialog(context),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text(
                        'Monthly Categories',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => _showAddCategoryDialog(context),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add'),
                      ),
                      const SizedBox(width: 4),
                      TextButton(
                        onPressed: () => _showCategoryPicker(context, categories),
                        child: const Text('Edit'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...categories.map((category) {
                    final spent = expenseBloc.categorySpentThisMonth(category, now);
                    final budget = expenseBloc.categoryBudget(category);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _BudgetCategoryTile(
                        category: category,
                        spent: spent,
                        budget: budget,
                        currency: expenseBloc,
                        color: expenseBloc.categoryColor(category),
                        icon: _categoryIcon(category),
                      ),
                    );
                  }),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showBudgetDialog(BuildContext context) async {
    final controller = TextEditingController(
      text: expenseBloc.monthlyBudget == 0
          ? ''
          : expenseBloc.monthlyBudget.toStringAsFixed(2),
    );

    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Edit Monthly Budget'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: '0.00',
            prefixText: '${expenseBloc.currencySymbol} ',
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
              if (parsed == null || parsed < 0) {
                return;
              }
              Navigator.of(context).pop(parsed);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null || !context.mounted) {
      return;
    }
    await expenseBloc.setMonthlyBudget(result);
  }

  Future<void> _showCategoryBudgetDialog(
    BuildContext context,
    String category,
  ) async {
    final current = expenseBloc.categoryBudget(category);
    final controller = TextEditingController(
      text: current == 0 ? '' : current.toStringAsFixed(2),
    );

    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Edit $category Budget'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: '0.00',
            prefixText: '${expenseBloc.currencySymbol} ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          if (current > 0)
            TextButton(
              onPressed: () => Navigator.of(context).pop(0),
              child: const Text('Remove'),
            ),
          FilledButton(
            onPressed: () {
              final parsed = double.tryParse(controller.text.trim());
              if (parsed == null || parsed < 0) {
                return;
              }
              Navigator.of(context).pop(parsed);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null || !context.mounted) {
      return;
    }
    await expenseBloc.setCategoryBudget(category, result);
  }

  Future<void> _showCategoryPicker(
    BuildContext context,
    List<String> categories,
  ) async {
    final parentContext = context;
    await showModalBottomSheet<void>(
      context: parentContext,
      backgroundColor: AppColors.surface,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: categories
              .map(
                (category) => ListTile(
                  title: Text(
                    category,
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  subtitle: Text(
                    expenseBloc.categoryBudget(category) > 0
                        ? expenseBloc.formatCurrency(
                            expenseBloc.categoryBudget(category),
                          )
                        : 'No budget set',
                    style: TextStyle(
                      color: expenseBloc.categoryBudget(category) > 0
                          ? AppColors.emerald
                          : AppColors.textSecondary,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Edit',
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await _showCategoryBudgetDialog(
                            parentContext,
                            category,
                          );
                        },
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: AppColors.emerald,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await expenseBloc.deleteCategory(category);
                          if (!parentContext.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(parentContext).showSnackBar(
                            SnackBar(content: Text('$category removed')),
                          );
                        },
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Future<void> _showAddCategoryDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final budgetController = TextEditingController();
    final result = await showDialog<(String, double)>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Add Category Budget'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              style: TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(hintText: 'Category name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: budgetController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: '0.00',
                prefixText: '${expenseBloc.currencySymbol} ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final budget = double.tryParse(budgetController.text.trim());
              if (name.isEmpty || budget == null || budget <= 0) {
                return;
              }
              Navigator.of(context).pop((name, budget));
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == null || !context.mounted) {
      return;
    }
    await expenseBloc.setCategoryBudget(result.$1, result.$2);
  }
}

class _TopBudgetCard extends StatelessWidget {
  const _TopBudgetCard({
    required this.title,
    required this.value,
    required this.icon,
    this.bright = false,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final bool bright;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final titleColor = bright
        ? AppColors.textPrimary.withValues(alpha: 0.8)
        : Colors.white.withValues(alpha: 0.72);
    final valueColor = bright ? AppColors.textPrimary : Colors.white;
    final iconColor = bright ? AppColors.textPrimary : AppColors.emerald;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: GlassCard(
        radius: 18,
        gradient: bright
            ? const LinearGradient(
                colors: [Color(0xFF29D36A), Color(0xFF20C76E)],
              )
            : const LinearGradient(
                colors: [Color(0xFF111A17), Color(0xFF0B1110)],
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 22,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: titleColor,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.progress, required this.onTap});

  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();
    const darkCardText = Colors.white;
    return GlassCard(
      radius: 20,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF3A49B8), Color(0xFF542CA6)],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 4,
            bottom: -6,
            child: Icon(
              Icons.home_work_outlined,
              size: 100,
              color: Colors.white.withValues(alpha: 0.18),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly Goal',
                      style: TextStyle(
                        color: darkCardText,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      progress == 0
                          ? 'Set your monthly budget to start tracking category goals.'
                          : "You're $percent% into your monthly budget. Keep an eye on your top categories.",
                      style: const TextStyle(
                        color: Color(0xFFD4DAFF),
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 18),
                    OutlinedButton(
                      onPressed: onTap,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: darkCardText,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                      ),
                      child: const Text('Edit Budget'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),

              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
                padding: const EdgeInsets.all(10),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: math.max(progress, 0.02),
                      strokeWidth: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation(AppColors.emerald),
                    ),
                    Text(
                      '${percent.clamp(0, 100)}%',
                      style: TextStyle(
                        color: darkCardText,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetCategoryTile extends StatelessWidget {
  const _BudgetCategoryTile({
    required this.category,
    required this.spent,
    required this.budget,
    required this.currency,
    required this.color,
    required this.icon,
  });

  final String category;
  final double spent;
  final double budget;
  final ExpenseBloc currency;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final safeBudget = budget <= 0 ? 1.0 : budget;
    final progress = (spent / safeBudget).clamp(0.0, 1.0);
    final isDarkMode = AppColors.isDarkMode;
    final titleColor = isDarkMode ? Colors.white : AppColors.textPrimary;
    final amountColor = isDarkMode ? Colors.white : AppColors.textPrimary;
    final status = budget <= 0
        ? 'Set a budget'
        : progress >= 0.9
        ? 'Near limit!'
        : progress >= 0.75
        ? 'Watch out'
        : 'On track';
    final statusColor = budget <= 0
        ? (isDarkMode ? Colors.white60 : AppColors.textSecondary)
        : progress >= 0.9
        ? const Color(0xFFFF6666)
        : progress >= 0.75
        ? const Color(0xFFFFB020)
        : const Color(0xFF7EF0D8);

    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.all(16),
      gradient: LinearGradient(
        colors: isDarkMode
            ? const [Color(0xFF081310), Color(0xFF060B0A)]
            : const [Colors.white, Color(0xFFF6FAF8)],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            category,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            '${currency.formatCurrency(spent)} / ${budget > 0 ? currency.formatCurrency(budget) : 'Set'}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: amountColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      status,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: budget <= 0 ? 0 : progress,
              backgroundColor: isDarkMode
                  ? Colors.white.withValues(alpha: 0.18)
                  : AppColors.textSecondary.withValues(alpha: 0.14),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

IconData _categoryIcon(String category) {
  switch (category) {
    case 'Food':
      return Icons.restaurant_rounded;
    case 'Shopping':
      return Icons.shopping_bag_outlined;
    case 'Travel':
      return Icons.directions_car_filled_outlined;
    case 'Bills':
      return Icons.receipt_long_outlined;
    case 'Health':
      return Icons.favorite_outline;
    case 'Entertainment':
      return Icons.movie_creation_outlined;
    default:
      return Icons.category_outlined;
  }
}
