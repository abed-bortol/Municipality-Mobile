import 'package:dio/dio.dart';
import 'package:municipality/core/network/api_call.dart';
import 'package:municipality/core/network/dio_provider.dart';
import 'package:municipality/features/audit/domain/audit_log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'audit_repository.g.dart';

@Riverpod(keepAlive: true)
AuditRepository auditRepository(Ref ref) =>
    AuditRepository(ref.watch(dioProvider));

/// Latest entries (administrators only); same 200 cap as the website.
@riverpod
Future<List<AuditLog>> auditLogs(Ref ref) =>
    ref.watch(auditRepositoryProvider).getLogs();

/// `/api/audit-logs` (server/src/routes/audit.routes.js).
class AuditRepository {
  AuditRepository(this._dio);

  final Dio _dio;

  Future<List<AuditLog>> getLogs({int limit = 200}) => apiCall(() async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/audit-logs',
      queryParameters: {'limit': limit},
    );
    return jsonList(res.data, 'logs').map(AuditLog.fromJson).toList();
  });
}
