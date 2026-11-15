import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:municipality/core/router/app_routes.dart';
import 'package:municipality/core/widgets/user_avatar.dart';
import 'package:municipality/l10n/l10n.dart';
import 'package:municipality/core/theme/app_colors.dart';
import 'package:municipality/features/auth/domain/user.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.slate800.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate700),
      ),
      child: Row(
        children: [
          UserAvatar(name: user.name, url: user.avatarUrl),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name,
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(user.email,
                    textDirection: TextDirection.ltr,
                    style: textTheme.bodySmall
                        ?.copyWith(color: AppColors.slate400)),
                if (user.title != null)
                  Text(user.title!,
                      style: textTheme.bodySmall
                          ?.copyWith(color: AppColors.teal400)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _Chip(
                      icon: Icons.badge_outlined,
                      label: l10n.roleLabel(user.role.apiValue),
                    ),
                    _Chip(
                      icon: Icons.location_on_outlined,
                      label: l10n.districtName(user.district),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.editProfile,
            onPressed: () => context.go(AppRoutes.profile),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.teal500.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.teal500.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.teal400),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.teal300,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
