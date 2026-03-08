import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../expenses/domain/models/expense.dart';
import '../../../expenses/presentation/bloc/expense_bloc.dart';
import '../widgets/analytics_widgets.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({
    super.key,
    required this.expenseBloc,
    required this.expenses,
    this.onBackToHome,
  });

  final ExpenseBloc expenseBloc;
  final List<Expense> expenses;
  final VoidCallback? onBackToHome;

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedPeriod = 0;

  @override
  Widget build(BuildContext context) {
    final hasExpenses = widget.expenses.isNotEmpty;
    final now = DateTime.now();
    final weeklyValues = widget.expenseBloc.weeklyBuckets(now);
    final total = _selectedPeriod == 0
        ? weeklyValues.fold<double>(0, (sum, value) => sum + value)
        : widget.expenseBloc.totalSpendingThisMonth(now);
    final categories = widget.expenseBloc.categoryBreakdown(now);
    final categoryLabels = categories.keys.take(5).toList();
    final insight = buildInsight(widget.expenseBloc, _selectedPeriod == 1);

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.background, Color(0xFF020403)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(
                    children: [
                      IconButton(
                        onPressed: widget.onBackToHome,
                        icon: const Icon(
                          Icons.arrow_back,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'Spending Analytics',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.calendar_month_outlined,
                        color: AppColors.textPrimary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  AnalyticsPeriodToggle(
                    selectedIndex: _selectedPeriod,
                    onChanged: (value) =>
                        setState(() => _selectedPeriod = value),
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 18),
                  _AnalyticsSectionHeader(
                    title: 'Spending Trend',
                    amount: analyticsCurrency(
                      total,
                      widget.expenseBloc.currencySymbol,
                    ),
                    trailing: StatPill(
                      label: hasExpenses ? '- 5.2%' : 'No change',
                      positive: false,
                    ),
                  ),
                  const SizedBox(height: 16),
                  hasExpenses
                      ? SpendingTrendChart(values: weeklyValues)
                      : const EmptyAnalyticsCard(),
                  const SizedBox(height: 28),
                  _AnalyticsSectionHeader(
                    title: 'Spending by Category',
                    amount: analyticsCurrency(
                      categories.values.fold<double>(
                        0,
                        (sum, value) => sum + value,
                      ),
                      widget.expenseBloc.currencySymbol,
                    ),
                    trailing: StatPill(
                      label: hasExpenses ? '+ 8.1%' : 'No change',
                      positive: true,
                    ),
                  ),
                  const SizedBox(height: 18),
                  CategoryStrip(
                    labels: categoryLabels.isEmpty
                        ? const ['Dining', 'Market', 'Travel', 'Bills', 'Other']
                        : categoryLabels,
                  ),
                  const SizedBox(height: 28),
                  SmartInsightCard(
                    insightTitle: hasExpenses
                        ? 'Spending Alert'
                        : 'Insight Waiting',
                    insightBody: insight,
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsSectionHeader extends StatelessWidget {
  const _AnalyticsSectionHeader({
    required this.title,
    required this.amount,
    required this.trailing,
  });

  final String title;
  final String amount;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              amount,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 36,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            trailing,
          ],
        ),
      ],
    );
  }
}
