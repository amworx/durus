// Durus — subjects screens (list / form).
//
// Arabic-only, RTL. All user-facing strings come from `context.l10n`.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:durus/core/durus_api.dart';
import 'package:durus/core/utils.dart';
import 'package:durus/l10n/app_localizations.dart';
import 'package:durus/l10n/l10n_ext.dart';
import 'package:durus/models/models.dart';
import 'package:durus/providers/providers.dart';
import 'package:durus/widgets/durus_top_bar.dart';
import 'package:durus/widgets/widgets.dart';

// ---------------------------------------------------------------------------
// Subjects list
// ---------------------------------------------------------------------------

/// Aggregates for one subject: enrolled students, this-month sessions,
/// tests (+passed at >=50%), and estimated income (each student's paid
/// total split evenly across their subjects — an estimate, never exact
/// when students take several subjects).
({int students, int sessions, int tests, int passed, double income})
    _subjectStats(
  String subjectId, {
  required List<StudentSubjectRef> refs,
  required List<LessonSession> lessons,
  required List<TestResult> tests,
  required List<Fee> fees,
  required List<Student> students,
  required String month,
}) {
  final enrolled = {
    for (final r in refs)
      if (r.subjectId == subjectId) r.studentId,
  };
  var sessions = 0;
  for (final l in lessons) {
    if (l.subjectId == subjectId && l.date.startsWith(month)) sessions++;
  }
  var testCount = 0;
  var passed = 0;
  for (final t in tests) {
    if (t.subjectId != subjectId) continue;
    testCount++;
    final max = (t.maxScore ?? 0).toDouble();
    if (max > 0 && (t.score ?? 0).toDouble() / max >= 0.5) passed++;
  }
  var income = 0.0;
  for (final id in enrolled) {
    var paid = 0.0;
    for (final f in fees) {
      if (f.studentId == id) paid += f.paidAmount;
    }
    var shares = 0;
    for (final r in refs) {
      if (r.studentId == id) shares++;
    }
    if (shares > 0) income += paid / shares;
  }
  return (
    students: enrolled.length,
    sessions: sessions,
    tests: testCount,
    passed: passed,
    income: income,
  );
}

class SubjectsScreen extends ConsumerWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: DurusTopBar(
        title: l10n.subjectsTitle,
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.subjectsAddTitle,
        onPressed: () => _openSubjectForm(context, null),
        child: const Icon(Icons.add),
      ),
      body: const _SubjectsBody(),
    );
  }
}

class _SubjectsBody extends ConsumerStatefulWidget {
  const _SubjectsBody();

  @override
  ConsumerState<_SubjectsBody> createState() => _SubjectsBodyState();
}

