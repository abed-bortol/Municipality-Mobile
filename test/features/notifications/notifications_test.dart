import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:municipality/core/domain/risk_level.dart';
import 'package:municipality/core/network/api_exception.dart';
import 'package:municipality/features/alerts/domain/alert.dart';
import 'package:municipality/features/auth/domain/auth_state.dart';
import 'package:municipality/features/auth/domain/user.dart';
import 'package:municipality/features/auth/presentation/auth_controller.dart';
import 'package:municipality/features/notifications/data/notifications_repository.dart';
import 'package:municipality/features/notifications/domain/app_notification.dart';
import 'package:municipality/features/notifications/presentation/notifications_controller.dart';

class _Auth extends AuthController {
  _Auth(this.state0);

  final AuthState state0;

  @override
  Future<AuthState> build() async => state0;
}

class FakeNotificationsRepository implements NotificationsRepository {
  List<AppNotification> server = const [
    AppNotification(id: 'n1', title: 'Status update'),
    AppNotification(id: 'n2', title: 'Assigned', type: NotificationType.assignment),
    AppNotification(id: 'n3', title: 'Old', isRead: true),
  ];
  bool failWrites = false;
  final readIds = <String>[];
  int fetches = 0;

  @override
  Future<List<AppNotification>> getMine() async {
    fetches++;
    return server;
  }

  @override
  Future<void> markAsRead(String id) async {
    if (failWrites) throw const NetworkException('offline');
    readIds.add(id);
  }

  @override
  Future<void> markAllAsRead() async {
    if (failWrites) throw const NetworkException('offline');
    readIds.add('*');
  }
}

void main() {
  group('models', () {
    test('Alert.fromJson normalizes populated references', () {
      final alert = Alert.fromJson({
        '_id': 'a1',
        'alertCode': 'ALT-001',
        'alertType': 'CLUSTER_DETECTED',
        'relatedReportId': {'_id': 'r1', 'reportNumber': 'TRP-1'},
        'riskLevel': 'CRITICAL',
        'area': 'Al-Mina',
        'status': 'ACKNOWLEDGED',
        'assignedOfficer': {'name': 'Dr. Lina'},
      });
      expect(alert.relatedReportId, 'r1');
      expect(alert.relatedClusterId, isNull);
      expect(alert.alertType, AlertType.clusterDetected);
      expect(alert.riskLevel, RiskLevel.critical);
      expect(alert.status, AlertStatus.acknowledged);
      expect(alert.assignedOfficer, 'Dr. Lina');
    });

    test('Alert.fromJson tolerates an empty officer and unknown values', () {
      final alert = Alert.fromJson({
        '_id': 'a2',
        'alertType': 'NEW_KIND',
        'status': 'ARCHIVED',
        'assignedOfficer': <String, dynamic>{},
      });
      expect(alert.assignedOfficer, isNull);
      expect(alert.alertType, AlertType.criticalIncident);
      expect(alert.status, AlertStatus.active);
    });

    test('AppNotification.fromJson', () {
      final n = AppNotification.fromJson({
        '_id': 'n1',
        'title': 'Critical',
        'type': 'CRITICAL_ALERT',
        'isRead': true,
        'createdAt': '2026-11-15T08:00:00.000Z',
      });
      expect(n.type, NotificationType.criticalAlert);
      expect(n.isRead, isTrue);
      expect(n.createdAt, DateTime.utc(2026, 11, 15, 8));
    });
  });

  group('NotificationsController', () {
    late FakeNotificationsRepository repo;

    ProviderContainer container(AuthState auth) {
      final c = ProviderContainer(overrides: [
        authControllerProvider.overrideWith(() => _Auth(auth)),
        notificationsRepositoryProvider.overrideWithValue(repo),
      ]);
      addTearDown(c.dispose);
      // Keep the auto-dispose provider alive, like the app bar bell does.
      c.listen(notificationsControllerProvider, (_, _) {});
      return c;
    }

    setUp(() => repo = FakeNotificationsRepository());

    test('signed out -> empty, nothing fetched', () async {
      final c = container(const AuthState.unauthenticated());
      await c.read(authControllerProvider.future);
      expect(await c.read(notificationsControllerProvider.future), isEmpty);
      expect(repo.fetches, 0);
    });

    test('mark as read is optimistic and updates the unread count', () async {
      final c = container(const AuthState.authenticated(User(id: 'u1')));
      await c.read(authControllerProvider.future);
      await c.read(notificationsControllerProvider.future);
      expect(c.read(unreadNotificationCountProvider), 2);

      await c.read(notificationsControllerProvider.notifier).markAsRead('n1');
      expect(c.read(unreadNotificationCountProvider), 1);
      expect(repo.readIds, ['n1']);

      await c.read(notificationsControllerProvider.notifier).markAllAsRead();
      expect(c.read(unreadNotificationCountProvider), 0);
      expect(repo.readIds, ['n1', '*']);
    });

    test('a failed write reloads the server state', () async {
      final c = container(const AuthState.authenticated(User(id: 'u1')));
      await c.read(authControllerProvider.future);
      await c.read(notificationsControllerProvider.future);
      repo.failWrites = true;

      await c.read(notificationsControllerProvider.notifier).markAllAsRead();
      expect(c.read(unreadNotificationCountProvider), 2);
    });
  });
}
