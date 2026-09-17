import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:durus/l10n/app_localizations.dart';
import 'package:durus/l10n/l10n_ext.dart';
import 'package:durus/core/config.dart';
import 'package:durus/providers/providers.dart';
import 'package:durus/widgets/widgets.dart';

/// Email + password sign-in. Switching to sign-up toggles the shared
/// [SignUpScreen] body in place — no navigation needed.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _showSignUp = false;

  @override
  Widget build(BuildContext context) {
    return _AuthLayout(
      showSignUp: _showSignUp,
      onSwitchMode: () => setState(() => _showSignUp = !_showSignUp),
    );
  }
}

/// Standalone sign-up screen (kept for contract completeness; the gate uses
/// [SignInScreen], which embeds the same forms).
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  bool _showSignIn = true;

  @override
  Widget build(BuildContext context) {
    return _AuthLayout(
      showSignUp: !_showSignIn,
      onSwitchMode: () => setState(() => _showSignIn = !_showSignIn),
    );
  }
}

class _AuthLayout extends StatelessWidget {
  const _AuthLayout({
    required this.showSignUp,
    required this.onSwitchMode,
  });

  final bool showSignUp;
  final VoidCallback onSwitchMode;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.school, size: 64, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  l10n.appTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.authSubtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 32),
                if (showSignUp)
                  _SignUpBody(onSwitch: onSwitchMode)
                else
                  _SignInBody(onSwitch: onSwitchMode),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Maps GoTrue error messages to friendly Arabic copy.
String _authErrorText(AuthException e, AppLocalizations l10n) {
  final m = e.message;
  if (m.contains('Invalid login credentials')) {
    return l10n.authInvalidCredentials;
  }
  if (m.contains('Email not confirmed')) {
    return l10n.authEmailNotConfirmed;
  }
  if (m.contains('email_address_invalid') || m.contains('invalid email')) {
    return l10n.authInvalidEmail;
  }
  if (m.contains('rate_limit') || m.contains('rate limit')) {
    return l10n.authRateLimited;
  }
  if (m.contains('already registered') || m.contains('already exists')) {
    return l10n.authUserExists;
  }
  if (m.contains('provider is not enabled') ||
      m.contains('Unsupported provider')) {
    return l10n.authGoogleNotConfigured;
  }
  return l10n.commonError;
}

/// Google sign-in button shared by the sign-in and sign-up forms. The OAuth
/// flow creates the account when needed, so one button serves both modes.
/// Cancellation stays quiet; misconfiguration explains itself in Arabic
/// instead of failing. [formBusy] disables the button while the password
/// form works, and [onBusyChanged] lets the parent disable its own submit
/// while Google is in flight.
class _GoogleSignInButton extends ConsumerStatefulWidget {
  const _GoogleSignInButton({
    required this.formBusy,
    required this.onBusyChanged,
  });

  final bool formBusy;
  final ValueChanged<bool> onBusyChanged;

  @override
  ConsumerState<_GoogleSignInButton> createState() =>
      _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends ConsumerState<_GoogleSignInButton> {
  bool _busy = false;

  Future<void> _run() async {
    if (_busy || widget.formBusy) {
      return;
    }
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    if (!AppConfig.isGoogleConfigured) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.authGoogleNotConfigured)),
      );
      return;
    }
    setState(() => _busy = true);
    widget.onBusyChanged(true);
    try {
      await ref.read(apiProvider).signInWithGoogle(
            googleWebClientId: AppConfig.googleWebClientId,
          );
      // Success transitions via the AuthGate; cancellation returns false
      // quietly — no snackbar either way.
    } on StateError catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              e.message == 'google_not_configured'
                  ? l10n.authGoogleNotConfigured
                  : l10n.commonError,
            ),
          ),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(_authErrorText(e, l10n))),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(friendlyError(e, l10n))));
      }
    } finally {
      widget.onBusyChanged(false);
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final disabled = _busy || widget.formBusy;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                l10n.authGoogleOr,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: disabled ? null : _run,
          child: _busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.colorScheme.primary),
                      ),
                      child: Text(
                        'G',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(l10n.authGoogleButton),
                  ],
                ),
        ),
      ],
    );
  }
}

class _SignInBody extends ConsumerStatefulWidget {
  const _SignInBody({required this.onSwitch});

  final VoidCallback onSwitch;

  @override
  ConsumerState<_SignInBody> createState() => _SignInBodyState();
}

