// Durus — students screens (list / form / detail).
//
// Arabic-only, RTL. All user-facing strings come from `context.l10n`.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:durus/core/config.dart';
import 'package:durus/core/durus_api.dart';
import 'package:durus/core/links.dart';
import 'package:durus/core/utils.dart';
import 'package:durus/core/attendance.dart';
import 'package:durus/l10n/app_localizations.dart';
import 'package:durus/l10n/l10n_ext.dart';
import 'package:durus/models/models.dart';
import 'package:durus/providers/providers.dart';
import 'package:durus/screens/reports_screen.dart';
import 'package:durus/widgets/session_detail_sheet.dart';
import 'package:durus/widgets/widgets.dart';

// ---------------------------------------------------------------------------
// Students list
// ---------------------------------------------------------------------------

class StudentsListScreen extends ConsumerWidget {
  const StudentsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.studentsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt),
            tooltip: l10n.studentsAddTitle,
            onPressed: () => _openStudentForm(context, null),
          ),
        ],
      ),
      body: const _StudentsListBody(),
    );
  }
}

class _StudentsListBody extends ConsumerStatefulWidget {
  const _StudentsListBody();

  @override
  ConsumerState<_StudentsListBody> createState() => _StudentsListBodyState();
}

class _StudentsListBodyState extends ConsumerState<_StudentsListBody> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  // ── filters ──
  String? _filterGrade;     // null = all
  String? _filterSubjectId; // null = all
  bool _sortNewest = false;
  // ── selection mode ──
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

  void _selectAll(List<Student> ids) => setState(() {
        if (_selected.length == ids.length) {
          _selected.clear();
        } else {
          _selected.addAll(ids.map((s) => s.id));
        }
      });

  // ── bulk helpers ──

  Future<void> _bulkDelete(List<Student> students) async {
    final l10n = context.l10n;
    final ok = await confirmDialog(
      context,
      title: l10n.bulkDeleteTitle,
      message: l10n.bulkDeleteConfirm(_selected.length),
    );
    if (!ok || !mounted) return;
    try {
      final api = ref.read(apiProvider);
      await api.deleteStudents(_selected.toList());
      _selected.clear();
      ref.invalidate(studentsProvider);
      ref.invalidate(studentSubjectRefsProvider);
      ref.invalidate(slotsProvider);
      ref.invalidate(lessonsProvider);
      ref.invalidate(testsProvider);
      ref.invalidate(notesProvider);
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
            hintText: l10n.studentsGrade,
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
      await api.updateStudentsGrade(
        _selected.toList(),
        result.isEmpty ? null : result,
      );
      _selected.clear();
      ref.invalidate(studentsProvider);
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

  Future<void> _bulkAssignSubject() async {
    final l10n = context.l10n;
    final subjects = ref.read(subjectsProvider).value ?? const <Subject>[];
    if (subjects.isEmpty) return;
    final picked = await showDialog<Subject?>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.bulkAssignSubjectTitle),
        children: [
          for (final s in subjects)
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(s),
              child: Text(s.displayLabel),
            ),
        ],
      ),
    );
    if (picked == null || !mounted) return;
    try {
      final api = ref.read(apiProvider);
      await api.assignSubjectToStudents(_selected.toList(), picked.id);
      _selected.clear();
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

  Future<void> _bulkShareLinks(List<Student> students) async {
    final l10n = context.l10n;
    final api = ref.read(apiProvider);
    final selected = students.where((s) => _selected.contains(s.id)).toList();
    final lines = <String>[];
    for (final student in selected) {
      final token = student.parentToken ?? await api.ensureParentToken(student.id);
      lines.add('${student.name}  ${AppConfig.webBaseUrl}/#/portal/$token');
    }
    final text = lines.join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.commonCopied)),
    );
    // Open WhatsApp with first parent phone if available
    for (final student in selected) {
      if (student.parentPhone != null && student.parentPhone!.trim().isNotEmpty) {
        await openExternal(waChatLink(student.parentPhone!, text: text));
        break;
      }
    }
    ref.invalidate(studentsProvider); // tokens may have been created
  }

