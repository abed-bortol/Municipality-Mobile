import 'package:flutter/material.dart';
import 'package:municipality/core/l10n/app_strings.dart';
import 'package:municipality/core/theme/app_colors.dart';

enum AuthMode { signIn, signUp }

/// Sign In / Sign Up segmented switch (website LoginPage mode tabs).
class AuthModeTabs extends StatelessWidget {
  const AuthModeTabs({super.key, required this.mode, required this.onChanged});

  final AuthMode mode;
  final ValueChanged<AuthMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.slate950.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate800),
      ),
      child: Row(
        children: [
          _tab(AuthMode.signIn, Icons.login, s.signIn),
          _tab(AuthMode.signUp, Icons.person_add_alt_1, s.signUp),
        ],
      ),
    );
  }

  Widget _tab(AuthMode value, IconData icon, String label) {
    final selected = mode == value;
    final color = selected ? Colors.white : AppColors.slate400;

    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: selected ? AppColors.teal600 : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          child: InkWell(
            onTap: () => onChanged(value),
            borderRadius: BorderRadius.circular(9),
            child: SizedBox(
              height: 44,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
