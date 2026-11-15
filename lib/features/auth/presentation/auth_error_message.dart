import 'package:municipality/core/l10n/app_strings.dart';
import 'package:municipality/core/network/api_exception.dart';

/// Localized, user-facing text for an auth failure. The server only sends
/// English messages, so the common cases are translated here.
String authErrorMessage(Object error, AppStrings s) => switch (error) {
      NetworkException() => s.errNetwork,
      ServerException(statusCode: 401) => s.errInvalidCredentials,
      ServerException(statusCode: 403) => s.errAccountDeactivated,
      ServerException(statusCode: 409) => s.errUserExists,
      ServerException(:final message) => message,
      _ => s.errUnexpected,
    };
