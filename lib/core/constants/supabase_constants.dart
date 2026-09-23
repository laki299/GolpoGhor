class SupabaseConstants {
  static const String supabaseUrl = 'https://yrsjmhkxdamtojwjfkis.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_SUBENWVOAfriBPFChyohYQ_arFgqRKf';

  // Core tables
  static const String profiles = 'profiles';
  static const String stories = 'stories';
  static const String novels = 'novels';
  static const String episodes = 'episodes';
  static const String comments = 'comments';
  static const String reactions = 'reactions';
  static const String follows = 'follows';
  static const String bookmarks = 'bookmarks';
  static const String readingProgress = 'reading_progress';

  // Monetization
  static const String appSettings = 'app_settings';
  static const String coinTransactions = 'coin_transactions';
  static const String contentUnlocks = 'content_unlocks';
  static const String adWatchLog = 'ad_watch_log';
  static const String withdrawRequests = 'withdraw_requests';

  // Media (audio / video)
  static const String audioPosts = 'audio_posts';
  static const String videoPosts = 'video_posts';
  static const String mediaUnlocks = 'media_unlocks';
  static const String mediaPlayCharges = 'media_play_charges';

  // Legacy Supabase storage (optional; images will move to R2)
  static const String storyImagesBucket = 'story_images';
}
