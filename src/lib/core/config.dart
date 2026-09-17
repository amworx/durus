/// App-wide static configuration.
///
/// Values can be overridden at build/run time with
/// `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=...`.
class AppConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://rdlapngvsxhdcoxdcjov.supabase.co',
  );

  /// New-format publishable key (maps to the `anon` role server-side).
  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_Ll-2TjHLCQKmk7bdqz6tbw_JWtgnDkM',
  );

  /// Google OAuth **web** client ID (Google Cloud Console → Credentials).
  /// Passed as `--dart-define=GOOGLE_WEB_CLIENT_ID=...` at build time; the
  /// native Android flow needs it as `serverClientId` to mint an ID token
  /// that Supabase exchanges for a session. Empty means Google sign-in is
  /// not configured — the UI then explains instead of failing.
  /// (Public identifier, not a secret; the client secret lives only in the
  /// Supabase dashboard's Google provider settings.)
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );

  /// True once a Google web client ID has been supplied at build time.
  static bool get isGoogleConfigured =>
      googleWebClientId.trim().isNotEmpty;

  /// Version shown in Settings and compared against the latest published
  /// release (app_meta.latest_release). Keep in sync with pubspec `version`.
  static const String appVersion = '1.1.17';

  /// Primary channel users are directed to when an update is available.
  /// Releases are published at https://github.com/amworx/durus/releases.
  static const String releasesPage =
      'https://github.com/amworx/durus/releases';

  /// Public web origin (GitHub Pages). Used to build shareable parent links:
  /// `$webBaseUrl/#/portal/<token>`.
  static const String webBaseUrl = 'https://amworx.github.io/durus';
}