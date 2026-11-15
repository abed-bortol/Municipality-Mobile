import 'package:municipality/l10n/l10n.dart';

/// Form validators shared by the sign-in and sign-up forms. Same rules as
/// the website and server (password >= 6 chars, auth.service.js).
abstract final class AuthValidators {
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static const minPasswordLength = 6;

  static String? email(String? value, AppLocalizations l10n) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return l10n.errEmailRequired;
    if (!_emailPattern.hasMatch(email)) return l10n.errEmailInvalid;
    return null;
  }

  static String? requiredPassword(String? value, AppLocalizations l10n) =>
      (value == null || value.isEmpty) ? l10n.errPasswordRequired : null;

  static String? newPassword(String? value, AppLocalizations l10n) =>
      (value == null || value.length < minPasswordLength)
          ? l10n.errPasswordShort
          : null;

  static String? name(String? value, AppLocalizations l10n) =>
      (value == null || value.trim().isEmpty) ? l10n.errNameRequired : null;
}
