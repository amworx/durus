import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:durus/core/avatar_url.dart';
import 'package:durus/core/google_auth.dart';
import 'package:durus/core/utils.dart';
import 'package:durus/l10n/l10n_ext.dart';
import 'package:durus/models/models.dart';
import 'package:durus/providers/providers.dart';
import 'package:durus/widgets/teacher_avatar.dart';
import 'package:durus/widgets/widgets.dart';

/// Full-screen teacher profile (confirmed mockup 2 — بطل أخضر + تبويبات).
///
/// Green gradient hero (generated avatar, name, email, animated status
/// badge, stats) above three tabs: البيانات (name/phone/bio + read-only
/// info), الدخول (email change with confirmation notice, password change
/// with current-password verification), الصورة (big preview, gender
/// picker, style picker, shuffle). Opened from the top-bar avatar and
/// from Settings → account.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final profileAsync = ref.watch(currentProfileProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: profileAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorRetry(
          message: l10n.commonError,
          onRetry: () => ref.invalidate(currentProfileProvider),
        ),
        data: (profile) {
          if (profile == null) {
            return EmptyState(
              icon: Icons.person_off_outlined,
              message: l10n.commonEmpty,
            );
          }
          return DefaultTabController(
            length: 3,
            child: Column(
              children: [
                _Hero(profile: profile),
                TabBar(
                  tabs: [
                    Tab(text: l10n.profileTabData),
                    Tab(text: l10n.profileTabAuth),
                    Tab(text: l10n.profileTabAvatar),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _DataTab(profile: profile),
                      _AuthTab(profile: profile),
                      _AvatarTab(profile: profile),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

// ── Hero ────────────────────────────────────────────────────────────────

class _Hero extends ConsumerWidget {
  const _Hero({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final students = ref.watch(studentsProvider).valueOrNull?.length ?? 0;
    final lessons = ref.watch(lessonsProvider).valueOrNull ?? const [];
    final monthCount =
        lessons.where((l) => l.date.startsWith(monthKey(DateTime.now()))).length;
    final subjects = ref.watch(subjectsProvider).valueOrNull?.length ?? 0;

    final name = profile.fullName?.trim() ?? '';
    final role = profile.isManager
        ? l10n.profileRoleManager
        : l10n.profileRoleTeacher;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF0A3B2E), Color(0xFF0E7C66), Color(0xFF12A083)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        children: [
          TeacherAvatar(
            seed: profile.avatarSeed ?? profile.id,
            theme: profile.avatarTheme,
            gender: profile.avatarGender,
            fallbackLabel: name,
            size: 84,
            showStatusDot: true,
            active: profile.active,
          ),
          const SizedBox(height: 10),
          Text(
            name.isEmpty ? l10n.commonNone : name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            '${profile.email} • $role',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),
          _ActiveBadge(label: '$role — ${l10n.settingsTeacherActive}'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _HeroChip('$students ${l10n.profileStatStudents}'),
              _HeroChip('$monthCount ${l10n.profileStatSessions}'),
              _HeroChip('$subjects ${l10n.profileStatSubjects}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Eldora-style animated status badge: white pill with a pulsing dot.
class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PulseDot(),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small building blocks ───────────────────────────────────────────────

class _SegOption<T> {
  const _SegOption({required this.value, required this.label});
  final T value;
  final String label;
}

class _Seg<T> extends StatelessWidget {
  const _Seg({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final List<_SegOption<T>> options;
  final T? selected;
  final ValueChanged<T> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: options.map((o) {
          final on = o.value == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(o.value),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: on ? theme.colorScheme.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: on
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  o.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: on
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ReadonlyInfo extends StatelessWidget {
  const _ReadonlyInfo({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return SectionCard(
      title: l10n.profileInfo,
      child: Column(
        children: [
          _Kv(
            label: l10n.profileRole,
            value: profile.isManager
                ? l10n.profileRoleManager
                : l10n.profileRoleTeacher,
          ),
          _Kv(
            label: l10n.commonStatus,
            value: l10n.settingsTeacherActive,
            valueColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

class _Kv extends StatelessWidget {
  const _Kv({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: valueColor ?? theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data tab ────────────────────────────────────────────────────────────

class _DataTab extends ConsumerStatefulWidget {
  const _DataTab({required this.profile});

  final Profile profile;

  @override
  ConsumerState<_DataTab> createState() => _DataTabState();
}

class _DataTabState extends ConsumerState<_DataTab> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _bioCtrl;
  late Profile _applied;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _applied = widget.profile;
    _nameCtrl = TextEditingController(text: widget.profile.fullName ?? '');
    _phoneCtrl = TextEditingController(text: widget.profile.phone ?? '');
    _bioCtrl = TextEditingController(text: widget.profile.bio ?? '');
  }

  @override
  void didUpdateWidget(_DataTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.profile != _applied) {
      _applied = widget.profile;
      _nameCtrl.text = widget.profile.fullName ?? '';
      _phoneCtrl.text = widget.profile.phone ?? '';
      _bioCtrl.text = widget.profile.bio ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    if (_nameCtrl.text.trim().isEmpty) {
      _snack(context, l10n.profileNameRequired);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(apiProvider).updateProfile(
            fullName: _nameCtrl.text,
            bio: _bioCtrl.text,
            phone: _phoneCtrl.text,
          );
      if (!mounted) return;
      ref.invalidate(currentProfileProvider);
      _snack(context, l10n.profileSaved);
    } catch (e) {
      if (mounted) _snack(context, friendlyError(e, l10n));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionCard(
          title: l10n.profileTabData,
          child: Column(
            children: [
              TextField(
                controller: _nameCtrl,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.commonName,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.profilePhone,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bioCtrl,
                maxLines: 3,
                maxLength: 160,
                decoration: InputDecoration(
                  labelText: l10n.profileBio,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        _ReadonlyInfo(profile: widget.profile),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check, size: 18),
          label: Text(l10n.commonSave),
        ),
      ],
    );
  }
}

// ── Auth tab ────────────────────────────────────────────────────────────

class _AuthTab extends ConsumerStatefulWidget {
  const _AuthTab({required this.profile});

  final Profile profile;

  @override
  ConsumerState<_AuthTab> createState() => _AuthTabState();
}

class _AuthTabState extends ConsumerState<_AuthTab> {
  final _newEmailCtrl = TextEditingController();
  final _curPwCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  final _confirmPwCtrl = TextEditingController();
  bool _emailSent = false;
  bool _sendingEmail = false;
  bool _changingPw = false;
  bool _obscureCur = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _newEmailCtrl.dispose();
    _curPwCtrl.dispose();
    _newPwCtrl.dispose();
    _confirmPwCtrl.dispose();
    super.dispose();
  }

  bool _validEmail(String v) {
    final t = v.trim();
    return t.contains('@') && t.contains('.') && !t.contains(' ');
  }

  Future<void> _sendEmail() async {
    final l10n = context.l10n;
    final v = _newEmailCtrl.text.trim();
    if (!_validEmail(v)) {
      _snack(context, l10n.profileEmailInvalid);
      return;
    }
    setState(() => _sendingEmail = true);
    try {
      await ref.read(apiProvider).updateEmail(v);
      if (!mounted) return;
      setState(() => _emailSent = true);
      _snack(context, l10n.profileEmailSentNotice);
    } catch (e) {
      if (mounted) _snack(context, friendlyError(e, l10n));
    } finally {
      if (mounted) setState(() => _sendingEmail = false);
    }
  }

  Future<void> _changePassword() async {
    final l10n = context.l10n;
    if (_newPwCtrl.text != _confirmPwCtrl.text) {
      _snack(context, l10n.profilePasswordMismatch);
      return;
    }
    if (_newPwCtrl.text.length < 6) {
      _snack(context, l10n.profilePasswordShort);
      return;
    }
    setState(() => _changingPw = true);
    try {
      await ref.read(apiProvider).updatePassword(
            currentPassword: _curPwCtrl.text,
            newPassword: _newPwCtrl.text,
          );
      if (!mounted) return;
      _curPwCtrl.clear();
      _newPwCtrl.clear();
      _confirmPwCtrl.clear();
      _snack(context, l10n.profilePasswordChanged);
    } catch (e) {
      if (mounted) _snack(context, friendlyError(e, l10n));
    } finally {
      if (mounted) setState(() => _changingPw = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sessionEmail =
        Supabase.instance.client.auth.currentUser?.email ?? widget.profile.email;
    // Google-only accounts have no password; the re-sign-in inside
    // updatePassword would only ever fail for them — say so upfront.
    // An account linked to BOTH keeps the form (it does have a password).
    final user = Supabase.instance.client.auth.currentUser;
    final showPwForm = showPasswordForm(
      identityProviders: [
        for (final i in user?.identities ?? const []) i.provider,
      ],
      appProvider: user?.appMetadata['provider'] as String?,
    );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionCard(
          title: l10n.profileEmailNew,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: TextEditingController(text: sessionEmail),
                readOnly: true,
                decoration: InputDecoration(
                  labelText: l10n.profileEmailCurrent,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _newEmailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _sendEmail(),
                decoration: InputDecoration(
                  labelText: l10n.profileEmailNew,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _sendingEmail ? null : _sendEmail,
                child: Text(l10n.profileEmailSend),
              ),
              if (_emailSent) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    l10n.profileEmailSentNotice,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        SectionCard(
          title: l10n.profileChangePassword,
          child: showPwForm
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _PasswordField(
                      controller: _curPwCtrl,
                      label: l10n.profilePasswordCurrent,
                      obscure: _obscureCur,
                      onToggle: () =>
                          setState(() => _obscureCur = !_obscureCur),
                    ),
                    const SizedBox(height: 12),
                    _PasswordField(
                      controller: _newPwCtrl,
                      label: l10n.profilePasswordNew,
                      obscure: _obscureNew,
                      onToggle: () =>
                          setState(() => _obscureNew = !_obscureNew),
                    ),
                    const SizedBox(height: 12),
                    _PasswordField(
                      controller: _confirmPwCtrl,
                      label: l10n.profilePasswordConfirm,
                      obscure: _obscureConfirm,
                      onToggle: () => setState(
                          () => _obscureConfirm = !_obscureConfirm),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _changingPw ? null : _changePassword,
                      child: Text(l10n.profileChangePassword),
                    ),
                  ],
                )
              : Text(
                  l10n.profilePasswordGoogleOnly,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
        ),
      ],
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
  });

  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
        ),
      ),
    );
  }
}

// ── Avatar tab ──────────────────────────────────────────────────────────

class _AvatarTab extends ConsumerStatefulWidget {
  const _AvatarTab({required this.profile});

  final Profile profile;

  @override
  ConsumerState<_AvatarTab> createState() => _AvatarTabState();
}

class _AvatarTabState extends ConsumerState<_AvatarTab> {
  late String _theme;
  late String? _gender;
  late String _seed;
  late Profile _applied;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _applied = widget.profile;
    _theme = kAvatarThemes.contains(widget.profile.avatarTheme)
        ? widget.profile.avatarTheme
        : kDefaultAvatarTheme;
    _gender = widget.profile.avatarGender;
    _seed = widget.profile.avatarSeed ?? widget.profile.id;
  }

  @override
  void didUpdateWidget(_AvatarTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.profile != _applied) {
      _applied = widget.profile;
      _theme = kAvatarThemes.contains(widget.profile.avatarTheme)
          ? widget.profile.avatarTheme
          : kDefaultAvatarTheme;
      _gender = widget.profile.avatarGender;
      _seed = widget.profile.avatarSeed ?? widget.profile.id;
    }
  }

  void _pickTheme(String t) {
    setState(() {
      _theme = t;
      _gender = null; // last action wins, like the approved mockup
    });
  }

  void _pickGender(String g) {
    setState(() => _gender = _gender == g ? null : g);
  }

  void _shuffle() {
    setState(
      () => _seed =
          '${widget.profile.id}-${Random().nextInt(90000) + 10000}',
    );
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    setState(() => _saving = true);
    try {
      await ref.read(apiProvider).updateProfile(
            avatarTheme: _theme,
            avatarGender: _gender,
            clearAvatarGender: _gender == null,
            avatarSeed: _seed,
          );
      if (!mounted) return;
      ref.invalidate(currentProfileProvider);
      _snack(context, l10n.profileSaved);
    } catch (e) {
      if (mounted) _snack(context, friendlyError(e, l10n));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = widget.profile.fullName?.trim() ?? '';
    final themeLabels = {
      'fatin-verse': l10n.profileThemeFatin,
      'yanliu': l10n.profileThemeYanliu,
      'micah': l10n.profileThemeMicah,
    };
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionCard(
          title: l10n.profileTabAvatar,
          child: Column(
            children: [
              TeacherAvatar(
                seed: _seed,
                theme: _theme,
                gender: _gender,
                fallbackLabel: name,
                size: 120,
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  l10n.profileGender,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              const SizedBox(height: 6),
              _Seg<String>(
                options: [
                  _SegOption(
                      value: 'm', label: l10n.profileGenderMale),
                  _SegOption(
                      value: 'f', label: l10n.profileGenderFemale),
                ],
                selected: _gender,
                onSelect: _pickGender,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  l10n.profileAvatarStyle,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              const SizedBox(height: 6),
              _Seg<String>(
                options: kAvatarThemes
                    .map((t) =>
                        _SegOption(value: t, label: themeLabels[t] ?? t))
                    .toList(),
                selected: _theme,
                onSelect: _pickTheme,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _shuffle,
                icon: const Text('🎲'),
                label: Text(l10n.profileAvatarShuffle),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.profileAvatarAuto,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check, size: 18),
          label: Text(l10n.commonSave),
        ),
      ],
    );
  }
}
