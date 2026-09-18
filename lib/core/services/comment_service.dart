import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_constants.dart';
import '../models/comment_model.dart';

class CommentService {
  final SupabaseClient _client = Supabase.instance.client;

  // ======================
  // Add Comment / Reply
  // ======================
  Future<CommentModel> addComment({
    required String content,
    String? storyId,
    String? episodeId,
    String? parentId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    if (storyId == null && episodeId == null) {
      throw Exception('Either storyId or episodeId is required');
    }

    final data = await _client
        .from(SupabaseConstants.comments)
        .insert({
          'user_id': userId,
          'story_id': storyId,
          'episode_id': episodeId,
          'parent_id': parentId,
          'content': content,
        })
        .select()
        .single();

    return CommentModel.fromJson(data);
  }

  // ======================
  // Get Comments for Story
  // ======================
  Future<List<CommentModel>> getStoryComments(String storyId) async {
    final data = await _client
        .from(SupabaseConstants.comments)
        .select('''
          *,
          profiles:user_id (
            full_name,
            avatar_url
          )
        ''')
        .eq('story_id', storyId)
        .isFilter('parent_id', null) // শুধু মূল কমেন্ট
        .order('created_at', ascending: false);

    return (data as List).map((json) {
      final map = Map<String, dynamic>.from(json);
      if (map['profiles'] != null) {
        map['user_name'] = map['profiles']['full_name'];
        map['user_avatar'] = map['profiles']['avatar_url'];
      }
      return CommentModel.fromJson(map);
    }).toList();
  }

  // ======================
  // Get Comments for Episode
  // ======================
  Future<List<CommentModel>> getEpisodeComments(String episodeId) async {
    final data = await _client
        .from(SupabaseConstants.comments)
        .select('''
          *,
          profiles:user_id (
            full_name,
            avatar_url
          )
        ''')
        .eq('episode_id', episodeId)
        .isFilter('parent_id', null) // শুধু মূল কমেন্ট
        .order('created_at', ascending: false);

    return (data as List).map((json) {
      final map = Map<String, dynamic>.from(json);
      if (map['profiles'] != null) {
        map['user_name'] = map['profiles']['full_name'];
        map['user_avatar'] = map['profiles']['avatar_url'];
      }
      return CommentModel.fromJson(map);
    }).toList();
  }

  // ======================
  // Get Replies of a Comment
  // ======================
  Future<List<CommentModel>> getReplies(String parentId) async {
    final data = await _client
        .from(SupabaseConstants.comments)
        .select('''
          *,
          profiles:user_id (
            full_name,
            avatar_url
          )
        ''')
        .eq('parent_id', parentId)
        .order('created_at', ascending: true);

    return (data as List).map((json) {
      final map = Map<String, dynamic>.from(json);
      if (map['profiles'] != null) {
        map['user_name'] = map['profiles']['full_name'];
        map['user_avatar'] = map['profiles']['avatar_url'];
      }
      return CommentModel.fromJson(map);
    }).toList();
  }

  // ======================
  // Delete Comment
  // ======================
  Future<void> deleteComment(String commentId) async {
    await _client
        .from(SupabaseConstants.comments)
        .delete()
        .eq('id', commentId);
  }
}
