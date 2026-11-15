import 'package:dio/dio.dart';

/// Adds `Authorization: Bearer <token>` and reports a rejected token,
/// mirroring the request/response interceptors in the website's axios client.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.readToken, required this.onUnauthorized});

  final Future<String?> Function() readToken;

  /// Called on 401 for non-`/auth/` requests that carried a token.
  final void Function() onUnauthorized;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await readToken();
    if (token != null) options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final sentToken = err.requestOptions.headers.containsKey('Authorization');
    final isAuthCall = err.requestOptions.path.startsWith('/auth/');
    if (err.response?.statusCode == 401 && sentToken && !isAuthCall) {
      onUnauthorized();
    }
    handler.next(err);
  }
}
