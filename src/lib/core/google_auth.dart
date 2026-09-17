import 'package:google_sign_in/google_sign_in.dart';

/// Google OAuth client-ID guard. The ID is a public identifier (it ships in
/// the app via `--dart-define=GOOGLE_WEB_CLIENT_ID=...`); the client secret
/// lives only in the Supabase dashboard and never enters the app.
bool isGoogleClientIdConfigured(String clientId) =>
    clientId.trim().isNotEmpty;

/// ID/access token pair from the native Google flow. Null as a whole means
/// the user cancelled — the caller must stay quiet, not show an error.
class GoogleAuthTokens {
  const GoogleAuthTokens({required this.idToken, required this.accessToken});

  final String? idToken;
  final String? accessToken;
}

/// Decides whether the change-password form makes sense for an account.
/// Google-only accounts have no password (the re-sign-in inside
/// password-change could never succeed), so they get an explanatory notice
/// instead. [identityProviders] are the linked identity provider names
/// (`User.identities[*].provider`: `'email'` for password, `'google'` for
/// Google); [appProvider] is the `app_metadata['provider']` fallback for
/// sessions whose identity list is missing. Fails open to the old behavior
/// (show the form) whenever the account state is unknown.
bool showPasswordForm({
  required List<String> identityProviders,
  String? appProvider,
}) {
  if (identityProviders.isEmpty) {
    return appProvider != 'google';
  }
  return identityProviders.contains('email');
}

/// `initialize` must run exactly once per app lifetime; guard it here so
/// every sign-in attempt (and retry) stays safe.
bool _googleInitDone = false;

/// Native Google sign-in (Android): system account picker → ID token +
/// authorized access token for Supabase's `signInWithIdToken`. Returns null
/// when the user cancels. Throws [StateError] (`google_not_configured`)
/// without touching any SDK when no client ID was supplied.
Future<GoogleAuthTokens?> defaultNativeGoogleSignIn(String clientId) async {
  if (!isGoogleClientIdConfigured(clientId)) {
    throw StateError('google_not_configured');
  }
  if (!_googleInitDone) {
    await GoogleSignIn.instance.initialize(serverClientId: clientId.trim());
    _googleInitDone = true;
  }
  try {
    final account = await GoogleSignIn.instance.authenticate(
      scopeHint: const ['email', 'profile'],
    );
    final authz = await account.authorizationClient
            .authorizationForScopes(const ['email', 'profile']) ??
        await account.authorizationClient
            .authorizeScopes(const ['email', 'profile']);
    return GoogleAuthTokens(
      idToken: account.authentication.idToken,
      accessToken: authz.accessToken,
    );
  } on GoogleSignInException catch (e) {
    if (e.code == GoogleSignInExceptionCode.canceled) {
      return null;
    }
    rethrow;
  }
}
