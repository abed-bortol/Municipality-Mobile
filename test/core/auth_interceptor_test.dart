import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:municipality/core/network/api_exception.dart';
import 'package:municipality/core/network/auth_interceptor.dart';

/// Answers every request with [status] and records the request headers.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.status);

  final int status;
  Map<String, dynamic>? lastHeaders;

  @override
  Future<ResponseBody> fetch(RequestOptions options, _, _) async {
    lastHeaders = options.headers;
    return ResponseBody.fromString(
      '{"message":"Invalid credentials"}',
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _StubAdapter adapter;
  late int expiredCalls;

  Dio buildDio(int status, {String? token = 'tok'}) {
    adapter = _StubAdapter(status);
    expiredCalls = 0;
    return Dio(BaseOptions(baseUrl: 'http://api.test'))
      ..httpClientAdapter = adapter
      ..interceptors.add(AuthInterceptor(
        readToken: () async => token,
        onUnauthorized: () => expiredCalls++,
      ));
  }

  test('adds the Bearer token', () async {
    await buildDio(200).get<void>('/reports');
    expect(adapter.lastHeaders?['Authorization'], 'Bearer tok');
  });

  test('401 on a data call reports session expiry', () async {
    final dio = buildDio(401);
    await expectLater(dio.get<void>('/reports'), throwsA(isA<DioException>()));
    expect(expiredCalls, 1);
  });

  test('401 on /auth/ (wrong password) does not', () async {
    final dio = buildDio(401);
    await expectLater(
        dio.post<void>('/auth/login'), throwsA(isA<DioException>()));
    expect(expiredCalls, 0);
  });

  test('ApiException.fromDio keeps the server message', () async {
    try {
      await buildDio(401).post<void>('/auth/login');
      fail('should throw');
    } on DioException catch (e) {
      expect(
        ApiException.fromDio(e),
        isA<ServerException>()
            .having((e) => e.statusCode, 'status', 401)
            .having((e) => e.message, 'message', 'Invalid credentials'),
      );
    }
  });
}
