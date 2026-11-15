import 'package:flutter/material.dart';
import 'package:municipality/l10n/l10n.dart';
import 'package:municipality/core/theme/app_colors.dart';

/// Placeholder for sections that are still being ported from the website.
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.construction_outlined,
                  size: 48, color: AppColors.teal400),
              const SizedBox(height: 16),
              Text(l10n.comingSoonTitle,
                  style: textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                l10n.comingSoonBody,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium
                    ?.copyWith(color: AppColors.slate400),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
