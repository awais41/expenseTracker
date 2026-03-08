import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/currency/app_currency.dart';
import '../../../../core/currency/exchange_rate_service.dart';
import '../../domain/models/expense.dart';

class ExpenseBloc {
  ExpenseBloc({ExchangeRateService? exchangeRateService})
    : _controller = StreamController<List<Expense>>.broadcast(),
      _exchangeRateService = exchangeRateService ?? const ExchangeRateService();

  static const _cacheKey = 'cached_expenses';
  static const _monthlyBudgetKey = 'monthly_budget';
  static const _currencyCodeKey = 'selected_currency_code';
  static const _categoryBudgetsKey = 'category_budgets';
  static const _customCategoriesKey = 'custom_categories';
  static const _hiddenBudgetCategoriesKey = 'hidden_budget_categories';
  static const defaultBudgetCategories = <String>[
    'Food',
    'Shopping',
    'Travel',
    'Bills',
    'Health',
    'Entertainment',
  ];

  final StreamController<List<Expense>> _controller;
  final List<Expense> _expenses = <Expense>[];
  final ExchangeRateService _exchangeRateService;
  SharedPreferences? _preferences;
  double _monthlyBudget = 0;
  AppCurrency? _selectedCurrency;
  final Map<String, double> _categoryBudgets = <String, double>{};
  final Set<String> _customCategories = <String>{};
  final Set<String> _hiddenBudgetCategories = <String>{};

  Stream<List<Expense>> get stream => _controller.stream;
  List<Expense> get expenses => List.unmodifiable(_expenses);
  double get monthlyBudget => _monthlyBudget;
  AppCurrency? get selectedCurrency => _selectedCurrency;
  String get currencyCode => _selectedCurrency?.code ?? 'USD';
  String get currencySymbol => _selectedCurrency?.symbol ?? r'$';
  Map<String, double> get categoryBudgets => Map.unmodifiable(_categoryBudgets);
  Set<String> get customCategories => Set.unmodifiable(_customCategories);
  Set<String> get hiddenBudgetCategories =>
      Set.unmodifiable(_hiddenBudgetCategories);
  bool isDefaultBudgetCategory(String category) =>
      defaultBudgetCategories.contains(category);

  Future<void> hydrate() async {
    _preferences ??= await SharedPreferences.getInstance();
    _monthlyBudget = _preferences!.getDouble(_monthlyBudgetKey) ?? 0;
    _selectedCurrency = AppCurrency.fromCode(
      _preferences!.getString(_currencyCodeKey),
    );
    final categoryBudgetJson = _preferences!.getString(_categoryBudgetsKey);
    _categoryBudgets
      ..clear()
      ..addAll(_decodeBudgetMap(categoryBudgetJson));
    final customCategoriesJson = _preferences!.getStringList(_customCategoriesKey);
    _customCategories
      ..clear()
      ..addAll(customCategoriesJson ?? const <String>[]);
    final hiddenCategoriesJson = _preferences!.getStringList(
      _hiddenBudgetCategoriesKey,
    );
    _hiddenBudgetCategories
      ..clear()
      ..addAll(hiddenCategoriesJson ?? const <String>[]);
    final encoded = _preferences!.getString(_cacheKey);
    if (encoded == null || encoded.isEmpty) {
      _controller.add(expenses);
      return;
    }

    final decoded = jsonDecode(encoded) as List<dynamic>;
    _expenses
      ..clear()
      ..addAll(
        decoded.cast<Map<dynamic, dynamic>>().map(
          (item) => Expense.fromMap(Map<String, dynamic>.from(item)),
        ),
      );
    _controller.add(expenses);
  }

  Future<void> addExpense(Expense expense) async {
    _hiddenBudgetCategories.remove(expense.category);
    _expenses.insert(0, expense.copyWith(currencyCode: currencyCode));
    _controller.add(expenses);
    await _persist();
    await _persistHiddenBudgetCategories();
  }