class _SubjectsBodyState extends ConsumerState<_SubjectsBody> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _filterGrade; // null = all
  final Set<String> _selected = {};
  bool get _selecting => _selected.isNotEmpty;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggle(String id) => setState(() {
        if (_selected.contains(id)) {
          _selected.remove(id);
        } else {
          _selected.add(id);
        }
      });

  void _selectAll(List<Subject> ids) => setState(() {
        if (_selected.length == ids.length) {
          _selected.clear();
        } else {
          _selected.addAll(ids.map((s) => s.id));
        }
      });

  Future<void> _bulkDelete() async {
    final l10n = context.l10n;
    final ok = await confirmDialog(
      context,
      title: l10n.bulkDeleteTitle,
      message: l10n.bulkDeleteConfirm(_selected.length),
    );
    if (!ok || !mounted) return;
    try {
      final api = ref.read(apiProvider);
      await api.deleteSubjects(_selected.toList());
      _selected.clear();
      ref.invalidate(subjectsProvider);
      ref.invalidate(studentSubjectRefsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.bulkCompleted)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.commonError)),
        );
      }
    }
  }

  Future<void> _bulkSetGrade() async {
    final l10n = context.l10n;
    final controller = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.bulkSetGradeTitle),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: l10n.subjectsGrade,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
    if (result == null || !mounted) return;
    try {
      final api = ref.read(apiProvider);
      await api.updateSubjectsGrade(
        _selected.toList(),
        result.isEmpty ? null : result,
      );
      _selected.clear();
      ref.invalidate(subjectsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.bulkCompleted)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.commonError)),
        );
      }
    }
  }

  // ── filter sheet (compact button + modal bottom sheet) ──

  int get _activeFilterCount => _filterGrade != null ? 1 : 0;

  Future<void> _openFilterSheet() async {
    final l10n = context.l10n;
    final subjects = ref.read(subjectsProvider).value ?? const <Subject>[];
    final result = await showFilterSheet(
      context,
      title: l10n.filterTitle,
      sections: [
        FilterSheetSection(
          id: 'grade',
          label: l10n.subjectsGrade,
          current: _filterGrade,
          choices: [
            FilterChoice(null, l10n.filterAllGrades),
            for (final g in _uniqueGrades(subjects)) FilterChoice(g, g),
          ],
        ),
      ],
    );
    if (result == null || !mounted) return;
    setState(() => _filterGrade = result['grade']);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final subjectsAsync = ref.watch(subjectsProvider);
    final refsAsync = ref.watch(studentSubjectRefsProvider);
    final lessons = ref.watch(lessonsProvider).value ?? const <LessonSession>[];
    final tests = ref.watch(testsProvider).value ?? const <TestResult>[];
    final fees = ref.watch(feesProvider).value ?? const <Fee>[];
    final students = ref.watch(studentsProvider).value ?? const <Student>[];
    final nowMonth = monthKey(DateTime.now());
    return Column(
      children: [
        // ── search + filter row ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value.trim()),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: l10n.commonSearch,
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilterButton(
                activeCount: _activeFilterCount,
                onPressed: _openFilterSheet,
              ),
            ],
          ),
        ),
        Expanded(
          child: subjectsAsync.when(
            loading: () => const LoadingView(),
            error: (error, stackTrace) => ErrorRetry(
              message: l10n.commonError,
              onRetry: () => ref.invalidate(subjectsProvider),
            ),
            data: (subjects) {
              final refs = refsAsync.value ?? const <StudentSubjectRef>[];
              var visible = subjects.where((s) {
                if (_filterGrade != null && (s.grade ?? '') != _filterGrade) {
                  return false;
                }
                return true;
              }).toList();
              if (_query.isNotEmpty) {
                visible = visible.where((s) => s.name.contains(_query)).toList();
              }
              if (visible.isEmpty) {
                return RefreshableEmpty(
                  onRefresh: () => refreshSchoolData(ref),
                  empty: EmptyState(
                    icon: (_query.isEmpty && _filterGrade == null)
                        ? Icons.menu_book_outlined
                        : Icons.search_off,
                    message: (_query.isEmpty && _filterGrade == null)
                        ? l10n.subjectsEmpty
                        : l10n.commonEmpty,
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () => refreshSchoolData(ref),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                  itemCount: visible.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final subject = visible[index];
                    final scheme = Theme.of(context).colorScheme;
                    final stats = _subjectStats(
                      subject.id,
                      refs: refs,
                      lessons: lessons,
                      tests: tests,
                      fees: fees,
                      students: students,
                      month: nowMonth,
                    );
                    final count = stats.students;
                    final grade = subject.grade;
                    final subtitleParts = <String>[
                      if (grade != null && grade.isNotEmpty)
                        '${l10n.subjectsGrade}: $grade',
                      '${l10n.subjectsStudentsCount}: $count',
                    ];
                    final isSelected = _selected.contains(subject.id);
                    return ListTile(
                      leading: _selecting
                          ? Checkbox(
                              value: isSelected,
                              onChanged: (_) => _toggle(subject.id),
                            )
                          : const CircleAvatar(child: Icon(Icons.menu_book_outlined)),
                      title: Text(subject.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(subtitleParts.join(' • ')),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              StatusChip(
                                label:
                                    '${stats.students} ${l10n.subjectsBadgeStudents}',
                                color: scheme.primary,
                              ),
                              StatusChip(
                                label:
                                    '${stats.sessions} ${l10n.subjectsBadgeSessions}',
                                color: scheme.tertiary,
                              ),
                              StatusChip(
                                label:
                                    '${stats.passed}/${stats.tests} ${l10n.subjectsBadgePass}',
                                color: Colors.green.shade700,
                              ),
                              StatusChip(
                                label:
                                    '~${stats.income.toStringAsFixed(0)} ${l10n.subjectsBadgeIncome}',
                                color: Colors.orange.shade800,
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: _selecting
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: l10n.commonEdit,
                              onPressed: () => _openSubjectForm(context, subject),
                            ),
                      selected: isSelected,
                      selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.25),
                      onTap: _selecting
                          ? () => _toggle(subject.id)
                          : () => _openSubjectForm(context, subject),
                      onLongPress: _selecting ? null : () => _toggle(subject.id),
                    );
                  },
                ),
              );
            },
          ),
        ),
        if (_selecting)
          SelectionBar(
            count: _selected.length,
            total: subjectsAsync.value?.length ?? 0,
            onClose: () => setState(() => _selected.clear()),
            onSelectAll: () {
              final current = ref.read(subjectsProvider).value ?? const <Subject>[];
              final ids = current.where((s) {
                if (_filterGrade != null && (s.grade ?? '') != _filterGrade) return false;
                if (_query.isNotEmpty && !s.name.contains(_query)) return false;
                return true;
              }).toList();
              _selectAll(ids);
            },
            actions: [
              BulkAction(
                icon: Icons.grade_outlined,
                label: l10n.bulkSetGrade,
                onTap: _bulkSetGrade,
              ),
              BulkAction(
                icon: Icons.delete_outline,
                label: l10n.commonDelete,
                color: Theme.of(context).colorScheme.error,
                onTap: _bulkDelete,
              ),
            ],
          ),
      ],
    );
  }

  List<String> _uniqueGrades(List<Subject> subjects) {
    final set = <String>{};
    for (final s in subjects) {
      final g = s.grade;
      if (g != null && g.isNotEmpty) set.add(g);
    }
    return set.toList()..sort();
  }
}

