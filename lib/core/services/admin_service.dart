import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_constants.dart';
import '../models/story_model.dart';
import '../models/novel_model.dart';
import '../models/user_model.dart';

class AdminService {
  final SupabaseClient _client = Supabase.instance.client;

  /// বর্তমান ইউজার admin কিনা
  Future<bool> isCurrentUserAdmin() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    final data = await _client
        .from(SupabaseConstants.profiles)
        .select('is_admin')
        .eq('id', userId)
        .maybeSingle();

    return data?['is_admin'] == true;
  }

  /// Dashboard stats
  Future<Map<String, int>> getStats() async {
    final users = await _client.from(SupabaseConstants.profiles).select('id');
    final stories = await _client
        .from(SupabaseConstants.stories)
        .select('id')
        .eq('is_published', true);
    final drafts = await _client
        .from(SupabaseConstants.stories)
        .select('id')
        .eq('is_published', false);
    final novels = await _client.from(SupabaseConstants.novels).select('id');
    final comments = await _client.from(SupabaseConstants.comments).select('id');

    return {
      'users': (users as List).length,
      'stories': (stories as List).length,
      'drafts': (drafts as List).length,
      'novels': (novels as List).length,
      'comments': (comments as List).length,
    };
  }

  /// সব published গল্প (মডারেশন)
  Future<List<StoryModel>> getAllStories({int limit = 50}) async {
    final data = await _client
        .from(SupabaseConstants.stories)
        .select('''
          *,
          profiles:author_id (full_name, username)
        ''')
        .order('created_at', ascending: false)
        .limit(limit);

    return (data as List).map((json) {
      final map = Map<String, dynamic>.from(json);
      if (map['profiles'] != null) {
        map['author_name'] = map['profiles']['full_name'];
        map['author_username'] = map['profiles']['username'];
      }
      return StoryModel.fromJson(map);
    }).toList();
  }

  /// গল্প আনপাবলিশ (হাইড)
  Future<void> unpublishStory(String storyId) async {
    await _client.from(SupabaseConstants.stories).update({
      'is_published': false,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', storyId);
  }

  /// গল্প ডিলিট
  Future<void> deleteStory(String storyId) async {
    await _client.from(SupabaseConstants.stories).delete().eq('id', storyId);
  }

  /// সব উপন্যাস
  Future<List<NovelModel>> getAllNovels({int limit = 50}) async {
    final data = await _client
        .from(SupabaseConstants.novels)
        .select('''
          *,
          profiles:author_id (full_name, username)
        ''')
        .order('created_at', ascending: false)
        .limit(limit);

    return (data as List).map((json) {
      final map = Map<String, dynamic>.from(json);
      if (map['profiles'] != null) {
        map['author_name'] = map['profiles']['full_name'];
        map['author_username'] = map['profiles']['username'];
      }
      return NovelModel.fromJson(map);
    }).toList();
  }

  /// উপন্যাস আনপাবলিশ
  Future<void> unpublishNovel(String novelId) async {
    await _client.from(SupabaseConstants.novels).update({
      'is_published': false,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', novelId);
  }

  /// উপন্যাস ডিলিট
  Future<void> deleteNovel(String novelId) async {
    await _client.from(SupabaseConstants.novels).delete().eq('id', novelId);
  }

  /// ইউজার লিস্ট
  Future<List<UserModel>> getAllUsers({int limit = 50}) async {
    final data = await _client
        .from(SupabaseConstants.profiles)
        .select()
        .order('created_at', ascending: false)
        .limit(limit);

    return (data as List).map((e) => UserModel.fromJson(e)).toList();
  }
}
