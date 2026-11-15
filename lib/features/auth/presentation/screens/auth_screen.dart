import 'package:flutter/material.dart';
import 'package:municipality/l10n/l10n.dart';
import 'package:municipality/core/theme/app_colors.dart';
import 'package:municipality/features/auth/presentation/widgets/auth_header.dart';
import 'package:municipality/features/auth/presentation/widgets/auth_mode_tabs.dart';
import 'package:municipality/features/auth/presentation/widgets/sign_in_form.dart';
import 'package:municipality/features/auth/presentation/widgets/sign_up_form.dart';

/// Sign in / sign up, ported from the website's `LoginPage.tsx`.
///
/// Mobile adaptations: fields stacked vertically, per-field validation,
/// proper keyboards + autofill (password managers), password visibility
/// toggle, "next" moves between fields, and the form scrolls above the keyboard.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  AuthMode _mode = AuthMode.signIn;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final isSignIn = _mode == AuthMode.signIn;

    return Scaffold(
      backgroundColor: AppColors.slate950,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  children: [
                    const AuthHeader(),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.slate900.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.slate800),
                          ),
                          child: Column(
                            children: [
                              Text(
                                isSignIn ? l10n.signInTitle : l10n.signUpTitle,
                                textAlign: TextAlign.center,
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isSignIn ? l10n.signInSubtitle : l10n.signUpSubtitle,
                                textAlign: TextAlign.center,
                                style: textTheme.bodySmall
                                    ?.copyWith(color: AppColors.slate400),
                              ),
                              const SizedBox(height: 20),
                              AuthModeTabs(
                                mode: _mode,
                                onChanged: (mode) =>
                                    setState(() => _mode = mode),
                              ),
                              const SizedBox(height: 20),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: isSignIn
                                    ? SignInForm(
                                        key: const ValueKey(AuthMode.signIn),
                                        emailController: _email,
                                      )
                                    : SignUpForm(
                                        key: const ValueKey(AuthMode.signUp),
                                        emailController: _email,
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Text(
                        l10n.footer,
                        textAlign: TextAlign.center,
                        style: textTheme.labelSmall
                            ?.copyWith(color: AppColors.slate500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
