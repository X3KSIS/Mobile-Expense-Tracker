/// The Supabase project the app talks to.
///
/// The app's own project is built in ([defaultUrl], [defaultPublishableKey]),
/// so a plain `flutter run` (or F5) connects. To point a build at another
/// project, pass its values:
///
/// ```sh
/// flutter run --dart-define-from-file=supabase.json
/// ```
///
/// with `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` (see
/// `supabase.example.json`).
///
/// The publishable key is public by design (it ships inside every copy of
/// the app); row-level security is what protects each user's data. Never
/// put a secret or service_role key in the app.
class SupabaseConfig {
  const SupabaseConfig({required this.url, required this.publishableKey});

  /// The values given with `--dart-define`, or the app's own project.
  factory SupabaseConfig.fromEnvironment() => const SupabaseConfig(
    url: String.fromEnvironment('SUPABASE_URL', defaultValue: defaultUrl),
    publishableKey: String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
      defaultValue: defaultPublishableKey,
    ),
  );

  /// The Expense Tracker project.
  static const String defaultUrl = 'https://ambfmaujbnraqiujckoh.supabase.co';

  /// Its publishable key (safe to ship; see the class comment).
  static const String defaultPublishableKey =
      'sb_publishable_RDAxareDbl9KlNPmvNB5_A_bfOiDJhO';

  final String url;
  final String publishableKey;

  /// False only if a build cleared both values; the app then shows a
  /// setup screen and nobody can sign in.
  bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;
}
