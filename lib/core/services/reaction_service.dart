import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_constants.dart';
import '../models/reaction_model.dart';

class ReactionService {
  final SupabaseClient _client = Supabase.instance.client;

  // ======================
  // Toggle Reaction
  // ======================
  Future<void> toggleReaction({
    required String reactionType,
    String? storyId,
    String? episodeId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    if (storyId == null && episodeId == null) {
      throw Exception('Either storyId or episodeId is required');
    }

    // আগে থেকে reaction আছে কিনা চেক
    var query = _client
        .from(SupabaseConstants.reactions)
        .select()
        .eq('user_id', userId)
        .eq('reaction_type', reactionType);

    if (storyId != null) {
      query = query.eq('story_id', storyId);
    } else {
      query = query.eq('episode_id', episodeId!);
    }

    final existing = await query.maybeSingle();

    if (existing != null) {
      // আগে থেকে থাকলে মুছে ফেলি (toggle off)
      await _client
          .from(SupabaseConstants.reactions)
          .delete()
          .eq('id', existing['id']);
    } else {
      // না থাকলে নতুন reaction যোগ
      await _client.from(SupabaseConstants.reactions).insert({
        'user_id': userId,
        'story_id': storyId,
        'episode_id': episodeId,
        'reaction_type': reactionType,
      });
    }
  }

  // ======================
  // Get Reaction Counts
  // ======================
  Future<Map<String, int>> getReactionCounts({
    String? storyId,
    String? episodeId,
  }) async {
    var query = _client.from(SupabaseConstants.reactions).select('reaction_type');

    if (storyId != null) {
      query = query.eq('story_id', storyId);
    } else if (episodeId != null) {
      query = query.eq('episode_id', episodeId);
    }

    final data = await query;

    final counts = <String, int>{};
    for (final row in data) {
      final type = row['reaction_type'] as String;
      counts[type] = (counts[type] ?? 0) + 1;
    }
    return counts;
  }

  // ======================
  // Get User's Reaction
  // ======================
  Future<String?> getUserReaction({
    String? storyId,
    String? episodeId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    var query = _client
        .from(SupabaseConstants.reactions)
        .select('reaction_type')
        .eq('user_id', userId);

    if (storyId != null) {
      query = query.eq('story_id', storyId);
    } else if (episodeId != null) {
      query = query.eq('episode_id', episodeId);
    }

    final data = await query.maybeSingle();
    return data?['reaction_type'] as String?;
  }
}
