import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:municipality/core/network/api_error_message.dart';
import 'package:municipality/core/theme/app_colors.dart';
import 'package:municipality/core/widgets/app_messenger.dart';
import 'package:municipality/core/widgets/error_banner.dart';
import 'package:municipality/core/widgets/primary_button.dart';
import 'package:municipality/features/auth/domain/user.dart';
import 'package:municipality/features/users/presentation/users_admin_providers.dart';
import 'package:municipality/l10n/l10n.dart';

const _amber = Color(0xFFFBBF24);

/// Website "Assign Role & Credentials" modal.
Future<void> showAssignRoleSheet(BuildContext context, User user) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _AssignRoleForm(user: user),
    );

class _AssignRoleForm extends ConsumerStatefulWidget {
  const _AssignRoleForm({required this.user});

  final User user;

  @override
  ConsumerState<_AssignRoleForm> createState() => _AssignRoleFormState();
}

class _AssignRoleFormState extends ConsumerState<_AssignRoleForm> {
  late UserRole _role = widget.user.role == UserRole.citizen
      ? UserRole.healthOfficer
      : widget.user.role;
  late final _badge = TextEditingController(text: widget.user.badgeNumber);
  // A citizen's default title ("Resident Reporter") is not carried over.
  late final _title = TextEditingController(
    text: widget.user.role == UserRole.healthOfficer ? widget.user.title : '',
  );
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _badge.dispose();
    _title.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final l10n = context.l10n;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await ref
          .read(userAdminActionsProvider.notifier)
          .updateRole(
            widget.user,
            _role,
            badgeNumber: _badge.text,
            // The website keeps no custom title for administrators.
            title: _role == UserRole.healthOfficer ? _title.text : '',
          );
      showAppSnackBar(
        l10n.roleAssigned(updated.name, l10n.roleLabel(updated.role.apiValue)),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = apiErrorMessage(e, l10n);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final user = widget.user;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.assignRoleTitle,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              user.name,
              style: textTheme.bodySmall?.copyWith(color: AppColors.slate400),
            ),
            const SizedBox(height: 4),
            Text(
              '${l10n.currentRole(l10n.roleLabel(user.role.apiValue))} · '
              '${l10n.districtName(user.district)}',
              style: textTheme.bodySmall?.copyWith(color: AppColors.teal300),
            ),
            const SizedBox(height: 16),
            ErrorBanner(message: _error),
            Text(
              l10n.newRoleLabel,
              style: textTheme.labelLarge?.copyWith(color: AppColors.slate300),
            ),
            const SizedBox(height: 6),
            SegmentedButton<UserRole>(
              showSelectedIcon: false,
              segments: [
                for (final role in UserRole.values)
                  ButtonSegment(
                    value: role,
                    label: Text(
                      l10n.roleLabel(role.apiValue),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              selected: {_role},
              onSelectionChanged: _saving
                  ? null
                  : (selection) => setState(() => _role = selection.first),
            ),
            const SizedBox(height: 16),
            if (_role != UserRole.citizen) ...[
              Text(
                _role == UserRole.healthOfficer
                    ? l10n.officerCredentials
                    : l10n.adminPrivileges,
                style: textTheme.labelLarge?.copyWith(
                  color: AppColors.teal300,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _badge,
                enabled: !_saving,
                decoration: InputDecoration(
                  labelText: l10n.badgeNumberLabel,
                  hintText: _role == UserRole.healthOfficer
                      ? 'TRP-OFF-18'
                      : 'TRP-ADM-18',
                  helperText: l10n.badgeAutoHint,
                  helperMaxLines: 2,
                  prefixIcon: const Icon(Icons.badge_outlined),
                ),
              ),
              if (_role == UserRole.healthOfficer) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _title,
                  enabled: !_saving,
                  decoration: InputDecoration(
                    labelText: l10n.designationTitle,
                    hintText: 'Municipal Field Inspector',
                    helperText: l10n.designationHint,
                    prefixIcon: const Icon(Icons.work_outline),
                  ),
                ),
              ],
            ] else if (user.role != UserRole.citizen)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _amber.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: _amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.revokeNotice,
                        style: textTheme.bodySmall?.copyWith(color: _amber),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: l10n.confirmRoleAssignment,
              loadingLabel: l10n.assigningRole,
              icon: Icons.verified_user_outlined,
              loading: _saving,
              onPressed: _confirm,
            ),
          ],
        ),
      ),
    );
  }
}