// ── filter sheet (compact button + modal bottom sheet) ──

  int get _activeFilterCount =>
      (_filterGrade != null ? 1 : 0) + (_filterSubjectId != null ? 1 : 0);

  Future<void> _openFilterSheet() async {
    final l10n = context.l10n;
    final students = ref.read(studentsProvider).value ?? const <Student>[];
    final subjects = ref.read(subjectsProvider).value ?? const <Subject>[];
    final result = await showFilterSheet(
      context,
      title: l10n.filterTitle,
      sections: [
        FilterSheetSection(
          id: 'grade',
          label: l10n.studentsGrade,
          current: _filterGrade,
          choices: [
            FilterChoice(null, l10n.filterAllGrades),
            for (final g in _uniqueGrades(students)) FilterChoice(g, g),
          ],
        ),
        FilterSheetSection(
          id: 'subject',
          label: l10n.subjectsTitle,
          current: _filterSubjectId,
          choices: [
            FilterChoice(null, l10n.filterAllSubjects),
            for (final s in subjects)
              FilterChoice(s.id, s.displayLabel),
          ],
        ),
      ],
    );
    if (result == null || !mounted) return;
    setState(() {
      _filterGrade = result['grade'];
      _filterSubjectId = result['subject'];
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final studentsAsync = ref.watch(studentsProvider);
    final refsAsync = ref.watch(studentSubjectRefsProvider);
    final refs = refsAsync.value ?? const <StudentSubjectRef>[];

    return Column(
      children: [
        // ── search + sort + filter row ──
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
              IconButton.filledTonal(
                icon: Icon(_sortNewest ? Icons.arrow_downward : Icons.sort_by_alpha),
                tooltip: _sortNewest ? l10n.sortNewest : l10n.sortName,
                onPressed: () => setState(() => _sortNewest = !_sortNewest),
              ),
              const SizedBox(width: 4),
              FilterButton(
                activeCount: _activeFilterCount,
                onPressed: _openFilterSheet,
              ),
            ],
          ),
        ),
        Expanded(
          child: studentsAsync.when(
            loading: () => const LoadingView(),
            error: (error, stackTrace) => ErrorRetry(
              message: l10n.commonError,
              onRetry: () => ref.invalidate(studentsProvider),
            ),
            data: (students) {
              // ── apply filters ──
              final assignedIds = _filterSubjectId == null
                  ? null
                  : refs.where((r) => r.subjectId == _filterSubjectId).map((r) => r.studentId).toSet();
              var visible = students.where((s) {
                if (_filterGrade != null && (s.grade ?? '') != _filterGrade) return false;
                if (assignedIds != null && !assignedIds.contains(s.id)) return false;
                return true;
              }).toList();
              if (_query.isNotEmpty) {
                visible = visible.where((s) => s.name.contains(_query)).toList();
              }
              if (_sortNewest) {
                visible = visible.reversed.toList();
              }
              if (visible.isEmpty) {
                return RefreshableEmpty(
                  onRefresh: () => refreshSchoolData(ref),
                  empty: EmptyState(
                    icon: (_query.isEmpty && _filterGrade == null && _filterSubjectId == null)
                        ? Icons.group_outlined
                        : Icons.search_off,
                    message: (_query.isEmpty && _filterGrade == null && _filterSubjectId == null)
                        ? l10n.studentsEmpty
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
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final student = visible[index];
                    final isSelected = _selected.contains(student.id);
                    return ListTile(
                      leading: _selecting
                          ? Checkbox(
                              value: isSelected,
                              onChanged: (_) => _toggle(student.id),
                            )
                          : CircleAvatar(child: Text(_initial(student.name))),
                      title: Text(student.name),
                      subtitle: Text(
                        _studentSubtitle(l10n, student),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: _selecting
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: l10n.commonEdit,
                              onPressed: () => _openStudentForm(context, student),
                            ),
                      selected: isSelected,
                      selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.25),
                      onTap: _selecting ? () => _toggle(student.id) : () => _openStudentDetail(context, student.id),
                      onLongPress: _selecting ? null : () => _toggle(student.id),
                    );
                  },
                ),
              );
            },
          ),
        ),
        // ── selection bar ──
        if (_selecting)
          SelectionBar(
            count: _selected.length,
            total: studentsAsync.value?.length ?? 0,
            onClose: () => setState(() => _selected.clear()),
            onSelectAll: () {
              final current = ref.read(studentsProvider).value ?? const <Student>[];
              // If filtering, select all visible only
              final ids = current.where((s) {
                if (_filterGrade != null && (s.grade ?? '') != _filterGrade) return false;
                if (_filterSubjectId != null) {
                  final assigned = refs.any((r) => r.studentId == s.id && r.subjectId == _filterSubjectId);
                  if (!assigned) return false;
                }
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
                icon: Icons.book_outlined,
                label: l10n.bulkAssignSubject,
                onTap: _bulkAssignSubject,
              ),
              BulkAction(
                icon: Icons.share_outlined,
                label: l10n.bulkShareLinks,
                onTap: () {
                  final students = ref.read(studentsProvider).value ?? const <Student>[];
                  _bulkShareLinks(students);
                },
              ),
              BulkAction(
                icon: Icons.delete_outline,
                label: l10n.commonDelete,
                color: Theme.of(context).colorScheme.error,
                onTap: () {
                  final students = ref.read(studentsProvider).value ?? const <Student>[];
                  _bulkDelete(students);
                },
              ),
            ],
          ),
      ],
    );
  }

  List<String> _uniqueGrades(List<Student> students) {
    final set = <String>{};
    for (final s in students) {
      final g = s.grade;
      if (g != null && g.isNotEmpty) set.add(g);
    }
    return set.toList()..sort();
  }
}

// ---------------------------------------------------------------------------
// Student form (create / edit)
// ---------------------------------------------------------------------------

class StudentFormScreen extends ConsumerStatefulWidget {
  const StudentFormScreen({super.key, this.student});

  final Student? student;

