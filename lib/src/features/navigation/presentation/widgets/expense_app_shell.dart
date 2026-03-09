import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../add_expense/presentation/screens/add_expense_screen.dart';
import '../../../analytics/presentation/screens/analytics_screen.dart';
import '../../../budget/presentation/screens/budget_screen.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../../expenses/domain/models/expense.dart';
import '../../../expenses/presentation/bloc/expense_bloc.dart';
import '../../../onboarding/presentation/screens/onboarding_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../bloc/navigation_bloc.dart';
import 'app_bottom_navigation.dart';

class ExpenseAppShell extends StatefulWidget {
  const ExpenseAppShell({
    super.key,
    required this.themeController,
  });

  final ThemeController themeController;

  @override
  State<ExpenseAppShell> createState() => _ExpenseAppShellState();
}

class _ExpenseAppShellState extends State<ExpenseAppShell> {
  static const _onboardingCompletedKey = 'onboarding_completed';

  late final NavigationBloc _navigationBloc;
  late final ExpenseBloc _expenseBloc;
  late final Future<void> _hydrateFuture;
  bool _showOnboarding = true;

  @override
  void initState() {
    super.initState();
    _navigationBloc = NavigationBloc();
    _expenseBloc = ExpenseBloc();
    _hydrateFuture = _hydrateAppState();
  }

  @override
  void dispose() {
    _navigationBloc.dispose();
    _expenseBloc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _hydrateFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (_showOnboarding) {
          return OnboardingScreen(
            onGetStarted: () {
              _completeOnboarding();
            },
          );
        }

        return StreamBuilder<int>(
          initialData: _navigationBloc.currentIndex,
          stream: _navigationBloc.stream,
          builder: (context, snapshot) {
            final currentIndex = snapshot.data ?? 0;

            return Scaffold(
              resizeToAvoidBottomInset: false,
              extendBody: true,
              body: Stack(
                children: [
                  Positioned.fill(child: _buildScreen(currentIndex)),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: SafeArea(
                      top: false,
                      child: AppBottomNavigation(
                        currentIndex: currentIndex,
                        onTap: _navigationBloc.changeTab,
                      ),
                    ),
                  ),
                ],
              ),
              floatingActionButton: currentIndex == 0
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 69),
                      child: FloatingActionButton(
                        onPressed: () => _navigationBloc.changeTab(4),
                        shape: const CircleBorder(),
                        mini: false,
                        child: Icon(
                          Icons.add,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    )
                  : null,
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.endFloat,
            );
          },
        );
      },
    );
  }

  Widget _buildScreen(int currentIndex) {
    switch (currentIndex) {
      case 0:
        return _dashboard(showWalletVariant: false);
      case 1:
        return StreamBuilder<List<Expense>>(
          initialData: _expenseBloc.expenses,
          stream: _expenseBloc.stream,
          builder: (context, snapshot) {
            return AnalyticsScreen(
              expenseBloc: _expenseBloc,
              expenses: snapshot.data ?? const <Expense>[],
              onBackToHome: () => _navigationBloc.changeTab(0),
            );
          },
        );
      case 2:
        return StreamBuilder<List<Expense>>(
          initialData: _expenseBloc.expenses,
          stream: _expenseBloc.stream,
          builder: (context, snapshot) {
            return BudgetScreen(expenseBloc: _expenseBloc);
          },
        );
      case 3:
        return StreamBuilder<List<Expense>>(
          initialData: _expenseBloc.expenses,
          stream: _expenseBloc.stream,
          builder: (context, snapshot) {
            return SettingsScreen(
              expenseBloc: _expenseBloc,
              themeController: widget.themeController,
            );
          },
        );
      case 4:
        return AddExpenseScreen(
          expenseBloc: _expenseBloc,
          initialCurrency: _expenseBloc.selectedCurrency,
          onCurrencyChanged: _expenseBloc.setCurrency,
          onSaved: (expense) async {
            await _expenseBloc.addExpense(expense);
            _navigationBloc.changeTab(0);
          },
          onClose: () => _navigationBloc.changeTab(0),
        );
      default:
        return _dashboard(showWalletVariant: false);
    }
  }

  Widget _dashboard({required bool showWalletVariant}) {
    return StreamBuilder<List<Expense>>(
      initialData: _expenseBloc.expenses,
      stream: _expenseBloc.stream,
      builder: (context, snapshot) {
        return DashboardScreen(
          expenses: snapshot.data ?? const <Expense>[],
          expenseBloc: _expenseBloc,
          showWalletVariant: showWalletVariant,
          onAddExpense: () => _navigationBloc.changeTab(4),
        );
      },
    );
  }

  Future<void> _hydrateAppState() async {
    await _expenseBloc.hydrate();
    final preferences = await SharedPreferences.getInstance();
    final onboardingCompleted =
        preferences.getBool(_onboardingCompletedKey) ?? false;
    _showOnboarding = !onboardingCompleted;
    if (!onboardingCompleted) {
      await preferences.setBool(_onboardingCompletedKey, true);
    }
  }

  Future<void> _completeOnboarding() async {
    if (mounted) {
      setState(() => _showOnboarding = false);
    }
    await _persistOnboardingCompleted();
  }

  Future<void> _persistOnboardingCompleted() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_onboardingCompletedKey, true);
  }
}
