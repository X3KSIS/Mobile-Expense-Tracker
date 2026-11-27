/// The Supabase project the app talks to, passed in at build time so no
/// keys live in the source code:
///
/// ```sh
/// flutter run --dart-define-from-file=supabase.json
/// ```
///
/// `supabase.json` (gitignored; copy `supabase.example.json`) holds
/// `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` from the project's API
/// settings (the publishable key starts `sb_publishable_`; a legacy anon
/// key also works). It is public by design: row-level security protects
/// the data. Never put a secret or service_role key in the app.
class SupabaseConfig {
  const SupabaseConfig({required this.url, required this.publishableKey});

  /// Reads the values given with `--dart-define`.
  factory SupabaseConfig.fromEnvironment() => const SupabaseConfig(
    url: String.fromEnvironment('SUPABASE_URL'),
    publishableKey: String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
  );

  final String url;
  final String publishableKey;

  /// False when the app was built without the Supabase values; it then
  /// runs on this device only, with a demo sign-in and no sync.
  bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;
}
