/// Cloudflare R2 — Access/Secret শুধু ল্যাপটপে dart-define দিয়ে দাও।
/// খালি key → isConfigured = false → Supabase fallback (নিরাপদ)।
class R2Constants {
  static const String accountId = '3ebf1d5c6799bd3a8c2e0a710f2b72bc';
  static const String bucketName = 'golpoghor';

  /// GitHub-এ কমিট করো না — ল্যাপটপে:
  /// --dart-define=R2_ACCESS_KEY=... --dart-define=R2_SECRET_KEY=...
  static const String accessKeyId = String.fromEnvironment(
    'R2_ACCESS_KEY',
    defaultValue: '',
  );
  static const String secretAccessKey = String.fromEnvironment(
    'R2_SECRET_KEY',
    defaultValue: '',
  );

  static const String publicBaseUrl =
      'https://pub-09f1cd9fdced4119ab588b1a4cfc9575.r2.dev';

  static bool get isConfigured =>
      accountId.isNotEmpty &&
      accessKeyId.isNotEmpty &&
      secretAccessKey.isNotEmpty &&
      publicBaseUrl.isNotEmpty;

  static String get endpoint =>
      'https://$accountId.r2.cloudflarestorage.com';
}
