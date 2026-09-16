import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:durus/core/attendance.dart';
import 'package:durus/core/utils.dart';
import 'package:durus/l10n/app_localizations.dart';
import 'package:durus/l10n/l10n_ext.dart';
import 'package:durus/models/models.dart';
import 'package:durus/providers/providers.dart';
import 'package:durus/screens/announcements_screen.dart';
import 'package:durus/screens/notifications_screen.dart';
import 'package:durus/widgets/announcement_compose_sheet.dart';
import 'package:durus/widgets/session_detail_sheet.dart';
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
          child: RefreshIndicator(
            onRefresh: () => refreshSchoolData(ref),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
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
    final slotIds = {for (final s in todaySlots) s.id};
    final recorded = lessons
        .where((l) => l.date == todayIso && slotIds.contains(l.slotId))
        .length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TodayStatsChips(
          total: todaySlots.length,
          recorded: recorded,
        ),
        const SizedBox(height: 12),
        for (final slot in todaySlots) ...[
          _SessionTile(
            slot: slot,
            studentName:
                studentsById[slot.studentId]?.name ?? l10n.commonNone,
            subjectName:
                subjectsById[slot.subjectId]?.displayLabel ?? l10n.commonNone,
            lesson: _lessonFor(lessons, slot.id, todayIso),
            onTap: () => _openDetail(
              context,
              ref,
              l10n,
              slot,
              studentsById[slot.studentId]?.name ?? l10n.commonNone,
              subjectsById[slot.subjectId]?.displayLabel ?? l10n.commonNone,
              todayIso,
            ),
            onQuickMark: (attendance) =>
                _quickMark(context, ref, l10n, slot, todayIso, attendance),
          ),
          if (slot != todaySlots.last) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

/// Compact chips: total / recorded / remaining for today.
class _TodayStatsChips extends StatelessWidget {
  const _TodayStatsChips({required this.total, required this.recorded});

  final int total;
  final int recorded;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final remaining = total - recorded;
    final chip = ({
      required String label,
      required IconData icon,
      required int value,
      Color? color,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color ?? scheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              '$label $value',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    };
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        chip(
          label: l10n.homeTodayTotal,
          icon: Icons.event_outlined,
          value: total,
        ),
        chip(
          label: l10n.homeTodayRecorded,
          icon: Icons.check_circle_outline,
          value: recorded,
          color: const Color(0xFF2E7D32),
        ),
        chip(
          label: l10n.homeTodayRemaining,
          icon: Icons.schedule,
          value: remaining,
        ),
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
          final theme = Theme.of(context);
          final children = <Widget>[];
          if (items.isEmpty) {
            children.add(
              EmptyState(
                icon: Icons.campaign_outlined,
                message: l10n.commonEmpty,
                compact: true,
              ),
            );
          } else {
            final sorted = [...items]..sort((a, b) {
                final at = a.createdAt?.millisecondsSinceEpoch ?? 0;
                final bt = b.createdAt?.millisecondsSinceEpoch ?? 0;
                return bt.compareTo(at);
              });
            final recent = sorted.take(3).toList();
            for (final item in recent) {
              final heading = item.title ?? item.body;
              children.add(
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  heading,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: item.title != null
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (item.pinned) ...[
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.push_pin,
                                  size: 14,
                                  color: theme.colorScheme.primary,
                                ),
                              ],
                            ],
                          ),
                          if (item.title != null &&
                              item.body != item.title) ...[
                            const SizedBox(height: 2),
                            Text(
                              item.body,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
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
              );
              if (item != recent.last) {
                children.add(const Divider(height: 20));
              }
            }
          }
          children.add(const SizedBox(height: 4));
          children.add(
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _compose(context, ref, l10n),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l10n.homeAddAnnouncement),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AnnouncementsScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                  label: Text(l10n.announcementsManageAll),
                ),
              ],
            ),
          );
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          );
        },
      ),
    );
  }

  Future<void> _compose(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final draft = await showAnnouncementComposeSheet(context);
    if (draft == null || !context.mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(apiProvider).createAnnouncement(
            title: draft.title,
            body: draft.body,
            audience: draft.audience,
            pinned: draft.pinned,
            expiresAt: draft.expiresAt,
          );
      ref.invalidate(announcementsProvider);
      ref.invalidate(teacherNotificationsProvider);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.homeAnnouncementAdded)),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyError(e, l10n))));
    }
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
    required this.onTap,
    required this.onQuickMark,
  });

  final RecurringSlot slot;
  final String studentName;
  final String subjectName;
  final LessonSession? lesson;
  final VoidCallback onTap;
  final ValueChanged<String> onQuickMark;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final recordedLesson = lesson;

    final status = recordedLesson == null
        ? null
        : attendanceStyle(l10n, scheme, recordedLesson.attendance);

    return Material(
      color: scheme.surfaceContainerHigh.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor:
                        scheme.primary.withValues(alpha: 0.15),
                    child: Text(
                      _initialOf(studentName),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          studentName,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subjectName,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (status != null)
                    StatusChip(label: status.label, color: status.color)
                  else
                    const Icon(Icons.touch_app_outlined,
                        size: 18, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule,
                      size: 16, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    '${timeFromMinutes(slot.startMinutes)} - '
                    '${timeFromMinutes(slot.endMinutes)}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const Spacer(),
                  Icon(Icons.place_outlined,
                      size: 16, color: scheme.onSurfaceVariant),
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
              if (recordedLesson != null &&
                  (recordedLesson.note?.isNotEmpty ??
                      false)) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.sticky_note_2_outlined,
                        size: 14, color: scheme.outline),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        recordedLesson.note!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ],
              if (recordedLesson == null) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 40,
                  child: Row(
                    children: [
                      for (final state in kAttendanceStates) ...[
                        Expanded(
                          child: _QuickMarkButton(
                            style: attendanceStyle(l10n, scheme, state),
                            onTap: () => onQuickMark(state),
                          ),
                        ),
                        if (state != kAttendanceStates.last)
                          const SizedBox(width: 6),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _initialOf(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return '?';
    }
    return trimmed.characters.first;
  }
}

class _QuickMarkButton extends StatelessWidget {
  const _QuickMarkButton({required this.style, required this.onTap});

  final AttendanceStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: style.color,
        side: BorderSide(color: style.color.withValues(alpha: 0.4)),
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        minimumSize: const Size(0, 36),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(style.icon, size: 14),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              style.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
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

Future<void> _quickMark(
  BuildContext context,
  WidgetRef ref,
  AppLocalizations l10n,
  RecurringSlot slot,
  String date,
  String attendance,
) async {
  final api = ref.read(apiProvider);
  final messenger = ScaffoldMessenger.of(context);
  try {
    final id = await api.recordAttendance(
          studentId: slot.studentId,
          subjectId: slot.subjectId,
          slotId: slot.id,
          date: date,
          attendance: attendance,
        ) ??
        '';
    ref.invalidate(lessonsProvider);
    ref.invalidate(teacherNotificationsProvider);
    if (context.mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.homeAttendanceSaved),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: l10n.commonUndo,
            onPressed: () async {
              if (id.isEmpty) {
                ref.invalidate(lessonsProvider);
                return;
              }
              await api.deleteLesson(id);
              ref.invalidate(lessonsProvider);
              ref.invalidate(teacherNotificationsProvider);
            },
          ),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      messenger.showSnackBar(SnackBar(content: Text(friendlyError(e, l10n))));
    }
  }
}

/// Opens the shared session editor (status, topics, homework, note, undo).
Future<void> _openDetail(
  BuildContext context,
  WidgetRef ref,
  AppLocalizations l10n,
  RecurringSlot slot,
  String studentName,
  String subjectName,
  String date,
) async {
  final lessons = ref.read(lessonsProvider).valueOrNull;
  final lesson = _lessonFor(lessons ?? const [], slot.id, date);
  final result = await showSessionDetailSheet(
    context,
    slot: slot,
    lesson: lesson,
    studentName: studentName,
    subjectName: subjectName,
    date: date,
  );
  if (result != null) {
    ref.invalidate(lessonsProvider);
    ref.invalidate(teacherNotificationsProvider);
  }
}

/// Local 'YYYY-MM-DD' for today (matches PostgREST date columns).
String _isoToday() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}