import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_constants.dart';
import '../models/novel_model.dart';
import '../models/episode_model.dart';
import '../models/content_block_model.dart';

class NovelService {
  final SupabaseClient _client = Supabase.instance.client;

  // ======================
  // Create Novel + First Episode
  // ======================
  Future<NovelModel> createNovel({
    required String title,
    String? description,
    String? category,
    List<String> tags = const [],
    String? coverUrl,
    required String firstEpisodeTitle,
    required List<ContentBlock> firstEpisodeBlocks,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    // 1. Novel তৈরি
    final novelData = await _client
        .from(SupabaseConstants.novels)
        .insert({
          'author_id': userId,
          'title': title,
          'description': description,
          'category': category,
          'tags': tags,
          'cover_url': coverUrl,
          'episode_count': 1,
          'is_published': true,
        })
        .select()
        .single();

    final novel = NovelModel.fromJson(novelData);

    // 2. প্রথম Episode তৈরি
    await _client.from(SupabaseConstants.episodes).insert({
      'novel_id': novel.id,
      'episode_number': 1,
      'title': firstEpisodeTitle,
      'content_blocks': firstEpisodeBlocks.map((e) => e.toJson()).toList(),
      'is_published': true,
    });

    return novel;
  }

  // ======================
  // Add New Episode (auto number)
  // ======================
  Future<EpisodeModel> addEpisode({
    required String novelId,
    required String title,
    required List<ContentBlock> contentBlocks,
  }) async {
    // সর্বশেষ episode number বের করা
    final last = await _client
        .from(SupabaseConstants.episodes)
        .select('episode_number')
        .eq('novel_id', novelId)
        .order('episode_number', ascending: false)
        .limit(1)
        .maybeSingle();

    final nextNumber = (last?['episode_number'] as int? ?? 0) + 1;

    final data = await _client
        .from(SupabaseConstants.episodes)
        .insert({
          'novel_id': novelId,
          'episode_number': nextNumber,
          'title': title,
          'content_blocks': contentBlocks.map((e) => e.toJson()).toList(),
          'is_published': true,
        })
        .select()
        .single();

    // Novel এর episode_count আপডেট
    await _client
        .from(SupabaseConstants.novels)
        .update({
          'episode_count': nextNumber,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', novelId);

    return EpisodeModel.fromJson(data);
  }

  // ======================
  // Get Novel Details
  // ======================
  Future<NovelModel?> getNovelById(String novelId) async {
    final data = await _client
        .from(SupabaseConstants.novels)
        .select('''
          *,
          profiles:author_id (
            full_name,
            username,
            avatar_url
          )
        ''')
        .eq('id', novelId)
        .maybeSingle();

    if (data == null) return null;

    final map = Map<String, dynamic>.from(data);
    if (map['profiles'] != null) {
      map['author_name'] = map['profiles']['full_name'];
      map['author_username'] = map['profiles']['username'];
      map['author_avatar'] = map['profiles']['avatar_url'];
    }

    return NovelModel.fromJson(map);
  }

  // ======================
  // Get All Episodes of a Novel
  // ======================
  Future<List<EpisodeModel>> getEpisodes(String novelId) async {
    final data = await _client
        .from(SupabaseConstants.episodes)
        .select()
        .eq('novel_id', novelId)
        .eq('is_published', true)
        .order('episode_number', ascending: true);

    return (data as List)
        .map((json) => EpisodeModel.fromJson(json))
        .toList();
  }

  // ======================
  // Get Single Episode
  // ======================
  Future<EpisodeModel?> getEpisodeById(String episodeId) async {
    final data = await _client
        .from(SupabaseConstants.episodes)
        .select()
        .eq('id', episodeId)
        .maybeSingle();

    if (data == null) return null;
    return EpisodeModel.fromJson(data);
  }

  // ======================
  // Update Episode
  // ======================
  Future<void> updateEpisode({
    required String episodeId,
    String? title,
    List<ContentBlock>? contentBlocks,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (title != null) updates['title'] = title;
    if (contentBlocks != null) {
      updates['content_blocks'] =
          contentBlocks.map((e) => e.toJson()).toList();
    }

    await _client
        .from(SupabaseConstants.episodes)
        .update(updates)
        .eq('id', episodeId);
  }

  // ======================
  // Get User's Novels
  // ======================
  Future<List<NovelModel>> getNovelsByAuthor(String authorId) async {
    final data = await _client
        .from(SupabaseConstants.novels)
        .select()
        .eq('author_id', authorId)
        .order('created_at', ascending: false);

    return (data as List)
        .map((json) => NovelModel.fromJson(json))
        .toList();
  }
}
