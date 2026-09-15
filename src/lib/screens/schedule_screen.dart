// Durus — weekly calendar (جدول الأسبوع).
//
// Shows one week at a time: a header with prev/this/next navigation and seven
// day sections listing both recurring slots (from `recurring_slots`) and
// recorded sessions (attendance rows) that fall on each day.
//
// Arabic-only, RTL. All user-facing strings come from `context.l10n`.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:durus/core/utils.dart';
import 'package:durus/l10n/app_localizations.dart';
import 'package:durus/l10n/l10n_ext.dart';
import 'package:durus/models/models.dart';
import 'package:durus/providers/providers.dart';
import 'package:durus/widgets/widgets.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    _weekStart = _mondayOf(DateTime.now());
  }

  DateTime _mondayOf(DateTime d) {
    final weekday = d.weekday; // 1 = Mon .. 7 = Sun
    return DateTime(d.year, d.month, d.day - (weekday - 1));
  }

  void _shiftWeek(int delta) {
    setState(() => _weekStart = _weekStart.add(Duration(days: delta * 7)));
  }

  void _goToThisWeek() {
    setState(() => _weekStart = _mondayOf(DateTime.now()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final slotsAsync = ref.watch(slotsProvider);
    final lessonsAsync = ref.watch(lessonsProvider);
    final students = ref.watch(studentsProvider).value ?? const <Student>[];
    final subjects = ref.watch(subjectsProvider).value ?? const <Subject>[];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.scheduleWeeklyTitle)),
      body: Column(
        children: [
          _weekHeader(context, l10n),
          const Divider(height: 1),
          Expanded(
            child: slotsAsync.when(
              loading: () => const LoadingView(),
              error: (error, stackTrace) => ErrorRetry(
                message: l10n.commonError,
                onRetry: () => ref.invalidate(slotsProvider),
              ),
              data: (slots) => lessonsAsync.when(
                loading: () => const LoadingView(),
                error: (error, stackTrace) => ErrorRetry(
                  message: l10n.commonError,
                  onRetry: () => ref.invalidate(lessonsProvider),
                ),
                data: (lessons) =>
                    _weekList(context, l10n, slots, lessons, students, subjects),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _weekHeader(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            tooltip: l10n.schedulePrevWeek,
            onPressed: () => _shiftWeek(-1),
            icon: const Icon(Icons.navigate_before),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  _weekRangeLabel(_weekStart),
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                TextButton(
                  onPressed: _goToThisWeek,
                  child: Text(l10n.scheduleThisWeek),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.scheduleNextWeek,
            onPressed: () => _shiftWeek(1),
            icon: const Icon(Icons.navigate_next),
          ),
        ],
      ),
    );
  }

  Widget _weekList(
    BuildContext context,
    AppLocalizations l10n,
    List<RecurringSlot> slots,
    List<LessonSession> lessons,
    List<Student> students,
    List<Subject> subjects,
  ) {
    final today = DateTime.now();
    final todayKey = isoDate(today);
    final items = <Widget>[];
    for (var i = 0; i < 7; i++) {
      final day = _weekStart.add(Duration(days: i));
      final dayKey = isoDate(day);
      final isToday = dayKey == todayKey;
      final daySlots = slots
          .where((s) => s.dayOfWeek == day.weekday && s.active)
          .toList()
        ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
      final dayLessons = lessons.where((l) => l.date == dayKey).toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      final empty = daySlots.isEmpty && dayLessons.isEmpty;

      items.add(
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _weekdayLabel(day.weekday),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isToday
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      fmtDate(day),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (empty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      l10n.scheduleNoSlots,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                else ...[
                  for (final slot in daySlots)
                    _slotRow(context, l10n, slot, students, subjects),
                  for (final lesson in dayLessons)
                    _lessonRow(context, l10n, lesson, students, subjects),
                ],
              ],
            ),
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: items,
    );
  }

  Widget _slotRow(
    BuildContext context,
    AppLocalizations l10n,
    RecurringSlot slot,
    List<Student> students,
    List<Subject> subjects,
  ) {
    final theme = Theme.of(context);
    final student = _studentById(students, slot.studentId);
    final subjectName = _subjectName(subjects, slot.subjectId);
    final location = _locationLabel(l10n, slot.location);
    final detailParts = <String>[
      if (student != null) student.name,
      if (subjectName.isNotEmpty) subjectName,
      if (location.isNotEmpty) location,
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(Icons.repeat, size: 16, color: theme.colorScheme.outline),
          const SizedBox(width: 6),
          SizedBox(
            width: 82,
            child: Text(
              '${timeFromMinutes(slot.startMinutes)} - '
              '${timeFromMinutes(slot.endMinutes)}',
              style: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              detailParts.isEmpty
                  ? l10n.scheduleRecurringSlot
                  : detailParts.join(' • '),
              style: theme.textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _lessonRow(
    BuildContext context,
    AppLocalizations l10n,
    LessonSession lesson,
    List<Student> students,
    List<Subject> subjects,
  ) {
    final theme = Theme.of(context);
    final student = _studentById(students, lesson.studentId);
    final subjectName = _subjectName(subjects, lesson.subjectId);
    final (label, color) = _attendanceStyle(l10n, lesson.attendance);
    final detailParts = <String>[
      if (student != null) student.name,
      if (subjectName.isNotEmpty) subjectName,
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              detailParts.isEmpty
                  ? l10n.scheduleRecurringSlot
                  : detailParts.join(' • '),
              style: theme.textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          StatusChip(label: label, color: color),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  String _weekRangeLabel(DateTime start) {
    final end = start.add(const Duration(days: 6));
    if (start.year == end.year && start.month == end.month) {
      return '${_dayNum(start)} - ${_dayNum(end)} '
          '${arabicMonths[start.month - 1]} ${start.year}';
    }
    if (start.year == end.year) {
      return '${_dayNum(start)} ${arabicMonths[start.month - 1]} - '
          '${_dayNum(end)} ${arabicMonths[end.month - 1]} ${start.year}';
    }
    return '${_dayNum(start)} ${arabicMonths[start.month - 1]} ${start.year} - '
        '${_dayNum(end)} ${arabicMonths[end.month - 1]} ${end.year}';
  }

  String _dayNum(DateTime d) => d.day.toString();

  String _weekdayLabel(int weekday) {
    final index = weekday - 1;
    if (index < 0 || index >= arabicWeekdays.length) return '';
    return arabicWeekdays[index];
  }

  Student? _studentById(List<Student> students, String id) {
    for (final student in students) {
      if (student.id == id) return student;
    }
    return null;
  }

  String _subjectName(List<Subject> subjects, String? subjectId) {
    if (subjectId == null) return '';
    for (final subject in subjects) {
      if (subject.id == subjectId) return subject.displayLabel;
    }
    return '';
  }

  String _locationLabel(AppLocalizations l10n, String? location) {
    return switch (location) {
      'student_home' => l10n.studentsLocationHome,
      'teacher' => l10n.studentsLocationTeacher,
      _ => location ?? '',
    };
  }

  (String, Color) _attendanceStyle(AppLocalizations l10n, String attendance) {
    return switch (attendance) {
      'present' => (l10n.homeMarkPresent, Colors.green),
      'absent' => (l10n.homeMarkAbsent, Colors.red),
      'rescheduled' => (l10n.homeMarkRescheduled, Colors.orange),
      _ => (attendance, Colors.blueGrey),
    };
  }
}