class _SignInBodyState extends ConsumerState<_SignInBody> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;
  bool _googleBusy = false;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return context.l10n.commonRequired;
    }
    if (!_emailPattern.hasMatch(v)) {
      return context.l10n.authInvalidCredentials;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return context.l10n.commonRequired;
    }
    if (v.length < 6) {
      return context.l10n.authInvalidCredentials;
    }
    return null;
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    setState(() => _submitting = true);
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(apiProvider).signIn(
            _emailController.text.trim(),
            _passwordController.text,
          );
      // The AuthGate reacts to the auth state change automatically.
    } on AuthException catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(_authErrorText(e, l10n))),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(friendlyError(e, l10n))));
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  /// Forgot-password flow: if the login form already holds a valid email,
  /// send the reset directly; otherwise ask for the email in a dialog first.
  Future<void> _forgotPassword() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);

    Future<void> send(String target) async {
      try {
        await ref.read(apiProvider).resetPassword(target);
        if (mounted) {
          messenger.showSnackBar(SnackBar(content: Text(l10n.authResetSent)));
        }
      } on AuthException {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.authRateLimited)),
          );
        }
      } catch (_) {
        if (mounted) {
          messenger.showSnackBar(SnackBar(content: Text(l10n.commonError)));
        }
      }
    }

    final email = _emailController.text.trim();
    if (_emailPattern.hasMatch(email)) {
      await send(email);
      return;
    }

    final controller = TextEditingController(text: email);
    final target = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.authResetDialogTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: l10n.authEmail,
            prefixIcon: const Icon(Icons.mail_outline),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () {
              final v = controller.text.trim();
              if (_emailPattern.hasMatch(v)) {
                Navigator.pop(dialogContext, v);
              }
            },
            child: Text(l10n.authResetButton),
          ),
        ],
      ),
    );
    controller.dispose();
    if (target != null) {
      await send(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l10n.authEmail,
              prefixIcon: const Icon(Icons.mail_outline),
            ),
            validator: _validateEmail,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: l10n.authPassword,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                tooltip: l10n.authPassword,
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                ),
              ),
            ),
            validator: _validatePassword,
          ),
          const SizedBox(height: 24),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed:
                  (_submitting || _googleBusy) ? null : _forgotPassword,
              child: Text(l10n.authForgotPassword),
            ),
          ),
          const SizedBox(height: 4),
          FilledButton(
            onPressed: (_submitting || _googleBusy) ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.authSignInButton),
          ),
          const SizedBox(height: 8),
          _GoogleSignInButton(
            formBusy: _submitting,
            onBusyChanged: (v) {
              if (mounted) setState(() => _googleBusy = v);
            },
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed:
                (_submitting || _googleBusy) ? null : widget.onSwitch,
            child: Text(l10n.authNoAccount),
          ),
        ],
      ),
    );
  }
}

class _SignUpBody extends ConsumerStatefulWidget {
  const _SignUpBody({required this.onSwitch});

  final VoidCallback onSwitch;

  @override
  ConsumerState<_SignUpBody> createState() => _SignUpBodyState();
}

class _SignUpBodyState extends ConsumerState<_SignUpBody> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;
  bool _googleBusy = false;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return context.l10n.commonRequired;
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return context.l10n.commonRequired;
    }
    if (!_emailPattern.hasMatch(v)) {
      return context.l10n.authInvalidCredentials;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return context.l10n.commonRequired;
    }
    if (v.length < 6) {
      return context.l10n.authInvalidCredentials;
    }
    return null;
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    setState(() => _submitting = true);
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(apiProvider).signUp(
            _emailController.text.trim(),
            _passwordController.text,
            _nameController.text.trim(),
          );
      if (!mounted) {
        return;
      }
      if (Supabase.instance.client.auth.currentUser == null) {
        // No auto session (e.g. email confirmation) — tell the user to
        // confirm the email, then go back to sign-in.
        messenger.showSnackBar(SnackBar(content: Text(l10n.authCheckEmail)));
        widget.onSwitch();
      }
      // Otherwise the AuthGate transitions automatically.
    } on AuthException catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(_authErrorText(e, l10n))),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(friendlyError(e, l10n))));
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
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nameController,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l10n.authFullName,
              prefixIcon: const Icon(Icons.person_outline),
            ),
            validator: _validateName,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l10n.authEmail,
              prefixIcon: const Icon(Icons.mail_outline),
            ),
            validator: _validateEmail,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: l10n.authPassword,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                tooltip: l10n.authPassword,
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                ),
              ),
            ),
            validator: _validatePassword,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: (_submitting || _googleBusy) ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.authSignUpButton),
          ),
          const SizedBox(height: 8),
          _GoogleSignInButton(
            formBusy: _submitting,
            onBusyChanged: (v) {
              if (mounted) setState(() => _googleBusy = v);
            },
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: (_submitting || _googleBusy) ? null : widget.onSwitch,
            child: Text(l10n.authHaveAccount),
          ),
        ],
      ),
    );
  }
}