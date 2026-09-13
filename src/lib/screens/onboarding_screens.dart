import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:durus/l10n/l10n_ext.dart';
import 'package:durus/providers/providers.dart';
import 'package:durus/widgets/widgets.dart';

/// One-time first-launch wizard: single vs multi teacher mode, plus the
/// invitation join path for teachers created by a manager.
///
/// Per ADR-004, in BOTH single and multi mode the creator becomes a manager;
/// the UI is identical afterwards — only RLS scoping differs.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _tokenController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _complete({
    required bool isManager,
    required bool singleMode,
  }) async {
    setState(() => _submitting = true);
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(apiProvider)
          .completeOnboarding(_nameController.text.trim(), isManager: isManager);
      if (!mounted) {
        return;
      }
      ref.invalidate(currentProfileProvider);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            singleMode
                ? l10n.onboardingWelcomeSingle
                : l10n.onboardingWelcomeMulti,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(friendlyError(e, l10n))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<void> _joinInvitation() async {
    final token = _tokenController.text.trim();
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    if (token.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.commonRequired)));
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(apiProvider).acceptInvitation(token);
      if (!mounted) {
        return;
      }
      ref.invalidate(currentProfileProvider);
    } on PostgrestException catch (e) {
      final message = e.message.contains('invalid_invitation')
          ? l10n.portalInvalid
          : l10n.commonError;
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(friendlyError(e, l10n))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.onboardingTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.onboardingSubtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _nameController,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: l10n.onboardingCreatorName,
                    hintText: l10n.commonOptional,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),
                _ModeCard(
                  icon: Icons.person,
                  title: l10n.onboardingSingle,
                  enabled: !_submitting,
                  onTap: () => _complete(isManager: true, singleMode: true),
                ),
                const SizedBox(height: 12),
                _ModeCard(
                  icon: Icons.groups_outlined,
                  title: l10n.onboardingMulti,
                  enabled: !_submitting,
                  onTap: () => _complete(isManager: true, singleMode: false),
                ),
                const SizedBox(height: 24),
                Divider(color: theme.colorScheme.outlineVariant),
                const SizedBox(height: 16),
                Text(
                  l10n.onboardingTokenTitle,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _tokenController,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _joinInvitation(),
                  decoration: InputDecoration(
                    hintText: l10n.onboardingTokenHint,
                    prefixIcon: const Icon(Icons.key_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _submitting ? null : _joinInvitation,
                  icon: const Icon(Icons.login),
                  label: Text(l10n.onboardingTokenSubmit),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 28, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: theme.textTheme.bodyLarge),
              ),
              Icon(
                Icons.chevron_left,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}