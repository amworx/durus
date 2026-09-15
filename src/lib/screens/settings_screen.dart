import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:durus/l10n/app_localizations.dart';
import 'package:durus/l10n/l10n_ext.dart';
import 'package:durus/models/models.dart';
import 'package:durus/providers/providers.dart';
import 'package:durus/screens/teachers_screen.dart';
import 'package:durus/theme/themes.dart';
import 'package:durus/widgets/widgets.dart';

/// Settings: profile + mode, appearance (theme/dark mode), teacher
/// management (manager only) and logout.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final profileAsync = ref.watch(currentProfileProvider);
    final profile = profileAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SectionCard(
                title: l10n.settingsProfile,
                child: _ProfileSection(profileAsync: profileAsync),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: l10n.settingsTheme,
                child: const _AppearanceSection(),
              ),
              if (profile?.isManager ?? false) ...[
                const SizedBox(height: 16),
                SectionCard(
                  title: l10n.settingsTeachers,
                  child: const _TeachersSection(),
                ),
              ],
              const SizedBox(height: 16),
              _LogoutButton(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileSection extends ConsumerWidget {
  const _ProfileSection({required this.profileAsync});

  final AsyncValue<Profile?> profileAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    if (profileAsync.isLoading) {
      return const LoadingView();
    }
    final error = profileAsync.error;
    if (error != null) {
      return ErrorRetry(
        message: l10n.commonError,
        onRetry: () => ref.invalidate(currentProfileProvider),
      );
    }
    final profile = profileAsync.valueOrNull;
    if (profile == null) {
      return EmptyState(
        icon: Icons.person_off_outlined,
        message: l10n.commonEmpty,
      );
    }

    final fullName = profile.fullName?.trim() ?? '';
    final teachersAsync = ref.watch(teachersProvider);
    final teacherCount = teachersAsync.valueOrNull?.length ?? 0;
    final modeText = _modeText(
      l10n,
      isManager: profile.isManager,
      teacherCount: teacherCount,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              child: Text(fullName.isEmpty ? '?' : fullName.characters.first),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName.isEmpty ? l10n.commonNone : fullName,
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(
                    profile.email,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StatusChip(label: modeText, color: theme.colorScheme.primary),
      ],
    );
  }
}

