import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:durus/l10n/l10n_ext.dart';
import 'package:durus/models/models.dart';
import 'package:durus/providers/providers.dart';

/// Audience picker with the manager-only 'all' segment hidden from
/// teachers (the server policy rejects it too). A teacher editing a
/// pre-fix 'all' row still sees it selected once, and moving away is
/// one tap; saving it unchanged surfaces a clear validation error.
class _AudiencePicker extends ConsumerWidget {
  const _AudiencePicker({required this.current, required this.onChanged});

  final String current;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isManager =
        ref.watch(currentProfileProvider).valueOrNull?.isManager ?? false;
    return SegmentedButton<String>(
      segments: [
        if (isManager || current == 'all')
          ButtonSegment(
            value: 'all',
            label: Text(l10n.announcementsAll),
          ),
        ButtonSegment(
          value: 'teachers',
          label: Text(l10n.announcementsTeachers),
        ),
        ButtonSegment(
          value: 'parents',
          label: Text(l10n.announcementsParents),
        ),
      ],
      selected: {current},
      onSelectionChanged: (sel) => onChanged(sel.first),
    );
  }
}

/// Draft data returned from the announcement compose sheet.
class AnnouncementDraft {
  const AnnouncementDraft({
    required this.body,
    this.title,
    required this.audience,
    required this.pinned,
    this.expiresAt,
  });

  final String body;
  final String? title;
  final String audience;
  final bool pinned;
  final String? expiresAt;
}

/// Opens the shared announcement compose / edit bottom sheet.
///
/// When [edit] is provided the sheet is pre-filled for editing.
/// Returns an [AnnouncementDraft] on save, or `null` when dismissed.
Future<AnnouncementDraft?> showAnnouncementComposeSheet(
  BuildContext context, {
  Announcement? edit,
}) {
  return showModalBottomSheet<AnnouncementDraft>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _AnnouncementComposeSheet(edit: edit),
  );
}

class _AnnouncementComposeSheet extends ConsumerStatefulWidget {
  const _AnnouncementComposeSheet({this.edit});

  final Announcement? edit;

  @override
  ConsumerState<_AnnouncementComposeSheet> createState() =>
      _AnnouncementComposeSheetState();
}

class _AnnouncementComposeSheetState
    extends ConsumerState<_AnnouncementComposeSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;
  late String _audience;
  late bool _pinned;
  String? _expiresAt;

  bool get _isEditing => widget.edit != null;

  @override
  void initState() {
    super.initState();
    final edit = widget.edit;
    _titleCtrl = TextEditingController(text: edit?.title ?? '');
    _bodyCtrl = TextEditingController(text: edit?.body ?? '');
    // Non-managers never see the 'all' audience (server rejects it too):
    // teachers announce to parents or fellow teachers only.
    final isManager =
        ref.read(currentProfileProvider).valueOrNull?.isManager ?? false;
    final initial = edit?.audience ?? 'all';
    _audience = (!isManager && initial == 'all') ? 'parents' : initial;
    _pinned = edit?.pinned ?? false;
    _expiresAt = edit?.expiresAt?.toIso8601String().substring(0, 10);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final body = _bodyCtrl.text.trim();
    if (body.isEmpty) return;
    Navigator.of(context).pop(
      AnnouncementDraft(
        body: body,
        title: _titleCtrl.text.trim().isEmpty
            ? null
            : _titleCtrl.text.trim(),
        audience: _audience,
        pinned: _pinned,
        expiresAt: _expiresAt,
      ),
    );
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt != null
          ? DateTime.tryParse(_expiresAt!) ?? now.add(const Duration(days: 30))
          : now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 3)),
      helpText: context.l10n.announcementsPickDate,
    );
    if (picked != null) {
      setState(() => _expiresAt = picked.toIso8601String().substring(0, 10));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

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
                    _isEditing ? l10n.announcementsEdit : l10n.announcementsAdd,
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
            const SizedBox(height: 16),

            // --- Title (optional) ---
            TextField(
              controller: _titleCtrl,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.announcementsTitleLabel,
                hintText: l10n.announcementsTitleHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // --- Body (required) ---
            TextField(
              controller: _bodyCtrl,
              autofocus: !_isEditing,
              minLines: 3,
              maxLines: 6,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                labelText: l10n.announcementsBodyLabel,
                hintText: l10n.announcementsBodyHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // --- Audience ('all' is manager-only, enforced server-side too) ---
            Text(l10n.announcementsAudience, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            _AudiencePicker(
              current: _audience,
              onChanged: (v) => setState(() => _audience = v),
            ),
            const SizedBox(height: 16),

            // --- Pinned ---
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.announcementsPinned),
              subtitle: Text(
                l10n.announcementsPinnedHint,
                style: theme.textTheme.bodySmall,
              ),
              value: _pinned,
              onChanged: (v) => setState(() => _pinned = v),
            ),

            // --- Expiry ---
            Row(
              children: [
                Expanded(
                  child: Text(
                    _expiresAt != null
                        ? '${l10n.announcementsExpiry}: $_expiresAt'
                        : l10n.announcementsNoExpiry,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: _pickExpiry,
                  icon: const Icon(Icons.event_outlined, size: 18),
                  label: Text(
                    _expiresAt != null
                        ? l10n.commonEdit
                        : l10n.announcementsPickDate,
                  ),
                ),
                if (_expiresAt != null)
                  IconButton(
                    tooltip: l10n.announcementsRemoveExpiry,
                    icon: Icon(Icons.close, size: 18, color: scheme.error),
                    onPressed: () => setState(() => _expiresAt = null),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // --- Save ---
            FilledButton.icon(
              onPressed: _save,
              icon: Icon(_isEditing ? Icons.check : Icons.send_outlined, size: 18),
              label: Text(_isEditing ? l10n.commonSave : l10n.announcementsPublish),
            ),
          ],
        ),
      ),
    );
  }
}
