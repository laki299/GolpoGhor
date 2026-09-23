/// Cloudflare R2 — পরে Account/Bucket/Key দিয়ে পূরণ করো।
/// এখন খালি রাখলে অ্যাপ ক্র্যাশ করবে না; আপলোড শুধু R2 কনফিগ থাকলে চালু হবে।
class R2Constants {
  static const String accountId = ''; // e.g. abc123
  static const String bucketName = 'golpoghor-media';
  static const String accessKeyId = '';
  static const String secretAccessKey = '';

  /// Public base URL (R2.dev or custom domain), without trailing slash
  /// e.g. https://pub-xxxxx.r2.dev  or  https://media.golpoghor.com
  static const String publicBaseUrl = '';

  static bool get isConfigured =>
      accountId.isNotEmpty &&
      accessKeyId.isNotEmpty &&
      secretAccessKey.isNotEmpty &&
      publicBaseUrl.isNotEmpty;

  static String endpoint =>
      'https://$accountId.r2.cloudflarestorage.com';
}
