import 'package:dio/dio.dart';
import 'package:municipality/core/network/api_call.dart';
import 'package:municipality/core/network/dio_provider.dart';
import 'package:municipality/features/reports/domain/new_report_request.dart';
import 'package:municipality/features/reports/domain/report.dart';
import 'package:municipality/features/reports/domain/reports_query.dart';
import 'package:municipality/features/reports/domain/reports_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'reports_repository_impl.g.dart';

@Riverpod(keepAlive: true)
ReportsRepository reportsRepository(Ref ref) =>
    ReportsRepositoryImpl(ref.watch(dioProvider));

/// `/api/reports` (server/src/routes/report.routes.js). Single-report
/// responses are `{ success, report }`, lists `{ reports, total, page, totalPages }`.
class ReportsRepositoryImpl implements ReportsRepository {
  ReportsRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<ReportsPage> getReports({
    ReportsQuery query = const ReportsQuery(),
    int page = 1,
    int limit = 20,
  }) =>
      apiCall(() async {
        final res = await _dio.get<Map<String, dynamic>>('/reports',
            queryParameters: {
              ...query.toQueryParameters(),
              'page': page,
              'limit': limit,
            });
        final body = res.data;
        return ReportsPage(
          reports: jsonList(body, 'reports').map(Report.fromJson).toList(),
          total: (body?['total'] as num?)?.toInt() ?? 0,
          page: (body?['page'] as num?)?.toInt() ?? page,
          totalPages: (body?['totalPages'] as num?)?.toInt() ?? 1,
        );
      });

  @override
  Future<Report> getReport(String id) => _report(
        () => _dio.get<Map<String, dynamic>>('/reports/$id'),
      );

  @override
  Future<Report> createReport(NewReportRequest request) => _report(
        () => _dio.post<Map<String, dynamic>>('/reports', data: request.toJson()),
      );

  @override
  Future<Report> updateStatus(
    String id,
    ReportStatus status, {
    String comment = '',
  }) =>
      _report(() => _dio.put<Map<String, dynamic>>(
            '/reports/$id/status',
            data: {'newStatus': status.apiValue, 'comment': comment},
          ));

  @override
  Future<Report> assignOfficer(String id, String officerId) =>
      _report(() => _dio.put<Map<String, dynamic>>(
            '/reports/$id/assign',
            data: {'officerId': officerId},
          ));

  @override
  Future<int> reassessRisks() => apiCall(() async {
        final res =
            await _dio.post<Map<String, dynamic>>('/reports/reassess-risk');
        return (res.data?['count'] as num?)?.toInt() ?? 0;
      });

  Future<Report> _report(
    Future<Response<Map<String, dynamic>>> Function() request,
  ) =>
      apiCall(() async {
        final res = await request();
        return Report.fromJson(jsonObject(res.data, 'report'));
      });
}
