import 'dart:async';

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
  // Deployed-state telemetry: one guarded upsert per uid per launch.
  // Never awaited, never throws (offline-safe).
  unawaited(ref.read(apiProvider).reportHeartbeat());
  return ref.read(apiProvider).currentProfile();
});

/// Server-decided app ownership (owner dashboard gate). False when signed
/// out or on any failure — the section simply stays hidden.
final isOwnerProvider = FutureProvider<bool>((ref) async {
  ref.watch(authSessionProvider);
  return ref.read(apiProvider).amIOwner();
});

/// The caller's school's feature/edit requests (RLS school-scoped).
final featureRequestsProvider =
    FutureProvider<List<FeatureRequest>>((ref) async {
  ref.watch(authSessionProvider);
  return ref.read(apiProvider).featureRequests();
});

/// Whole-product snapshot for the owner dashboard. The RPC fails closed
/// for non-owners; the entry point is hidden unless [isOwnerProvider].
final ownerOverviewProvider = FutureProvider<OwnerOverview>((ref) async {
  ref.watch(authSessionProvider);
  return ref.read(apiProvider).ownerOverview();
});

/// Latest client error reports (owner-only RPC).
final ownerErrorsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(authSessionProvider);
  return ref.read(apiProvider).ownerErrors();
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

final notificationPrefsProvider = FutureProvider<Map<String, bool>>((ref) async {
  ref.watch(authSessionProvider);
  return ref.read(apiProvider).notificationPrefs();
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

/// Fetches every school-data provider in parallel and awaits completion.
/// Used by pull-to-refresh gestures on the main tabs. Individual failures are
/// swallowed here on purpose — the failing provider renders its own
/// [ErrorRetry] widget.
Future<void> refreshSchoolData(WidgetRef ref) async {
  try {
    await Future.wait([
      ref.refresh(studentsProvider.future),
      ref.refresh(subjectsProvider.future),
      ref.refresh(slotsProvider.future),
      ref.refresh(lessonsProvider.future),
      ref.refresh(feesProvider.future),
      ref.refresh(paymentsProvider.future),
      ref.refresh(testsProvider.future),
      ref.refresh(notesProvider.future),
      ref.refresh(announcementsProvider.future),
      ref.refresh(studentSubjectRefsProvider.future),
      ref.refresh(teacherNotificationsProvider.future),
    ]);
  } catch (_) {
    // See doc comment above.
  }
}

/// Invalidates every school-data provider without awaiting (fire-and-forget).
/// Used when the app returns from background so the next build refetches
/// instead of showing stale cached data — no app restart required.
void invalidateAllSchoolData(WidgetRef ref) {
  ref.invalidate(studentsProvider);
  ref.invalidate(subjectsProvider);
  ref.invalidate(slotsProvider);
  ref.invalidate(lessonsProvider);
  ref.invalidate(feesProvider);
  ref.invalidate(paymentsProvider);
  ref.invalidate(testsProvider);
  ref.invalidate(notesProvider);
  ref.invalidate(announcementsProvider);
  ref.invalidate(studentSubjectRefsProvider);
  ref.invalidate(teacherNotificationsProvider);
}