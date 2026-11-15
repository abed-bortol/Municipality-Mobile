/// `readValue` helpers for json_serializable that normalize Mongo documents
/// the same way the website's `utils/normalize.ts` does.
library;

/// `_id` (server) or `id` (our own toJson). Accepts populated references.
Object? readId(Map<dynamic, dynamic> json, String key) => idOf(
      json.containsKey('_id') ? json['_id'] : json[key],
    );

/// The id of a value that may be a plain id or a populated document.
String idOf(Object? value) => switch (value) {
      null => '',
      String() => value,
      Map() => (value['_id'] ?? value['id'] ?? '').toString(),
      _ => value.toString(),
    };

/// Empty strings become null so optional fields stay optional.
Object? readNonEmpty(Map<dynamic, dynamic> json, String key) {
  final value = json[key];
  return value is String && value.isEmpty ? null : value;
}

/// Numbers that may arrive as strings (`Number(...)` on the web).
Object? readDouble(Map<dynamic, dynamic> json, String key) =>
    switch (json[key]) {
      num v => v.toDouble(),
      String v => double.tryParse(v),
      _ => null,
    };
