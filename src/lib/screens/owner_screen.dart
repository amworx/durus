import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:durus/l10n/app_localizations.dart';
import 'package:durus/l10n/l10n_ext.dart';
import 'package:durus/models/models.dart';
import 'package:durus/providers/providers.dart';
import 'package:durus/widgets/durus_top_bar.dart';
import 'package:durus/widgets/widgets.dart';

/// Arabic label for a feature-request status code. Shared with the
/// Settings feature-request section.
String featureRequestStatusLabel(String status, AppLocalizations l10n) {
  switch (status) {
    case 'reviewing':
      return l10n.featReqStatusReviewing;
    case 'planned':
      return l10n.featReqStatusPlanned;
    case 'done':
      return l10n.featReqStatusDone;
    case 'rejected':
      return l10n.featReqStatusRejected;
    case 'new':
    default:
      return l10n.featReqStatusNew;
  }
}

/// App-owner dashboard: whole-product totals, deployed versions, signups,
/// per-school health and feature requests with status management. Split into
/// four bottom-bar tabs so each job gets its own screen: the totals are the
/// daily glance, while schools, requests and errors are opened on demand
/// instead of pushing each other down one long page. Visible only to
/// `app_owners` (the RPC itself fails closed for anyone else).
class OwnerDashboardScreen extends ConsumerStatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  ConsumerState<OwnerDashboardScreen> createState() =>
      _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends ConsumerState<OwnerDashboardScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: DurusTopBar(title: l10n.ownerTitle),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: IndexedStack(
            index: _index,
            children: const [
              _OverviewTab(),
              _SchoolsTab(),
              _RequestsTab(),
              _ErrorsTab(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: l10n.ownerTabOverview,
          ),
          NavigationDestination(
            icon: const Icon(Icons.school_outlined),
            selectedIcon: const Icon(Icons.school),
            label: l10n.ownerSchools,
          ),
          NavigationDestination(
            icon: const Icon(Icons.forum_outlined),
            selectedIcon: const Icon(Icons.forum),
            label: l10n.ownerTabRequests,
          ),
          NavigationDestination(
            icon: const Icon(Icons.report_problem_outlined),
            selectedIcon: const Icon(Icons.report_problem),
            label: l10n.ownerTabErrors,
          ),
        ],
      ),
    );
  }
}

/// Shared frame for the three tabs that read `owner_overview`: a refreshable
/// scrollable body with loading and retry states, so each tab only has to
/// describe its own sections.
class _OverviewTabFrame extends ConsumerWidget {
  const _OverviewTabFrame({required this.builder});

  final List<Widget> Function(BuildContext context, OwnerOverview overview)
      builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final overviewAsync = ref.watch(ownerOverviewProvider);
    return RefreshIndicator(
      onRefresh: () => ref.refresh(ownerOverviewProvider.future),
      child: overviewAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorRetry(
          message: l10n.commonError,
          onRetry: () => ref.invalidate(ownerOverviewProvider),
        ),
        data: (overview) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: builder(context, overview),
        ),
      ),
    );
  }
}

/// Tab 1 — the numbers: totals, deployed versions, weekly signups.
class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _OverviewTabFrame(
      builder: (context, overview) {
        final t = overview.totals;
        return [
          _StatGrid(entries: [
            (l10n.ownerUsers, '${t['users'] ?? 0}'),
            (l10n.settingsTeachers, '${t['teachers'] ?? 0}'),
            (l10n.ownerSchools, '${t['schools'] ?? 0}'),
            (l10n.studentsTitle, '${t['students'] ?? 0}'),
            (l10n.subjectsTitle, '${t['subjects'] ?? 0}'),
            (l10n.ownerActiveToday, '${overview.activeToday}'),
            (l10n.ownerActiveWeek, '${overview.activeWeek}'),
            (l10n.ownerCollected, '${t['collected_month'] ?? 0}'),
            (l10n.ownerOutstanding, '${t['outstanding'] ?? 0}'),
          ]),
          const SizedBox(height: 16),
          SectionCard(
            title: l10n.ownerVersions,
            child: overview.versions.isEmpty
                ? Text(l10n.ownerEmpty)
                : Column(
                    children: [
                      for (final v in overview.versions)
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            '${v['version'] ?? '?'} • ${v['platform'] ?? '?'}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          trailing: Text('${v['users'] ?? 0}'),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: l10n.ownerSignups,
            child: overview.signupsPerWeek.isEmpty
                ? Text(l10n.ownerEmpty)
                : _SignupBars(weeks: overview.signupsPerWeek),
          ),
        ];
      },
    );
  }
}

/// Tab 2 — every school with its teacher/student counts and a stagnation chip.
class _SchoolsTab extends StatelessWidget {
  const _SchoolsTab();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _OverviewTabFrame(
      builder: (context, overview) => [
        SectionCard(
          title: overview.schools.isEmpty
              ? l10n.ownerSchools
              : '${l10n.ownerSchools} (${overview.schools.length})',
          child: overview.schools.isEmpty
              ? Text(l10n.ownerEmpty)
              : Column(
                  children: [
                    for (final s in overview.schools) _SchoolRow(school: s),
                  ],
                ),
        ),
      ],
    );
  }
}

