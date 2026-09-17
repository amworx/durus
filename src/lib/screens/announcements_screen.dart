// Durus — Announcements management screen.
//
// Full list with pin/edit/delete. Uses the shared compose sheet.
// Arabic-only, RTL. All user-facing strings come from `context.l10n`.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:durus/core/utils.dart';
import 'package:durus/l10n/app_localizations.dart';
import 'package:durus/l10n/l10n_ext.dart';
import 'package:durus/models/models.dart';
import 'package:durus/providers/providers.dart';
import 'package:durus/widgets/announcement_compose_sheet.dart';
import 'package:durus/widgets/widgets.dart';

class AnnouncementsScreen extends ConsumerStatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  ConsumerState<AnnouncementsScreen> createState() =>
      _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends ConsumerState<AnnouncementsScreen> {
  Future<Map<String, int>>? _announcementReads;

  @override
  void initState() {
    super.initState();
    _announcementReads =
        ref.read(apiProvider).receiptCounts(kind: 'announcement');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final announcementsAsync = ref.watch(announcementsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.announcementsTitle),
        actions: [
          IconButton(
            tooltip: l10n.announcementsAdd,
            onPressed: () => _compose(context, l10n),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: announcementsAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorRetry(
          message: l10n.commonError,
          onRetry: () => ref.invalidate(announcementsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.campaign_outlined,
              message: l10n.announcementsNoData,
            );
          }
          // Sort: pinned first, then newest first.
          final sorted = [...items]..sort((a, b) {
              if (a.pinned != b.pinned) return a.pinned ? 0 : 1;
              final at = a.createdAt?.millisecondsSinceEpoch ?? 0;
              final bt = b.createdAt?.millisecondsSinceEpoch ?? 0;
              return bt.compareTo(at);
            });
          return FutureBuilder<Map<String, int>>(
            future: _announcementReads,
            builder: (context, snap) {
              final counts = snap.data ?? const <String, int>{};
              return RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(announcementsProvider),
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  itemCount: sorted.length,
                  itemBuilder: (context, index) => _AnnouncementTile(
                    announcement: sorted[index],
                    readCount: counts[sorted[index].id] ?? 0,
                    onEdit: () =>
                        _compose(context, l10n, edit: sorted[index]),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _compose(BuildContext context, AppLocalizations l10n,
      {Announcement? edit}) async {
    final draft = await showAnnouncementComposeSheet(context, edit: edit);
    if (draft == null || !context.mounted) return;
    final api = ref.read(apiProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (edit != null) {
        await api.updateAnnouncement(
          edit.id,
          title: draft.title,
          body: draft.body,
          audience: draft.audience,
          pinned: draft.pinned,
          expiresAt: draft.expiresAt,
        );
      } else {
        await api.createAnnouncement(
          title: draft.title,
          body: draft.body,
          audience: draft.audience,
          pinned: draft.pinned,
          expiresAt: draft.expiresAt,
        );
      }
      ref.invalidate(announcementsProvider);
      ref.invalidate(teacherNotificationsProvider);
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              edit != null ? l10n.announcementsUpdated : l10n.homeAnnouncementAdded,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(friendlyError(e, l10n))),
        );
      }
    }
  }
}

class _AnnouncementTile extends ConsumerWidget {
  const _AnnouncementTile({
    required this.announcement,
    required this.onEdit,
    this.readCount = 0,
  });

  final Announcement announcement;
  final VoidCallback onEdit;

  /// Parents that confirmed reading (receipts); 0 hides the chip.
  final int readCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final item = announcement;

    final title = item.title;
    final subtitle = title != null ? item.body : null;
    final displayBody = title != null ? title : item.body;

    final audienceLabel = switch (item.audience) {
      'parents' => l10n.announcementsParents,
      'teachers' => l10n.announcementsTeachers,
      _ => l10n.announcementsAll,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (item.pinned)
                    Icon(Icons.push_pin, size: 16, color: scheme.primary),
                  if (item.pinned) const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      displayBody,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (action) => _handleAction(
                      context,
                      ref,
                      l10n,
                      action,
                    ),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'pin',
                        child: Text(
                          item.pinned
                              ? l10n.announcementsUnpin
                              : l10n.announcementsPin,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(l10n.commonEdit),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(l10n.commonDelete,
                            style: TextStyle(color: scheme.error)),
                      ),
                    ],
                  ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  _Chip(label: audienceLabel, icon: Icons.group_outlined),
                  const SizedBox(width: 8),
                  if (readCount > 0) ...[
                    _Chip(
                      label: '✓ $readCount',
                      icon: Icons.done_all_outlined,
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (item.expiresAt != null)
                    _Chip(
                      label:
                          '${l10n.announcementsExpiryLabel}: ${item.expiresAt!.toIso8601String().substring(0, 10)}',
                      icon: Icons.event_outlined,
                    ),
                  const Spacer(),
                  if (item.createdAt != null)
                    Text(
                      fmtDate(item.createdAt!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleAction(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    String action,
  ) async {
    final api = ref.read(apiProvider);
    switch (action) {
      case 'pin':
        await api.setAnnouncementPinned(announcement.id, !announcement.pinned);
        ref.invalidate(announcementsProvider);
      case 'edit':
        onEdit();
      case 'delete':
        final ok = await confirmDialog(
          context,
          title: l10n.commonConfirmDelete,
          message: l10n.announcementsDeleteConfirm,
        );
        if (!ok || !context.mounted) return;
        await api.deleteAnnouncement(announcement.id);
        ref.invalidate(announcementsProvider);
        ref.invalidate(teacherNotificationsProvider);
    }
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: scheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
