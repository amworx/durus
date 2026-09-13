import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:durus/core/utils.dart';
import 'package:durus/l10n/app_localizations.dart';
import 'package:durus/l10n/l10n_ext.dart';
import 'package:durus/models/models.dart';
import 'package:durus/providers/providers.dart';
import 'package:durus/screens/notifications_screen.dart';
import 'package:durus/widgets/widgets.dart';

/// Home dashboard: today's sessions with one-tap attendance, plus the latest
/// announcements. Responsive (max-width 760) for web/admin usage.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final notifications = ref.watch(teacherNotificationsProvider);
    final unread =
        notifications.valueOrNull?.where((n) => !n.isRead).length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeTodaySessions),
        actions: [
          IconButton(
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
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: const [
              _TodaySessionsCard(),
              SizedBox(height: 16),
              _AnnouncementsCard(),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodaySessionsCard extends ConsumerWidget {
  const _TodaySessionsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SectionCard(
      title: l10n.homeTodaySessions,
      child: _buildBody(context, ref, l10n),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final slotsAsync = ref.watch(slotsProvider);
    final studentsAsync = ref.watch(studentsProvider);
    final subjectsAsync = ref.watch(subjectsProvider);
    final lessonsAsync = ref.watch(lessonsProvider);

    if (slotsAsync.isLoading ||
        studentsAsync.isLoading ||
        subjectsAsync.isLoading ||
        lessonsAsync.isLoading) {
      return const LoadingView();
    }
    final error = slotsAsync.error ??
        studentsAsync.error ??
        subjectsAsync.error ??
        lessonsAsync.error;
    if (error != null) {
      return ErrorRetry(
        message: l10n.commonError,
        onRetry: () {
          ref.invalidate(slotsProvider);
          ref.invalidate(studentsProvider);
          ref.invalidate(subjectsProvider);
          ref.invalidate(lessonsProvider);
        },
      );
    }

    final slots = slotsAsync.valueOrNull ?? const <RecurringSlot>[];
    final students = studentsAsync.valueOrNull ?? const <Student>[];
    final subjects = subjectsAsync.valueOrNull ?? const <Subject>[];
    final lessons = lessonsAsync.valueOrNull ?? const <LessonSession>[];

    final today = DateTime.now().weekday;
    final todaySlots = slots.where((s) => s.dayOfWeek == today).toList();
    if (todaySlots.isEmpty) {
      return EmptyState(
        icon: Icons.event_busy_outlined,
        message: l10n.homeNoSessions,
      );
    }

    final studentsById = {for (final s in students) s.id: s};
    final subjectsById = {for (final s in subjects) s.id: s};
    final todayIso = _isoToday();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final slot in todaySlots) ...[
          _SessionTile(
            slot: slot,
            studentName: studentsById[slot.studentId]?.name ?? l10n.commonNone,
            subjectName:
                subjectsById[slot.subjectId]?.name ?? l10n.commonNone,
            lesson: _lessonFor(lessons, slot.id, todayIso),
            onMark: (attendance) =>
                _markAttendance(context, ref, l10n, slot, todayIso, attendance),
          ),
          if (slot != todaySlots.last) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _AnnouncementsCard extends ConsumerWidget {
  const _AnnouncementsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final announcementsAsync = ref.watch(announcementsProvider);
    return SectionCard(
      title: l10n.homeAnnouncements,
      child: announcementsAsync.when(
        loading: () => const LoadingView(),
        error: (error, stackTrace) => ErrorRetry(
          message: l10n.commonError,
          onRetry: () => ref.invalidate(announcementsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.campaign_outlined,
              message: l10n.commonEmpty,
            );
          }
          final sorted = [...items]..sort((a, b) {
              final at = a.createdAt?.millisecondsSinceEpoch ?? 0;
              final bt = b.createdAt?.millisecondsSinceEpoch ?? 0;
              return bt.compareTo(at);
            });
          final recent = sorted.take(3).toList();
          final theme = Theme.of(context);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final item in recent) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.campaign_outlined,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(item.body, style: theme.textTheme.bodyMedium),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _announcementDate(l10n, item),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                if (item != recent.last) const Divider(height: 20),
              ],
            ],
          );
        },
      ),
    );
  }

  String _announcementDate(AppLocalizations l10n, Announcement item) {
    final created = item.createdAt;
    if (created == null) {
      return l10n.commonNone;
    }
    return fmtDate(created);
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.slot,
    required this.studentName,
    required this.subjectName,
    required this.lesson,
    required this.onMark,
  });

  final RecurringSlot slot;
  final String studentName;
  final String subjectName;
  final LessonSession? lesson;
  final ValueChanged<String> onMark;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final recordedLesson = lesson;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                timeFromMinutes(slot.startMinutes),
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  studentName,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              if (recordedLesson != null)
                StatusChip(
                  label: _attendanceLabel(l10n, recordedLesson.attendance),
                  color: _attendanceColor(recordedLesson.attendance, scheme),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.auto_stories_outlined,
                size: 16,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                subjectName,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const Spacer(),
              Icon(
                Icons.place_outlined,
                size: 16,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                slot.location == 'student_home'
                    ? l10n.studentsLocationHome
                    : l10n.studentsLocationTeacher,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          if (recordedLesson == null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                _MarkButton(
                  label: l10n.homeMarkPresent,
                  color: const Color(0xFF2E7D32),
                  onTap: () => onMark('present'),
                ),
                const SizedBox(width: 8),
                _MarkButton(
                  label: l10n.homeMarkAbsent,
                  color: scheme.error,
                  onTap: () => onMark('absent'),
                ),
                const SizedBox(width: 8),
                _MarkButton(
                  label: l10n.homeMarkRescheduled,
                  color: const Color(0xFFEF6C00),
                  onTap: () => onMark('rescheduled'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _attendanceLabel(AppLocalizations l10n, String attendance) {
    return switch (attendance) {
      'present' => l10n.homeMarkPresent,
      'absent' => l10n.homeMarkAbsent,
      _ => l10n.homeMarkRescheduled,
    };
  }

  Color _attendanceColor(String attendance, ColorScheme scheme) {
    return switch (attendance) {
      'present' => const Color(0xFF2E7D32),
      'absent' => scheme.error,
      _ => const Color(0xFFEF6C00),
    };
  }
}

class _MarkButton extends StatelessWidget {
  const _MarkButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.4)),
          padding: const EdgeInsets.symmetric(vertical: 8),
          minimumSize: const Size(0, 36),
        ),
        child: Text(label, style: const TextStyle(fontSize: 13)),
      ),
    );
  }
}

LessonSession? _lessonFor(
  List<LessonSession> lessons,
  String slotId,
  String date,
) {
  for (final lesson in lessons) {
    if (lesson.slotId == slotId && lesson.date == date) {
      return lesson;
    }
  }
  return null;
}

Future<void> _markAttendance(
  BuildContext context,
  WidgetRef ref,
  AppLocalizations l10n,
  RecurringSlot slot,
  String date,
  String attendance,
) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref.read(apiProvider).recordAttendance(
          studentId: slot.studentId,
          subjectId: slot.subjectId,
          slotId: slot.id,
          date: date,
          attendance: attendance,
        );
    ref.invalidate(lessonsProvider);
    ref.invalidate(teacherNotificationsProvider);
    if (context.mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.homeAttendanceSaved)),
      );
    }
  } catch (e) {
    if (context.mounted) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyError(e, l10n))));
    }
  }
}

/// Local 'YYYY-MM-DD' for today (matches PostgREST date columns).
String _isoToday() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}