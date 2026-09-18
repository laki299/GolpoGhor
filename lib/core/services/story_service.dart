import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_constants.dart';
import '../models/story_model.dart';
import '../models/content_block_model.dart';

class StoryService {
  final SupabaseClient _client = Supabase.instance.client;

  // ======================
  // Create Story (Published)
  // ======================
  Future<StoryModel> createStory({
    required String title,
    String? description,
    String? category,
    List<String> tags = const [],
    required List<ContentBlock> contentBlocks,
    String? coverUrl,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final data = await _client
        .from(SupabaseConstants.stories)
        .insert({
          'author_id': userId,
          'title': title,
          'description': description,
          'category': category,
          'tags': tags,
          'content_blocks': contentBlocks.map((e) => e.toJson()).toList(),
          'cover_url': coverUrl,
          'is_published': true,
        })
        .select()
        .single();

    return StoryModel.fromJson(data);
  }

  // ======================
  // Save as Draft
  // ======================
  Future<StoryModel> saveDraft({
    required String title,
    String? description,
    String? category,
    List<String> tags = const [],
    required List<ContentBlock> contentBlocks,
    String? coverUrl,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final data = await _client
        .from(SupabaseConstants.stories)
        .insert({
          'author_id': userId,
          'title': title.isEmpty ? 'শিরোনামহীন খসড়া' : title,
          'description': description,
          'category': category,
          'tags': tags,
          'content_blocks': contentBlocks.map((e) => e.toJson()).toList(),
          'cover_url': coverUrl,
          'is_published': false,
        })
        .select()
        .single();

    return StoryModel.fromJson(data);
  }

  // ======================
  // Get User Drafts
  // ======================
  Future<List<StoryModel>> getDrafts() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await _client
        .from(SupabaseConstants.stories)
        .select()
        .eq('author_id', userId)
        .eq('is_published', false)
        .order('updated_at', ascending: false);

    return (data as List).map((e) => StoryModel.fromJson(e)).toList();
  }

  // ======================
  // Publish Draft
  // ======================
  Future<void> publishDraft(String storyId) async {
    await _client.from(SupabaseConstants.stories).update({
      'is_published': true,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', storyId);
  }

  // ======================
  // Feed (Published stories)
  // ======================
  Future<List<StoryModel>> getFeed({
    int limit = 15,
    int offset = 0,
  }) async {
    final data = await _client
        .from(SupabaseConstants.stories)
        .select('''
          *,
          profiles:author_id (
            full_name,
            username,
            avatar_url
          )
        ''')
        .eq('is_published', true)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (data as List).map((json) {
      final map = Map<String, dynamic>.from(json);
      if (map['profiles'] != null) {
        map['author_name'] = map['profiles']['full_name'];
        map['author_username'] = map['profiles']['username'];
        map['author_avatar'] = map['profiles']['avatar_url'];
      }
      return StoryModel.fromJson(map);
    }).toList();
  }

  // ======================
  // Get Story by ID
  // ======================
  Future<StoryModel?> getStoryById(String storyId) async {
    final data = await _client
        .from(SupabaseConstants.stories)
        .select('''
          *,
          profiles:author_id (
            full_name,
            username,
            avatar_url
          )
        ''')
        .eq('id', storyId)
        .maybeSingle();

    if (data == null) return null;

    final map = Map<String, dynamic>.from(data);
    if (map['profiles'] != null) {
      map['author_name'] = map['profiles']['full_name'];
      map['author_username'] = map['profiles']['username'];
      map['author_avatar'] = map['profiles']['avatar_url'];
    }

    return StoryModel.fromJson(map);
  }

  // ======================
  // Update Story
  // ======================
  Future<void> updateStory({
    required String storyId,
    String? title,
    String? description,
    String? category,
    List<String>? tags,
    List<ContentBlock>? contentBlocks,
    String? coverUrl,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (category != null) updates['category'] = category;
    if (tags != null) updates['tags'] = tags;
    if (contentBlocks != null) {
      updates['content_blocks'] =
          contentBlocks.map((e) => e.toJson()).toList();
    }
    if (coverUrl != null) updates['cover_url'] = coverUrl;

    await _client
        .from(SupabaseConstants.stories)
        .update(updates)
        .eq('id', storyId);
  }

  // ======================
  // Delete Story
  // ======================
  Future<void> deleteStory(String storyId) async {
    await _client.from(SupabaseConstants.stories).delete().eq('id', storyId);
  }

  // ======================
  // Get Stories by Author
  // ======================
  Future<List<StoryModel>> getStoriesByAuthor(String authorId) async {
    final data = await _client
        .from(SupabaseConstants.stories)
        .select()
        .eq('author_id', authorId)
        .eq('is_published', true)
        .order('created_at', ascending: false);

    return (data as List).map((e) => StoryModel.fromJson(e)).toList();
  }
}
