import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:durus/core/attendance.dart';
import 'package:durus/core/utils.dart';
import 'package:durus/l10n/l10n_ext.dart';
import 'package:durus/models/models.dart';
import 'package:durus/providers/providers.dart';
import 'package:durus/widgets/widgets.dart';

/// Opens the shared session editor bottom sheet.
///
/// Returns:
///  - `'saved'`   when the attendance row was created/updated
///  - `'deleted'` when the row was cleared (undo)
///  - `null`      when dismissed without changes
Future<String?> showSessionDetailSheet(
  BuildContext context, {
  required RecurringSlot? slot,
  required LessonSession? lesson,
  required String studentName,
  required String subjectName,
  required String date,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _SessionDetailSheet(
      slot: slot,
      lesson: lesson,
      studentName: studentName,
      subjectName: subjectName,
      date: date,
    ),
  );
}

class _SessionDetailSheet extends ConsumerStatefulWidget {
  const _SessionDetailSheet({
    required this.slot,
    required this.lesson,
    required this.studentName,
    required this.subjectName,
    required this.date,
  });

  final RecurringSlot? slot;
  final LessonSession? lesson;
  final String studentName;
  final String subjectName;
  final String date;

  @override
  ConsumerState<_SessionDetailSheet> createState() =>
      _SessionDetailSheetState();
}

class _SessionDetailSheetState extends ConsumerState<_SessionDetailSheet> {
  late String _attendance;
  late final TextEditingController _topics;
  late final TextEditingController _homework;
  late final TextEditingController _note;
  String? _rescheduledTo;
  bool _saving = false;

  /// Effective slot: the real recurring slot when available, otherwise a
  /// synthetic fallback built from the recorded lesson (history view).
  RecurringSlot get _slot {
    final cached = widget.slot;
    if (cached != null) return cached;
    final lesson = widget.lesson;
    return RecurringSlot(
      id: lesson?.slotId ?? '',
      schoolId: lesson?.schoolId ?? '',
      studentId: lesson?.studentId ?? '',
      subjectId: lesson?.subjectId ?? '',
      dayOfWeek:
          lesson != null ? DateTime.tryParse(lesson.date)?.weekday ?? 1 : 1,
      startMinutes: 0,
      endMinutes: 0,
      location: 'student_home',
      teacherId: lesson?.recordedBy ?? '',
    );
  }

  @override
  void initState() {
    super.initState();
    final lesson = widget.lesson;
    _attendance = lesson?.attendance ?? 'present';
    _topics = TextEditingController(text: lesson?.topics ?? '');
    _homework = TextEditingController(text: lesson?.homework ?? '');
    _note = TextEditingController(text: lesson?.note ?? '');
    _rescheduledTo = lesson?.rescheduledTo;
  }

  @override
  void dispose() {
    _topics.dispose();
    _homework.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final api = ref.read(apiProvider);
    setState(() => _saving = true);
    try {
      final lesson = widget.lesson;
      if (lesson == null) {
        await api.recordAttendance(
          studentId: _slot.studentId,
          subjectId: _slot.subjectId,
          slotId: _slot.id,
          date: widget.date,
          attendance: _attendance,
          note: _note.text.trim(),
          topics: _topics.text.trim(),
          homework: _homework.text.trim(),
          rescheduledTo: _rescheduledTo,
        );
      } else {
        await api.updateLesson(
          lesson.id,
          attendance: _attendance,
          note: _note.text.trim(),
          topics: _topics.text.trim(),
          homework: _homework.text.trim(),
          rescheduledTo: _rescheduledTo,
        );
      }
      if (!mounted) return;
      navigator.pop('saved');
      messenger.showSnackBar(SnackBar(content: Text(l10n.homeSessionSaved)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(friendlyError(e, l10n))));
    }
  }

  Future<void> _undo() async {
    final l10n = context.l10n;
    final lesson = widget.lesson;
    if (lesson == null) return;
    final ok = await confirmDialog(
      context,
      title: l10n.sessionDetailUndoConfirmTitle,
      message: l10n.sessionDetailUndoConfirmMessage,
    );
    if (!ok || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(apiProvider).deleteLesson(lesson.id);
      if (!mounted) return;
      navigator.pop('deleted');
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.homeAttendanceCleared)),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(friendlyError(e, l10n))));
    }
  }

  Future<void> _pickDate() async {
    final l10n = context.l10n;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _rescheduledTo != null
          ? DateTime.tryParse(_rescheduledTo!) ?? now
          : now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 730)),
      helpText: l10n.sessionDetailPickDate,
    );
    if (picked != null) {
      setState(() => _rescheduledTo = isoDate(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final slot = _slot;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.sessionDetailTitle,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: l10n.commonClose,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _HeaderRow(
              icon: Icons.person_outline,
              text: widget.studentName,
            ),
            _HeaderRow(
              icon: Icons.auto_stories_outlined,
              text: widget.subjectName,
            ),
            _HeaderRow(
              icon: Icons.schedule,
              text:
                  '${timeFromMinutes(slot.startMinutes)} - ${timeFromMinutes(slot.endMinutes)} · ${fmtDate(DateTime.parse(widget.date))}',
            ),
            _HeaderRow(
              icon: Icons.place_outlined,
              text: slot.location == 'student_home'
                  ? l10n.studentsLocationHome
                  : l10n.studentsLocationTeacher,
            ),
            const SizedBox(height: 16),

            Text(
              l10n.sessionDetailAttendance,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final state in kAttendanceStates)
                  ChoiceChip(
                    selected: _attendance == state,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _attendance = state),
                    avatar: Icon(
                      attendanceStyle(l10n, scheme, state).icon,
                      size: 18,
                    ),
                    label: Text(
                      attendanceStyle(l10n, scheme, state).label,
                    ),
                    selectedColor: attendanceStyle(l10n, scheme, state)
                        .color
                        .withValues(alpha: 0.18),
                    labelStyle: TextStyle(
                      color: _attendance == state
                          ? attendanceStyle(l10n, scheme, state).color
                          : scheme.onSurfaceVariant,
                      fontWeight: _attendance == state
                          ? FontWeight.w700
                          : FontWeight.normal,
                    ),
                  ),
              ],
            ),

            if (_attendance == 'rescheduled') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.sessionDetailRescheduledTo,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _pickDate,
                    icon: Icon(
                      Icons.event_outlined,
                      size: 18,
                      color: _rescheduledTo != null
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                    label: Text(
                      _rescheduledTo != null
                          ? fmtDate(DateTime.parse(_rescheduledTo!))
                          : l10n.sessionDetailPickDate,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),
            TextField(
              controller: _topics,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.sessionDetailTopics,
                hintText: l10n.sessionDetailTopicsHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _homework,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.sessionDetailHomework,
                hintText: l10n.sessionDetailHomeworkHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              minLines: 2,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                labelText: l10n.sessionDetailNote,
                hintText: l10n.sessionDetailNoteHint,
                border: const OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                if (widget.lesson != null) ...[
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _undo,
                    icon: const Icon(Icons.undo_outlined, size: 18),
                    label: Text(l10n.sessionDetailUndo),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: scheme.error,
                      side: BorderSide(
                        color: scheme.error.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check, size: 18),
                    label: Text(
                      widget.lesson == null
                          ? l10n.sessionDetailSave
                          : l10n.commonSave,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}