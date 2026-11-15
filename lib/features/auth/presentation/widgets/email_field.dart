import 'package:flutter/material.dart';
import 'package:municipality/l10n/l10n.dart';
import 'package:municipality/features/auth/presentation/widgets/auth_validators.dart';

class EmailField extends StatelessWidget {
  const EmailField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      textDirection: TextDirection.ltr,
      autocorrect: false,
      autofillHints: const [AutofillHints.email, AutofillHints.username],
      decoration: InputDecoration(
        labelText: l10n.email,
        hintText: 'your.email@tripoli.lb',
        prefixIcon: const Icon(Icons.mail_outline),
      ),
      validator: (v) => AuthValidators.email(v, l10n),
    );
  }
}
