import 'package:flutter/material.dart';

import '../../../add_expense/presentation/screens/add_expense_screen.dart';
import '../../../expenses/presentation/bloc/expense_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/widgets/glass_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.expenseBloc,
    required this.themeController,
  });

  final ExpenseBloc expenseBloc;
  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    final cardGradient = LinearGradient(
      colors: AppColors.isDarkMode
          ? const [Color(0xFF1B1F24), Color(0xFF11151A)]
          : [AppColors.settingsCardStart, AppColors.settingsCardEnd],
    );

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
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const _Header(),
                  const SizedBox(height: 24),
                  const _SectionLabel('PREFERENCES'),
                  const SizedBox(height: 14),
                  GlassCard(
                    padding: EdgeInsets.zero,
                    radius: 18,
                    gradient: cardGradient,
                    child: Column(
                      children: [
                        _SettingRow(
                          icon: Icons.attach_money_rounded,
                          title: 'Currency',
                          subtitle: 'Set your primary currency',
                          trailingLabel: expenseBloc.currencyCode,
                          onTap: () => _showCurrencyPicker(context),
                        ),
                        Divider(height: 1, color: AppColors.border),
                        const _SettingRow(
                          icon: Icons.notifications_none_rounded,
                          title: 'Notifications',
                          subtitle: 'Manage alerts and sounds',
                          isEnabled: false,
                        ),
                        Divider(height: 1, color: AppColors.border),
                        _SettingRow(
                          icon: Icons.nightlight_round,
                          title: 'Dark Mode',
                          subtitle: 'Switch theme colors',
                          trailing: _ThemeToggle(
                            themeController: themeController,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  const _SectionLabel('DATA & PRIVACY'),
                  const SizedBox(height: 14),
                  GlassCard(
                    padding: EdgeInsets.zero,
                    radius: 18,
                    gradient: cardGradient,
                    child: Column(
                      children: [
                        _SettingRow(
                          icon: Icons.ios_share_outlined,
                          title: 'Export Reports',
                          subtitle: 'Download your financial history',
                          isEnabled: false,
                        ),
                        Divider(height: 1, color: AppColors.border),
                        _SettingRow(
                          icon: Icons.shield_outlined,
                          title: 'Security',
                          subtitle: '2FA, Passwords, Biometrics',
                          isEnabled: false,
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCurrencyPicker(BuildContext context) async {
    final result = await showDialog(
      context: context,
      builder: (context) => CurrencyPickerDialog(
        selectedCurrency: expenseBloc.selectedCurrency,
        forceSelection: false,
      ),
    );

    if (result == null) {
      return;
    }

    try {
      await expenseBloc.setCurrency(result);
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.arrow_back, color: AppColors.textPrimary),
        Expanded(
          child: Text(
            'Settings',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(width: 24),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.emerald,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailingLabel,
    this.trailing,
    this.onTap,
    this.isEnabled = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailingLabel;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final accentColor = _iconColor(icon);
    final iconBackgroundColor = isEnabled
        ? accentColor.withValues(alpha: 0.14)
        : AppColors.textSecondary.withValues(alpha: 0.12);
    final resolvedIconColor = isEnabled
        ? accentColor
        : AppColors.textSecondary.withValues(alpha: 0.72);
    final titleColor = isEnabled
        ? AppColors.textPrimary
        : AppColors.textSecondary.withValues(alpha: 0.9);
    final subtitleColor = isEnabled
        ? AppColors.textSecondary
        : AppColors.textSecondary.withValues(alpha: 0.72);

    return InkWell(
      onTap: isEnabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: resolvedIconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            trailing ??
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isEnabled)
                      Text(
                        'Coming soon',
                        style: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.72),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    else if (trailingLabel != null)
                      Text(
                        trailingLabel!,
                        style: TextStyle(
                          color: AppColors.emerald,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    if (isEnabled) ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ],
                ),
          ],
        ),
      ),
    );
  }

  Color _iconColor(IconData icon) {
    switch (icon) {
      case Icons.attach_money_rounded:
        return const Color(0xFF4ADE80);
      case Icons.notifications_none_rounded:
        return const Color(0xFF60A5FA);
      case Icons.nightlight_round:
        return const Color(0xFFF59E0B);
      case Icons.ios_share_outlined:
        return const Color(0xFFA78BFA);
      case Icons.shield_outlined:
        return const Color(0xFF22D3EE);
      default:
        return AppColors.emerald;
    }
  }
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle({required this.themeController});

  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    return Switch.adaptive(
      value: themeController.isDarkMode,
      onChanged: themeController.setDarkMode,
      activeThumbColor: Colors.white,
      activeTrackColor: AppColors.emerald,
    );
  }
}
