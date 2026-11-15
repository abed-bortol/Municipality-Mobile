import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:municipality/core/constants/tripoli_districts.dart';
import 'package:municipality/l10n/l10n.dart';
import 'package:municipality/core/theme/app_colors.dart';
import 'package:municipality/core/widgets/app_messenger.dart';
import 'package:municipality/core/widgets/error_banner.dart';
import 'package:municipality/core/widgets/primary_button.dart';
import 'package:municipality/features/auth/domain/register_request.dart';
import 'package:municipality/features/auth/presentation/auth_controller.dart';
import 'package:municipality/features/auth/presentation/auth_error_message.dart';
import 'package:municipality/features/auth/presentation/widgets/auth_validators.dart';
import 'package:municipality/features/auth/presentation/widgets/email_field.dart';
import 'package:municipality/features/auth/presentation/widgets/password_field.dart';

class SignUpForm extends ConsumerStatefulWidget {
  const SignUpForm({super.key, required this.emailController});

  /// Owned by the parent so the email survives switching tabs.
  final TextEditingController emailController;

  @override
  ConsumerState<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends ConsumerState<SignUpForm> {
  static const _phonePrefix = '+961 ';

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController(text: _phonePrefix);
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  String _district = tripoliDistricts.first;

  AutovalidateMode _autovalidate = AutovalidateMode.disabled;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _phone, _password, _confirmPassword]) {
      c.dispose();
    }
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
    final phone = _phone.text.trim();
    try {
      await ref.read(authControllerProvider.notifier).register(RegisterRequest(
            name: _name.text.trim(),
            email: widget.emailController.text.trim(),
            phone: phone == _phonePrefix.trim() ? '' : phone,
            district: _district,
            password: _password.text,
          ));
      TextInput.finishAutofillContext();
      showAppSnackBar(l10n.signUpSuccess);
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
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              decoration: InputDecoration(
                labelText: l10n.fullName,
                hintText: l10n.fullNameHint,
                prefixIcon: const Icon(Icons.person_outline),
              ),
              validator: (v) => AuthValidators.name(v, l10n),
            ),
            const SizedBox(height: 14),
            EmailField(controller: widget.emailController),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              textDirection: TextDirection.ltr,
              autofillHints: const [AutofillHints.telephoneNumber],
              decoration: InputDecoration(
                labelText: '${l10n.phone} (${l10n.optional})',
                hintText: '+961 0 123456',
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _district,
              isExpanded: true,
              dropdownColor: AppColors.slate800,
              borderRadius: BorderRadius.circular(12),
              decoration: InputDecoration(
                labelText: l10n.district,
                prefixIcon: const Icon(Icons.location_on_outlined),
              ),
              items: [
                for (final d in tripoliDistricts)
                  DropdownMenuItem(value: d, child: Text(l10n.districtName(d))),
              ],
              onChanged: (v) => setState(() => _district = v ?? _district),
            ),
            const SizedBox(height: 14),
            PasswordField(
              controller: _password,
              label: l10n.password,
              autofillHint: AutofillHints.newPassword,
              textInputAction: TextInputAction.next,
              validator: (v) => AuthValidators.newPassword(v, l10n),
            ),
            const SizedBox(height: 14),
            PasswordField(
              controller: _confirmPassword,
              label: l10n.confirmPassword,
              autofillHint: AutofillHints.newPassword,
              textInputAction: TextInputAction.done,
              onSubmitted: _submit,
              validator: (v) =>
                  v != _password.text ? l10n.errPasswordMismatch : null,
            ),
            const SizedBox(height: 22),
            PrimaryButton(
              label: l10n.createAccountAndEnter,
              icon: Icons.person_add_alt_1,
              loading: _submitting,
              loadingLabel: l10n.creatingAccount,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
