import 'package:supabase_flutter/supabase_flutter.dart';

class GiftService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Real transfer: sender loses coins, receiver gains.
  Future<Map<String, dynamic>> giftCoins({
    required String toUserId,
    required int amount,
  }) async {
    final res = await _client.rpc(
      'gift_coins',
      params: {
        'p_to_user': toUserId,
        'p_amount': amount,
      },
    );
    if (res is Map) return Map<String, dynamic>.from(res);
    return {'ok': true};
  }
}
