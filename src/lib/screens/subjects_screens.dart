// Durus — subjects screens (list / form).
//
// Arabic-only, RTL. All user-facing strings come from `context.l10n`.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:durus/core/durus_api.dart';
import 'package:durus/l10n/l10n_ext.dart';
import 'package:durus/models/models.dart';
import 'package:durus/providers/providers.dart';
import 'package:durus/widgets/widgets.dart';

// ---------------------------------------------------------------------------
// Subjects list
// ---------------------------------------------------------------------------

class SubjectsScreen extends ConsumerWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.subjectsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.subjectsAddTitle,
            onPressed: () => _openSubjectForm(context, null),
          ),
        ],
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final subjectsAsync = ref.watch(subjectsProvider);
    final refsAsync = ref.watch(studentSubjectRefsProvider);
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
          child: subjectsAsync.when(
            loading: () => const LoadingView(),
            error: (error, stackTrace) => ErrorRetry(
              message: l10n.commonError,
              onRetry: () => ref.invalidate(subjectsProvider),
            ),
            data: (subjects) {
              final refs = refsAsync.value ?? const <StudentSubjectRef>[];
              final visible = _query.isEmpty
                  ? subjects
                  : subjects.where((s) => s.name.contains(_query)).toList();
              if (visible.isEmpty) {
                return RefreshableEmpty(
                  onRefresh: () => refreshSchoolData(ref),
                  empty: EmptyState(
                    icon: _query.isEmpty
                        ? Icons.menu_book_outlined
                        : Icons.search_off,
                    message: _query.isEmpty
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
                  final count =
                      refs.where((r) => r.subjectId == subject.id).length;
                  final grade = subject.grade;
                  final subtitleParts = <String>[
                    if (grade != null && grade.isNotEmpty)
                      '${l10n.subjectsGrade}: $grade',
                    '${l10n.subjectsStudentsCount}: $count',
                  ];
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.menu_book_outlined)),
                    title: Text(subject.name),
                    subtitle: Text(subtitleParts.join(' • ')),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: l10n.commonEdit,
                      onPressed: () => _openSubjectForm(context, subject),
                    ),
                    onTap: () => _openSubjectForm(context, subject),
                  );
                },
              ),
            );
          },
        ),
      ),
    ],
  );
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