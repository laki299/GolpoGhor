import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_constants.dart';

class FollowService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Follow / Unfollow toggle
  Future<void> toggleFollow(String targetUserId) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('User not logged in');
    if (currentUserId == targetUserId) return; // নিজেকে ফলো করা যাবে না

    final existing = await _client
        .from(SupabaseConstants.follows)
        .select()
        .eq('follower_id', currentUserId)
        .eq('following_id', targetUserId)
        .maybeSingle();

    if (existing != null) {
      // Unfollow
      await _client
          .from(SupabaseConstants.follows)
          .delete()
          .eq('follower_id', currentUserId)
          .eq('following_id', targetUserId);
    } else {
      // Follow
      await _client.from(SupabaseConstants.follows).insert({
        'follower_id': currentUserId,
        'following_id': targetUserId,
      });
    }
  }

  /// Check if current user is following someone
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

  /// Get follower count
  Future<int> getFollowerCount(String userId) async {
    final data = await _client
        .from(SupabaseConstants.follows)
        .select('follower_id')
        .eq('following_id', userId);

    return (data as List).length;
  }

  /// Get following count
  Future<int> getFollowingCount(String userId) async {
    final data = await _client
        .from(SupabaseConstants.follows)
        .select('following_id')
        .eq('follower_id', userId);

    return (data as List).length;
  }
}
