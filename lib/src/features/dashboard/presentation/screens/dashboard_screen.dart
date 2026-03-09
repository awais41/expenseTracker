import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../expenses/domain/models/expense.dart';
import '../../../expenses/presentation/bloc/expense_bloc.dart';
import '../widgets/dashboard_widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.expenses,
    required this.expenseBloc,
    this.showWalletVariant = false,
    this.onAddExpense,
  });

  final List<Expense> expenses;
  final ExpenseBloc expenseBloc;
  final bool showWalletVariant;
  final VoidCallback? onAddExpense;

  @override
  Widget build(BuildContext context) {
    final hasExpenses = expenses.isNotEmpty;

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
                  DashboardHeader(showWalletVariant: showWalletVariant),
                  const SizedBox(height: 12),
                  if (hasExpenses) ...[
                    SummaryCard(expenseBloc: expenseBloc, expenses: expenses),
                    const SizedBox(height: 12),
                    StatGrid(
                      expenseBloc: expenseBloc,
                      expenses: expenses,
                      onSetMonthlyBudget: () =>
                          _showMonthlyBudgetDialog(context),
                    ),
                    const SizedBox(height: 14),
                    FlowAnalysisCard(expenseBloc: expenseBloc),
                    const SizedBox(height: 14),
                    CategoryBreakdownSection(expenseBloc: expenseBloc),
                    const SizedBox(height: 14),
                    TransactionsSection(
                      expenses: expenses,
                      expenseBloc: expenseBloc,
                    ),
                  ] else ...[
                    EmptyHomeHero(
                      monthlyBudget: expenseBloc.monthlyBudget,
                      currencySymbol: expenseBloc.currencySymbol,
                      onAddExpense: onAddExpense,
                      onSetMonthlyBudget: () =>
                          _showMonthlyBudgetDialog(context),
                    ),
                    const SizedBox(height: 14),
                    const QuickStartSection(),
                    const SizedBox(height: 14),
                    const EmptyInsightsSection(),
                    const SizedBox(height: 14),
                    const EmptyTransactionsSection(),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMonthlyBudgetDialog(BuildContext context) async {
    final controller = TextEditingController(
      text: expenseBloc.monthlyBudget == 0
          ? ''
          : expenseBloc.monthlyBudget.toStringAsFixed(2),
    );

    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Set Monthly Budget'),
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
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Monthly budget set to ${expenseBloc.formatCurrency(result)}',
        ),
      ),
    );
  }
}
