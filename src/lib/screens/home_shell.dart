import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:durus/l10n/l10n_ext.dart';
import 'package:durus/providers/providers.dart';
import 'package:durus/screens/fees_screens.dart';
import 'package:durus/screens/home_screen.dart';
import 'package:durus/screens/settings_screen.dart';
import 'package:durus/screens/students_screens.dart';
import 'package:durus/screens/subjects_screens.dart';

/// Main tab shell. Five destinations; the active tab is kept alive via
/// [IndexedStack] so scrolling/state survives tab switches.
///
/// Also subscribes to Postgres realtime on the `notifications` table so the
/// badge count and the notifications center stay fresh when DB triggers add
/// rows (attendance, fees, payments, …).
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;
  RealtimeChannel? _notificationsChannel;

  @override
  void initState() {
    super.initState();
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
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    final channel = _notificationsChannel;
    if (channel != null) {
      Supabase.instance.client.removeChannel(channel);
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