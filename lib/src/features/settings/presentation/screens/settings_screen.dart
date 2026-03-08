import 'package:flutter/material.dart';

import '../../../add_expense/presentation/screens/add_expense_screen.dart';
import '../../../expenses/presentation/bloc/expense_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.expenseBloc});

  final ExpenseBloc expenseBloc;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.background, Color(0xFF030504)],
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
                    gradient: const LinearGradient(
                      colors: [Color(0xFF083425), Color(0xFF06251E)],
                    ),
                    child: Column(
                      children: [
                        _SettingRow(
                          icon: Icons.attach_money_rounded,
                          title: 'Currency',
                          subtitle: 'Set your primary currency',
                          trailingLabel: expenseBloc.currencyCode,
                          onTap: () => _showCurrencyPicker(context),
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        const _SettingRow(
                          icon: Icons.notifications_none_rounded,
                          title: 'Notifications',
                          subtitle: 'Manage alerts and sounds',
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        const _SettingRow(
                          icon: Icons.nightlight_round,
                          title: 'Dark Mode',
                          subtitle: 'Switch theme colors',
                          trailing: _ThemeToggle(),
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
                    gradient: const LinearGradient(
                      colors: [Color(0xFF083425), Color(0xFF06251E)],
                    ),
                    child: Column(
                      children: const [
                        _SettingRow(
                          icon: Icons.ios_share_outlined,
                          title: 'Export Reports',
                          subtitle: 'Download your financial history',
                        ),
                        Divider(height: 1, color: AppColors.border),
                        _SettingRow(
                          icon: Icons.shield_outlined,
                          title: 'Security',
                          subtitle: '2FA, Passwords, Biometrics',
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
    return const Row(
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
      style: const TextStyle(
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
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailingLabel;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.emerald.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.emerald),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
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
                    if (trailingLabel != null)
                      Text(
                        trailingLabel!,
                        style: const TextStyle(
                          color: AppColors.emerald,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
          ],
        ),
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 24,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.emerald,
        borderRadius: BorderRadius.circular(99),
      ),
      child: const Align(
        alignment: Alignment.centerRight,
        child: CircleAvatar(radius: 10, backgroundColor: Colors.white),
      ),
    );
  }
}
