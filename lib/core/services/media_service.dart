import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_constants.dart';
import '../models/audio_post_model.dart';
import '../models/video_post_model.dart';

class MediaService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<bool> isAudioFeedEnabled() async {
    try {
      final data = await _client
          .from(SupabaseConstants.appSettings)
          .select('value')
          .eq('key', 'audio_feed')
          .maybeSingle();
      if (data == null) return false;
      final v = data['value'];
      if (v is Map) return v['enabled'] == true;
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isVideoFeedEnabled() async {
    try {
      final data = await _client
          .from(SupabaseConstants.appSettings)
          .select('value')
          .eq('key', 'video_feed')
          .maybeSingle();
      if (data == null) return false;
      final v = data['value'];
      if (v is Map) return v['enabled'] == true;
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> setAudioFeedEnabled(bool enabled) async {
    await _client.from(SupabaseConstants.appSettings).upsert({
      'key': 'audio_feed',
      'value': {'enabled': enabled},
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> setVideoFeedEnabled(bool enabled) async {
    await _client.from(SupabaseConstants.appSettings).upsert({
      'key': 'video_feed',
      'value': {'enabled': enabled},
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<AudioPostModel>> getAudioFeed({int limit = 20}) async {
    final data = await _client
        .from(SupabaseConstants.audioPosts)
        .select('*, profiles:author_id(full_name, avatar_url)')
        .eq('is_published', true)
        .order('created_at', ascending: false)
        .limit(limit);
    return (data as List)
        .map((e) => AudioPostModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<VideoPostModel>> getVideoFeed({int limit = 20}) async {
    final data = await _client
        .from(SupabaseConstants.videoPosts)
        .select('*, profiles:author_id(full_name, avatar_url)')
        .eq('is_published', true)
        .order('created_at', ascending: false)
        .limit(limit);
    return (data as List)
        .map((e) => VideoPostModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Charge per 5s tick (RPC). Throws on insufficient coins.
  Future<Map<String, dynamic>> chargePlay({
    required String mediaType, // audio | video
    required String mediaId,
    int seconds = 5,
  }) async {
    final res = await _client.rpc(
      'charge_media_play',
      params: {
        'p_media_type': mediaType,
        'p_media_id': mediaId,
        'p_seconds': seconds,
      },
    );
    if (res is Map) return Map<String, dynamic>.from(res);
    return {'ok': true};
  }
}
