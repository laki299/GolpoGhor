import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_constants.dart';
import '../models/story_model.dart';
import '../models/novel_model.dart';
import '../models/user_model.dart';

class AdminService {
  final SupabaseClient _client = Supabase.instance.client;

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

  /// মনিটাইজেশন স্ট্যাট (টেবিল না থাকলে ০)
  Future<Map<String, int>> getMonetizationStats() async {
    try {
      final txs = await _client
          .from(SupabaseConstants.coinTransactions)
          .select('amount, type');
      final unlocks =
          await _client.from(SupabaseConstants.contentUnlocks).select('id');
      final ads = await _client.from(SupabaseConstants.adWatchLog).select('id');
      final withdraws = await _client
          .from(SupabaseConstants.withdrawRequests)
          .select('id')
          .eq('status', 'pending');

      int earned = 0;
      int spent = 0;
      for (final t in (txs as List)) {
        final amount = (t['amount'] as num?)?.toInt() ?? 0;
        if (amount >= 0) {
          earned += amount;
        } else {
          spent += amount.abs();
        }
      }

      return {
        'coins_earned': earned,
        'coins_spent': spent,
        'unlocks': (unlocks as List).length,
        'ads_watched': (ads as List).length,
        'pending_withdraws': (withdraws as List).length,
      };
    } catch (_) {
      return {
        'coins_earned': 0,
        'coins_spent': 0,
        'unlocks': 0,
        'ads_watched': 0,
        'pending_withdraws': 0,
      };
    }
  }

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

  Future<void> unpublishStory(String storyId) async {
    await _client.from(SupabaseConstants.stories).update({
      'is_published': false,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', storyId);
  }

  Future<void> deleteStory(String storyId) async {
    await _client.from(SupabaseConstants.stories).delete().eq('id', storyId);
  }

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

  Future<void> unpublishNovel(String novelId) async {
    await _client.from(SupabaseConstants.novels).update({
      'is_published': false,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', novelId);
  }

  Future<void> deleteNovel(String novelId) async {
    await _client.from(SupabaseConstants.novels).delete().eq('id', novelId);
  }

  Future<List<UserModel>> getAllUsers({int limit = 50}) async {
    final data = await _client
        .from(SupabaseConstants.profiles)
        .select()
        .order('created_at', ascending: false)
        .limit(limit);

    return (data as List).map((e) => UserModel.fromJson(e)).toList();
  }
}
