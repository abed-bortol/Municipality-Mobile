import 'package:municipality/features/auth/domain/user.dart';
import 'package:municipality/features/users/data/users_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'users_admin_providers.g.dart';

/// Users directory (administrators only).
@riverpod
Future<List<User>> users(Ref ref) =>
    ref.watch(usersRepositoryProvider).getUsers();

/// Website AdminUsersManagement search: name, email or district (raw or
/// translated), within the selected role.
List<User> filterUsers(
  List<User> users, {
  String query = '',
  UserRole? role,
  String Function(String district)? districtLabel,
}) {
  final q = query.trim().toLowerCase();
  return [
    for (final u in users)
      if ((role == null || u.role == role) &&
          (q.isEmpty ||
              u.name.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q) ||
              u.district.toLowerCase().contains(q) ||
              (districtLabel?.call(u.district).toLowerCase().contains(q) ??
                  false)))
        u,
  ];
}

/// Account changes. Both throw `ApiException`; on success the directory
/// and the officer picker are refreshed.
@Riverpod(keepAlive: true)
class UserAdminActions extends _$UserAdminActions {
  @override
  void build() {}

  Future<User> createCitizen({
    required String name,
    required String email,
    required String password,
    String phone = '',
    String? district,
  }) async {
    final user = await ref
        .read(usersRepositoryProvider)
        .createCitizen(
          name: name,
          email: email,
          password: password,
          phone: phone,
          district: district,
        );
    _refresh();
    return user;
  }

  Future<User> updateRole(
    User user,
    UserRole role, {
    String badgeNumber = '',
    String title = '',
  }) async {
    final updated = await ref
        .read(usersRepositoryProvider)
        .updateRole(
          user.id,
          role,
          // Citizens lose their badge and title on the server.
          badgeNumber: role == UserRole.citizen ? '' : badgeNumber.trim(),
          title: role == UserRole.citizen ? '' : title.trim(),
        );
    _refresh();
    return updated;
  }

  void _refresh() => ref
    ..invalidate(usersProvider)
    ..invalidate(officersProvider);
}