/// Tab 3 — feature requests and their triage dropdowns, isolated from the
/// rest of the dashboard so a long list no longer buries everything below it.
class _RequestsTab extends StatelessWidget {
  const _RequestsTab();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _OverviewTabFrame(
      builder: (context, overview) => [
        SectionCard(
          title: overview.requests.isEmpty
              ? l10n.ownerRequests
              : '${l10n.ownerRequests} (${overview.requests.length})',
          child: overview.requests.isEmpty
              ? Text(l10n.ownerEmpty)
              : Column(
                  children: [
                    for (final r in overview.requests) _OwnerRequestRow(request: r),
                  ],
                ),
        ),
      ],
    );
  }
}

/// Tab 4 — recent client error reports, newest first.
class _ErrorsTab extends ConsumerWidget {
  const _ErrorsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final errorsAsync = ref.watch(ownerErrorsProvider);
    return RefreshIndicator(
      onRefresh: () => ref.refresh(ownerErrorsProvider.future),
      child: errorsAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorRetry(
          message: l10n.commonError,
          onRetry: () => ref.invalidate(ownerErrorsProvider),
        ),
        data: (errors) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            SectionCard(
              title: errors.isEmpty
                  ? l10n.ownerErrors
                  : '${l10n.ownerErrors} (${errors.length})',
              child: errors.isEmpty
                  ? Text(l10n.ownerEmpty)
                  : Column(
                      children: [
                        for (final e in errors) _ErrorRow(error: e),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  const _ErrorRow({required this.error});

  final Map<String, dynamic> error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final who = [
      if ((error['author_email'] as String?)?.isNotEmpty ?? false)
        error['author_email'],
      if ((error['app_version'] as String?)?.isNotEmpty ?? false)
        'v${error['app_version']}',
      if ((error['screen'] as String?)?.isNotEmpty ?? false) error['screen'],
    ].join(' • ');
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(
        '${error['message'] ?? ''}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        // Exception/SQL text is Latin and reads left-to-right even inside the
        // RTL layout.
        textDirection: TextDirection.ltr,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
      ),
      subtitle: who.isEmpty
          ? null
          : Text(
              who,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.entries});

  final List<(String, String)> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        // Three columns on a phone (as designed), four once the web/tablet
        // layout gives us the width for them.
        final wide = constraints.maxWidth >= 640;
        return GridView.count(
          crossAxisCount: wide ? 4 : 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: wide ? 1.5 : 1.15,
          children: [
            for (final (label, value) in entries)
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        value,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SignupBars extends StatelessWidget {
  const _SignupBars({required this.weeks});

  final List<Map<String, dynamic>> weeks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    var max = 1;
    for (final w in weeks) {
      final c = (w['count'] as num?)?.toInt() ?? 0;
      if (c > max) max = c;
    }
    return Column(
      children: [
        for (final w in weeks)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                SizedBox(
                  width: 92,
                  child: Text(
                    '${w['week'] ?? ''}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                Expanded(
                  child: FractionallySizedBox(
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor:
                        (((w['count'] as num?)?.toInt() ?? 0) / max)
                            .clamp(0.04, 1.0),
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${w['count'] ?? 0}'),
              ],
            ),
          ),
      ],
    );
  }
}

class _SchoolRow extends StatelessWidget {
  const _SchoolRow({required this.school});

  final Map<String, dynamic> school;

  bool get _dead {
    final raw = school['last_session'];
    if (raw is! String) return true;
    final last = DateTime.tryParse(raw);
    if (last == null) return true;
    return DateTime.now().difference(last).inDays > 30;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final manager = (school['manager'] as String?)?.trim() ?? '';
    final email = (school['email'] as String?)?.trim() ?? '';
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(
        manager.isNotEmpty ? manager : email,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '${l10n.settingsTeachers}: ${school['teachers'] ?? 0} • '
        '${l10n.studentsTitle}: ${school['students'] ?? 0}',
        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
      ),
      trailing: _dead
          ? StatusChip(label: l10n.ownerDead, color: theme.colorScheme.error)
          : null,
    );
  }
}

class _OwnerRequestRow extends ConsumerStatefulWidget {
  const _OwnerRequestRow({required this.request});

  final FeatureRequest request;

  @override
  ConsumerState<_OwnerRequestRow> createState() => _OwnerRequestRowState();
}

class _OwnerRequestRowState extends ConsumerState<_OwnerRequestRow> {
  bool _saving = false;

  static const _statuses = ['new', 'reviewing', 'planned', 'done', 'rejected'];

  Future<void> _setStatus(String status) async {
    if (_saving || status == widget.request.status) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(apiProvider)
          .setFeatureRequestStatus(widget.request.id, status);
      ref.invalidate(ownerOverviewProvider);
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(context.l10n.commonError)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final r = widget.request;
    final author = (r.authorName?.trim().isNotEmpty ?? false)
        ? r.authorName!.trim()
        : (r.authorEmail ?? '');
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                StatusChip(
                  label: r.type == 'edit'
                      ? l10n.featReqEdit
                      : l10n.featReqFeature,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    r.title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            if (r.body.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(r.body.trim()),
            ],
            if (author.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                author,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue:
                  _statuses.contains(r.status) ? r.status : 'new',
              onChanged: _saving ? null : (v) => v != null ? _setStatus(v) : null,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                for (final s in _statuses)
                  DropdownMenuItem(
                    value: s,
                    child: Text(featureRequestStatusLabel(s, l10n)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
