/// API location, equivalent to the website's `API_BASE_URL` (APIConst.ts).
///
/// The phone can't reach `localhost` on your PC, so in development this
/// points at the PC's Wi-Fi IP. Override without code changes:
///   flutter run --dart-define=API_URL=http://192.168.1.20:5050/api
abstract final class Env {
  static const apiBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://192.168.1.7:5001/api',
  );

  static const apiTimeout = Duration(seconds: 15);
}
