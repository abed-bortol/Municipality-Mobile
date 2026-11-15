import 'package:dio/dio.dart';
import 'package:municipality/core/config/env.dart';
import 'package:municipality/core/network/auth_interceptor.dart';
import 'package:municipality/features/auth/data/auth_local_data_source.dart';
import 'package:municipality/features/auth/presentation/auth_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dio_provider.g.dart';

/// Shared HTTP client for every feature's remote data source.
@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  final dio = Dio(BaseOptions(
    baseUrl: Env.apiBaseUrl,
    connectTimeout: Env.apiTimeout,
    receiveTimeout: Env.apiTimeout,
    sendTimeout: Env.apiTimeout,
    contentType: Headers.jsonContentType,
    responseType: ResponseType.json,
    headers: {'Accept': 'application/json'},
  ));

  dio.interceptors.add(AuthInterceptor(
    readToken: () => ref.read(authLocalDataSourceProvider).readToken(),
    // Read lazily (not during build) so there is no provider cycle.
    onUnauthorized: () =>
        ref.read(authControllerProvider.notifier).onSessionExpired(),
  ));

  ref.onDispose(dio.close);
  return dio;
}
