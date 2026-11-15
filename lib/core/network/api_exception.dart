import 'package:dio/dio.dart';

/// Failure from the API, normalized like the website's axios interceptor
/// (`utils/axios.ts`): the server's `message` plus the HTTP status.
/// Presentation code maps it to a localized message.
sealed class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  factory ApiException.fromDio(DioException e) {
    final response = e.response;
    if (response == null) return NetworkException(e.message ?? e.type.name);

    final data = response.data;
    final status = response.statusCode ?? 0;
    final serverMessage = data is Map ? data['message'] as String? : null;
    return ServerException(
      statusCode: status,
      message: serverMessage ?? 'Request failed ($status)',
    );
  }

  @override
  String toString() => '$runtimeType: $message';
}

/// No response: offline, timeout, DNS, server down.
final class NetworkException extends ApiException {
  const NetworkException(super.message);
}

/// The server answered with a non-2xx status.
final class ServerException extends ApiException {
  const ServerException({required this.statusCode, required String message})
      : super(message);

  final int statusCode;

  /// Token missing/expired (401) or account not allowed (403).
  bool get isAuthError => statusCode == 401 || statusCode == 403;
}

/// The server answered 2xx but not with the expected shape.
final class UnexpectedResponseException extends ApiException {
  const UnexpectedResponseException()
      : super('Unexpected response from the server.');
}
