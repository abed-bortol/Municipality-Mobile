import 'package:dio/dio.dart';
import 'package:municipality/core/network/api_exception.dart';

/// Runs a Dio call and converts failures to [ApiException], so repositories
/// and the UI never see Dio types.
Future<T> apiCall<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on DioException catch (e) {
    throw ApiException.fromDio(e);
  }
}

/// Reads `body[key]` as a JSON object or throws [UnexpectedResponseException].
Map<String, dynamic> jsonObject(Object? body, String key) {
  final value = body is Map ? body[key] : null;
  if (value is Map<String, dynamic>) return value;
  throw const UnexpectedResponseException();
}

/// Reads `body[key]` as a list of JSON objects.
List<Map<String, dynamic>> jsonList(Object? body, String key) {
  final value = body is Map ? body[key] : null;
  if (value is List) return value.cast<Map<String, dynamic>>();
  throw const UnexpectedResponseException();
}