// ---------------------------------------------------------------------------
// Subject form (create / edit)
// ---------------------------------------------------------------------------

class SubjectFormScreen extends ConsumerStatefulWidget {
  const SubjectFormScreen({super.key, this.subject});

  final Subject? subject;

  @override
  ConsumerState<SubjectFormScreen> createState() => _SubjectFormScreenState();
}

class _SubjectFormScreenState extends ConsumerState<SubjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _gradeController;
  late final TextEditingController _notesController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final subject = widget.subject;
    _nameController = TextEditingController(text: subject?.name ?? '');
    _gradeController = TextEditingController(text: subject?.grade ?? '');
    _notesController = TextEditingController(text: subject?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gradeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _subjectStatsCard(
    BuildContext context,
    AppLocalizations l10n,
    Subject subject,
  ) {
    final refs =
        ref.watch(studentSubjectRefsProvider).value ?? const <StudentSubjectRef>[];
    final stats = _subjectStats(
      subject.id,
      refs: refs,
      lessons: ref.watch(lessonsProvider).value ?? const <LessonSession>[],
      tests: ref.watch(testsProvider).value ?? const <TestResult>[],
      fees: ref.watch(feesProvider).value ?? const <Fee>[],
      students: ref.watch(studentsProvider).value ?? const <Student>[],
      month: monthKey(DateTime.now()),
    );
    return SectionCard(
      title: l10n.subjectsStatsTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _statRow(
            l10n.subjectsBadgeStudents,
            '${stats.students}',
          ),
          _statRow(
            l10n.subjectsBadgeSessions,
            '${stats.sessions}',
          ),
          _statRow(
            l10n.subjectsBadgePass,
            '${stats.passed}/${stats.tests}',
          ),
          _statRow(
            l10n.subjectsBadgeIncome,
            '~${stats.income.toStringAsFixed(0)}',
          ),
          const SizedBox(height: 4),
          Text(
            l10n.subjectsIncomeNote,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final subject = widget.subject;
    final name = _nameController.text.trim();
    final gradeText = _gradeController.text.trim();
    final notesText = _notesController.text.trim();
    setState(() => _saving = true);
    try {
      final DurusApi api = ref.read(apiProvider);
      if (subject == null) {
        await api.createSubject(
          name,
          grade: gradeText.isEmpty ? null : gradeText,
          notes: notesText.isEmpty ? null : notesText,
        );
      } else {
        await api.updateSubject(
          subject.id,
          name: name,
          grade: gradeText.isEmpty ? null : gradeText,
          notes: notesText.isEmpty ? null : notesText,
        );
      }
      ref.invalidate(subjectsProvider);
      ref.invalidate(studentSubjectRefsProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.commonError)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteSubject() async {
    final l10n = context.l10n;
    final subject = widget.subject;
    if (subject == null) return;
    final confirmed = await confirmDialog(
      context,
      title: l10n.commonDelete,
      message: l10n.commonConfirmDelete,
    );
    if (!confirmed || !mounted) return;
    try {
      final DurusApi api = ref.read(apiProvider);
      await api.deleteSubject(subject.id);
      ref.invalidate(subjectsProvider);
      ref.invalidate(studentSubjectRefsProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.commonError)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final subject = widget.subject;
    return Scaffold(
      appBar: AppBar(
        title: Text(subject == null ? l10n.subjectsAddTitle : l10n.subjectsEditTitle),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (subject != null) ...[
              _subjectStatsCard(context, l10n, subject),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.commonName,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? l10n.commonRequired : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _gradeController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.subjectsGrade,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.commonNotes,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.commonSave),
            ),
            if (subject != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: _deleteSubject,
                icon: const Icon(Icons.delete_outline),
                label: Text(l10n.commonDelete),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

void _openSubjectForm(BuildContext context, Subject? subject) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => SubjectFormScreen(subject: subject),
    ),
  );
}