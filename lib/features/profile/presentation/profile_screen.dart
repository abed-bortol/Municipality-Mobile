import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:municipality/core/constants/tripoli_districts.dart';
import 'package:municipality/core/network/api_error_message.dart';
import 'package:municipality/core/theme/app_colors.dart';
import 'package:municipality/core/widgets/app_messenger.dart';
import 'package:municipality/core/widgets/error_banner.dart';
import 'package:municipality/core/widgets/primary_button.dart';
import 'package:municipality/core/widgets/section_card.dart';
import 'package:municipality/core/widgets/user_avatar.dart';
import 'package:municipality/features/auth/domain/auth_state.dart';
import 'package:municipality/features/auth/domain/profile_update.dart';
import 'package:municipality/features/auth/domain/user.dart';
import 'package:municipality/features/auth/presentation/auth_controller.dart';
import 'package:municipality/l10n/l10n.dart';

/// Quick picks from the website's UserProfileModal.
const avatarPresets = [
  'https://images.unsplash.com/photo-1622253692010-333f2da6031d?auto=format&fit=crop&w=200&q=80',
  'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
  'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=200&q=80',
  'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=200&q=80',
  'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=200&q=80',
  'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&w=200&q=80',
];

/// Website UserProfileModal as a screen: the signed-in user's own details.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = switch (ref.watch(authControllerProvider).value) {
      Authenticated(:final user) => user,
      _ => null,
    };
    // Signed out: the router is already leaving this screen.
    if (user == null) return const Scaffold();
    return _ProfileForm(user: user);
  }
}

class _ProfileForm extends ConsumerStatefulWidget {
  const _ProfileForm({required this.user});

  final User user;

  @override
  ConsumerState<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<_ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.user.name);
  late final _phone = TextEditingController(text: widget.user.phone);
  late final _title = TextEditingController(text: widget.user.title);
  late final _bio = TextEditingController(text: widget.user.bio);
  late final _avatar = TextEditingController(text: widget.user.avatarUrl);
  late String _district = tripoliDistricts.contains(widget.user.district)
      ? widget.user.district
      : tripoliDistricts.first;
  bool _saving = false;
  bool _dirty = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _phone, _title, _bio, _avatar]) {
      c.dispose();
    }
    super.dispose();
  }

  void _setAvatar(String url) => setState(() {
    _avatar.text = url;
    _dirty = true;
  });

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final l10n = context.l10n;
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .updateProfile(
            ProfileUpdate(
              name: _name.text.trim(),
              phone: _phone.text.trim(),
              district: _district,
              title: _title.text.trim(),
              bio: _bio.text.trim(),
              avatarUrl: _avatar.text.trim(),
            ),
          );
      showAppSnackBar(l10n.profileUpdated);
      if (mounted) {
        setState(() => _dirty = false);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = apiErrorMessage(e, l10n);
        });
      }
    }
  }

  Future<bool> _confirmDiscard() async {
    final l10n = context.l10n;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.discardChangesTitle),
            content: Text(l10n.discardChangesBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.discard),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final user = widget.user;

    return PopScope(
      canPop: !_dirty || _saving,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && context.mounted) {
          setState(() => _dirty = false);
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.userProfile)),
        body: Form(
          key: _formKey,
          onChanged: () {
            if (!_dirty) setState(() => _dirty = true);
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.profileSubtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.slate400,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: panelDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          UserAvatar(
                            name: _name.text,
                            url: _avatar.text,
                            radius: 32,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _name.text,
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  l10n.roleLabel(user.role.apiValue),
                                  style: textTheme.labelMedium?.copyWith(
                                    color: AppColors.teal400,
                                  ),
                                ),
                                Text(
                                  [
                                    l10n.userIdLabel(user.id),
                                    ?user.badgeNumber,
                                  ].join(' • '),
                                  style: textTheme.labelSmall?.copyWith(
                                    color: AppColors.slate400,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _avatar,
                        enabled: !_saving,
                        keyboardType: TextInputType.url,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: l10n.profilePictureUrl,
                          hintText: 'https://images.unsplash.com/...',
                          prefixIcon: const Icon(Icons.link),
                          suffixIcon: _avatar.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: l10n.removeAvatar,
                                  onPressed: _saving
                                      ? null
                                      : () => _setAvatar(''),
                                  icon: const Icon(Icons.close),
                                ),
                        ),
                        validator: (value) {
                          final text = (value ?? '').trim();
                          if (text.isEmpty) return null;
                          final uri = Uri.tryParse(text);
                          final ok =
                              uri != null &&
                              (uri.scheme == 'http' || uri.scheme == 'https') &&
                              uri.host.isNotEmpty;
                          return ok ? null : l10n.errUrlInvalid;
                        },
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.selectAvatar,
                        style: textTheme.labelMedium?.copyWith(
                          color: AppColors.slate400,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final (i, url) in avatarPresets.indexed)
                              Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  end: 8,
                                ),
                                child: _AvatarChoice(
                                  url: url,
                                  label: l10n.avatarPreset(i + 1),
                                  selected: _avatar.text == url,
                                  onTap: _saving ? null : () => _setAvatar(url),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ErrorBanner(message: _error),
                TextFormField(
                  controller: _name,
                  enabled: !_saving,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: '${l10n.fullName} *',
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? l10n.errNameRequired : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _title,
                  enabled: !_saving,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.jobTitleBio,
                    hintText: l10n.jobTitleHint,
                    prefixIcon: const Icon(Icons.work_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: user.email,
                  readOnly: true,
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: l10n.email,
                    helperText: l10n.emailLocked,
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  enabled: !_saving,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.phone,
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _district,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.tripoliDistrict,
                    prefixIcon: const Icon(Icons.location_city_outlined),
                  ),
                  items: [
                    for (final d in tripoliDistricts)
                      DropdownMenuItem(
                        value: d,
                        child: Text(l10n.districtName(d)),
                      ),
                  ],
                  onChanged: _saving
                      ? null
                      : (v) => setState(() {
                          _district = v!;
                          _dirty = true;
                        }),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bio,
                  enabled: !_saving,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: l10n.bioLabel,
                    hintText: l10n.bioHint,
                    hintMaxLines: 2,
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: l10n.saveProfile,
                  loadingLabel: l10n.savingProfile,
                  icon: Icons.save_outlined,
                  loading: _saving,
                  onPressed: _save,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarChoice extends StatelessWidget {
  const _AvatarChoice({
    required this.url,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String url;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    child: InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.teal400 : AppColors.slate700,
            width: 2,
          ),
        ),
        child: UserAvatar(name: label, url: url, radius: 22),
      ),
    ),
  );
}