  @override
  ConsumerState<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends ConsumerState<StudentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _gradeController;
  late final TextEditingController _birthYearController;
  late final TextEditingController _parentNameController;
  late final TextEditingController _parentPhoneController;
  late final TextEditingController _notesController;
  String? _location;
  String? _selectedTeacherId;
  final Set<String> _selectedSubjectIds = <String>{};
  bool _subjectsPrefilled = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final student = widget.student;
    _nameController = TextEditingController(text: student?.name ?? '');
    _gradeController = TextEditingController(text: student?.grade ?? '');
    _birthYearController = TextEditingController(
      text: student?.birthYear?.toString() ?? '',
    );
    _parentNameController = TextEditingController(text: student?.parentName ?? '');
    _parentPhoneController = TextEditingController(text: student?.parentPhone ?? '');
    _notesController = TextEditingController(text: student?.notes ?? '');
    _location = student?.defaultLocation;
    _selectedTeacherId = student?.assignedTeacherId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gradeController.dispose();
    _birthYearController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _maybePrefillSubjects() {
    if (_subjectsPrefilled) return;
    final studentId = widget.student?.id;
    if (studentId == null) return;
    final refs = ref.read(studentSubjectRefsProvider).value;
    if (refs == null) return;
    _subjectsPrefilled = true;
    _selectedSubjectIds
      ..clear()
      ..addAll(refs.where((r) => r.studentId == studentId).map((r) => r.subjectId));
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final student = widget.student;
    final name = _nameController.text.trim();
    final gradeText = _gradeController.text.trim();
    final birthText = _birthYearController.text.trim();
    final parentNameText = _parentNameController.text.trim();
    final parentPhoneText = _parentPhoneController.text.trim();
    final notesText = _notesController.text.trim();
    int? birthYear;
    if (birthText.isNotEmpty) {
      birthYear = int.tryParse(birthText);
    }
    final profile = ref.read(currentProfileProvider).value;
    final isManager = profile?.isManager ?? false;
    final assignedTeacherId = isManager
        ? (_selectedTeacherId ?? (student == null ? profile?.id : null))
        : profile?.id;
    setState(() => _saving = true);
    try {
      final DurusApi api = ref.read(apiProvider);
      if (student == null) {
        final created = await api.createStudent(
          name: name,
          grade: gradeText.isEmpty ? null : gradeText,
          birthYear: birthYear,
          defaultLocation: _location ?? 'student_home',
          assignedTeacherId: assignedTeacherId,
          parentName: parentNameText.isEmpty ? null : parentNameText,
          parentPhone: parentPhoneText.isEmpty ? null : parentPhoneText,
          notes: notesText.isEmpty ? null : notesText,
        );
        await api.setStudentSubjects(created.id, _selectedSubjectIds.toList());
      } else {
        await api.updateStudent(
          student.id,
          name: name,
          grade: gradeText.isEmpty ? null : gradeText,
          birthYear: birthYear,
          defaultLocation: _location,
          assignedTeacherId: assignedTeacherId,
          parentName: parentNameText.isEmpty ? null : parentNameText,
          parentPhone: parentPhoneText.isEmpty ? null : parentPhoneText,
          notes: notesText.isEmpty ? null : notesText,
        );
        await api.setStudentSubjects(student.id, _selectedSubjectIds.toList());
      }
      ref.invalidate(studentsProvider);
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final student = widget.student;
    final profile = ref.watch(currentProfileProvider).value;
    final isManager = profile?.isManager ?? false;
    final teachersAsync = ref.watch(teachersProvider);
    final teachers = teachersAsync.value ?? const <Profile>[];
    final subjectsAsync = ref.watch(subjectsProvider);

    _maybePrefillSubjects();

    final locationItems = <DropdownMenuItem<String>>[
      DropdownMenuItem(value: 'student_home', child: Text(l10n.studentsLocationHome)),
      DropdownMenuItem(value: 'teacher', child: Text(l10n.studentsLocationTeacher)),
    ];
    final locationValue = _initialIfPresent(locationItems, _location);

    return Scaffold(
      appBar: AppBar(
        title: Text(student == null ? l10n.studentsAddTitle : l10n.studentsEditTitle),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _gradeController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l10n.studentsGrade,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _birthYearController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l10n.studentsBirthYear,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      return int.tryParse(value.trim()) == null ? l10n.commonError : null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: locationValue,
              decoration: InputDecoration(
                labelText: l10n.studentsLocation,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: locationItems,
              onChanged: (value) => setState(() => _location = value),
            ),
            const SizedBox(height: 16),
            if (isManager)
              _buildTeacherDropdown(l10n, profile, teachers, student)
            else if (profile != null)
              _buildFixedTeacher(context, l10n, profile),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _parentNameController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l10n.studentsParentName,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _parentPhoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: l10n.studentsParentPhone,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
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
            Text(l10n.studentsSubjectsAssigned, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            subjectsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, stackTrace) => Text(l10n.commonError),
              data: (subjects) {
                if (subjects.isEmpty) {
                  return Text(
                    l10n.studentsNoSubjects,
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                }
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final subject in subjects)
                      FilterChip(
                        label: Text(
                          subject.displayLabel,
                          style: TextStyle(
                            color: _selectedSubjectIds.contains(subject.id)
                                ? Theme.of(context).colorScheme.onPrimary
                                : null,
                          ),
                        ),
                        selected: _selectedSubjectIds.contains(subject.id),
                        onSelected: (selected) => setState(() {
                          if (selected) {
                            _selectedSubjectIds.add(subject.id);
                          } else {
                            _selectedSubjectIds.remove(subject.id);
                          }
                        }),
                      ),
                  ],
                );
              },
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
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTeacherDropdown(
    AppLocalizations l10n,
    Profile? profile,
    List<Profile> teachers,
    Student? student,
  ) {
    final options = <Profile>[
      if (profile != null && !teachers.any((t) => t.id == profile.id)) profile,
      ...teachers,
    ];
    final items = <DropdownMenuItem<String>>[
      for (final teacher in options)
        DropdownMenuItem(
            value: teacher.id, child: Text(teacher.fullName ?? '')),
    ];
    final value = student == null
        ? (_selectedTeacherId ?? profile?.id)
        : _selectedTeacherId;
    return DropdownButtonFormField<String>(
      initialValue: _initialIfPresent(items, value),
      decoration: InputDecoration(
        labelText: l10n.studentsAssignedTeacher,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: items,
      onChanged: (selected) => setState(() => _selectedTeacherId = selected),
    );
  }

  Widget _buildFixedTeacher(
    BuildContext context,
    AppLocalizations l10n,
    Profile profile,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: profile.id,
      decoration: InputDecoration(
        labelText: l10n.studentsAssignedTeacher,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: [
        DropdownMenuItem(value: profile.id, child: Text(profile.fullName ?? '')),
      ],
      onChanged: null,
    );
  }
}

// ---------------------------------------------------------------------------
// Student detail
// ---------------------------------------------------------------------------

class StudentDetailScreen extends ConsumerStatefulWidget {
  const StudentDetailScreen({super.key, required this.studentId});

  final String studentId;

  @override
  ConsumerState<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends ConsumerState<StudentDetailScreen> {
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Widget _sectionBody<T>(
    AsyncValue<T> async,
    Widget Function(T data) builder,
  ) {
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: LinearProgressIndicator(),
      ),
      error: (error, stackTrace) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(context.l10n.commonError),
      ),
      data: builder,
    );
  }

  Future<String?> _generateParentLink(Student student) async {
    final l10n = context.l10n;
    try {
      final DurusApi api = ref.read(apiProvider);
      final token = await api.ensureParentToken(student.id);
      ref.invalidate(studentsProvider);
      return token;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.commonError)),
        );
      }
      return null;
    }
  }

  /// Ensures a token exists, then shares the full portal link with the
  /// parent via WhatsApp (and copies it to the clipboard as a fallback).
  Future<void> _shareParentLink(Student student) async {
    final l10n = context.l10n;
    var token = student.parentToken;
    if (token == null || token.isEmpty) {
      token = await _generateParentLink(student);
    }
    if (token == null || token.isEmpty) return;
    final linkText = '${AppConfig.webBaseUrl}/#/portal/$token';
    await Clipboard.setData(ClipboardData(text: linkText));
    if (!mounted) return;
    if (_hasParentPhone(student)) {
      final ok = await openExternal(waChatLink(student.parentPhone!, text: linkText));
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.studentsShareLinkHint)),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.studentsLinkCopied)),
      );
    }
  }

  Future<void> _copyParentLink(String linkText) async {
    final l10n = context.l10n;
    await Clipboard.setData(ClipboardData(text: linkText));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.studentsLinkCopied)),
      );
    }
  }

  bool _hasParentPhone(Student student) {
    final phone = student.parentPhone;
    return phone != null && phone.trim().isNotEmpty;
  }

  /// Opens a WhatsApp chat with the student's parent, pre-filled with a
  /// greeting (or a custom [text] when supplied, e.g. from reports).
  Future<void> _openWhatsApp(Student student, {String? text}) async {
    final l10n = context.l10n;
    final phone = student.parentPhone;
    if (!_hasParentPhone(student)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.studentsNoParentPhone)),
      );
      return;
    }
    final message = text ??
        l10n.studentsWhatsappGreeting(student.name);
    final ok = await openExternal(waChatLink(phone!, text: message));
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.commonOpenFailed)),
      );
    }
  }

  /// Bottom sheet with extra student actions: WhatsApp / share parent link /
  /// export attendance / export tests / delete.
  Future<void> _showStudentActions(
    BuildContext context,
    AppLocalizations l10n,
    Student student,
  ) async {
    final scheme = Theme.of(context).colorScheme;
    final lessons = ref.read(lessonsProvider).value ?? const <LessonSession>[];
    final tests = ref.read(testsProvider).value ?? const <TestResult>[];
    final subjects = ref.read(subjectsProvider).value ?? const <Subject>[];

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_hasParentPhone(student))
              ListTile(
                leading: const Icon(Icons.chat),
                title: Text(l10n.studentsWhatsappContact),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openWhatsApp(student);
                },
              ),
            ListTile(
              leading: const Icon(Icons.link),
              title: Text(l10n.studentsShareLink),
              subtitle: Text(l10n.studentsShareLinkHint),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _shareParentLink(student);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month_outlined),
              title: Text(l10n.studentsExportAttendance),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _shareExport(
                  student,
                  _composeAttendanceExport(l10n, student, lessons, subjects),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment_outlined),
              title: Text(l10n.studentsExportTests),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _shareExport(
                  student,
                  _composeTestsExport(l10n, student, tests, subjects),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: scheme.error),
              title: Text(
                l10n.commonDelete,
                style: TextStyle(color: scheme.error),
              ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _deleteStudent(student);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Copies [text] to the clipboard, tells the teacher it is ready, and opens
  /// WhatsApp with the text pre-filled when a parent phone exists.
  Future<void> _shareExport(Student student, String text) async {
    final l10n = context.l10n;
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.studentsExportShared)),
    );
    if (_hasParentPhone(student)) {
      final ok =
          await openExternal(waChatLink(student.parentPhone!, text: text));
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.commonOpenFailed)),
        );
      }
    }
  }

  /// Plain-text attendance log for one student (newest first).
  String _composeAttendanceExport(
    AppLocalizations l10n,
    Student student,
    List<LessonSession> lessons,
    List<Subject> subjects,
  ) {
    final list = lessons
        .where((l) => l.studentId == student.id)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    if (list.isEmpty) return '';
    final lines = <String>[
      '${l10n.studentsExportAttendance} — ${student.name}',
      for (final lesson in list)
        '${lesson.date} • ${_subjectName(subjects, lesson.subjectId).isEmpty ? l10n.commonNone : _subjectName(subjects, lesson.subjectId)} • ${attendanceStyle(l10n, Theme.of(context).colorScheme, lesson.attendance).label}',
    ];
    return lines.join('\n');
  }

  /// Plain-text tests log for one student (newest first).
  String _composeTestsExport(
    AppLocalizations l10n,
    Student student,
    List<TestResult> tests,
    List<Subject> subjects,
  ) {
    final list = tests
        .where((t) => t.studentId == student.id)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    if (list.isEmpty) return '';
    final lines = <String>[
      '${l10n.studentsExportTests} — ${student.name}',
      for (final test in list)
        '${test.date} • ${_subjectName(subjects, test.subjectId).isEmpty ? l10n.commonNone : _subjectName(subjects, test.subjectId)} • ${_testTypeLabel(l10n, test.type)} • ${_numText(test.score ?? 0)} / ${_numText(test.maxScore ?? 0)}',
    ];
    return lines.join('\n');
  }

  Future<void> _deleteStudent(Student student) async {
    final l10n = context.l10n;
    final confirmed = await confirmDialog(
      context,
      title: l10n.commonDelete,
      message: l10n.commonConfirmDelete,
    );
    if (!confirmed || !mounted) return;
    try {
      final DurusApi api = ref.read(apiProvider);
      await api.deleteStudent(student.id);
      ref.invalidate(studentsProvider);
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

  Future<void> _addNote(Student student) async {
    final body = _noteController.text.trim();
    if (body.isEmpty) return;
    final l10n = context.l10n;
    try {
      final DurusApi api = ref.read(apiProvider);
      await api.createNote(studentId: student.id, body: body);
      ref.invalidate(notesProvider);
      if (mounted) _noteController.clear();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.commonError)),
        );
      }
    }
  }

  Future<void> _deleteSlot(RecurringSlot slot) async {
    final l10n = context.l10n;
    final confirmed = await confirmDialog(
      context,
      title: l10n.commonDelete,
      message: l10n.commonConfirmDelete,
    );
    if (!confirmed || !mounted) return;
    try {
      final DurusApi api = ref.read(apiProvider);
      await api.deleteSlot(slot.id);
      ref.invalidate(slotsProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.commonError)),
        );
      }
    }
  }

  Future<void> _deleteTest(TestResult test) async {
    final l10n = context.l10n;
    final confirmed = await confirmDialog(
      context,
      title: l10n.commonDelete,
      message: l10n.commonConfirmDelete,
    );
    if (!confirmed || !mounted) return;
    try {
      final DurusApi api = ref.read(apiProvider);
      await api.deleteTest(test.id);
      ref.invalidate(testsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.testsDeleted)),
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final studentsAsync = ref.watch(studentsProvider);
    final refsAsync = ref.watch(studentSubjectRefsProvider);
    final subjectsAsync = ref.watch(subjectsProvider);
    final slotsAsync = ref.watch(slotsProvider);
    final lessonsAsync = ref.watch(lessonsProvider);
    final testsAsync = ref.watch(testsProvider);
    final notesAsync = ref.watch(notesProvider);
    final cachedStudent = _findStudent(
      studentsAsync.value ?? const <Student>[],
      widget.studentId,
    );
    final subjects = subjectsAsync.value ?? const <Subject>[];
    final slots = slotsAsync.value ?? const <RecurringSlot>[];

    return Scaffold(
      appBar: AppBar(title: Text(cachedStudent?.name ?? l10n.studentsTitle)),
      bottomNavigationBar: cachedStudent == null
          ? null
          : _studentBottomBar(context, l10n, cachedStudent),
      body: studentsAsync.when(
        loading: () => const LoadingView(),
        error: (error, stackTrace) => ErrorRetry(
          message: l10n.commonError,
          onRetry: () => ref.invalidate(studentsProvider),
        ),
        data: (students) {
          final student = _findStudent(students, widget.studentId);
          if (student == null) {
            return EmptyState(
              icon: Icons.person_off_outlined,
              message: l10n.studentsEmpty,
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _headerCard(context, l10n, student),
              const SizedBox(height: 16),
              SectionCard(
                title: l10n.studentsParentLink,
                child: _parentLinkSection(context, l10n, student),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: l10n.studentsSubjectsAssigned,
                child: _sectionBody(refsAsync, (refs) {
                  final assigned = subjects
                      .where((s) => refs
                          .where((r) => r.studentId == student.id)
                          .any((r) => r.subjectId == s.id))
                      .toList();
                  if (assigned.isEmpty) {
                    return Text(
                      l10n.studentsNoSubjects,
                      style: Theme.of(context).textTheme.bodySmall,
                    );
                  }
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final subject in assigned) Chip(label: Text(subject.displayLabel)),
                    ],
                  );
                }),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: l10n.studentsDetailSlots,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton.icon(
                        onPressed: () => _openSlotForm(context, null, student.id),
                        icon: const Icon(Icons.add),
                        label: Text(l10n.scheduleAddSlot),
                      ),
                    ),
                    _sectionBody(slotsAsync, (slots) {
                      final list = slots
                          .where((s) => s.studentId == student.id)
                          .toList()
                        ..sort((a, b) {
                          final day = a.dayOfWeek.compareTo(b.dayOfWeek);
                          return day != 0
                              ? day
                              : a.startMinutes.compareTo(b.startMinutes);
                        });
                      if (list.isEmpty) {
                        return Text(
                          l10n.commonEmpty,
                          style: Theme.of(context).textTheme.bodySmall,
                        );
                      }
                      return Column(
                        children: [
                          for (final slot in list) _slotTile(context, l10n, subjects, slot),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: l10n.studentsDetailAttendance,
                child: _sectionBody(lessonsAsync, (lessons) {
                  final list = lessons
                      .where((l) => l.studentId == student.id)
                      .toList()
                    ..sort((a, b) => b.date.compareTo(a.date));
                  if (list.isEmpty) {
                    return Text(
                      l10n.studentsNoAttendance,
                      style: Theme.of(context).textTheme.bodySmall,
                    );
                  }
                  return Column(
                    children: [
                      for (final lesson in list.take(10))
                        _attendanceTile(
                          context,
                          l10n,
                          subjects,
                          lesson,
                          slots: slots,
                          studentName: student.name,
                        ),
                    ],
                  );
                }),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: l10n.studentsDetailTests,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton.icon(
                        onPressed: () => _openTestSheet(context, student.id),
                        icon: const Icon(Icons.add),
                        label: Text(l10n.testsAddTitle),
                      ),
                    ),
                    _sectionBody(testsAsync, (tests) {
                      final list = tests
                          .where((t) => t.studentId == student.id)
                          .toList()
                        ..sort((a, b) => b.date.compareTo(a.date));
                      if (list.isEmpty) {
                        return Text(
                          l10n.testsEmpty,
                          style: Theme.of(context).textTheme.bodySmall,
                        );
                      }
                      return Column(
                        children: [
                          for (final test in list) _testTile(context, l10n, subjects, test),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: l10n.studentsStatsTitle,
                child: _sectionBody(testsAsync, (tests) {
                  return _statsSection(
                    context,
                    l10n,
                    student,
                    subjects,
                    lessonsAsync.value ?? const <LessonSession>[],
                    tests,
                  );
                }),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: l10n.studentsDetailNotes,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionBody(notesAsync, (notes) {
                      final list = notes
                          .where((n) => n.studentId == student.id)
                          .toList()
                        ..sort((a, b) {
                          final ta = a.createdAt;
                          final tb = b.createdAt;
                          if (ta == null && tb == null) return 0;
                          if (ta == null) return 1;
                          if (tb == null) return -1;
                          return tb.compareTo(ta);
                        });
                      if (list.isEmpty) {
                        return Text(
                          l10n.notesEmpty,
                          style: Theme.of(context).textTheme.bodySmall,
                        );
                      }
                      return Column(
                        children: [
                          for (final note in list)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.sticky_note_2_outlined, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(note.body),
                                        Text(
                                          _noteCreatedLabel(note),
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      );
                    }),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _noteController,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _addNote(student),
                            decoration: InputDecoration(
                              hintText: l10n.notesAddHint,
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          icon: const Icon(Icons.send),
                          tooltip: l10n.commonAdd,
                          onPressed: () => _addNote(student),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  /// Bottom bar holding the major student actions: edit / reports / more
  /// options / delete. Stays fixed at the bottom of the student window.
  Widget _studentBottomBar(
    BuildContext context,
    AppLocalizations l10n,
    Student student,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return BottomAppBar(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _bottomBarAction(
            icon: Icons.edit_outlined,
            label: l10n.commonEdit,
            onTap: () => _openStudentForm(context, student),
          ),
          _bottomBarAction(
            icon: Icons.description_outlined,
            label: l10n.reportsTitle,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => MonthlyReportScreen(
                  studentId: student.id,
                  studentName: student.name,
                ),
              ),
            ),
          ),
          _bottomBarAction(
            icon: Icons.more_horiz,
            label: l10n.studentsActions,
            onTap: () => _showStudentActions(context, l10n, student),
          ),
          _bottomBarAction(
            icon: Icons.delete_outline,
            label: l10n.commonDelete,
            color: scheme.error,
            onTap: () => _deleteStudent(student),
          ),
        ],
      ),
    );
  }

  /// A single tappable icon+label action used in the fixed bottom bar.
  Widget _bottomBarAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final fg = color ?? scheme.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: fg),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: fg),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerCard(
    BuildContext context,
    AppLocalizations l10n,
    Student student,
  ) {
    final theme = Theme.of(context);
    final grade = student.grade;
    final birthYear = student.birthYear;
    final parentName = student.parentName;
    final parentPhone = student.parentPhone;
    final location = _locationLabel(l10n, student.defaultLocation);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 24, child: Text(_initial(student.name))),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(student.name, style: theme.textTheme.titleLarge),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (grade != null && grade.isNotEmpty)
                  _infoChip(context, Icons.school_outlined, grade),
                if (location.isNotEmpty)
                  _infoChip(context, Icons.place_outlined, location),
                if (parentName != null && parentName.isNotEmpty)
                  _infoChip(context, Icons.person_outline, parentName),
                if (parentPhone != null && parentPhone.isNotEmpty)
                  _infoChip(context, Icons.phone_outlined, parentPhone),
                if (birthYear != null)
                  _infoChip(
                    context,
                    Icons.calendar_month,
                    '${l10n.studentsBirthYear}: $birthYear',
                  ),
              ],
            ),
            if (_hasParentPhone(student)) ...[
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FilledButton.tonalIcon(
                  onPressed: () => _openWhatsApp(student),
                  icon: const Icon(Icons.chat),
                  label: Text(l10n.studentsWhatsappContact),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoChip(BuildContext context, IconData icon, String label) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.onSecondaryContainer),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: scheme.onSecondaryContainer,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _parentLinkSection(
    BuildContext context,
    AppLocalizations l10n,
    Student student,
  ) {
    final token = student.parentToken;
    if (token == null || token.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.studentsParentLinkEmpty),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: () => _generateParentLink(student),
            icon: const Icon(Icons.link),
            label: Text(l10n.studentsGenerateLink),
          ),
        ],
      );
    }
    final linkText = '${AppConfig.webBaseUrl}/#/portal/$token';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.studentsShareLinkHint,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SelectableText(
            linkText,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Wrap(
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: () => _copyParentLink(linkText),
                icon: const Icon(Icons.copy),
                label: Text(l10n.studentsCopyLink),
              ),
              if (_hasParentPhone(student)) ...[
                TextButton.icon(
                  onPressed: () => _openWhatsApp(student, text: linkText),
                  icon: const Icon(Icons.chat),
                  label: Text(l10n.studentsShareLink),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Teacher-side performance summary for one student (attendance rate,
  /// tests average, tests count) with an export/share action.
  Widget _statsSection(
    BuildContext context,
    AppLocalizations l10n,
    Student student,
    List<Subject> subjects,
    List<LessonSession> lessons,
    List<TestResult> tests,
  ) {
    final theme = Theme.of(context);
    final myLessons =
        lessons.where((l) => l.studentId == student.id).toList();
    final myTests = tests.where((t) => t.studentId == student.id).toList();

    final presentCount = myLessons
        .where((l) => l.attendance == 'present')
        .length;
    final attendanceRate = myLessons.isEmpty
        ? 0
        : ((presentCount / myLessons.length) * 100).round();

    double? averagePct;
    var scored = 0;
    for (final test in myTests) {
      final score = test.score;
      final maxScore = test.maxScore;
      if (score != null && maxScore != null && maxScore > 0) {
        averagePct = (averagePct ?? 0) + (score / maxScore) * 100;
        scored++;
      }
    }
    if (scored > 0) averagePct = (averagePct ?? 0) / scored;

    final rows = <Widget>[
      _metricRow(
        context,
        l10n.studentsStatsAttendanceRate,
        myLessons.isEmpty ? l10n.commonNone : '$attendanceRate%',
      ),
      _metricRow(
        context,
        l10n.studentsStatsTestsCount,
        '${myTests.length}',
      ),
      if (averagePct != null)
        _metricRow(
          context,
          l10n.studentsStatsTestsAverage,
          '${_numText(averagePct)}%',
        )
      else
        _metricRow(context, l10n.studentsStatsTestsAverage, l10n.commonNone),
    ];

    final summary = <String>[
      '${l10n.studentsStatsTitle} — ${student.name}',
      '${l10n.studentsStatsAttendanceRate}: '
          '${myLessons.isEmpty ? l10n.commonNone : '$attendanceRate%'}',
      '${l10n.studentsStatsTestsCount}: ${myTests.length}',
      if (averagePct == null)
        l10n.studentsStatsNoTests
      else
        '${l10n.studentsStatsTestsAverage}: ${_numText(averagePct)}%',
      for (final test in myTests.take(5))
        '${test.date} • ${_subjectName(subjects, test.subjectId).isEmpty ? l10n.commonNone : _subjectName(subjects, test.subjectId)} • ${_testTypeLabel(l10n, test.type)} • ${_numText(test.score ?? 0)} / ${_numText(test.maxScore ?? 0)}',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in rows) row,
        if (myTests.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l10n.studentsStatsNoTests,
              style: theme.textTheme.bodySmall,
            ),
          ),
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton.icon(
            onPressed: () => _shareExport(student, summary.join('\n')),
            icon: const Icon(Icons.ios_share),
            label: Text(l10n.studentsStatsExport),
          ),
        ),
      ],
    );
  }

  Widget _metricRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _slotTile(
    BuildContext context,
    AppLocalizations l10n,
    List<Subject> subjects,
    RecurringSlot slot,
  ) {
    final subjectName = _subjectName(subjects, slot.subjectId);
    final location = _locationLabel(l10n, slot.location);
    final subtitleParts = <String>[
      '${_dayLabel(slot.dayOfWeek)} • '
          '${timeFromMinutes(slot.startMinutes)} - ${timeFromMinutes(slot.endMinutes)}',
      if (location.isNotEmpty) location,
    ];
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.event, color: Colors.blueGrey),
      title: Text(subjectName.isEmpty ? l10n.commonNone : subjectName),
      subtitle: Text(subtitleParts.join(' • ')),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (slot.active)
            StatusChip(label: l10n.scheduleActive, color: Colors.green),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: l10n.commonEdit,
            onPressed: () => _openSlotForm(context, slot, slot.studentId),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: l10n.commonDelete,
            onPressed: () => _deleteSlot(slot),
          ),
        ],
      ),
    );
  }

  Widget _testTile(
    BuildContext context,
    AppLocalizations l10n,
    List<Subject> subjects,
    TestResult test,
  ) {
    final subjectName = _subjectName(subjects, test.subjectId);
    final subtitleParts = <String>[
      _testTypeLabel(l10n, test.type),
      '${_numText(test.score ?? 0)} / ${_numText(test.maxScore ?? 0)}',
    ];
    final student = _findStudent(
      ref.read(studentsProvider).value ?? const <Student>[],
      test.studentId,
    );
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: const Icon(Icons.assignment_outlined, color: Colors.blueGrey),
      title: Text(subjectName.isEmpty ? l10n.commonNone : subjectName),
      subtitle: Text(subtitleParts.join(' • ')),
      trailing: Text(test.date),
      onTap: () => _showTestActions(context, l10n, subjects, test, student),
      onLongPress: () => _deleteTest(test),
    );
  }

  /// Bottom sheet for a single test: edit / share result / delete.
  Future<void> _showTestActions(
    BuildContext context,
    AppLocalizations l10n,
    List<Subject> subjects,
    TestResult test,
    Student? student,
  ) async {
    final scheme = Theme.of(context).colorScheme;
    final subjectName = _subjectName(subjects, test.subjectId);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                subjectName.isEmpty ? l10n.commonNone : subjectName,
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              subtitle: Text(
                '${test.date} • ${_testTypeLabel(l10n, test.type)} • '
                '${_numText(test.score ?? 0)} / ${_numText(test.maxScore ?? 0)}',
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n.commonEdit),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _openTestSheet(context, test.studentId, test: test);
              },
            ),
            ListTile(
              leading: const Icon(Icons.ios_share),
              title: Text(l10n.testsShareResult),
              onTap: () {
                Navigator.of(sheetContext).pop();
                if (student == null) return;
                _shareExport(
                  student,
                  '${l10n.testsShareResult} — $subjectName • ${test.date} • '
                      '${_testTypeLabel(l10n, test.type)} • '
                      '${_numText(test.score ?? 0)} / ${_numText(test.maxScore ?? 0)}',
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: scheme.error),
              title: Text(
                l10n.commonDelete,
                style: TextStyle(color: scheme.error),
              ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _deleteTest(test);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _attendanceTile(
    BuildContext context,
    AppLocalizations l10n,
    List<Subject> subjects,
    LessonSession lesson, {
    required List<RecurringSlot> slots,
    required String studentName,
  }) {
    final subjectName = _subjectName(subjects, lesson.subjectId);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final style = attendanceStyle(l10n, scheme, lesson.attendance);
    final titleParts = <String>[
      lesson.date,
      if (subjectName.isNotEmpty) subjectName,
    ];
    return InkWell(
      onTap: () => _openAttendanceDetail(
        context,
        l10n,
        lesson,
        studentName,
        subjectName,
        slots,
      ),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                titleParts.join(' • '),
                style: theme.textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            StatusChip(label: style.label, color: style.color),
          ],
        ),
      ),
    );
  }

  Future<void> _openAttendanceDetail(
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
  // Sub-form sheets
  // -------------------------------------------------------------------------

  void _openSlotForm(BuildContext context, RecurringSlot? slot, String studentId) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SlotFormSheet(studentId: studentId, slot: slot),
    );
  }

  void _openTestSheet(BuildContext context, String studentId, {TestResult? test}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _TestSheet(studentId: studentId, test: test),
    );
  }
}

