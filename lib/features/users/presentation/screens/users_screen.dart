import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:municipality/core/theme/app_colors.dart';
import 'package:municipality/core/widgets/empty_state.dart';
import 'package:municipality/core/widgets/risk_badge.dart';
import 'package:municipality/core/widgets/section_card.dart';
import 'package:municipality/core/widgets/skeleton.dart';
import 'package:municipality/features/auth/domain/auth_state.dart';
import 'package:municipality/features/auth/domain/user.dart';
import 'package:municipality/features/auth/presentation/auth_controller.dart';
import 'package:municipality/features/users/presentation/users_admin_providers.dart';
import 'package:municipality/features/users/presentation/widgets/assign_role_sheet.dart';
import 'package:municipality/features/users/presentation/widgets/register_citizen_screen.dart';
import 'package:municipality/l10n/l10n.dart';

const _purple = Color(0xFFA78BFA);
const _blue = Color(0xFF60A5FA);

Color roleColor(UserRole role) => switch (role) {
  UserRole.administrator => _purple,
  UserRole.healthOfficer => AppColors.teal400,
  UserRole.citizen => _blue,
};

/// Website AdminUsersManagement: directory with search, role filter,
/// citizen registration and role assignment (administrators only).
class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  final _search = TextEditingController();
  UserRole? _role;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final users = ref.watch(usersProvider);
    final all = users.value ?? const <User>[];
    final shown = filterUsers(
      all,
      query: _search.text,
      role: _role,
      districtLabel: l10n.districtName,
    );
    final meId = switch (ref.watch(authControllerProvider).value) {
      Authenticated(:final user) => user.id,
      _ => null,
    };
    int count(UserRole role) => all.where((u) => u.role == role).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.usersOfficers),
        actions: [
          IconButton(
            tooltip: l10n.refresh,
            onPressed: () => ref.invalidate(usersProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            fullscreenDialog: true,
            builder: (_) => const RegisterCitizenScreen(),
          ),
        ),
        icon: const Icon(Icons.person_add_alt_1),
        label: Text(l10n.registerCitizen),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.refresh(usersProvider.future).then((_) {}, onError: (_) {}),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              sliver: SliverList.list(
                children: [
                  Text(
                    l10n.usersDirectoryTitle,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    l10n.usersDirectoryDesc,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.slate400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.totalRegisteredUsers(all.length),
                    style: textTheme.labelMedium?.copyWith(
                      color: AppColors.slate300,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: panelDecoration,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          color: AppColors.teal400,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '${l10n.rbacRuleTitle}: ',
                                  style: const TextStyle(
                                    color: AppColors.teal300,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                TextSpan(text: l10n.rbacRuleBody),
                              ],
                            ),
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.slate300,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: l10n.searchUsersHint,
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _chip(l10n.allUsersCount(all.length), null),
                        _chip(
                          l10n.healthOfficersCount(
                            count(UserRole.healthOfficer),
                          ),
                          UserRole.healthOfficer,
                        ),
                        _chip(
                          l10n.citizensCount(count(UserRole.citizen)),
                          UserRole.citizen,
                        ),
                        _chip(
                          l10n.administratorsCount(
                            count(UserRole.administrator),
                          ),
                          UserRole.administrator,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            switch (users) {
              AsyncValue(hasValue: true) when shown.isEmpty =>
                SliverToBoxAdapter(
                  child: EmptyState(
                    icon: Icons.person_search_outlined,
                    message: l10n.noUsersFound,
                  ),
                ),
              AsyncValue(hasValue: true) => SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                sliver: SliverList.separated(
                  itemCount: shown.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) =>
                      _UserCard(user: shown[i], isMe: shown[i].id == meId),
                ),
              ),
              AsyncError() => SliverToBoxAdapter(
                child: LoadErrorView(
                  onRetry: () => ref.invalidate(usersProvider),
                ),
              ),
              _ => SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.separated(
                  itemCount: 5,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, _) => const Skeleton(height: 96),
                ),
              ),
            },
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, UserRole? role) => Padding(
    padding: const EdgeInsetsDirectional.only(end: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: _role == role,
      onSelected: (_) => setState(() => _role = role),
      selectedColor: (role == null ? _purple : roleColor(role)).withValues(
        alpha: 0.35,
      ),
      showCheckmark: false,
    ),
  );
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.isMe});

  final User user;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final contact = [user.email, user.phone].where((s) => s.isNotEmpty);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: panelDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 6),
                Pill(label: l10n.youBadge, color: _purple),
              ],
              const Spacer(),
              Pill(
                label: l10n.roleLabel(user.role.apiValue),
                color: roleColor(user.role),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            contact.join(' · '),
            style: textTheme.bodySmall?.copyWith(color: AppColors.slate400),
          ),
          if (user.title != null)
            Text(
              user.title!,
              style: textTheme.bodySmall?.copyWith(color: AppColors.teal400),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.place_outlined,
                size: 16,
                color: AppColors.slate400,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  l10n.districtName(user.district),
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.slate300,
                  ),
                ),
              ),
              if (user.badgeNumber != null)
                Pill(label: user.badgeNumber!, color: AppColors.teal300),
              const SizedBox(width: 4),
              TextButton.icon(
                onPressed: () => showAssignRoleSheet(context, user),
                icon: const Icon(Icons.workspace_premium_outlined, size: 18),
                label: Text(l10n.assignRoleAction),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
