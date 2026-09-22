import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_constants.dart';

class WithdrawService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<int> getMinWithdrawCoins() async {
    try {
      final data = await _client
          .from(SupabaseConstants.appSettings)
          .select('value')
          .eq('key', 'withdraw_min_coins')
          .maybeSingle();
      if (data == null) return 5000;
      final value = data['value'];
      if (value is Map) return (value['min'] as num?)?.toInt() ?? 5000;
      return 5000;
    } catch (_) {
      return 5000;
    }
  }

  Future<List<Map<String, dynamic>>> getMyRequests() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    final data = await _client
        .from(SupabaseConstants.withdrawRequests)
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data as List);
  }

  Future<void> createRequest(int coins) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('লগইন নেই');

    final min = await getMinWithdrawCoins();
    if (coins < min) {
      throw Exception('সর্বনিম্ন $min কয়েন লাগবে');
    }

    await _client.from(SupabaseConstants.withdrawRequests).insert({
      'user_id': uid,
      'coins': coins,
      'status': 'pending',
    });
  }

  /// Admin: সব pending
  Future<List<Map<String, dynamic>>> getPendingForAdmin() async {
    final data = await _client
        .from(SupabaseConstants.withdrawRequests)
        .select('*, profiles:user_id (full_name, username)')
        .eq('status', 'pending')
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(data as List);
  }

  Future<void> updateStatus({
    required String id,
    required String status,
    String? note,
  }) async {
    await _client.from(SupabaseConstants.withdrawRequests).update({
      'status': status,
      'admin_note': note,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }
}
