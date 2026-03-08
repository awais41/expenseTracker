import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../expenses/presentation/bloc/expense_bloc.dart';

class AnalyticsPeriodToggle extends StatelessWidget {
  const AnalyticsPeriodToggle({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = ['Weekly', 'Monthly'];
    return Row(
      children: List.generate(labels.length, (index) {
        final selected = selectedIndex == index;
        return GestureDetector(
          onTap: () => onChanged(index),
          child: Padding(
            padding: EdgeInsets.only(right: index == 0 ? 24 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  labels[index],
                  style: TextStyle(
                    color: selected ? AppColors.emeraldSoft : Colors.white54,
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 3,
                  width: 42,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.emerald : Colors.transparent,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class StatPill extends StatelessWidget {
  const StatPill({super.key, required this.label, required this.positive});

  final String label;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final color = positive ? AppColors.emeraldSoft : const Color(0xFFFF6B6B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class SpendingTrendChart extends StatelessWidget {
  const SpendingTrendChart({super.key, required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 18,
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 18),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0A1F19), Color(0xFF06110E)],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 170,
            child: CustomPaint(
              painter: _TrendPainter(values),
              child: const SizedBox.expand(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                _AxisLabel('Mon'),
                _AxisLabel('Tue'),
                _AxisLabel('Wed'),
                _AxisLabel('Thu'),
                _AxisLabel('Fri'),
                _AxisLabel('Sat'),
                _AxisLabel('Sun'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AxisLabel extends StatelessWidget {
  const _AxisLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Colors.white60,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class CategoryStrip extends StatelessWidget {
  const CategoryStrip({super.key, required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: labels
          .map(
            (label) => Expanded(
              child: Text(
                label.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class SmartInsightCard extends StatelessWidget {
  const SmartInsightCard({
    super.key,
    required this.insightTitle,
    required this.insightBody,
  });

  final String insightTitle;
  final String insightBody;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 18,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF121F18), Color(0xFF091411)],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -18,
            child: Icon(
              Icons.tips_and_updates_outlined,
              size: 84,
              color: AppColors.emerald.withValues(alpha: 0.12),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: AppColors.emeraldSoft,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'SMART INSIGHT',
                    style: TextStyle(
                      color: AppColors.emeraldSoft,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                insightTitle,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                insightBody,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                ),
                child: const Text(
                  'View Details',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class EmptyAnalyticsCard extends StatelessWidget {
  const EmptyAnalyticsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 18,
      child: const Column(
        children: [
          Icon(Icons.insights_outlined, color: Colors.white38, size: 36),
          SizedBox(height: 14),
          Text(
            'Add a few expenses to unlock analytics.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.values);

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) {
      return;
    }

    final background = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x2200FFAA), Color(0x0000FFAA)],
      ).createShader(Offset.zero & size);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(18)),
      background,
    );

    final maxValue = values.reduce(math.max);
    final normalized = values
        .map(
          (value) => maxValue == 0 ? 0.6 : (value / maxValue).clamp(0.08, 1.0),
        )
        .toList();

    final path = Path();
    for (var i = 0; i < normalized.length; i++) {
      final x = (size.width / (normalized.length - 1)) * i;
      final y = size.height - (normalized[i] * (size.height - 18)) - 10;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final previousX = (size.width / (normalized.length - 1)) * (i - 1);
        final previousY =
            size.height - (normalized[i - 1] * (size.height - 18)) - 10;
        final controlX = (previousX + x) / 2;
        path.cubicTo(controlX, previousY, controlX, y, x, y);
      }
    }

    final glowPaint = Paint()
      ..color = AppColors.emerald.withValues(alpha: 0.35)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    final linePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF21F4A3), Color(0xFF31D681)],
      ).createShader(Offset.zero & size)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.values != values;
}

String analyticsCurrency(double value, String symbol) =>
    '$symbol${value.toStringAsFixed(2)}';

String buildInsight(ExpenseBloc bloc, bool monthly) {
  final now = DateTime.now();
  final categories = bloc.categoryBreakdown(now);
  if (categories.isEmpty) {
    return 'Start logging expenses to get tailored insights about your top spending areas.';
  }

  final sorted = categories.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final top = sorted.first;
  final scope = monthly ? 'this month' : 'this week';
  return 'Your ${top.key.toLowerCase()} expenses are the highest $scope. Review that category first to reduce overspending.';
}
