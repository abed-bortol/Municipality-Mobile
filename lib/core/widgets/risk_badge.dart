import 'package:flutter/material.dart';
import 'package:municipality/core/domain/risk_level.dart';
import 'package:municipality/l10n/l10n.dart';

/// Risk level pill (website `getRiskColor`: rose / orange / amber / emerald).
class RiskBadge extends StatelessWidget {
  const RiskBadge({super.key, required this.level});

  final RiskLevel level;

  static Color colorOf(RiskLevel level) => switch (level) {
    RiskLevel.critical => const Color(0xFFFB7185),
    RiskLevel.high => const Color(0xFFFB923C),
    RiskLevel.medium => const Color(0xFFFBBF24),
    RiskLevel.low => const Color(0xFF34D399),
  };

  @override
  Widget build(BuildContext context) => Pill(
    label: context.l10n.riskLabel(level.apiValue),
    color: colorOf(level),
  );
}

/// Small tinted label used for statuses and risk levels.
class Pill extends StatelessWidget {
  const Pill({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
