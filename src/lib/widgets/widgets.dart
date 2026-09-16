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

/// One selectable option inside a [FilterSheetSection].
class FilterChoice {
  const FilterChoice(this.value, this.label);

  /// The applied filter value. The first option of each section is the
  /// "all" sentinel (e.g. `null`, or a `_all*` marker on Fees).
  final String? value;
  final String label;
}

/// One labeled dropdown inside the reusable filter bottom sheet.
class FilterSheetSection {
  const FilterSheetSection({
    required this.id,
    required this.label,
    required this.choices,
    this.current,
  });

  final String id;
  final String label;
  final List<FilterChoice> choices;
  final String? current;
}

/// Raises an icon button with an active-filter count badge. Tapping it opens
/// the filter sheet; the parent applies the returned values itself.
class FilterButton extends StatelessWidget {
  const FilterButton({
    super.key,
    required this.activeCount,
    required this.onPressed,
    this.tooltip,
  });

  final int activeCount;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return IconButton.filledTonal(
      tooltip: tooltip ?? l10n.filterTitle,
      onPressed: onPressed,
      icon: Badge.count(
        count: activeCount,
        isLabelVisible: activeCount > 0,
        child: const Icon(Icons.tune),
      ),
    );
  }
}

/// Shows a modal bottom sheet with one labeled dropdown per [sections] plus
/// "مسح الكل" (clear all) and "تطبيق" (apply) actions.
///
/// Returns a map of section-id → chosen value when applied, or `null` when
/// dismissed. The first choice of each section is treated as the "all"
/// sentinel and is what "مسح الكل" resets to.
Future<Map<String, String?>?> showFilterSheet(
  BuildContext context, {
  required String title,
  required List<FilterSheetSection> sections,
}) {
  final drafts = {for (final s in sections) s.id: s.current};
  return showModalBottomSheet<Map<String, String?>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setSheetState) {
        final l10n = context.l10n;
        final theme = Theme.of(context);
        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16,
              0,
              16,
              MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                for (final section in sections) ...[
                  Text(
                    section.label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String?>(
                    key: ValueKey('${section.id}:${drafts[section.id]}'),
                    initialValue: drafts[section.id],
                    isDense: true,
                    decoration: InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: [
                      for (final c in section.choices)
                        DropdownMenuItem<String?>(
                          value: c.value,
                          child: Text(c.label),
                        ),
                    ],
                    onChanged: (v) => setSheetState(() => drafts[section.id] = v),
                  ),
                  const SizedBox(height: 14),
                ],
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setSheetState(() {
                          for (final s in sections) {
                            drafts[s.id] = s.choices.first.value;
                          }
                        }),
                        child: Text(l10n.filterClearAll),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () =>
                            Navigator.of(sheetContext).pop({...drafts}),
                        child: Text(l10n.filterApply),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}