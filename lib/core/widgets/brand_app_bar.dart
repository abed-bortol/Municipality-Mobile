import 'package:flutter/material.dart';
import 'package:municipality/core/l10n/app_strings.dart';
import 'package:municipality/core/theme/app_colors.dart';
import 'package:municipality/core/widgets/brand_logo.dart';

/// App bar with the website Navbar's brand block: logo tile, app title and
/// country chip. Used on the shell's root screens.
class BrandAppBar extends StatelessWidget implements PreferredSizeWidget {
  const BrandAppBar({super.key, this.actions});

  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final textTheme = Theme.of(context).textTheme;

    return AppBar(
      titleSpacing: 16,
      title: Row(
        children: [
          const BrandLogo(size: 36),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              s.appTitle,
              overflow: TextOverflow.ellipsis,
              style:
                  textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.teal950,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.teal800.withValues(alpha: 0.8)),
            ),
            child: Text(
              s.isAr ? s.country : s.country.toUpperCase(),
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.teal300,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
      actions: actions,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1),
      ),
    );
  }
}
