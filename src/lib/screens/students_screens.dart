// Durus — students screens (list / form / detail).
//
// Arabic-only, RTL. All user-facing strings come from `context.l10n`.
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:durus/core/durus_api.dart';
import 'package:durus/core/utils.dart';
import 'package:durus/l10n/app_localizations.dart';
import 'package:durus/l10n/l10n_ext.dart';
import 'package:durus/models/models.dart';
import 'package:durus/providers/providers.dart';
import 'package:durus/screens/reports_screen.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final studentsAsync = ref.watch(studentsProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
        Expanded(
          child: studentsAsync.when(
            loading: () => const LoadingView(),
            error: (error, stackTrace) => ErrorRetry(
              message: l10n.commonError,
              onRetry: () => ref.invalidate(studentsProvider),
            ),
            data: (students) {
              final visible = _query.isEmpty
                  ? students
                  : students.where((s) => s.name.contains(_query)).toList();
              if (visible.isEmpty) {
                return EmptyState(
                  icon: _query.isEmpty ? Icons.group_outlined : Icons.search_off,
                  message: _query.isEmpty ? l10n.studentsEmpty : l10n.commonEmpty,
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                itemCount: visible.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final student = visible[index];
                  return ListTile(
                    leading: CircleAvatar(child: Text(_initial(student.name))),
                    title: Text(student.name),
                    subtitle: Text(
                      _studentSubtitle(l10n, student),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: l10n.commonEdit,
                      onPressed: () => _openStudentForm(context, student),
                    ),
                    onTap: () => _openStudentDetail(context, student.id),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
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
                        label: Text(subject.name),
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

  Future<void> _generateParentLink(Student student) async {
    final l10n = context.l10n;
    try {
      final DurusApi api = ref.read(apiProvider);
      await api.ensureParentToken(student.id);
      ref.invalidate(studentsProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.commonError)),
        );
      }
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

    return Scaffold(
      appBar: AppBar(title: Text(cachedStudent?.name ?? l10n.studentsTitle)),
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
              FilledButton.tonalIcon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => MonthlyReportScreen(
                      studentId: student.id,
                      studentName: student.name,
                    ),
                  ),
                ),
                icon: const Icon(Icons.description_outlined),
                label: Text('${l10n.reportsTitle} — ${student.name}'),
              ),
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
                      for (final subject in assigned) Chip(label: Text(subject.name)),
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
                        _attendanceTile(context, l10n, subjects, lesson),
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
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => _deleteStudent(student),
                icon: const Icon(Icons.delete_outline),
                label: Text('${l10n.studentsTitle} ${l10n.commonDelete}'),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
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
    final linkText = kIsWeb ? Uri.base.resolve('#/portal/$token').toString() : token;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
          child: TextButton.icon(
            onPressed: () => _copyParentLink(linkText),
            icon: const Icon(Icons.copy),
            label: Text(l10n.studentsCopyLink),
          ),
        ),
      ],
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
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: const Icon(Icons.assignment_outlined, color: Colors.blueGrey),
      title: Text(subjectName.isEmpty ? l10n.commonNone : subjectName),
      subtitle: Text(subtitleParts.join(' • ')),
      trailing: Text(test.date),
      onLongPress: () => _deleteTest(test),
    );
  }

  Widget _attendanceTile(
    BuildContext context,
    AppLocalizations l10n,
    List<Subject> subjects,
    LessonSession lesson,
  ) {
    final subjectName = _subjectName(subjects, lesson.subjectId);
    final theme = Theme.of(context);
    final (label, color) = _attendanceStyle(l10n, lesson.attendance);
    final titleParts = <String>[
      lesson.date,
      if (subjectName.isNotEmpty) subjectName,
    ];
    return Padding(
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
          StatusChip(label: label, color: color),
        ],
      ),
    );
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

  void _openTestSheet(BuildContext context, String studentId) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _TestSheet(studentId: studentId),
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
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    if (_endMinutes <= _startMinutes) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.commonError)));
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
        DropdownMenuItem(value: subject.id, child: Text(subject.name)),
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
  const _TestSheet({required this.studentId});

  final String studentId;

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
      await api.createTest(
        studentId: widget.studentId,
        subjectId: _subjectId,
        type: _type,
        date: _isoDate(_date),
        score: score,
        maxScore: maxScore,
        note: note.isEmpty ? null : note,
      );
      ref.invalidate(testsProvider);
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
    final subjectItems = <DropdownMenuItem<String>>[
      for (final subject in subjects)
        DropdownMenuItem(value: subject.id, child: Text(subject.name)),
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
                  l10n.testsAddTitle,
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
      'teacher' => l10n.studentsLocationTeacher,
      _ => location ?? '',
    };
}

String _dayLabel(int dayOfWeek) {
  final index = dayOfWeek - 1;
  if (index < 0 || index >= arabicWeekdays.length) return '';
  return arabicWeekdays[index];
}

(String, Color) _attendanceStyle(AppLocalizations l10n, String attendance) {
  return switch (attendance) {
    'present' => (l10n.homeMarkPresent, Colors.green),
    'absent' => (l10n.homeMarkAbsent, Colors.red),
    'rescheduled' => (l10n.homeMarkRescheduled, Colors.orange),
    _ => (attendance, Colors.blueGrey),
  };
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
    if (subject.id == subjectId) return subject.name;
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