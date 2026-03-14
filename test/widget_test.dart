import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:expense_tracker/src/app.dart';
import 'package:expense_tracker/src/core/currency/app_currency.dart';
import 'package:expense_tracker/src/core/currency/exchange_rate_service.dart';
import 'package:expense_tracker/src/features/expenses/domain/models/expense.dart';
import 'package:expense_tracker/src/features/expenses/presentation/bloc/expense_bloc.dart';

void main() {
  test('changing currency converts existing amounts with current rate', () async {
    SharedPreferences.setMockInitialValues({
      'selected_currency_code': 'USD',
      'monthly_budget': 100.0,
    });

    final bloc = ExpenseBloc(
      exchangeRateService: _FakeExchangeRateService(rate: 0.5),
    );
    await bloc.hydrate();
    await bloc.addExpense(
      Expense(
        id: '1',
        amount: 40,
        currencyCode: 'USD',
        category: 'Food',
        note: 'Lunch',
        paymentMethod: 'Cash',
        date: DateTime(2026, 3, 8),
        icon: Icons.restaurant_outlined,
      ),
    );

    await bloc.setCurrency(
      const AppCurrency(code: 'EUR', name: 'Euro', symbol: '€'),
    );

    expect(bloc.currencyCode, 'EUR');
    expect(bloc.monthlyBudget, 50);
    expect(bloc.expenses.first.amount, 20);
  });

  test('custom category budget can be added and removed', () async {
    SharedPreferences.setMockInitialValues({
      'selected_currency_code': 'USD',
    });

    final bloc = ExpenseBloc(
      exchangeRateService: _FakeExchangeRateService(rate: 1),
    );
    await bloc.hydrate();
    await bloc.setCategoryBudget('Pets', 250);

    expect(bloc.categoryBudgets['Pets'], 250);
    expect(bloc.availableCategories(), contains('Pets'));

    await bloc.deleteCategory('Pets');

    expect(bloc.availableCategories(), isNot(contains('Pets')));
  });

  testWidgets('first launch shows onboarding', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ExpenseTrackerApp());
    await tester.pumpAndSettle();

    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Sign in'), findsNothing);
    expect(find.text('Groups'), findsNothing);
  });

  testWidgets('onboarding enters the public local-first shell', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ExpenseTrackerApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.text('Expense Tracker'), findsOneWidget);
    expect(find.text('Analytics'), findsOneWidget);
    expect(find.text('Budget'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Groups'), findsNothing);
  });

  testWidgets('public shell navigates across main screens', (tester) async {
    SharedPreferences.setMockInitialValues(_publicSeed());

    await tester.pumpWidget(const ExpenseTrackerApp());
    await tester.pumpAndSettle();

    expect(find.text('Analytics'), findsOneWidget);
    expect(find.text('Budget'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.text('Analytics'));
    await tester.pumpAndSettle();
    expect(find.text('Spending Analytics'), findsOneWidget);

    await tester.tap(find.text('Budget'));
    await tester.pumpAndSettle();
    expect(find.text('Monthly Categories'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('ABOUT'), 200);
    expect(find.text('ABOUT'), findsOneWidget);
    expect(find.text('ACCOUNT'), findsNothing);
  });

  testWidgets('settings dark mode toggle rebuilds app in light mode', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      ..._publicSeed(),
      'dark_mode_enabled': true,
    });

    await tester.pumpWidget(const ExpenseTrackerApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.light);
  });
}

Map<String, Object> _publicSeed() {
  return {
    'selected_currency_code': 'USD',
    'onboarding_completed': true,
  };
}

class _FakeExchangeRateService extends ExchangeRateService {
  const _FakeExchangeRateService({required this.rate});

  final double rate;

  @override
  Future<ExchangeRateResult> latestRate({
    required String base,
    required String target,
    required SharedPreferences preferences,
  }) async {
    return ExchangeRateResult(
      base: base,
      target: target,
      rate: rate,
      date: '2026-03-08',
    );
  }
}