  Future<void> setMonthlyBudget(double budget) async {
    _monthlyBudget = budget;
    _controller.add(expenses);
    _preferences ??= await SharedPreferences.getInstance();
    await _preferences!.setDouble(_monthlyBudgetKey, budget);
  }

  Future<void> setCategoryBudget(String category, double budget) async {
    _hiddenBudgetCategories.remove(category);
    if (!isDefaultBudgetCategory(category)) {
      _customCategories.add(category);
    }
    if (budget <= 0) {
      _categoryBudgets.remove(category);
    } else {
      _categoryBudgets[category] = budget;
    }
    _controller.add(expenses);
    await _persistCategoryBudgets();
    await _persistCustomCategories();
    await _persistHiddenBudgetCategories();
  }

  Future<void> addCustomCategory(String category) async {
    final normalized = category.trim();
    if (normalized.isEmpty) {
      return;
    }
    _hiddenBudgetCategories.remove(normalized);
    _customCategories.add(normalized);
    _controller.add(expenses);
    await _persistCustomCategories();
    await _persistHiddenBudgetCategories();
  }

  Future<void> deleteCategory(String category) async {
    _categoryBudgets.remove(category);
    _customCategories.remove(category);
    _hiddenBudgetCategories.add(category);
    _controller.add(expenses);
    await _persistCategoryBudgets();
    await _persistCustomCategories();
    await _persistHiddenBudgetCategories();
  }

  Future<void> setCurrency(AppCurrency currency) async {
    _preferences ??= await SharedPreferences.getInstance();
    final previousCode = currencyCode;
    if (previousCode == currency.code) {
      return;
    }

    if (_selectedCurrency != null) {
      final rateResult = await _exchangeRateService.latestRate(
        base: previousCode,
        target: currency.code,
        preferences: _preferences!,
      );
      final rate = rateResult.rate;
      for (var index = 0; index < _expenses.length; index++) {
        final expense = _expenses[index];
        _expenses[index] = expense.copyWith(
          amount: _roundCurrency(expense.amount * rate),
          currencyCode: currency.code,
        );
      }
      _monthlyBudget = _roundCurrency(_monthlyBudget * rate);
      for (final entry in _categoryBudgets.entries.toList()) {
        _categoryBudgets[entry.key] = _roundCurrency(entry.value * rate);
      }
      await _preferences!.setDouble(_monthlyBudgetKey, _monthlyBudget);
      await _persist();
      await _persistCategoryBudgets();
    }

    _selectedCurrency = currency;
    _controller.add(expenses);
    await _preferences!.setString(_currencyCodeKey, currency.code);
  }

  String formatCurrency(double value) => '$currencySymbol${value.toStringAsFixed(2)}';

  double totalSpendingThisMonth(DateTime now) {
    return _expenses
        .where(
          (expense) =>
              expense.date.year == now.year && expense.date.month == now.month,
        )
        .fold<double>(0, (sum, expense) => sum + expense.amount);
  }

  double dailyAverageThisMonth(DateTime now) {
    final total = totalSpendingThisMonth(now);
    return total / now.day.clamp(1, 31);
  }

  double remainingMonthlyBudget(DateTime now) {
    return (_monthlyBudget - totalSpendingThisMonth(now)).clamp(0.0, double.infinity);
  }

  double categoryBudget(String category) => _categoryBudgets[category] ?? 0;

  double categorySpentThisMonth(String category, DateTime now) {
    return _expenses
        .where(
          (expense) =>
              expense.category == category &&
              expense.date.year == now.year &&
              expense.date.month == now.month,
        )
        .fold<double>(0, (sum, expense) => sum + expense.amount);
  }

  List<String> budgetCategories(DateTime now) {
    final categories = <String>{
      ...defaultBudgetCategories,
      ..._customCategories,
      ..._categoryBudgets.keys,
      ...categoryBreakdown(now).keys,
    }.where((category) => !_hiddenBudgetCategories.contains(category));
    final sorted = categories.toList()..sort();
    return sorted;
  }

