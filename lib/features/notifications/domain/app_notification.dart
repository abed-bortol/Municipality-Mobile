import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:municipality/core/utils/json_readers.dart';

part 'app_notification.freezed.dart';
part 'app_notification.g.dart';

enum NotificationType {
  @JsonValue('STATUS_UPDATE')
  statusUpdate,
  @JsonValue('CRITICAL_ALERT')
  criticalAlert,
  @JsonValue('CLUSTER_ALERT')
  clusterAlert,
  @JsonValue('ASSIGNMENT')
  assignment,
  @JsonValue('SYSTEM')
  system,
}

/// In-app notification for the signed-in user (`toNotification()` on the
/// website). Named to avoid Flutter's `Notification`.
@freezed
abstract class AppNotification with _$AppNotification {
  const factory AppNotification({
    @JsonKey(readValue: readId) required String id,
    @Default('') String title,
    @Default('') String message,
    @JsonKey(unknownEnumValue: NotificationType.system)
    @Default(NotificationType.statusUpdate)
    NotificationType type,
    @Default(false) bool isRead,
    DateTime? createdAt,
  }) = _AppNotification;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationFromJson(json);
}
