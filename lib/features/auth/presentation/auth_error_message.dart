import 'package:municipality/l10n/l10n.dart';
import 'package:municipality/core/network/api_exception.dart';

/// Localized, user-facing text for an auth failure. The server only sends
/// English messages, so the common cases are translated here.
String authErrorMessage(Object error, AppLocalizations l10n) => switch (error) {
      NetworkException() => l10n.errNetwork,
      ServerException(statusCode: 401) => l10n.errInvalidCredentials,
      ServerException(statusCode: 403) => l10n.errAccountDeactivated,
      ServerException(statusCode: 409) => l10n.errUserExists,
      ServerException(:final message) => message,
      _ => l10n.errUnexpected,
    };
