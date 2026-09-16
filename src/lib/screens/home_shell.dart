import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:durus/core/local_notifications.dart';
import 'package:durus/l10n/l10n_ext.dart';
import 'package:durus/providers/providers.dart';
import 'package:durus/screens/fees_screens.dart';
import 'package:durus/screens/home_screen.dart';
import 'package:durus/screens/notifications_screen.dart';
import 'package:durus/screens/schedule_screen.dart';
import 'package:durus/screens/settings_screen.dart';
import 'package:durus/screens/students_screens.dart';
import 'package:durus/screens/subjects_screens.dart';

/// Main tab shell. Five destinations; the active tab is kept alive via
/// [IndexedStack] so scrolling/state survives tab switches.
///
/// Also subscribes to Postgres realtime on the `notifications` table so the
/// badge count and the notifications center stay fresh when DB triggers add
/// rows (attendance, fees, payments, …), and on the `announcements` table so
/// the announcements section refreshes when an announcement is added or
/// edited from any device without a manual refresh.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell>
    with WidgetsBindingObserver {
  int _index = 0;
  RealtimeChannel? _notificationsChannel;
  RealtimeChannel? _announcementsChannel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Tap on a system notification -> open the notifications center.
    LocalNotifications.onTapped = (response) async {
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const NotificationsScreen(),
        ),
      );
    };

    final client = Supabase.instance.client;
    _notificationsChannel = client
        .channel('durus-notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          callback: (payload) {
            if (!mounted) return;
            ref.invalidate(teacherNotificationsProvider);
            _showSystemNotificationFor(payload);
          },
        )
        .subscribe();
    // Announcements are also published on the realtime publication; when a
    // row changes (add/edit/pin/delete from any device), invalidate the
    // provider so the announcements section refreshes without a manual
    // pull-to-refresh — same pattern as the notifications badge.
    // System notifications are NOT shown here: the DB trigger
    // trg_notify_announcement already inserts into the notifications table,
    // so the notifications channel handles the system notification.
    _announcementsChannel = client
        .channel('durus-announcements')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'announcements',
          callback: (payload) {
            if (!mounted) return;
            ref.invalidate(announcementsProvider);
          },
        )
        .subscribe();
  }

  /// Shows an Android system notification for a new row, honoring the
  /// notification prefs. No-ops on web (LocalNotifications is a no-op) and
  /// for DELETE events (rows removed silently).
  Future<void> _showSystemNotificationFor(PostgresChangePayload payload) async {
    if (payload.eventType == PostgresChangeEvent.delete) return;

    final record = payload.newRecord;

    final title = (record['title'] as String?)?.trim() ?? '';
    final body = (record['body'] as String?)?.trim() ?? '';
    if (title.isEmpty) return;

    final type = (record['type'] as String?) ?? 'general';

    // Respect the user's per-category prefs (same keys as the in-app center).
    final prefsAsync = ref.read(notificationPrefsProvider);
    final prefs = prefsAsync.valueOrNull ?? const {};
    if (prefs[type] == false) return;

    // Deterministic id per row so repeated events overwrite, not stack.
    final rowId = record['id'];
    final id = (rowId is String ? rowId.hashCode : title.hashCode) & 0x7FFFFFFF;

    await LocalNotifications.show(
      id: id,
      title: title,
      body: body,
      payload: type,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refetch school data when the app comes back to the foreground so
    // changes made elsewhere (other teacher, portal, seed data) appear
    // without closing and reopening the app.
    if (state == AppLifecycleState.resumed) {
      invalidateAllSchoolData(ref);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    LocalNotifications.onTapped = null;
    final notificationsChannel = _notificationsChannel;
    if (notificationsChannel != null) {
      Supabase.instance.client.removeChannel(notificationsChannel);
    }
    final announcementsChannel = _announcementsChannel;
    if (announcementsChannel != null) {
      Supabase.instance.client.removeChannel(announcementsChannel);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(),
          ScheduleScreen(),
          StudentsListScreen(),
          SubjectsScreen(),
          FeesScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.today_outlined),
            selectedIcon: const Icon(Icons.today),
            label: l10n.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month),
            label: l10n.navSchedule,
          ),
          NavigationDestination(
            icon: const Icon(Icons.people_outline),
            selectedIcon: const Icon(Icons.people),
            label: l10n.navStudents,
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            selectedIcon: const Icon(Icons.menu_book),
            label: l10n.navSubjects,
          ),
          NavigationDestination(
            icon: const Icon(Icons.payments_outlined),
            selectedIcon: const Icon(Icons.payments),
            label: l10n.navFees,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.navSettings,
          ),
        ],
      ),
    );
  }
}