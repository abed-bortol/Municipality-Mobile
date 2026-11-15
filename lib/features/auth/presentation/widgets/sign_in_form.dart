import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:municipality/l10n/l10n.dart';
import 'package:municipality/core/widgets/app_messenger.dart';
import 'package:municipality/core/widgets/error_banner.dart';
import 'package:municipality/core/widgets/primary_button.dart';
import 'package:municipality/features/auth/presentation/auth_controller.dart';
import 'package:municipality/features/auth/presentation/auth_error_message.dart';
import 'package:municipality/features/auth/presentation/widgets/auth_validators.dart';
import 'package:municipality/features/auth/presentation/widgets/email_field.dart';
import 'package:municipality/features/auth/presentation/widgets/password_field.dart';

class SignInForm extends ConsumerStatefulWidget {
  const SignInForm({super.key, required this.emailController});

  /// Owned by the parent so the email survives switching tabs.
  final TextEditingController emailController;

  @override
  ConsumerState<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends ConsumerState<SignInForm> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();

  AutovalidateMode _autovalidate = AutovalidateMode.disabled;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    setState(() {
      _error = null;
      _autovalidate = AutovalidateMode.onUserInteraction;
    });
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    try {
      await ref.read(authControllerProvider.notifier).signIn(
            email: widget.emailController.text,
            password: _password.text,
          );
      // Lets the OS offer to save the credentials in the password manager.
      TextInput.finishAutofillContext();
      showAppSnackBar(l10n.signInSuccess);
    } on Object catch (e) {
      if (mounted) setState(() => _error = authErrorMessage(e, l10n));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Form(
      key: _formKey,
      autovalidateMode: _autovalidate,
      child: AutofillGroup(
        child: Column(
          children: [
            ErrorBanner(message: _error),
            EmailField(controller: widget.emailController),
            const SizedBox(height: 14),
            PasswordField(
              controller: _password,
              label: l10n.password,
              autofillHint: AutofillHints.password,
              textInputAction: TextInputAction.done,
              onSubmitted: _submit,
              validator: (v) => AuthValidators.requiredPassword(v, l10n),
            ),
            const SizedBox(height: 22),
            PrimaryButton(
              label: l10n.signIn,
              icon: Icons.login,
              loading: _submitting,
              loadingLabel: l10n.signingIn,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
