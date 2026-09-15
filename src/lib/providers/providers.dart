import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/durus_api.dart';
import '../models/models.dart';
import '../theme/themes.dart';

/// SharedPreferences is initialized once at app startup by the bootstrap
/// worker; this provider is overridden with the real instance during setup.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(),
);

final apiProvider = Provider<DurusApi>((ref) => DurusApi());

/// Selected design system. The design IS the brightness (فسيفساء = light,
/// سكون = dark), so there is no separate dark-mode toggle.
final themeKeyProvider = StateProvider<String>((ref) => kThemeFusayfesa);

/// Emits on every auth state change (sign-in, sign-out, token refresh).
final authSessionProvider =
    StreamProvider<AuthState>((ref) => Supabase.instance.client.auth.onAuthStateChange);

final currentProfileProvider = FutureProvider<Profile?>((ref) async {
  ref.watch(authSessionProvider); // re-fetch on auth changes
  final u = Supabase.instance.client.auth.currentUser;
  if (u == null) {
    return null;
  }
  return ref.read(apiProvider).currentProfile();
});

final currentSchoolIdProvider = Provider<String?>((ref) {
  final p = ref.watch(currentProfileProvider).valueOrNull;
  if (p == null) {
    return null;
  }
  return p.isManager ? p.id : p.managerId;
});

final subjectsProvider = FutureProvider<List<Subject>>((ref) async {
  ref.watch(authSessionProvider);
  return ref.read(apiProvider).subjects();
});

final studentsProvider = FutureProvider<List<Student>>((ref) async {
  ref.watch(authSessionProvider);
  return ref.read(apiProvider).students();
});

final slotsProvider = FutureProvider<List<RecurringSlot>>((ref) async {
  ref.watch(authSessionProvider);
  return ref.read(apiProvider).slots();
});

final lessonsProvider = FutureProvider<List<LessonSession>>((ref) async {
  ref.watch(authSessionProvider);
  return ref.read(apiProvider).lessons();
});

final feesProvider = FutureProvider<List<Fee>>((ref) async {
  ref.watch(authSessionProvider);
  return ref.read(apiProvider).fees();
});

final paymentsProvider = FutureProvider<List<Payment>>((ref) async {
  ref.watch(authSessionProvider);
  return ref.read(apiProvider).payments();
});

final testsProvider = FutureProvider<List<TestResult>>((ref) async {
  ref.watch(authSessionProvider);
  return ref.read(apiProvider).tests();
});

final notesProvider = FutureProvider<List<LessonNote>>((ref) async {
  ref.watch(authSessionProvider);
  return ref.read(apiProvider).notes();
});

final announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
  ref.watch(authSessionProvider);
  return ref.read(apiProvider).announcements();
});

final teachersProvider = FutureProvider<List<Profile>>((ref) async {
  ref.watch(authSessionProvider);
  return ref.read(apiProvider).teachers();
});

final invitationsProvider = FutureProvider<List<Invitation>>((ref) async {
  ref.watch(authSessionProvider);
  return ref.read(apiProvider).invitations();
});

final teacherNotificationsProvider = FutureProvider<List<AppNotification>>((ref) async {
  ref.watch(authSessionProvider);
  return ref.read(apiProvider).teacherNotifications();
});

final studentSubjectRefsProvider = FutureProvider<List<StudentSubjectRef>>((ref) async {
  ref.watch(authSessionProvider);
  return ref.read(apiProvider).studentSubjectRefs();
});