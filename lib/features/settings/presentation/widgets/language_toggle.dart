import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:municipality/l10n/l10n.dart';
import 'package:municipality/core/theme/app_colors.dart';
import 'package:municipality/features/settings/presentation/locale_controller.dart';

/// "العربية / English" switch, like the website's language button.
class LanguageToggle extends ConsumerWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return OutlinedButton.icon(
      onPressed: () => ref
          .read(localeControllerProvider.notifier)
          .setLanguage(context.isArabic ? 'en' : 'ar'),
      icon: const Icon(Icons.language, size: 16, color: AppColors.teal400),
      label: Text(l10n.otherLanguage),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.slate300,
        backgroundColor: AppColors.slate900,
        side: const BorderSide(color: AppColors.slate800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        minimumSize: const Size(0, 40),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
