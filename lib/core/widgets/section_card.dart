import 'package:flutter/material.dart';
import 'package:municipality/core/theme/app_colors.dart';

/// Website panel: bg-slate-800/40 border-slate-700/50 rounded-2xl.
final panelDecoration = BoxDecoration(
  color: AppColors.slate800.withValues(alpha: 0.4),
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: AppColors.slate700.withValues(alpha: 0.5)),
);

/// Panel with a header row (icon, title, optional subtitle and action).
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: panelDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.teal400),
                const SizedBox(width: 8),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.slate400,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
