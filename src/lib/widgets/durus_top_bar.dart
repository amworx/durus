import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:durus/l10n/l10n_ext.dart';
import 'package:durus/providers/providers.dart';
import 'package:durus/screens/notifications_screen.dart';
import 'package:durus/theme/themes.dart';
import 'package:durus/screens/profile_screen.dart';
import 'package:durus/widgets/teacher_avatar.dart';

/// Top bar cloned from the cloudmate-classroom design and adapted for Durus:
/// profile avatar on the start side, a centered two-tone brand title, and a
/// notification bell (with unread badge) at the far end. Fully RTL-aware.
///
/// Pass [title] to show a normal centered text (e.g. "الجدول"), or leave it
/// `null` to show the two-tone "دُر"+"وس" brand wordmark. Extra [actions] are
/// placed before the bell so the bell always sits at the end side.
class DurusTopBar extends ConsumerWidget implements PreferredSizeWidget {
  const DurusTopBar({
    super.key,
    this.title,
    this.actions = const [],
    this.showBell = true,
    this.showAvatar = true,
  });

  /// Centered title; `null` renders the two-tone "دروس" brand wordmark.
  final String? title;

  /// Extra actions placed between the center and the notification bell.
  final List<Widget> actions;

  /// Whether the notification bell (with unread badge) is shown.
  final bool showBell;

  /// Whether the profile avatar leading button is shown.
  final bool showAvatar;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      leading: showAvatar ? const _ProfileAvatarButton() : null,
      title: title == null ? const _BrandWordmark() : Text(title!),
      actions: [
        ...actions,
        if (showBell) const _NotificationBell(),
      ],
    );
  }
}

/// Profile avatar leading button; tapping it opens the profile edit sheet.
class _ProfileAvatarButton extends ConsumerWidget {
  const _ProfileAvatarButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final profile = ref.watch(currentProfileProvider).valueOrNull;
    final fullName = profile?.fullName?.trim() ?? '';

    return IconButton(
      tooltip: l10n.settingsProfile,
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const ProfileScreen(),
        ),
      ),
      icon: TeacherAvatar(
        seed: profile?.id ?? '',
        theme: profile?.avatarTheme,
        gender: profile?.avatarGender,
        fallbackLabel: fullName,
        size: 28,
      ),
    );
  }
}

/// Centered two-tone brand wordmark: "دُر" in primary + "وس" in onSurface,
/// mirroring Cloudmate's "Cloud"+"mate" split-word signature.
class _BrandWordmark extends StatelessWidget {
  const _BrandWordmark();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text.rich(
      TextSpan(
        style: const TextStyle(
          fontFamily: kFontFamily,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          height: 1.2,
        ),
        children: [
          TextSpan(text: 'دُر', style: TextStyle(color: scheme.primary)),
          TextSpan(text: 'وس', style: TextStyle(color: scheme.onSurface)),
        ],
      ),
    );
  }
}

/// Notification bell with an unread-count badge; opens the notifications
/// screen. Mirrors the previous Home app-bar bell behavior.
class _NotificationBell extends ConsumerWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final notifications = ref.watch(teacherNotificationsProvider);
    final unread =
        notifications.valueOrNull?.where((n) => !n.isRead).length ?? 0;

    return IconButton(
      tooltip: l10n.notificationsTitle,
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const NotificationsScreen(),
        ),
      ),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text('$unread'),
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}