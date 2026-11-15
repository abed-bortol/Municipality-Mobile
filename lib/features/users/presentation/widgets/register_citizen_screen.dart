import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:municipality/core/constants/tripoli_districts.dart';
import 'package:municipality/core/network/api_error_message.dart';
import 'package:municipality/core/theme/app_colors.dart';
import 'package:municipality/core/widgets/app_messenger.dart';
import 'package:municipality/core/widgets/error_banner.dart';
import 'package:municipality/core/widgets/primary_button.dart';
import 'package:municipality/core/widgets/section_card.dart';
import 'package:municipality/features/users/presentation/users_admin_providers.dart';
import 'package:municipality/l10n/l10n.dart';

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Website "Register New Citizen" modal (always creates a citizen).
class RegisterCitizenScreen extends ConsumerStatefulWidget {
  const RegisterCitizenScreen({super.key});

  @override
  ConsumerState<RegisterCitizenScreen> createState() =>
      _RegisterCitizenScreenState();
}

class _RegisterCitizenScreenState extends ConsumerState<RegisterCitizenScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController(text: '+961 ');
  final _password = TextEditingController();
  String _district = 'Al-Tal';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final phone = _phone.text.trim();
    try {
      final user = await ref
          .read(userAdminActionsProvider.notifier)
          .createCitizen(
            name: _name.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
            // The prefilled country code alone means "no phone".
            phone: phone == '+961' ? '' : phone,
            district: _district,
          );
      showAppSnackBar(l10n.citizenRegistered(user.name));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = apiErrorMessage(e, l10n);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.registerCitizen)),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: panelDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.accountPolicyTitle,
                      style: textTheme.labelLarge?.copyWith(
                        color: AppColors.teal300,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.accountPolicyBody,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.slate300,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.citizenOnlyRole,
                      style: textTheme.labelSmall?.copyWith(
                        color: AppColors.teal400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ErrorBanner(message: _error),
              TextFormField(
                controller: _name,
                enabled: !_saving,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: '${l10n.fullName} *',
                  hintText: l10n.fullNameHint,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? l10n.errNameRequired : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                enabled: !_saving,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: '${l10n.email} *',
                  hintText: 'citizen@tripoli.lb',
                  prefixIcon: const Icon(Icons.alternate_email),
                ),
                validator: (v) {
                  final text = (v ?? '').trim();
                  if (text.isEmpty) return l10n.errEmailRequired;
                  return _emailPattern.hasMatch(text)
                      ? null
                      : l10n.errEmailInvalid;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                enabled: !_saving,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.phone,
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _district,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.tripoliDistrict,
                  prefixIcon: const Icon(Icons.location_city_outlined),
                ),
                items: [
                  for (final d in tripoliDistricts)
                    DropdownMenuItem(
                      value: d,
                      child: Text(l10n.districtName(d)),
                    ),
                ],
                onChanged: _saving
                    ? null
                    : (v) => setState(() => _district = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                enabled: !_saving,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: '${l10n.initialPassword} *',
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                validator: (v) {
                  if ((v ?? '').isEmpty) return l10n.errPasswordRequired;
                  return v!.length < 6 ? l10n.errPasswordShort : null;
                },
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: l10n.registerCitizenBtn,
                loadingLabel: l10n.registeringCitizen,
                icon: Icons.person_add_alt_1,
                loading: _saving,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