class _SlotFormSheet extends ConsumerStatefulWidget {
  const _SlotFormSheet({required this.studentId, this.slot});

  final String studentId;
  final RecurringSlot? slot;

  @override
  ConsumerState<_SlotFormSheet> createState() => _SlotFormSheetState();
}

class _SlotFormSheetState extends ConsumerState<_SlotFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late int _dayOfWeek;
  late int _startMinutes;
  late int _endMinutes;
  late bool _active;
  String? _location;
  String? _subjectId;
  bool _saving = false;
  bool _timeInvalid = false;

  @override
  void initState() {
    super.initState();
    final slot = widget.slot;
    _dayOfWeek = slot?.dayOfWeek ?? DateTime.now().weekday;
    _startMinutes = slot?.startMinutes ?? 540;
    _endMinutes = slot?.endMinutes ?? 600;
    _active = slot?.active ?? true;
    _location = slot?.location;
    _subjectId = slot?.subjectId;
  }

  Future<void> _pickTime({required bool isStart}) async {
    final current = isStart ? _startMinutes : _endMinutes;
    final initial = TimeOfDay(hour: current ~/ 60, minute: current % 60);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null || !mounted) return;
    setState(() {
      final minutes = minutesOfDay(picked.hour, picked.minute);
      if (isStart) {
        _startMinutes = minutes;
      } else {
        _endMinutes = minutes;
      }
      _timeInvalid = false;
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    if (_endMinutes <= _startMinutes) {
      setState(() => _timeInvalid = true);
      messenger.showSnackBar(SnackBar(content: Text(l10n.scheduleTimeInvalid)));
      return;
    }
    setState(() => _saving = true);
    try {
      final DurusApi api = ref.read(apiProvider);
      final slot = widget.slot;
      if (slot == null) {
        await api.createSlot(
          studentId: widget.studentId,
          subjectId: _subjectId,
          dayOfWeek: _dayOfWeek,
          startMinutes: _startMinutes,
          endMinutes: _endMinutes,
          location: _location ?? 'student_home',
        );
      } else {
        await api.updateSlot(
          slot.id,
          dayOfWeek: _dayOfWeek,
          startMinutes: _startMinutes,
          endMinutes: _endMinutes,
          location: _location,
          subjectId: _subjectId,
          active: _active,
        );
      }
      ref.invalidate(slotsProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.commonError)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final subjectsAsync = ref.watch(subjectsProvider);
    final subjects = subjectsAsync.value ?? const <Subject>[];

    final dayItems = <DropdownMenuItem<int>>[
      for (var i = 1; i <= 7; i++)
        DropdownMenuItem(value: i, child: Text(_dayLabel(i))),
    ];
    final subjectItems = <DropdownMenuItem<String>>[
      for (final subject in subjects)
        DropdownMenuItem(value: subject.id, child: Text(subject.displayLabel)),
    ];
    final locationItems = <DropdownMenuItem<String>>[
      DropdownMenuItem(value: 'student_home', child: Text(l10n.studentsLocationHome)),
      DropdownMenuItem(value: 'teacher', child: Text(l10n.studentsLocationTeacher)),
    ];

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.slot == null ? l10n.scheduleAddSlot : l10n.commonEdit,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _initialIfPresent(subjectItems, _subjectId),
                  decoration: InputDecoration(
                    labelText: l10n.homeSubject,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: subjectItems,
                  onChanged: (value) => setState(() => _subjectId = value),
                  validator: (value) =>
                      value == null ? l10n.commonRequired : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _initialIfPresent(dayItems, _dayOfWeek),
                  decoration: InputDecoration(
                    labelText: l10n.scheduleDay,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: dayItems,
                  onChanged: (value) => setState(() => _dayOfWeek = value ?? 1),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: Text(l10n.scheduleStart)),
                    TextButton.icon(
                      onPressed: () => _pickTime(isStart: true),
                      icon: const Icon(Icons.schedule),
                      label: Text(timeFromMinutes(_startMinutes)),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: Text(l10n.scheduleEnd)),
                    TextButton.icon(
                      onPressed: () => _pickTime(isStart: false),
                      icon: const Icon(Icons.schedule),
                      label: Text(timeFromMinutes(_endMinutes)),
                    ),
                  ],
                ),
                if (_timeInvalid)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      l10n.scheduleTimeInvalid,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _initialIfPresent(locationItems, _location),
                  decoration: InputDecoration(
                    labelText: l10n.scheduleLocation,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: locationItems,
                  onChanged: (value) => setState(() => _location = value),
                ),
                if (widget.slot != null)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.scheduleActive),
                    value: _active,
                    onChanged: (value) => setState(() => _active = value),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(l10n.commonCancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(l10n.commonSave),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TestSheet extends ConsumerStatefulWidget {
  const _TestSheet({required this.studentId, this.test});

  final String studentId;
  final TestResult? test;

  @override
  ConsumerState<_TestSheet> createState() => _TestSheetState();
}

class _TestSheetState extends ConsumerState<_TestSheet> {
  final _formKey = GlobalKey<FormState>();
  final _scoreController = TextEditingController();
  final _maxScoreController = TextEditingController();
  final _noteController = TextEditingController();
  String? _subjectId;
  String _type = 'monthly';
  DateTime _date = DateTime.now();
  bool _saving = false;

  bool get _isEdit => widget.test != null;

  @override
  void initState() {
    super.initState();
    final test = widget.test;
    if (test == null) return;
    _subjectId = test.subjectId;
    _type = test.type;
    _date = _parseIsoDate(test.date) ?? DateTime.now();
    final score = test.score;
    final maxScore = test.maxScore;
    _scoreController.text = score == null ? '' : _numText(score);
    _maxScoreController.text = maxScore == null ? '' : _numText(maxScore);
    final note = test.note;
    if (note != null && note.isNotEmpty) {
      _noteController.text = note;
    }
  }

  static DateTime? _parseIsoDate(String value) {
    final parts = value.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    return DateTime(year, month, day);
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _maxScoreController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final score = double.tryParse(_scoreController.text.trim());
    final maxScore = double.tryParse(_maxScoreController.text.trim());
    if (score == null || maxScore == null) return;
    setState(() => _saving = true);
    try {
      final DurusApi api = ref.read(apiProvider);
      final note = _noteController.text.trim();
      if (_isEdit) {
        await api.updateTest(
          widget.test!.id,
          subjectId: _subjectId,
          type: _type,
          date: _isoDate(_date),
          score: score,
          maxScore: maxScore,
          note: note.isEmpty ? null : note,
        );
      } else {
        await api.createTest(
          studentId: widget.studentId,
          subjectId: _subjectId,
          type: _type,
          date: _isoDate(_date),
          score: score,
          maxScore: maxScore,
          note: note.isEmpty ? null : note,
        );
      }
      ref.invalidate(testsProvider);
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.testsSaved)));
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.commonError)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final subjectsAsync = ref.watch(subjectsProvider);
    final subjects = subjectsAsync.value ?? const <Subject>[];
    final subjectItems = <DropdownMenuItem<String>>[
      for (final subject in subjects)
        DropdownMenuItem(value: subject.id, child: Text(subject.displayLabel)),
    ];
    final typeItems = <DropdownMenuItem<String>>[
      DropdownMenuItem(value: 'monthly', child: Text(l10n.testsTypeMonthly)),
      DropdownMenuItem(value: 'midterm', child: Text(l10n.testsTypeMidterm)),
      DropdownMenuItem(value: 'final', child: Text(l10n.testsTypeFinal)),
      DropdownMenuItem(value: 'quiz', child: Text(l10n.testsTypeQuiz)),
      DropdownMenuItem(value: 'other', child: Text(l10n.testsTypeOther)),
    ];

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _isEdit ? l10n.testsEditTitle : l10n.testsAddTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _initialIfPresent(subjectItems, _subjectId),
                  decoration: InputDecoration(
                    labelText: l10n.homeSubject,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: subjectItems,
                  onChanged: (value) => setState(() => _subjectId = value),
                  validator: (value) =>
                      value == null ? l10n.commonRequired : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _initialIfPresent(typeItems, _type),
                  decoration: InputDecoration(
                    labelText: l10n.testsType,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: typeItems,
                  onChanged: (value) => setState(() => _type = value ?? 'monthly'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${l10n.commonDate}: ${fmtDate(_date)}',
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(l10n.commonEdit),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _scoreController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: l10n.testsScore,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.commonRequired;
                          }
                          return double.tryParse(value.trim()) == null
                              ? l10n.commonError
                              : null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _maxScoreController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: l10n.testsMaxScore,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.commonRequired;
                          }
                          return double.tryParse(value.trim()) == null
                              ? l10n.commonError
                              : null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: l10n.commonNotes,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(l10n.commonCancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(l10n.commonSave),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

void _openStudentForm(BuildContext context, Student? student) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => StudentFormScreen(student: student),
    ),
  );
}

