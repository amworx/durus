// Durus — teacher management screen (manager users only).
//
// Arabic-only, RTL. All user-facing strings come from `context.l10n`.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:durus/core/durus_api.dart';
import 'package:durus/l10n/app_localizations.dart';
import 'package:durus/l10n/l10n_ext.dart';
import 'package:durus/models/models.dart';
import 'package:durus/providers/providers.dart';
import 'package:durus/widgets/widgets.dart';

class TeacherManagementScreen extends ConsumerWidget {
  const TeacherManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTeachers)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            title: l10n.settingsAddTeacher,
            child: const _AddTeacherForm(),
          ),
          const SizedBox(height: 16),
          const _InviteSection(),
          const SizedBox(height: 16),
          SectionCard(
            title: l10n.settingsTeachers,
            child: const _TeachersList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Create teacher with credentials
// ---------------------------------------------------------------------------

class _AddTeacherForm extends ConsumerStatefulWidget {
  const _AddTeacherForm();

  @override
  ConsumerState<_AddTeacherForm> createState() => _AddTeacherFormState();
}

class _AddTeacherFormState extends ConsumerState<_AddTeacherForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _submitting = true);
    try {
      final DurusApi api = ref.read(apiProvider);
      await api.createTeacher(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );
      ref.invalidate(teachersProvider);
      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.settingsTeacherCreated)),
        );
      }
    } on PostgrestException catch (_) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.commonError)));
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.commonError)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nameController,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l10n.settingsTeacherFullName,
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (value) =>
                value == null || value.trim().isEmpty ? l10n.commonRequired : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l10n.settingsTeacherEmail,
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (value) =>
                value == null || value.trim().isEmpty ? l10n.commonRequired : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: l10n.settingsTeacherPassword,
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (value) => value == null || value.isEmpty
                ? l10n.commonRequired
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.settingsShareCredentials,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.settingsAddTeacher),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Invitation links
// ---------------------------------------------------------------------------

class _InviteSection extends ConsumerStatefulWidget {
  const _InviteSection();

  @override
  ConsumerState<_InviteSection> createState() => _InviteSectionState();
}

class _InviteSectionState extends ConsumerState<_InviteSection> {
  String? _generatedToken;
  bool _generating = false;

  Future<void> _generate() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _generating = true);
    try {
      final DurusApi api = ref.read(apiProvider);
      final invitation = await api.createInvitation(email: null);
      ref.invalidate(invitationsProvider);
      if (mounted) {
        setState(() => _generatedToken = invitation.token);
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.commonError)));
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _copyToken(String token) async {
    final l10n = context.l10n;
    await Clipboard.setData(ClipboardData(text: token));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.studentsLinkCopied)),
      );
    }
  }

  Future<void> _revoke(Invitation invitation) async {
    final l10n = context.l10n;
    final confirmed = await confirmDialog(
      context,
      title: l10n.commonDelete,
      message: l10n.commonConfirmDelete,
    );
    if (!confirmed || !mounted) return;
    try {
      final DurusApi api = ref.read(apiProvider);
      await api.revokeInvitation(invitation.id);
      ref.invalidate(invitationsProvider);
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
    final invitationsAsync = ref.watch(invitationsProvider);
    final token = _generatedToken;
    return SectionCard(
      title: l10n.settingsInviteLink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.tonalIcon(
            onPressed: _generating ? null : _generate,
            icon: _generating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.link),
            label: Text(l10n.settingsInviteLink),
          ),
          if (token != null && token.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      token,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    tooltip: l10n.settingsCopy,
                    onPressed: () => _copyToken(token),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          invitationsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: LinearProgressIndicator(),
            ),
            error: (error, stackTrace) => ErrorRetry(
              message: l10n.commonError,
              onRetry: () => ref.invalidate(invitationsProvider),
            ),
            data: (invitations) {
              if (invitations.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    l10n.commonEmpty,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              }
              return Column(
                children: [
                  for (final invitation in invitations)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: const Icon(Icons.mail_outline),
                      title: Text(_invitationTitle(l10n, invitation)),
                      subtitle: SelectableText(
                        invitation.token,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: l10n.commonDelete,
                        onPressed: () => _revoke(invitation),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Teachers list
// ---------------------------------------------------------------------------

class _TeachersList extends ConsumerWidget {
  const _TeachersList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final teachersAsync = ref.watch(teachersProvider);
    return teachersAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => ErrorRetry(
        message: l10n.commonError,
        onRetry: () => ref.invalidate(teachersProvider),
      ),
      data: (teachers) {
        if (teachers.isEmpty) {
          return EmptyState(
            icon: Icons.group_outlined,
            message: l10n.settingsTeachersEmpty,
          );
        }
        return Column(
          children: [
            for (final teacher in teachers)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  child: Text(_initial(teacher.fullName)),
                ),
                title: Text(teacher.fullName ?? ''),
                subtitle: Text(teacher.email),
              ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _invitationTitle(AppLocalizations l10n, Invitation invitation) {
  final email = invitation.email;
  if (email != null && email.isNotEmpty) return email;
  final token = invitation.token;
  if (token.isNotEmpty) return token;
  return l10n.commonNone;
}

String _initial(String? name) {
  if (name == null || name.isEmpty) return '';
  return name.substring(0, 1);
}