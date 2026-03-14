import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/navigation/presentation/widgets/expense_app_shell.dart';
import 'features/onboarding/presentation/screens/onboarding_screen.dart';

class ExpenseTrackerApp extends StatefulWidget {
  const ExpenseTrackerApp({super.key});

  @override
  State<ExpenseTrackerApp> createState() => _ExpenseTrackerAppState();
}

class _ExpenseTrackerAppState extends State<ExpenseTrackerApp> {
  static const _onboardingCompletedKey = 'onboarding_completed';

  late final ThemeController _themeController;
  late Future<bool> _onboardingFuture;

  @override
  void initState() {
    super.initState();
    _themeController = ThemeController()..hydrate();
    _onboardingFuture = _loadOnboardingState();
  }

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeController,
      builder: (context, _) => MaterialApp(
        title: 'Expense Tracker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode:
            _themeController.isDarkMode ? ThemeMode.dark : ThemeMode.light,
        home: FutureBuilder<bool>(
          future: _onboardingFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.data ?? false) {
              return ExpenseAppShell(themeController: _themeController);
            }

            return OnboardingScreen(onGetStarted: _completeOnboarding);
          },
        ),
      ),
    );
  }

  Future<bool> _loadOnboardingState() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_onboardingCompletedKey) ?? false;
  }

  Future<void> _completeOnboarding() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_onboardingCompletedKey, true);
    if (!mounted) {
      return;
    }

    setState(() {
      _onboardingFuture = Future<bool>.value(true);
    });
  }
}
