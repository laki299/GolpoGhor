import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_constants.dart';

class FollowService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> toggleFollow(String targetUserId) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('User not logged in');
    if (currentUserId == targetUserId) return;

    final existing = await _client
        .from(SupabaseConstants.follows)
        .select()
        .eq('follower_id', currentUserId)
        .eq('following_id', targetUserId)
        .maybeSingle();

    if (existing != null) {
      await _client
          .from(SupabaseConstants.follows)
          .delete()
          .eq('follower_id', currentUserId)
          .eq('following_id', targetUserId);
    } else {
      await _client.from(SupabaseConstants.follows).insert({
        'follower_id': currentUserId,
        'following_id': targetUserId,
      });
    }
  }

  Future<bool> isFollowing(String targetUserId) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return false;

    final data = await _client
        .from(SupabaseConstants.follows)
        .select()
        .eq('follower_id', currentUserId)
        .eq('following_id', targetUserId)
        .maybeSingle();

    return data != null;
  }

  Future<int> getFollowerCount(String userId) async {
    final data = await _client
        .from(SupabaseConstants.follows)
        .select('follower_id')
        .eq('following_id', userId);

    return (data as List).length;
  }

  Future<int> getFollowingCount(String userId) async {
    final data = await _client
        .from(SupabaseConstants.follows)
        .select('following_id')
        .eq('follower_id', userId);

    return (data as List).length;
  }
}
