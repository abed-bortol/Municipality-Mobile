import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Dates in the current app language (`toLocaleDateString` on the website).
extension BuildContextDateFormat on BuildContext {
  String _locale() => Localizations.localeOf(this).toLanguageTag();

  /// e.g. "Nov 15, 2026".
  String formatDate(DateTime date) =>
      DateFormat.yMMMd(_locale()).format(date.toLocal());

  /// e.g. "Nov 15, 2026 14:05".
  String formatDateTime(DateTime date) =>
      DateFormat.yMMMd(_locale()).add_Hm().format(date.toLocal());
}
