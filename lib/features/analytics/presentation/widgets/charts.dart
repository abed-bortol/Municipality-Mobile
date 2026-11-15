import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:municipality/core/theme/app_colors.dart';
import 'package:municipality/l10n/l10n.dart';

/// One bar or slice: a translated label and its count.
typedef ChartEntry = ({String label, int count, Color color});

/// Labelled horizontal bars; reads better on a phone than the website's
/// rotated column labels.
class BarList extends StatelessWidget {
  const BarList({super.key, required this.entries});

  final List<ChartEntry> entries;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final max = entries.fold(0, (m, e) => math.max(m, e.count));

    return Column(
      children: [
        for (final e in entries)
          Semantics(
            label: l10n.chartValue(e.label, e.count),
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          e.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.slate300,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${e.count}',
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: max == 0 ? 0 : e.count / max,
                      minHeight: 10,
                      color: e.color,
                      backgroundColor: AppColors.slate800,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Donut with a legend (website risk level pie).
class DonutChart extends StatelessWidget {
  const DonutChart({super.key, required this.entries, this.size = 150});

  final List<ChartEntry> entries;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final total = entries.fold(0, (sum, e) => sum + e.count);

    return Column(
      children: [
        Semantics(
          label: entries
              .map((e) => l10n.chartValue(e.label, e.count))
              .join(', '),
          excludeSemantics: true,
          child: SizedBox.square(
            dimension: size,
            child: CustomPaint(
              painter: _DonutPainter(entries),
              child: Center(
                child: Text(
                  '$total',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            for (final e in entries)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: e.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.chartValue(e.label, e.count),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.slate300),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.entries);

  final List<ChartEntry> entries;

  static const _gap = 0.06; // radians between slices

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.18;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    final total = entries.fold(0, (sum, e) => sum + e.count);
    if (total == 0) {
      canvas.drawArc(
        rect,
        0,
        2 * math.pi,
        false,
        paint..color = AppColors.slate800,
      );
      return;
    }

    final slices = entries.where((e) => e.count > 0).toList();
    final gap = slices.length > 1 ? _gap : 0.0;
    var start = -math.pi / 2;
    for (final e in slices) {
      final sweep = 2 * math.pi * e.count / total;
      canvas.drawArc(
        rect,
        start + gap / 2,
        math.max(sweep - gap, 0.01),
        false,
        paint..color = e.color,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.entries != entries;
}
