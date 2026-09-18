import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_constants.dart';
import '../models/reading_progress_model.dart';

class ReadingProgressService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> saveProgress({
    String? storyId,
    String? episodeId,
    required double progressPercent,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    if (storyId == null && episodeId == null) return;

    final percent = progressPercent.clamp(0.0, 100.0);

    var query = _client
        .from(SupabaseConstants.readingProgress)
        .select()
        .eq('user_id', userId);

    if (storyId != null) {
      query = query.eq('story_id', storyId);
    } else {
      query = query.eq('episode_id', episodeId!);
    }

    final existing = await query.maybeSingle();

    if (existing != null) {
      await _client.from(SupabaseConstants.readingProgress).update({
        'progress_percent': percent,
        'last_read_at': DateTime.now().toIso8601String(),
      }).eq('id', existing['id']);
    } else {
      await _client.from(SupabaseConstants.readingProgress).insert({
        'user_id': userId,
        'story_id': storyId,
        'episode_id': episodeId,
        'progress_percent': percent,
        'last_read_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<ReadingProgressModel?> getProgress({
    String? storyId,
    String? episodeId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    var query = _client
        .from(SupabaseConstants.readingProgress)
        .select()
        .eq('user_id', userId);

    if (storyId != null) {
      query = query.eq('story_id', storyId);
    } else if (episodeId != null) {
      query = query.eq('episode_id', episodeId);
    } else {
      return null;
    }

    final data = await query.maybeSingle();
    if (data == null) return null;
    return ReadingProgressModel.fromJson(data);
  }

  Future<List<ReadingProgressModel>> getAllProgress() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await _client
        .from(SupabaseConstants.readingProgress)
        .select()
        .eq('user_id', userId)
        .order('last_read_at', ascending: false);

    return (data as List)
        .map((e) => ReadingProgressModel.fromJson(e))
        .toList();
  }
}
