import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_constants.dart';
import '../models/bookmark_model.dart';

class BookmarkService {
  final SupabaseClient _client = Supabase.instance.client;

  // ======================
  // Toggle Bookmark
  // ======================
  Future<void> toggleBookmark({
    String? storyId,
    String? novelId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    if (storyId == null && novelId == null) {
      throw Exception('Either storyId or novelId is required');
    }

    var query = _client
        .from(SupabaseConstants.bookmarks)
        .select()
        .eq('user_id', userId);

    if (storyId != null) {
      query = query.eq('story_id', storyId);
    } else {
      query = query.eq('novel_id', novelId!);
    }

    final existing = await query.maybeSingle();

    if (existing != null) {
      await _client
          .from(SupabaseConstants.bookmarks)
          .delete()
          .eq('id', existing['id']);
    } else {
      await _client.from(SupabaseConstants.bookmarks).insert({
        'user_id': userId,
        'story_id': storyId,
        'novel_id': novelId,
      });
    }
  }

  // ======================
  // Check if Bookmarked
  // ======================
  Future<bool> isBookmarked({
    String? storyId,
    String? novelId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    var query = _client
        .from(SupabaseConstants.bookmarks)
        .select()
        .eq('user_id', userId);

    if (storyId != null) {
      query = query.eq('story_id', storyId);
    } else if (novelId != null) {
      query = query.eq('novel_id', novelId);
    }

    final data = await query.maybeSingle();
    return data != null;
  }

  // ======================
  // Get User Bookmarks
  // ======================
  Future<List<BookmarkModel>> getUserBookmarks() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await _client
        .from(SupabaseConstants.bookmarks)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (data as List)
        .map((json) => BookmarkModel.fromJson(json))
        .toList();
  }
}
