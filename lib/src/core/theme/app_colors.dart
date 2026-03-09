import 'package:flutter/material.dart';

abstract final class AppColors {
  static const emerald = Color(0xFF10B981);
  static const emeraldDark = Color(0xFF0F766E);
  static const emeraldSoft = Color(0xFF34D399);
  static const lime = Color(0xFFA3E635);
  static const cyan = Color(0xFF22D3EE);
  static const pink = Color(0xFFF472B6);
  static const danger = Color(0xFFFF5D5D);

  static bool _isDarkMode = true;

  static void applyTheme(bool isDarkMode) {
    _isDarkMode = isDarkMode;
  }

  static bool get isDarkMode => _isDarkMode;

  static Color get background =>
      _isDarkMode ? const Color(0xFF0A0C0B) : const Color(0xFFF8FBF9);
  static Color get backgroundAlt =>
      _isDarkMode ? const Color(0xFF020403) : const Color(0xFFE8F0EC);
  static Color get surface =>
      _isDarkMode ? const Color(0xFF121514) : const Color(0xFFFFFFFF);
  static Color get surfaceAlt =>
      _isDarkMode ? const Color(0xFF161B19) : const Color(0xFFF2F7F4);
  static Color get surfaceMuted =>
      _isDarkMode ? const Color(0xFF0D1512) : const Color(0xFFEAF2EE);
  static Color get border =>
      _isDarkMode ? const Color(0x14FFFFFF) : const Color(0x1F0F172A);
  static Color get textPrimary =>
      _isDarkMode ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
  static Color get textSecondary =>
      _isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569);
  static Color get textMuted =>
      _isDarkMode ? const Color(0x8064748B) : const Color(0x8064758B);
  static Color get iconMuted =>
      _isDarkMode ? Colors.white54 : const Color(0xFF64748B);
  static Color get navBackground =>
      _isDarkMode ? const Color(0xF2121514) : const Color(0xF8FFFFFF);
  static Color get overlay =>
      _isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04);
  static Color get shadow =>
      _isDarkMode ? const Color(0x26000000) : const Color(0x140F172A);
  static Color get screenGradientEnd => backgroundAlt;
  static Color get cardGradientStart =>
      _isDarkMode ? const Color(0xFF111A17) : const Color(0xFFFFFFFF);
  static Color get cardGradientEnd =>
      _isDarkMode ? const Color(0xFF0B1110) : const Color(0xFFF2F7F4);
  static Color get settingsCardStart =>
      _isDarkMode ? const Color(0xFF083425) : const Color(0xFFFFFFFF);
  static Color get settingsCardEnd =>
      _isDarkMode ? const Color(0xFF06251E) : const Color(0xFFEAF6F0);
  static Color get notesCardStart =>
      _isDarkMode ? const Color(0xFF012A22) : const Color(0xFFFFFFFF);
  static Color get notesCardEnd =>
      _isDarkMode ? const Color(0xFF01211B) : const Color(0xFFF1F7F4);
  static Color get chartCardStart =>
      _isDarkMode ? const Color(0xFF0A1F19) : const Color(0xFFFFFFFF);
  static Color get chartCardEnd =>
      _isDarkMode ? const Color(0xFF06110E) : const Color(0xFFF2F7F4);
  static Color get insightCardStart =>
      _isDarkMode ? const Color(0xFF121F18) : const Color(0xFFFFFFFF);
  static Color get insightCardEnd =>
      _isDarkMode ? const Color(0xFF091411) : const Color(0xFFEAF6F0);
  static Color get chartLineStart =>
      _isDarkMode ? const Color(0xFF21F4A3) : const Color(0xFF0F172A);
  static Color get chartLineEnd =>
      _isDarkMode ? const Color(0xFF31D681) : const Color(0xFF334155);
  static Color get chartGlow =>
      _isDarkMode ? emerald.withValues(alpha: 0.35) : const Color(0x330F172A);
  static Color get chartFillStart =>
      _isDarkMode ? const Color(0x2200FFAA) : const Color(0x120F172A);
  static Color get chartFillEnd =>
      _isDarkMode ? const Color(0x0000FFAA) : const Color(0x000F172A);
}
