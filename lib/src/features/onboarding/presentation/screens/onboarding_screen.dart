import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key, required this.onGetStarted});

  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0E1714), AppColors.background],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: const Color(0xFF20694B),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 18,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Aura',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: onGetStarted,
                          child: const Text(
                            'Skip',
                            style: TextStyle(
                              color: Color(0xFF20694B),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset(
                        'assets/design_concept/Background.png',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 280,
                      ),
                    ),
                    const SizedBox(height: 28),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: textTheme.headlineMedium?.copyWith(
                          fontSize: 30,
                          height: 1.18,
                        ),
                        children: const [
                          TextSpan(text: 'Master your wealth\n'),
                          TextSpan(text: 'with '),
                          TextSpan(
                            text: 'artful',
                            style: TextStyle(color: Color(0xFF20694B)),
                          ),
                          TextSpan(text: '\nprecision.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Experience the most aesthetic way to\ntrack expenses and grow your savings\nwith luxury precision.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge?.copyWith(
                        fontSize: 14,
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _PageDot(width: 24, active: true),
                        SizedBox(width: 10),
                        _PageDot(width: 6),
                        SizedBox(width: 10),
                        _PageDot(width: 6),
                      ],
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: onGetStarted,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2FCF9D),
                          foregroundColor: AppColors.textPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Get Started',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const SizedBox(height: 22),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.translate, color: Colors.white38, size: 18),
                        SizedBox(width: 24),
                        Icon(
                          Icons.verified_user_outlined,
                          color: Colors.white38,
                          size: 18,
                        ),
                        SizedBox(width: 24),
                        Icon(
                          Icons.shield_outlined,
                          color: Colors.white38,
                          size: 18,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PageDot extends StatelessWidget {
  const _PageDot({required this.width, this.active = false});

  final double width;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 6,
      decoration: BoxDecoration(
        color: active
            ? AppColors.emerald
            : AppColors.emerald.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}
