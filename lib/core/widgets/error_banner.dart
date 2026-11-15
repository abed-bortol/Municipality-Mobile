import 'package:flutter/material.dart';
import 'package:municipality/core/theme/app_colors.dart';

/// Inline error box (website: rose-500/10 bg, rose-500/30 border).
/// Animates open/closed; announced to screen readers when it appears.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.message});

  final String? message;

  static const _rose500 = Color(0xFFF43F5E);

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: message == null
          ? const SizedBox(width: double.infinity)
          : Semantics(
              liveRegion: true,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _rose500.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _rose500.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 18, color: AppColors.rose400),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        message!,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.rose300, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
