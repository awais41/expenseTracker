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

    await bloc.setCurrency(const AppCurrency(code: 'EUR', name: 'Euro', symbol: '€'));

    expect(bloc.currencyCode, 'EUR');
    expect(bloc.monthlyBudget, 50);
    expect(bloc.expenses.first.amount, 20);
    expect(bloc.expenses.first.currencyCode, 'EUR');
  });

  test('setting category budget persists in bloc state', () async {
    SharedPreferences.setMockInitialValues({
      'selected_currency_code': 'USD',
    });

    final bloc = ExpenseBloc(
      exchangeRateService: _FakeExchangeRateService(rate: 1),
    );
    await bloc.hydrate();
    await bloc.setCategoryBudget('Food', 500);

    expect(bloc.categoryBudget('Food'), 500);
    expect(bloc.categoryBudgets['Food'], 500);
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
    expect(bloc.budgetCategories(DateTime(2026, 3, 9)), contains('Pets'));
    expect(bloc.availableCategories(), contains('Pets'));

    await bloc.deleteCategory('Pets');

    expect(bloc.categoryBudgets.containsKey('Pets'), isFalse);
    expect(bloc.budgetCategories(DateTime(2026, 3, 9)), isNot(contains('Pets')));
    expect(bloc.availableCategories(), isNot(contains('Pets')));
  });

  test('default budget category can be hidden when deleted', () async {
    SharedPreferences.setMockInitialValues({
      'selected_currency_code': 'USD',
    });

    final bloc = ExpenseBloc(
      exchangeRateService: _FakeExchangeRateService(rate: 1),
    );
    await bloc.hydrate();

    expect(bloc.budgetCategories(DateTime(2026, 3, 9)), contains('Health'));

    await bloc.deleteCategory('Health');

    expect(bloc.budgetCategories(DateTime(2026, 3, 9)), isNot(contains('Health')));
    expect(bloc.hiddenBudgetCategories, contains('Health'));
  });

  testWidgets('app renders onboarding and enters shell', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ExpenseTrackerApp());
    await tester.pumpAndSettle();

    expect(find.text('Get Started'), findsOneWidget);
    expect(
      find.text(
        'Experience the most aesthetic way to\ntrack expenses and grow your savings\nwith luxury precision.',
      ),
      findsOneWidget,
    );
    expect(find.text('Aura'), findsNothing);
    expect(find.text('Sign In'), findsNothing);

    final image = tester.widget<Image>(find.byType(Image).first);
    final provider = image.image as AssetImage;
    expect(provider.assetName, 'assets/design_concept/Background.png');

    await tester.ensureVisible(find.text('Get Started'));
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.text('Your expense story starts here'), findsOneWidget);
    expect(find.text('Expense Tracker'), findsOneWidget);
  });

  testWidgets('bottom navigation moves across implemented screens', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'selected_currency_code': 'USD',
    });
    await tester.pumpWidget(const ExpenseTrackerApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Get Started'));
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.text('Analytics'), findsOneWidget);
    expect(find.text('Budget'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('New Expense'), findsOneWidget);
    expect(find.text('Tap to edit amount'), findsOneWidget);

    await tester.tap(find.text('Analytics'));
    await tester.pumpAndSettle();
    expect(find.text('Spending Analytics'), findsOneWidget);

    await tester.tap(find.text('Budget'));
    await tester.pumpAndSettle();
    expect(find.text('Monthly Categories'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('PREFERENCES'), findsOneWidget);
  });

  testWidgets('saving an expense populates home data', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ExpenseTrackerApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Get Started'));
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ListTile, 'USD • US Dollar').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tap to edit amount'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '24.5');
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, 'Coffee');
    await tester.tap(find.byType(FilledButton).last);
    await tester.pumpAndSettle();

    expect(find.text('Coffee'), findsOneWidget);
  });

  testWidgets('first expense flow prompts for currency selection', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ExpenseTrackerApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Get Started'));
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Select Currency'), findsOneWidget);
    expect(find.text('Search currency'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'PKR');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'PKR • Pakistani Rupee'));
    await tester.pumpAndSettle();

    expect(find.text('Select Currency'), findsNothing);
    expect(find.text('CURRENCY'), findsNothing);
  });

  testWidgets('user can set a monthly budget from home', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ExpenseTrackerApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Get Started'));
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Set monthly budget'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '1500');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Monthly budget: \$1500.00'), findsOneWidget);
  });

  testWidgets('settings opens currency picker and shows selected currency', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'selected_currency_code': 'USD',
    });
    await tester.pumpWidget(const ExpenseTrackerApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Get Started'));
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Currency'));
    await tester.pumpAndSettle();

    expect(find.text('Select Currency'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'USD • US Dollar'), findsOneWidget);
  });

  testWidgets('completed onboarding is skipped on restart', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'onboarding_completed': true,
    });
    await tester.pumpWidget(const ExpenseTrackerApp());
    await tester.pumpAndSettle();

    expect(find.text('Get Started'), findsNothing);
    expect(find.text('Expense Tracker'), findsOneWidget);
  });

  testWidgets('onboarding is marked completed after being shown once', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ExpenseTrackerApp());
    await tester.pumpAndSettle();

    expect(find.text('Get Started'), findsOneWidget);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('onboarding_completed'), true);
  });
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