void _openStudentDetail(BuildContext context, String studentId) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => StudentDetailScreen(studentId: studentId),
    ),
  );
}

String _initial(String name) => name.isEmpty ? '' : name.substring(0, 1);

String _studentSubtitle(AppLocalizations l10n, Student student) {
  final parts = <String>[];
  final grade = student.grade;
  if (grade != null && grade.isNotEmpty) {
    parts.add('${l10n.studentsGrade}: $grade');
  }
  final location = _locationLabel(l10n, student.defaultLocation);
  if (location.isNotEmpty) {
    parts.add(location);
  }
  final parentName = student.parentName;
  if (parentName != null && parentName.isNotEmpty) {
    parts.add('${l10n.studentsParentName}: $parentName');
  }
  return parts.isEmpty ? l10n.commonEmpty : parts.join(' • ');
}

String _locationLabel(AppLocalizations l10n, String? location) {
  return switch (location) {
    'student_home' => l10n.studentsLocationHome,
    'teacher_home' => l10n.studentsLocationTeacher,
    _ => location ?? '',
  };
}

String _dayLabel(int dayOfWeek) {
  final index = dayOfWeek - 1;
  if (index < 0 || index >= arabicWeekdays.length) return '';
  return arabicWeekdays[index];
}

String _testTypeLabel(AppLocalizations l10n, String? type) {
  return switch (type) {
    'monthly' => l10n.testsTypeMonthly,
    'midterm' => l10n.testsTypeMidterm,
    'final' => l10n.testsTypeFinal,
    'quiz' => l10n.testsTypeQuiz,
    'other' => l10n.testsTypeOther,
    _ => l10n.commonNone,
  };
}

String _subjectName(List<Subject> subjects, String? subjectId) {
  if (subjectId == null) return '';
  for (final subject in subjects) {
    if (subject.id == subjectId) return subject.displayLabel;
  }
  return '';
}

String _numText(num value) {
  if (value == value.truncateToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(2);
}

String _isoDate(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

String _noteCreatedLabel(LessonNote note) {
  final created = note.createdAt;
  return created == null ? '' : fmtDate(created);
}

T? _initialIfPresent<T>(List<DropdownMenuItem<T>> items, T? value) {
  if (value == null) return null;
  return items.any((item) => item.value == value) ? value : null;
}

Student? _findStudent(List<Student> students, String id) {
  for (final student in students) {
    if (student.id == id) return student;
  }
  return null;
}