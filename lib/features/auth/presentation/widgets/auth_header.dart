import 'package:flutter/material.dart';
import 'package:municipality/core/l10n/app_strings.dart';
import 'package:municipality/core/theme/app_colors.dart';
import 'package:municipality/core/widgets/brand_logo.dart';
import 'package:municipality/features/settings/presentation/widgets/language_toggle.dart';

/// Brand + language switch bar at the top of the auth screen.
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          const BrandLogo(size: 40),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.appTitle,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                Text(
                  s.directorate,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.teal400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const LanguageToggle(),
        ],
      ),
    );
  }
}
