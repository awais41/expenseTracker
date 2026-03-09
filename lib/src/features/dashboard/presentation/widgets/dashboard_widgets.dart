import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../expenses/domain/models/expense.dart';
import '../../../expenses/presentation/bloc/expense_bloc.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key, required this.showWalletVariant});

  final bool showWalletVariant;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              showWalletVariant ? 'Wallet Overview' : 'Home',
              style: TextStyle(
                color: AppColors.emerald.withValues(alpha: 0.7),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'Expense Tracker',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.emerald.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.notifications_none_rounded,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class EmptyHomeHero extends StatelessWidget {
  const EmptyHomeHero({
    super.key,
    required this.monthlyBudget,
    required this.currencySymbol,
    this.onAddExpense,
    this.onSetMonthlyBudget,
  });

  final double monthlyBudget;
  final String currencySymbol;
  final VoidCallback? onAddExpense;
  final VoidCallback? onSetMonthlyBudget;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF12382D), Color(0xFF0A1714)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.emerald.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.auto_graph_rounded,
              color: AppColors.emerald,
              size: 24,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Your expense story starts here',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'There is no sample data anymore. Add your first expense and Home will start filling with totals, trends, and recent activity.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          if (monthlyBudget > 0) ...[
            const SizedBox(height: 12),
            Text(
              'Monthly budget: ${_currency(monthlyBudget, currencySymbol)}',
              style: TextStyle(
                color: AppColors.emerald,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onAddExpense,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.emerald,
                foregroundColor: AppColors.textPrimary,
                minimumSize: const Size.fromHeight(44),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Add your first expense',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onSetMonthlyBudget,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.emerald,
                side: BorderSide(
                  color: AppColors.emerald.withValues(alpha: 0.2),
                ),
                minimumSize: const Size.fromHeight(42),
              ),
              icon: const Icon(Icons.savings_outlined, size: 18),
              label: const Text(
                'Set monthly budget',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QuickStartSection extends StatelessWidget {
  const QuickStartSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Start',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _GuideCard(
                icon: Icons.receipt_long_rounded,
                title: 'Add expenses',
                body: 'Track food, transport, bills, shopping, and more.',
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _GuideCard(
                icon: Icons.savings_outlined,
                title: 'Set budgets',
                body: 'Budget insights appear after you log spending.',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.emerald, size: 20),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyInsightsSection extends StatelessWidget {
  const EmptyInsightsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Insights',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'No data yet',
                  style: TextStyle(
                    color: AppColors.emerald,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Icon(Icons.bar_chart_rounded, color: AppColors.textSecondary, size: 32),
                SizedBox(height: 10),
                Text(
                  'Charts and summaries will appear after your first few expenses.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyTransactionsSection extends StatelessWidget {
  const EmptyTransactionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Transactions',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.receipt_outlined,
                  color: AppColors.emerald,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'No transactions yet',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Once you save an expense, it will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.expenseBloc,
    required this.expenses,
  });

  final ExpenseBloc expenseBloc;
  final List<Expense> expenses;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final total = expenseBloc.totalSpendingThisMonth(now);
    final average = expenseBloc.dailyAverageThisMonth(now);

    return GlassCard(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF16946E), Color(0xFF16524F)],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -24,
            right: -18,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOTAL SPENDING THIS MONTH',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                expenseBloc.formatCurrency(total),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _MetricColumn(
                      label: 'DAILY AVERAGE',
                      value: expenseBloc.formatCurrency(average),
                      valueColor: Colors.white,
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _MetricColumn(
                        label: 'EXPENSES',
                        value: expenses.length.toString(),
                        valueColor: const Color(0xFF6EE7B7),
                        icon: Icons.receipt_long_rounded,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricColumn extends StatelessWidget {
  _MetricColumn({
    required this.label,
    required this.value,
    Color? valueColor,
    this.icon,
  }) : valueColor = valueColor ?? AppColors.textPrimary;

  final String label;
  final String value;
  final Color valueColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: valueColor),
              const SizedBox(width: 2),
            ],
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class StatGrid extends StatelessWidget {
  const StatGrid({
    super.key,
    required this.expenseBloc,
    required this.expenses,
    required this.onSetMonthlyBudget,
  });

  final ExpenseBloc expenseBloc;
  final List<Expense> expenses;
  final VoidCallback onSetMonthlyBudget;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final total = expenseBloc.totalSpendingThisMonth(now);
    final monthlyBudget = expenseBloc.monthlyBudget;
    final remaining = math.max(0.0, monthlyBudget - total);
    final progress = monthlyBudget == 0
        ? 0.0
        : (total / monthlyBudget).clamp(0.0, 1.0);
    final thisWeek = expenseBloc.weeklyBuckets(now).fold(0.0, (a, b) => a + b);
    final budgetConfigured = monthlyBudget > 0;

    return Row(
      children: [
        Expanded(
          child: MiniStatCard(
            title: budgetConfigured ? 'REMAINING' : 'MONTHLY BUDGET',
            value: budgetConfigured
                ? expenseBloc.formatCurrency(remaining)
                : 'Set now',
            footer: budgetConfigured
                ? 'BUDGET ${expenseBloc.formatCurrency(monthlyBudget)}'
                : 'TAP TO SET',
            progress: progress,
            onTap: onSetMonthlyBudget,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: MiniStatCard(
            title: 'THIS WEEK',
            value: expenseBloc.formatCurrency(thisWeek),
            footer: '${expenses.length} EXPENSES',
          ),
        ),
      ],
    );
  }
}

class MiniStatCard extends StatelessWidget {
  const MiniStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.footer,
    this.progress,
    this.onTap,
  });

  final String title;
  final String value;
  final String footer;
  final double? progress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: GlassCard(
        radius: 16,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            if (progress != null)
              _BudgetBar(progress: progress!)
            else
              const SizedBox(height: 4),
            const SizedBox(height: 6),
            Text(
              footer,
              style: TextStyle(
                color: AppColors.lime,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetBar extends StatelessWidget {
  const _BudgetBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: progress,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              gradient: const LinearGradient(
                colors: [AppColors.emerald, AppColors.lime],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class FlowAnalysisCard extends StatelessWidget {
  const FlowAnalysisCard({super.key, required this.expenseBloc});

  final ExpenseBloc expenseBloc;

  @override
  Widget build(BuildContext context) {
    final rawValues = expenseBloc.weeklyBuckets(DateTime.now());
    final maxValue = rawValues.fold<double>(0, math.max);
    final values = rawValues
        .map(
          (value) => maxValue == 0 ? 0.12 : (value / maxValue).clamp(0.12, 1.0),
        )
        .toList();
    const labels = <String>['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

    return GlassCard(
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Flow Analysis',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'This Week',
                  style: TextStyle(
                    color: AppColors.emerald,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 118,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(values.length, (index) {
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: 14,
                            height: 72.0 * values[index],
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(99),
                              gradient: const LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [AppColors.emerald, AppColors.cyan],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        labels[index],
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryBreakdownSection extends StatelessWidget {
  const CategoryBreakdownSection({super.key, required this.expenseBloc});

  final ExpenseBloc expenseBloc;

  @override
  Widget build(BuildContext context) {
    final breakdown = expenseBloc.categoryBreakdown(DateTime.now());
    final total = breakdown.values.fold(0.0, (sum, value) => sum + value);
    final topEntries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topThree = topEntries.take(3).toList();
    final segments = topThree
        .map(
          (entry) => (
            color: expenseBloc.categoryColor(entry.key),
            value: total == 0 ? 0.0 : entry.value / total,
          ),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category Breakdown',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Row(
            children: [
              SizedBox(
                width: 96,
                height: 96,
                child: CustomPaint(
                  painter: _DonutPainter(segments: segments),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Top',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          topThree.isEmpty ? 'None' : topThree.first.key,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: topThree
                      .map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: BreakdownLegend(
                            color: expenseBloc.categoryColor(entry.key),
                            label: entry.key,
                            value: total == 0
                                ? '0%'
                                : '${((entry.value / total) * 100).round()}%',
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class BreakdownLegend extends StatelessWidget {
  const BreakdownLegend({
    super.key,
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 6),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class TransactionsSection extends StatelessWidget {
  const TransactionsSection({
    super.key,
    required this.expenses,
    required this.expenseBloc,
  });

  final List<Expense> expenses;
  final ExpenseBloc expenseBloc;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Recent Transactions',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            Spacer(),
            Text(
              'Live',
              style: TextStyle(
                color: AppColors.emerald,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...expenses.take(5).map<Widget>((Expense expense) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Icon(
                    expense.icon,
                    color: AppColors.textPrimary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.note.isEmpty ? expense.category : expense.note,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${expense.category} • ${_dateLabel(expense.date)}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '-${expenseBloc.formatCurrency(expense.amount)}',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.segments});

  final List<({Color color, double value})> segments;

  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    final rect = Offset.zero & size;
    canvas.drawArc(rect.deflate(10), 0, math.pi * 2, false, basePaint);

    var start = -math.pi / 2;
    for (final segment in segments) {
      final sweep = math.pi * 2 * segment.value;
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect.deflate(10), start, sweep, false, paint);
      start += sweep + 0.08;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.segments != segments;
}

String _currency(double value, String symbol) =>
    '$symbol${value.toStringAsFixed(2)}';

String _dateLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final candidate = DateTime(date.year, date.month, date.day);
  if (candidate == today) {
    return 'Today';
  }
  if (candidate == today.subtract(const Duration(days: 1))) {
    return 'Yesterday';
  }
  return '${date.day}/${date.month}/${date.year}';
}