class _AppearanceSection extends ConsumerWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final themeKey = ref.watch(themeKeyProvider);
    final prefs = ref.watch(sharedPrefsProvider);
    final selected = normalizeThemeKey(themeKey);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.settingsThemePick,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        RadioGroup<String>(
          groupValue: selected,
          onChanged: (value) {
            if (value == null) {
              return;
            }
            ref.read(themeKeyProvider.notifier).state = value;
            prefs.setString('theme_key', value);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: Text(l10n.settingsThemeFusayfesa),
                subtitle: Text(l10n.settingsThemeFusayfesaSub),
                secondary: const _DesignPreview(design: kThemeFusayfesa),
                value: kThemeFusayfesa,
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
              RadioListTile<String>(
                title: Text(l10n.settingsThemeSukoon),
                subtitle: Text(l10n.settingsThemeSukoonSub),
                secondary: const _DesignPreview(design: kThemeSukoon),
                value: kThemeSukoon,
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Small static mock of a design system used as the radio thumbnail in the
/// settings picker. Uses the design's own tokens, not the active theme, so
/// the preview always represents what the user is choosing.
class _DesignPreview extends StatelessWidget {
  const _DesignPreview({required this.design});

  final String design;

  @override
  Widget build(BuildContext context) {
    final isSukoon = design == kThemeSukoon;
    final bg = isSukoon ? const Color(0xFF0A0A0C) : const Color(0xFFFAF8F4);
    final fg = isSukoon ? const Color(0xFFF2F0EB) : const Color(0xFF14213D);
    final mutedC = isSukoon ? const Color(0xFF8F8F86) : const Color(0xFF6F7A8C);
    final accent = isSukoon ? const Color(0xFFE8AD65) : const Color(0xFF0E7C66);

    return Container(
      width: 44,
      height: 56,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(isSukoon ? 8 : 10),
        border: isSukoon
            ? Border.all(color: const Color(0xFF232329))
            : Border.all(color: const Color(0xFFECEAE3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Accent "stat" bar.
            Container(
              height: 15,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: AlignmentDirectional.centerEnd,
              decoration: BoxDecoration(
                color: isSukoon ? const Color(0xFF1A1A20) : const Color(0xFFDFF3EC),
                borderRadius: BorderRadius.circular(isSukoon ? 4 : 6),
              ),
              child: Text(
                '٥٢',
                style: TextStyle(
                  fontFamily: kFontFamily,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                  color: accent,
                ),
              ),
            ),
            const SizedBox(height: 4),
            _line(widthFactor: 0.9, color: fg),
            const SizedBox(height: 2),
            _line(widthFactor: 0.6, color: mutedC),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: _line(widthFactor: 1, color: accent, height: 3),
                ),
                const SizedBox(width: 3),
                _dot(isSukoon ? const Color(0xFFE8AD65) : const Color(0xFFE8622B)),
                const SizedBox(width: 2),
                _dot(isSukoon ? const Color(0xFF8F8F86) : const Color(0xFF3B4A8C)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _line({
    required double widthFactor,
    required Color color,
    double height = 2,
  }) {
    return FractionallySizedBox(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _dot(Color color) {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _TeachersSection extends ConsumerWidget {
  const _TeachersSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final teachersAsync = ref.watch(teachersProvider);

    return teachersAsync.when(
      loading: () => const LoadingView(),
      error: (error, stackTrace) => ErrorRetry(
        message: l10n.commonError,
        onRetry: () => ref.invalidate(teachersProvider),
      ),
      data: (teachers) {
        final children = <Widget>[];
        if (teachers.isEmpty) {
          children.add(
            EmptyState(
              icon: Icons.group_outlined,
              message: l10n.settingsTeachersEmpty,
              compact: true,
            ),
          );
        } else {
          for (final Profile teacher in teachers) {
            children.add(
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person_outline),
                title: Text(_teacherName(l10n, teacher)),
                subtitle: Text(teacher.email),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StatusChip(
                      label: teacher.active
                          ? l10n.settingsTeacherActive
                          : l10n.settingsTeacherDisabled,
                      color: teacher.active ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Switch(
                      value: teacher.active,
                      onChanged: (value) =>
                          _toggleTeacher(context, ref, l10n, teacher, value),
                    ),
                  ],
                ),
              ),
            );
          }
        }
        children.add(const SizedBox(height: 8));
        children.add(
          FilledButton.tonalIcon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const TeacherManagementScreen(),
              ),
            ),
            icon: const Icon(Icons.person_add_alt),
            label: Text(l10n.settingsAddTeacher),
          ),
        );
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        );
      },
    );
  }

  Future<void> _toggleTeacher(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    Profile teacher,
    bool value,
  ) async {
    try {
      await ref.read(apiProvider).setTeacherActive(teacher.id, value);
      if (!context.mounted) {
        return;
      }
      ref.invalidate(teachersProvider);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.settingsTeacherStatusUpdated)));
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(friendlyError(e, l10n))));
    }
  }
}

class _LogoutButton extends ConsumerWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.error,
        side: BorderSide(color: scheme.error.withValues(alpha: 0.4)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      onPressed: () async {
        final confirmed = await confirmDialog(
          context,
          title: l10n.settingsLogout,
          message: l10n.settingsLogout,
        );
        if (!confirmed || !context.mounted) {
          return;
        }
        try {
          await ref.read(apiProvider).signOut();
          if (context.mounted) {
            ref.invalidate(currentProfileProvider);
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(friendlyError(e, l10n))),
            );
          }
        }
      },
      icon: const Icon(Icons.logout),
      label: Text(l10n.settingsLogout),
    );
  }
}

String _modeText(
  AppLocalizations l10n, {
  required bool isManager,
  required int teacherCount,
}) {
  if (!isManager) {
    return l10n.settingsTeachers;
  }
  return teacherCount == 0 ? l10n.settingsSingleMode : l10n.settingsMultiMode;
}

String _teacherName(AppLocalizations l10n, Profile teacher) {
  final name = teacher.fullName?.trim() ?? '';
  return name.isEmpty ? l10n.commonNone : name;
}