  List<String> availableCategories() {
    final categories = <String>{
      ...defaultBudgetCategories,
      ..._customCategories,
      ..._categoryBudgets.keys,
      ..._expenses.map((expense) => expense.category),
    }.where((category) => !_hiddenBudgetCategories.contains(category));
    final sorted = categories.toList()..sort();
    return sorted;
  }

  double totalSaved(DateTime now) {
    final totalCategoryBudget = _categoryBudgets.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );
    if (totalCategoryBudget > 0) {
      return (totalCategoryBudget - totalSpendingThisMonth(now)).clamp(
        0.0,
        double.infinity,
      );
    }
    return remainingMonthlyBudget(now);
  }

  Map<String, double> categoryBreakdown(DateTime now) {
    final totals = <String, double>{};
    for (final expense in _expenses.where(
      (expense) =>
          expense.date.year == now.year && expense.date.month == now.month,
    )) {
      totals.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    return totals;
  }

  List<double> weeklyBuckets(DateTime now) {
    final values = List<double>.filled(7, 0);
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final normalizedStart = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day,
    );

    for (final expense in _expenses) {
      final expenseDay = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      final diff = expenseDay.difference(normalizedStart).inDays;
      if (diff >= 0 && diff < 7) {
        values[diff] += expense.amount;
      }
    }

    return values;
  }

  Color categoryColor(String category) {
    switch (category) {
      case 'Food':
        return const Color(0xFF22D3EE);
      case 'Travel':
        return const Color(0xFFF472B6);
      case 'Shopping':
        return const Color(0xFFA3E635);
      case 'Health':
        return const Color(0xFF4ADE80);
      case 'Bills':
        return const Color(0xFFF59E0B);
      case 'Entertainment':
        return const Color(0xFFFFB020);
      default:
        final index = category.hashCode.abs() % _fallbackColors.length;
        return _fallbackColors[index];
    }
  }

  IconData categoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant_outlined;
      case 'Travel':
        return Icons.directions_car_outlined;
      case 'Shopping':
        return Icons.shopping_bag_outlined;
      case 'Health':
        return Icons.medical_services_outlined;
      case 'Bills':
        return Icons.receipt_long_outlined;
      case 'Entertainment':
        return Icons.movie_creation_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  Future<void> _persist() async {
    _preferences ??= await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      _expenses.map((expense) => expense.toMap()).toList(),
    );
    await _preferences!.setString(_cacheKey, encoded);
  }

  Future<void> _persistCategoryBudgets() async {
    _preferences ??= await SharedPreferences.getInstance();
    await _preferences!.setString(
      _categoryBudgetsKey,
      jsonEncode(_categoryBudgets),
    );
  }

  Future<void> _persistCustomCategories() async {
    _preferences ??= await SharedPreferences.getInstance();
    await _preferences!.setStringList(
      _customCategoriesKey,
      _customCategories.toList()..sort(),
    );
  }

  Future<void> _persistHiddenBudgetCategories() async {
    _preferences ??= await SharedPreferences.getInstance();
    await _preferences!.setStringList(
      _hiddenBudgetCategoriesKey,
      _hiddenBudgetCategories.toList()..sort(),
    );
  }

  void dispose() {
    _controller.close();
  }

  double _roundCurrency(double value) => double.parse(value.toStringAsFixed(2));

  Map<String, double> _decodeBudgetMap(String? encoded) {
    if (encoded == null || encoded.isEmpty) {
      return <String, double>{};
    }
    final decoded = Map<String, dynamic>.from(jsonDecode(encoded) as Map);
    return decoded.map(
      (key, value) => MapEntry(key, (value as num).toDouble()),
    );
  }

  static const _fallbackColors = <Color>[
    Color(0xFF22D3EE),
    Color(0xFFA3E635),
    Color(0xFFF472B6),
    Color(0xFFFFB020),
    Color(0xFF60A5FA),
    Color(0xFF4ADE80),
  ];
}
