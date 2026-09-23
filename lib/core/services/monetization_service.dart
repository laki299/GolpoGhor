import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_constants.dart';
import '../constants/coin_constants.dart';

class MonetizationService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<bool> isMonetizationEnabled() async {
    try {
      final data = await _client
          .from(SupabaseConstants.appSettings)
          .select('value')
          .eq('key', 'monetization')
          .maybeSingle();
      if (data == null) return false;
      final value = data['value'];
      if (value is Map) return value['enabled'] == true;
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> setMonetizationEnabled(bool enabled) async {
    await _client.from(SupabaseConstants.appSettings).upsert({
      'key': 'monetization',
      'value': {'enabled': enabled},
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> getMyCoins() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return 0;
    final data = await _client
        .from(SupabaseConstants.profiles)
        .select('coins')
        .eq('id', uid)
        .maybeSingle();
    return (data?['coins'] as num?)?.toInt() ?? 0;
  }

  Future<bool> isStoryUnlocked(String storyId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return false;
    final row = await _client
        .from(SupabaseConstants.contentUnlocks)
        .select('id')
        .eq('user_id', uid)
        .eq('story_id', storyId)
        .maybeSingle();
    return row != null;
  }

  Future<bool> isEpisodeUnlocked(String episodeId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return false;
    final row = await _client
        .from(SupabaseConstants.contentUnlocks)
        .select('id')
        .eq('user_id', uid)
        .eq('episode_id', episodeId)
        .maybeSingle();
    return row != null;
  }

  Future<bool> canAccessStory(String storyId) async {
    if (!await isMonetizationEnabled()) return true;
    return isStoryUnlocked(storyId);
  }

  Future<bool> canAccessEpisode(String episodeId) async {
    if (!await isMonetizationEnabled()) return true;
    return isEpisodeUnlocked(episodeId);
  }

  Future<Duration> adCooldownRemaining() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return Duration.zero;

    final data = await _client
        .from(SupabaseConstants.adWatchLog)
        .select('created_at')
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (data == null) return Duration.zero;

    final last = DateTime.parse(data['created_at'] as String).toUtc();
    final next =
        last.add(const Duration(seconds: CoinConstants.adCooldownSeconds));
    final now = DateTime.now().toUtc();
    if (now.isAfter(next) || now.isAtSameMomentAs(next)) {
      return Duration.zero;
    }
    return next.difference(now);
  }

  Future<List<Map<String, dynamic>>> getMyTransactions({int limit = 30}) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    final data = await _client
        .from(SupabaseConstants.coinTransactions)
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(data as List);
  }

  /// Secure unlock via Supabase RPC
  Future<Map<String, dynamic>> unlockContent({
    required String type, // 'story' | 'episode'
    required String refId,
    required int amount,
  }) async {
    final res = await _client.rpc(
      'spend_unlock',
      params: {
        'p_type': type,
        'p_ref_id': refId,
        'p_amount': amount,
      },
    );
    if (res is Map) {
      return Map<String, dynamic>.from(res);
    }
    return {'ok': true};
  }

  /// Reader screens call this
  Future<void> spendCoins({
    required String type,
    required int amount,
    String? refType,
    String? refId,
  }) async {
    if (refId == null || refType == null) {
      throw Exception('refType ও refId লাগবে');
    }
    final kind = refType == 'story' ? 'story' : 'episode';
    final result = await unlockContent(
      type: kind,
      refId: refId,
      amount: amount,
    );
    if (result['ok'] != true) {
      throw Exception('আনলক ব্যর্থ');
    }
  }

  /// পরে: AppLovin + SSV
  Future<int> claimAdReward() async {
    throw UnimplementedError(
      'AppLovin MAX + SSV পরে যুক্ত করুন',
    );
  }
}
