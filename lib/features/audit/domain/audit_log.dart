import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:municipality/core/utils/json_readers.dart';

part 'audit_log.freezed.dart';
part 'audit_log.g.dart';

/// Audit trail entry, normalized like `toAuditLog()` in the website's
/// `utils/normalize.ts`. [userRole] and [action] are raw server values.
@freezed
abstract class AuditLog with _$AuditLog {
  const factory AuditLog({
    @JsonKey(readValue: readId) required String id,
    @Default('') String userName,
    @Default('') String userRole,
    @Default('') String action,
    @Default('') String resource,
    @Default('') String details,
    @Default('') String ipAddress,
    DateTime? createdAt,
  }) = _AuditLog;

  factory AuditLog.fromJson(Map<String, dynamic> json) =>
      _$AuditLogFromJson(json);
}
