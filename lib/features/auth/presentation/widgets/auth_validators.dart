import 'package:municipality/core/l10n/app_strings.dart';

/// Form validators shared by the sign-in and sign-up forms. Same rules as
/// the website and server (password >= 6 chars, auth.service.js).
abstract final class AuthValidators {
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static const minPasswordLength = 6;

  static String? email(String? value, AppStrings s) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return s.errEmailRequired;
    if (!_emailPattern.hasMatch(email)) return s.errEmailInvalid;
    return null;
  }

  static String? requiredPassword(String? value, AppStrings s) =>
      (value == null || value.isEmpty) ? s.errPasswordRequired : null;

  static String? newPassword(String? value, AppStrings s) =>
      (value == null || value.length < minPasswordLength)
          ? s.errPasswordShort
          : null;

  static String? name(String? value, AppStrings s) =>
      (value == null || value.trim().isEmpty) ? s.errNameRequired : null;
}
