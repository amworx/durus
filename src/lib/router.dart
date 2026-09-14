import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:durus/l10n/l10n_ext.dart';
import 'package:durus/providers/providers.dart';
import 'package:durus/screens/auth_screens.dart';
import 'package:durus/screens/home_shell.dart';
import 'package:durus/screens/onboarding_screens.dart';
import 'package:durus/screens/portal_screens.dart';
import 'package:durus/widgets/widgets.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const AuthGate(),
    ),
    GoRoute(
      path: '/portal',
      builder: (context, state) => const PortalEntryScreen(),
    ),
    GoRoute(
      path: '/portal/:token',
      builder: (context, state) =>
          PortalHomeScreen(token: state.pathParameters['token'] ?? ''),
    ),
  ],
  errorBuilder: (context, state) => const _NotFoundScreen(),
);

/// Decides what the root route shows based on session + onboarding state:
/// sign-in -> first-launch wizard -> home shell.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep subscribed so the gate reacts to every auth state change.
    ref.watch(authSessionProvider);
    final l10n = context.l10n;

    final session = Supabase.instance.client.auth.currentUser;
    if (session == null) {
      return const SignInScreen();
    }

    final profileAsync = ref.watch(currentProfileProvider);
    if (profileAsync.isLoading) {
      return const LoadingView();
    }
    final profileError = profileAsync.error;
    if (profileError != null) {
      return ErrorRetry(
        message: friendlyError(profileError, l10n),
        onRetry: () => ref.invalidate(currentProfileProvider),
      );
    }
    final profile = profileAsync.valueOrNull;
    if (profile == null) {
      return const SignInScreen();
    }

    // Manager may have disabled this teacher account -> block the app.
    if (!profile.active) {
      return const DisabledAccountScreen();
    }

    if (!profile.onboarded) {
      return const OnboardingScreen();
    }
    return const HomeShell();
  }
}

/// Shown to teachers whose manager disabled their account. The user can only
/// log out; re-enabling happens from the manager's settings screen.
class DisabledAccountScreen extends ConsumerWidget {
  const DisabledAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.block, size: 64, color: scheme.error),
                const SizedBox(height: 16),
                Text(
                  l10n.accountDisabledTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.accountDisabledMessage,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.error,
                    side: BorderSide(color: scheme.error.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () async {
                    await ref.read(apiProvider).signOut();
                    if (context.mounted) {
                      ref.invalidate(currentProfileProvider);
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: Text(l10n.settingsLogout),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.link_off, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text(l10n.commonError),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/'),
              child: Text(l10n.commonBack),
            ),
          ],
        ),
      ),
    );
  }
}