import 'package:flutter/material.dart';

import 'package:durus/l10n/app_localizations.dart';
import 'package:durus/l10n/l10n_ext.dart';

/// Shared UI building blocks and helpers used across the teacher app.
/// Kept dependency-free (no providers) so any screen can use them.

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class ErrorRetry extends StatelessWidget {
  const ErrorRetry({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 40, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.commonRetry),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.compact = false,
  });

  final IconData icon;
  final String message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.all(compact ? 8 : 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card with a title used for every dashboard/settings section.
/// Parents are expected to add vertical spacing between cards.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// Material confirm dialog returning `true` when the user confirms.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final l10n = context.l10n;
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.commonNo),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.commonYes),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Small rounded status pill (e.g. attendance/status labels).
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Maps an exception to a short user-facing message. Falls back to a fixed
/// Arabic string when no localization instance is available.
String friendlyError(Object error, [AppLocalizations? l10n]) {
  if (l10n != null) {
    return l10n.commonError;
  }
  return 'حدث خطأ ما';
}

/// Empty state that still supports pull-to-refresh — keeps a scrollable (with
/// fill-remaining layout) so `RefreshIndicator` can be triggered even when a
/// list has no rows yet and the user needs to fetch newly added data.
class RefreshableEmpty extends StatelessWidget {
  const RefreshableEmpty({
    super.key,
    required this.onRefresh,
    required this.empty,
  });

  final Future<void> Function() onRefresh;
  final Widget empty;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(hasScrollBody: false, child: empty),
        ],
      ),
    );
  }
}

/// One tappable action shown inside the [SelectionBar].
class BulkAction {
  const BulkAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool enabled;
}

/// Bottom bar shown while working with a multi-select list (bulk operations).
/// Displays the current selection count plus actions (delete / set grade /
/// assign subject / mark paid ...). Parent screens provide the actions and
/// toggle visibility themselves.
class SelectionBar extends StatelessWidget {
  const SelectionBar({
    super.key,
    required this.count,
    required this.total,
    required this.onClose,
    required this.actions,
    this.onSelectAll,
  });

  final int count;
  final int total;
  final VoidCallback onClose;
  final List<BulkAction> actions;
  final VoidCallback? onSelectAll;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Material(
      elevation: 8,
      color: theme.colorScheme.surfaceContainerLow,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: l10n.commonClose,
                onPressed: onClose,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  l10n.bulkSelected(count),
                  style: theme.textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onSelectAll != null)
                IconButton(
                  icon: Icon(
                    count == total
                        ? Icons.deselect
                        : Icons.select_all,
                  ),
                  tooltip: l10n.commonSelectAll,
                  onPressed: onSelectAll,
                ),
              const SizedBox(width: 4),
              for (final action in actions)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 4),
                  child: _SelectionActionChip(action: action),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionActionChip extends StatelessWidget {
  const _SelectionActionChip({required this.action});

  final BulkAction action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fg = action.color ?? scheme.onSurfaceVariant;
    return InkWell(
      onTap: action.enabled ? action.onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(action.icon, color: action.enabled ? fg : scheme.outlineVariant),
            const SizedBox(height: 2),
            Text(
              action.label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: action.enabled ? fg : scheme.outlineVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}