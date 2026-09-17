// Durus — weekly calendar (جدول الأسبوع).
//
// Chosen design (option 6 — التوليفة): a green "today" hero card on top, a
// seven-day tab strip, then a vertical timeline (axis on the right, RTL):
// recurring slots render as dashed teal blocks ("مكرر"), recorded sessions
// render with their attendance color and chip. Lessons whose slot is missing
// are grouped under the timeline as "جلسات بدون موعد".
//
// Arabic-only, RTL. All user-facing strings come from `context.l10n`.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:durus/core/attendance.dart';
import 'package:durus/core/utils.dart';
import 'package:durus/l10n/app_localizations.dart';
import 'package:durus/l10n/l10n_ext.dart';
import 'package:durus/models/models.dart';
import 'package:durus/providers/providers.dart';
import 'package:durus/widgets/durus_top_bar.dart';
import 'package:durus/widgets/session_detail_sheet.dart';
import 'package:durus/widgets/widgets.dart';

/// One positioned block on the timeline: either a recurring slot (`rec`) or a
/// recorded lesson that carries the same visual language as the rest of the
/// app (present/late/absent…).
class _TimelineEntry {
  _TimelineEntry.rec(this.slot)
      : assert(slot != null),
        lesson = null;

  _TimelineEntry.lesson(this.lesson, {required this.slot}) : assert(lesson != null);

  final RecurringSlot? slot;
  final LessonSession? lesson;

