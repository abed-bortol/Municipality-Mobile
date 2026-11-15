import 'package:dio/dio.dart';
import 'package:municipality/core/network/api_call.dart';
import 'package:municipality/core/network/dio_provider.dart';
import 'package:municipality/features/investigations/domain/investigation.dart';
import 'package:municipality/features/reports/domain/report.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'investigations_repository.g.dart';

@Riverpod(keepAlive: true)
InvestigationsRepository investigationsRepository(Ref ref) =>
    InvestigationsRepository(ref.watch(dioProvider));

/// `/api/investigations` (server/src/routes/investigation.routes.js).
/// Staff only. All methods throw `ApiException`.
class InvestigationsRepository {
  InvestigationsRepository(this._dio);

  final Dio _dio;

  /// Newest first, with the related report populated.
  Future<List<Investigation>> getInvestigations() => apiCall(() async {
        final res = await _dio.get<Map<String, dynamic>>('/investigations');
        return jsonList(res.data, 'investigations')
            .map(Investigation.fromJson)
            .toList();
      });

  /// Opens an investigation (report VERIFIED -> IN_INVESTIGATION) or updates
  /// the report's open draft.
  Future<Investigation> save(String reportId, InvestigationDraft draft) =>
      apiCall(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          '/investigations',
          data: {'reportId': reportId, ...draft.toJson()},
        );
        return Investigation.fromJson(jsonObject(res.data, 'investigation'));
      });

  /// Edits any investigation, including a completed one.
  Future<Investigation> update(String id, InvestigationDraft draft) =>
      apiCall(() async {
        final res = await _dio.put<Map<String, dynamic>>(
          '/investigations/$id',
          data: draft.toJson(),
        );
        return Investigation.fromJson(jsonObject(res.data, 'investigation'));
      });

  /// Completes the investigation; the report moves IN_INVESTIGATION -> RESOLVED.
  Future<Report> finalize(String reportId, InvestigationDraft draft) =>
      apiCall(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          '/investigations/report/$reportId/finalize',
          data: draft.toJson(),
        );
        return Report.fromJson(jsonObject(res.data, 'report'));
      });
}
