import 'package:municipality/core/network/api_exception.dart';
import 'package:municipality/l10n/l10n.dart';

/// User-facing text for a failed API call: the server's message when it sent
/// one (e.g. "Invalid status transition"), otherwise a localized fallback.
String apiErrorMessage(Object error, AppLocalizations l10n) => switch (error) {
      NetworkException() => l10n.errNetwork,
      ServerException(:final message) when message.isNotEmpty => message,
      _ => l10n.errUnexpected,
    };