  bool get isRec => lesson == null;
  int get startMinutes => slot!.startMinutes;
  int get endMinutes => slot!.endMinutes;
  String get studentId => lesson?.studentId ?? slot!.studentId;
  String? get subjectId => lesson?.subjectId ?? slot!.subjectId;
}

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  late DateTime _weekStart;
  int _selectedIndex = 0; // 0 = Monday .. 6 = Sunday

  @override
  void initState() {
    super.initState();
    _weekStart = _mondayOf(DateTime.now());
    _selectedIndex = DateTime.now().weekday - 1;
  }

  DateTime _mondayOf(DateTime d) {
    final weekday = d.weekday; // 1 = Mon .. 7 = Sun
    return DateTime(d.year, d.month, d.day - (weekday - 1));
  }

  void _shiftWeek(int delta) {
    setState(() => _weekStart = _weekStart.add(Duration(days: delta * 7)));
  }

  void _goToThisWeek() {
    setState(() {
      _weekStart = _mondayOf(DateTime.now());
      _selectedIndex = DateTime.now().weekday - 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final slotsAsync = ref.watch(slotsProvider);
    final lessonsAsync = ref.watch(lessonsProvider);
    final students = ref.watch(studentsProvider).value ?? const <Student>[];
    final subjects = ref.watch(subjectsProvider).value ?? const <Subject>[];

    return Scaffold(
      appBar: DurusTopBar(title: l10n.scheduleWeeklyTitle),
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
                    _comboView(context, l10n, slots, lessons, students, subjects),
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

  // -------------------------------------------------------------------------
  // Combo view: hero card + day tabs + timeline
  // -------------------------------------------------------------------------

  Widget _comboView(
    BuildContext context,
    AppLocalizations l10n,
    List<RecurringSlot> slots,
    List<LessonSession> lessons,
    List<Student> students,
    List<Subject> subjects,
  ) {
    final today = DateTime.now();
    final todayKey = isoDate(today);
    final day = _weekStart.add(Duration(days: _selectedIndex));
    final dayKey = isoDate(day);
    final isToday = dayKey == todayKey;

    // Recurring slots for the selected weekday, sorted by start time.
    // Non-active students leave the timeline (their recorded history,
    // including untimed rows, still shows below).
    final statusByStudent = {for (final st in students) st.id: st.status};
    final daySlots = slots
        .where((s) =>
            s.dayOfWeek == day.weekday &&
            s.active &&
            (statusByStudent[s.studentId] ?? 'active') == 'active')
        .toList()
      ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

    // Recorded lessons for the selected date.
    final dayLessons = lessons.where((l) => l.date == dayKey).toList();

    // Resolve each lesson's time from its recurring slot (slot id may be empty
    // for ad-hoc history rows).
    final slotById = {for (final s in slots) s.id: s};
    final resolved = <_TimelineEntry>[];
    final untimed = <LessonSession>[];
    for (final lesson in dayLessons) {
      final slot = (lesson.slotId != null) ? slotById[lesson.slotId] : null;
      if (slot == null) {
        untimed.add(lesson);
      } else {
        resolved.add(_TimelineEntry.lesson(lesson, slot: slot));
      }
    }
    final usedSlotIds = resolved.map((e) => e.slot!.id).toSet();

    // Merge: a recorded session replaces its template slot; remaining slots
    // are shown as dashed recurring blocks.
    final entries = <_TimelineEntry>[
      for (final slot in daySlots)
        if (!usedSlotIds.contains(slot.id)) _TimelineEntry.rec(slot),
      ...resolved,
    ]..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

    return RefreshIndicator(
      onRefresh: () => refreshSchoolData(ref),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _heroCard(context, l10n, day, isToday, entries, untimed, students,
              subjects),
          _dayTabs(context, l10n, todayKey),
          _timeline(context, l10n, entries, students, subjects, slots),
          if (untimed.isNotEmpty) _untimedSection(context, l10n, untimed, students, subjects, slots),
        ],
      ),
    );
  }

  // ── Hero card ────────────────────────────────────────────────────────────

  Widget _heroCard(
    BuildContext context,
    AppLocalizations l10n,
    DateTime day,
    bool isToday,
    List<_TimelineEntry> entries,
    List<LessonSession> untimed,
    List<Student> students,
    List<Subject> subjects,
  ) {
    final label = isToday
        ? '${l10n.scheduleDay} — ${_weekdayLabel(day.weekday)} ${_dayNum(day)}'
        : '${_weekdayLabel(day.weekday)} ${_dayNum(day)}';

    _TimelineEntry? next;
    if (entries.isNotEmpty) {
      if (isToday) {
        final nowMin = DateTime.now().hour * 60 + DateTime.now().minute;
        for (final e in entries) {
          if (e.endMinutes > nowMin) {
            next = e;
            break;
          }
        }
        next ??= entries.first;
      } else {
        next = entries.first;
      }
    }

    final heroCount = entries.length + untimed.length;
    final countText = isToday
        ? '${l10n.scheduleHeroCount(heroCount)} ${l10n.scheduleDay}'
        : l10n.scheduleHeroCount(heroCount);

    String nowLine;
    String nextLine;
    String? soonText;
    if (next == null) {
      nowLine = l10n.scheduleHeroNoSessions;
      nextLine = l10n.scheduleHeroFreeDay;
    } else {
      nowLine = isToday
          ? l10n.scheduleHeroComingNext(timeFromMinutes(next.startMinutes))
          : l10n.scheduleHeroFirstSession(timeFromMinutes(next.startMinutes));
      nextLine = _heroDetail(l10n, next, students, subjects);
      if (isToday) {
        final diff = next.startMinutes -
            (DateTime.now().hour * 60 + DateTime.now().minute);
        if (diff >= 1) soonText = l10n.scheduleHeroAfterMinutes(diff);
      }
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A3B2E), Color(0xFF0E7C66), Color(0xFF12A083)],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            left: -30,
            top: -40,
            child: _HeroCircle(size: 130, alpha: 0.08),
          ),
          const Positioned(
            left: 30,
            bottom: -50,
            child: _HeroCircle(size: 100, alpha: 0.06),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  nowLine,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                Text(
                  nextLine,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        countText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (soonText != null)
                      Text(
                        soonText,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _heroDetail(
    AppLocalizations l10n,
    _TimelineEntry entry,
    List<Student> students,
    List<Subject> subjects,
  ) {
    final student = _studentById(students, entry.studentId);
    final subjectName = _subjectName(subjects, entry.subjectId);
    final location = entry.isRec
        ? _locationLabel(l10n, entry.slot!.location)
        : _locationLabel(l10n, entry.slot!.location);
    final parts = <String>[
      subjectName.isNotEmpty && student != null
          ? '$subjectName ${l10n.scheduleWith} ${student.name}'
          : (student?.name ?? subjectName),
      if (location.isNotEmpty) location,
    ];
    return parts.join(' • ');
  }

  // ── Day tabs ─────────────────────────────────────────────────────────────

  Widget _dayTabs(BuildContext context, AppLocalizations l10n, String todayKey) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(child: _dayTab(context, l10n, i, todayKey)),
        ],
      ),
    );
  }

  Widget _dayTab(
    BuildContext context,
    AppLocalizations l10n,
    int index,
    String todayKey,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final day = _weekStart.add(Duration(days: index));
    final isToday = isoDate(day) == todayKey;
    final isOn = index == _selectedIndex;

    Color bg = scheme.surface;
    Color fg = scheme.onSurfaceVariant;
    Color border = scheme.outlineVariant;
    if (isOn) {
      bg = scheme.primary;
      fg = Colors.white;
      border = scheme.primary;
    } else if (isToday) {
      bg = scheme.primaryContainer;
      fg = scheme.primary;
      border = scheme.primary;
    }

    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          _tabLabel(l10n, day.weekday),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: fg,
          ),
        ),
      ),
    );
  }

  String _tabLabel(AppLocalizations l10n, int weekday) {
    return switch (weekday) {
      1 => l10n.scheduleTabMon,
      2 => l10n.scheduleTabTue,
      3 => l10n.scheduleTabWed,
      4 => l10n.scheduleTabThu,
      5 => l10n.scheduleTabFri,
      6 => l10n.scheduleTabSat,
      _ => l10n.scheduleTabSun,
    };
  }

  // ── Timeline ─────────────────────────────────────────────────────────────

  Widget _timeline(
    BuildContext context,
    AppLocalizations l10n,
    List<_TimelineEntry> entries,
    List<Student> students,
    List<Subject> subjects,
    List<RecurringSlot> slots,
  ) {
    final scheme = Theme.of(context).colorScheme;
    const pxPerMin = 50 / 90; // 90 min = 50 px, per the design spec

    var gridStart = 480; // 08:00
    var gridEnd = 1020; // 17:00
    if (entries.isNotEmpty) {
      final earliest = entries.map((e) => e.startMinutes).reduce(math.min);
      final latest = entries.map((e) => e.endMinutes).reduce(math.max);
      gridStart = math.max(0, ((earliest - 30) ~/ 30) * 30);
      gridEnd = math.min(1440, ((latest + 30 + 29) ~/ 30) * 30);
    }

    final lines = <int>[];
    for (var m = gridStart; m <= gridEnd; m += 90) {
      lines.add(m);
    }

    final height = (gridEnd - gridStart) * pxPerMin + 12;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SizedBox(
        height: height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hour gutter on the axis side (right in RTL).
            SizedBox(
              width: 34,
              child: Stack(
                children: [
                  for (final m in lines)
                    Positioned(
                      top: 6 + (m - gridStart) * pxPerMin - 5,
                      left: 0,
                      width: 32,
                      child: Text(
                        timeFromMinutes(m),
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: BorderDirectional(
                    start: BorderSide(width: 2, color: scheme.outlineVariant),
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    for (final m in lines)
                      Positioned(
                        top: 6 + (m - gridStart) * pxPerMin,
                        left: 0,
                        right: 0,
                        child: _DashedLine(color: scheme.outlineVariant),
                      ),
                    for (final e in entries)
                      Positioned(
                        top: 8 + (e.startMinutes - gridStart) * pxPerMin,
                        left: 5,
                        right: 5,
                        height: math.max(
                            (e.endMinutes - e.startMinutes) * pxPerMin, 30),
                        child: _timelineBlock(
                            context, l10n, e, students, subjects, slots),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timelineBlock(
    BuildContext context,
    AppLocalizations l10n,
    _TimelineEntry entry,
    List<Student> students,
    List<Subject> subjects,
    List<RecurringSlot> slots,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final student = _studentById(students, entry.studentId);
    final subjectName = _subjectName(subjects, entry.subjectId);
    final timeRange =
        '${timeFromMinutes(entry.startMinutes)} – ${timeFromMinutes(entry.endMinutes)}';

    if (entry.isRec) {
      final slot = entry.slot!;
      return InkWell(
        onTap: () => _recordSlot(
          context,
          l10n,
          slot,
          student?.name ?? '',
          subjectName,
        ),
        borderRadius: BorderRadius.circular(10),
        child: _DashBorder(
          color: scheme.primary,
          child: _blockShell(
            scheme: scheme,
            bg: scheme.primaryContainer,
            textColor: scheme.onPrimaryContainer,
            startBorderColor: null,
            nm: l10n.scheduleRecurringSlot,
            sb: '$timeRange • ${student?.name ?? ''}',
            chip: _blockChip(
              l10n.scheduleRecurringChip,
              scheme.primary,
              scheme.primary.withValues(alpha: 0.15),
            ),
          ),
        ),
      );
    }

    final lesson = entry.lesson!;
    final style = attendanceStyle(l10n, scheme, lesson.attendance);
    final bg = _lessonBg(lesson.attendance, scheme);
    return InkWell(
      onTap: () => _openLesson(
        context,
        l10n,
        lesson,
        student?.name ?? '',
        subjectName,
        slots,
      ),
      borderRadius: BorderRadius.circular(10),
      child: _blockShell(
        scheme: scheme,
        bg: bg,
        textColor: scheme.onSurface,
        startBorderColor: style.color,
        nm: student?.name ?? l10n.scheduleRecurringSlot,
        sb: '$timeRange • ${subjectName.isEmpty ? (student?.name ?? '') : subjectName}',
        chip: lesson.attendance == 'present'
            ? _blockChip(style.label, Colors.white, style.color)
            : _blockChip(style.label, style.color, Colors.white),
      ),
    );
  }

  Color _lessonBg(String attendance, ColorScheme scheme) {
    return switch (attendance) {
      'present' => const Color(0xFFE4F2E4),
      'late' => const Color(0xFFFFF3D6),
      'absent' => const Color(0xFFFBE3E3),
      'rescheduled' => const Color(0xFFFFE8D1),
      'cancelled' => scheme.surfaceContainerHighest,
      _ => scheme.surfaceContainerHighest,
    };
  }

  Widget _blockShell({
    required ColorScheme scheme,
    required Color bg,
    required Color textColor,
    required Color? startBorderColor,
    required String nm,
    required String sb,
    required Widget chip,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: startBorderColor == null
            ? null
            : BorderDirectional(
                start: BorderSide(color: startBorderColor, width: 3),
              ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  nm,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ),
              chip,
            ],
          ),
          Text(
            sb,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: textColor.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blockChip(String label, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  // ── Untimed recorded lessons ─────────────────────────────────────────────

  Widget _untimedSection(
    BuildContext context,
    AppLocalizations l10n,
    List<LessonSession> lessons,
    List<Student> students,
    List<Subject> subjects,
    List<RecurringSlot> slots,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.scheduleUntimedTitle,
            style: theme.textTheme.labelMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          for (final lesson in lessons)
            _untimedRow(context, l10n, lesson, students, subjects, slots),
        ],
      ),
    );
  }

  Widget _untimedRow(
    BuildContext context,
    AppLocalizations l10n,
    LessonSession lesson,
    List<Student> students,
    List<Subject> subjects,
    List<RecurringSlot> slots,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final student = _studentById(students, lesson.studentId);
    final subjectName = _subjectName(subjects, lesson.subjectId);
    final style = attendanceStyle(l10n, scheme, lesson.attendance);
    final detailParts = <String>[
      if (student != null) student.name,
      if (subjectName.isNotEmpty) subjectName,
    ];
    return InkWell(
      onTap: () => _openLesson(
        context,
        l10n,
        lesson,
        student?.name ?? '',
        subjectName,
        slots,
      ),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
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
            StatusChip(label: style.label, color: style.color),
          ],
        ),
      ),
    );
  }

  /// Records attendance for a recurring slot that has no recorded lesson
  /// yet: opens the shared session sheet in create mode for the selected
  /// day (same flow as Home's tap-anywhere tile). Re-checks for an
  /// existing lesson first so a tap can never create a duplicate.
  Future<void> _recordSlot(
    BuildContext context,
    AppLocalizations l10n,
    RecurringSlot slot,
    String studentName,
    String subjectName,
  ) async {
    final day = _weekStart.add(Duration(days: _selectedIndex));
    final date = isoDate(day);
    final lessons = ref.read(lessonsProvider).valueOrNull ?? const <LessonSession>[];
    LessonSession? lesson;
    for (final l in lessons) {
      if (l.slotId == slot.id && l.date == date) {
        lesson = l;
        break;
      }
    }
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

  Future<void> _openLesson(
    BuildContext context,
    AppLocalizations l10n,
    LessonSession lesson,
    String studentName,
    String subjectName,
    List<RecurringSlot> slots,
  ) async {
    RecurringSlot? slot;
    for (final s in slots) {
      if (s.id == lesson.slotId) {
        slot = s;
        break;
      }
    }
    final result = await showSessionDetailSheet(
      context,
      slot: slot,
      lesson: lesson,
      studentName: studentName,
      subjectName: subjectName,
      date: lesson.date,
    );
    if (result != null) {
      ref.invalidate(lessonsProvider);
      ref.invalidate(teacherNotificationsProvider);
    }
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
}

/// Decorative translucent circle on the hero card.
class _HeroCircle extends StatelessWidget {
  const _HeroCircle({required this.size, required this.alpha});

  final double size;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: alpha),
      ),
    );
  }
}

/// 1px dashed horizontal line (hour grid).
class _DashedLine extends StatelessWidget {
  const _DashedLine({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 1,
      width: double.infinity,
      child: CustomPaint(painter: _DashLinePainter(color)),
    );
  }
}

class _DashLinePainter extends CustomPainter {
  const _DashLinePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const dash = 4.0;
    const gap = 3.0;
    var x = 0.0;
    while (x < size.width) {
      final end = math.min(x + dash, size.width);
      canvas.drawLine(Offset(x, 0), Offset(end, 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DashLinePainter old) => old.color != color;
}

/// Wraps a child with a dashed rounded border (clocked to the 4 edges).
class _DashBorder extends StatelessWidget {
  const _DashBorder({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashRectPainter(color),
      child: child,
    );
  }
}

class _DashRectPainter extends CustomPainter {
  const _DashRectPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    const dash = 4.0;
    const gap = 3.0;
    final w = size.width;
    final h = size.height;
    _dash(canvas, paint, Offset(0, 0), Offset(w, 0), dash, gap);
    _dash(canvas, paint, Offset(w, 0), Offset(w, h), dash, gap);
    _dash(canvas, paint, Offset(0, h), Offset(w, h), dash, gap);
    _dash(canvas, paint, Offset(0, 0), Offset(0, h), dash, gap);
  }

  void _dash(
    Canvas canvas,
    Paint paint,
    Offset a,
    Offset b,
    double dash,
    double gap,
  ) {
    final total = (b - a).distance;
    if (total <= 0) return;
    final dir = (b - a) / total;
    var d = 0.0;
    while (d < total) {
      final end = math.min(d + dash, total);
      canvas.drawLine(a + dir * d, a + dir * end, paint);
      d += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DashRectPainter old) => old.color != color;
}