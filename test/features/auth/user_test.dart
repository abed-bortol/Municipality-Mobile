import 'package:flutter_test/flutter_test.dart';
import 'package:municipality/features/auth/domain/register_request.dart';
import 'package:municipality/features/auth/domain/user.dart';

void main() {
  group('User.fromJson', () {
    test('normalizes a server document like toUser() on the web', () {
      final user = User.fromJson({
        '_id': 'abc123',
        'name': 'Samer Karami',
        'email': 'samer@tripoli.lb',
        'role': 'HEALTH_OFFICER',
        'avatar': 'https://example.com/a.png',
        'badgeNumber': '',
        'district': '',
        'createdAt': '2026-01-02T03:04:05.000Z',
      });

      expect(user.id, 'abc123');
      expect(user.role, UserRole.healthOfficer);
      expect(user.district, 'Al-Tal');
      expect(user.avatarUrl, 'https://example.com/a.png');
      expect(user.badgeNumber, isNull);
      expect(user.createdAt, DateTime.utc(2026, 1, 2, 3, 4, 5));
    });

    test('unknown role falls back to citizen', () {
      expect(User.fromJson({'_id': '1', 'role': 'SYSTEM'}).role,
          UserRole.citizen);
    });

    test('round-trips through toJson (stored session)', () {
      const user = User(
        id: '1',
        name: 'A',
        email: 'a@b.c',
        role: UserRole.administrator,
        district: 'Al-Mina',
        avatarUrl: 'x.png',
      );
      expect(User.fromJson(user.toJson()), user);
    });
  });

  test('RegisterRequest omits a null district', () {
    const request = RegisterRequest(name: 'A', email: 'a@b.c', password: 'secret');
    expect(request.toJson().containsKey('district'), isFalse);
    expect(request.toJson()['phone'], '');
  });
}
