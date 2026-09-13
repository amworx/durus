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
}