import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_colors.dart';

class ThemeController extends ChangeNotifier {
  static const darkModeKey = 'dark_mode_enabled';

  bool _isDarkMode = true;

  bool get isDarkMode => _isDarkMode;

  Future<void> hydrate() async {
    final preferences = await SharedPreferences.getInstance();
    _isDarkMode = preferences.getBool(darkModeKey) ?? true;
    AppColors.applyTheme(_isDarkMode);
    notifyListeners();
  }

  Future<void> setDarkMode(bool isDarkMode) async {
    if (_isDarkMode == isDarkMode) {
      return;
    }

    _isDarkMode = isDarkMode;
    AppColors.applyTheme(_isDarkMode);
    notifyListeners();

    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(darkModeKey, isDarkMode);
  }
}
