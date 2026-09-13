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
    final darkMode = ref.watch(darkModeProvider);
    final prefs = ref.watch(sharedPrefsProvider);
    final selected = const [kThemeDaftar, kThemeLawh, kThemeMaktab]
            .contains(themeKey)
        ? themeKey
        : kThemeDaftar;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                title: Text(l10n.settingsThemeDaftar),
                value: kThemeDaftar,
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
              RadioListTile<String>(
                title: Text(l10n.settingsThemeLawh),
                value: kThemeLawh,
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
              RadioListTile<String>(
                title: Text(l10n.settingsThemeMaktab),
                value: kThemeMaktab,
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        SwitchListTile(
          title: Text(l10n.settingsTheme),
          secondary: const Icon(Icons.dark_mode_outlined),
          value: darkMode,
          contentPadding: EdgeInsets.zero,
          onChanged: (value) {
            ref.read(darkModeProvider.notifier).state = value;
            prefs.setBool('dark_mode', value);
          },
        ),
      ],
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
        if (teachers.isEmpty) {
          return EmptyState(
            icon: Icons.group_outlined,
            message: l10n.settingsTeachersEmpty,
            compact: true,
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final Profile teacher in teachers)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person_outline),
                title: Text(_teacherName(l10n, teacher)),
                subtitle: Text(teacher.email),
              ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const TeacherManagementScreen(),
                ),
              ),
              icon: const Icon(Icons.person_add_alt),
              label: Text(l10n.settingsAddTeacher),
            ),
          ],
        );
      },
    );
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