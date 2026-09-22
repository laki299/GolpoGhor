import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_constants.dart';

class WriterEarningsSummary {
  final int totalCoins;
  final int days7;
  final int days15;
  final int days30;
  final List<ContentEarning> byContent;

  WriterEarningsSummary({
    required this.totalCoins,
    required this.days7,
    required this.days15,
    required this.days30,
    required this.byContent,
  });
}

class ContentEarning {
  final String id;
  final String title;
  final String kind; // story | episode
  final int coins;
  final int unlockCount;

  ContentEarning({
    required this.id,
    required this.title,
    required this.kind,
    required this.coins,
    required this.unlockCount,
  });
}

class WriterEarningsService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<WriterEarningsSummary> getMyEarnings() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      return WriterEarningsSummary(
        totalCoins: 0,
        days7: 0,
        days15: 0,
        days30: 0,
        byContent: [],
      );
    }

    // লেখকের গল্প
    final stories = await _client
        .from(SupabaseConstants.stories)
        .select('id, title')
        .eq('author_id', uid);

    // লেখকের উপন্যাসের পর্ব
    final novels = await _client
        .from(SupabaseConstants.novels)
        .select('id')
        .eq('author_id', uid);

    final novelIds = (novels as List).map((n) => n['id'] as String).toList();

    List<dynamic> episodes = [];
    if (novelIds.isNotEmpty) {
      episodes = await _client
          .from(SupabaseConstants.episodes)
          .select('id, title, novel_id')
          .inFilter('novel_id', novelIds);
    }

    final storyIds = (stories as List).map((s) => s['id'] as String).toList();
    final episodeIds = episodes.map((e) => e['id'] as String).toList();

    final storyTitle = {
      for (final s in stories as List) s['id'] as String: s['title'] as String? ?? 'গল্প',
    };
    final episodeTitle = {
      for (final e in episodes) e['id'] as String: e['title'] as String? ?? 'পর্ব',
    };

    // সব unlock যেখানে এই কনটেন্ট
    final unlocks = <Map<String, dynamic>>[];

    if (storyIds.isNotEmpty) {
      final sUnlocks = await _client
          .from(SupabaseConstants.contentUnlocks)
          .select('story_id, episode_id, coins_spent, created_at')
          .inFilter('story_id', storyIds);
      unlocks.addAll(List<Map<String, dynamic>>.from(sUnlocks as List));
    }

    if (episodeIds.isNotEmpty) {
      final eUnlocks = await _client
          .from(SupabaseConstants.contentUnlocks)
          .select('story_id, episode_id, coins_spent, created_at')
          .inFilter('episode_id', episodeIds);
      unlocks.addAll(List<Map<String, dynamic>>.from(eUnlocks as List));
    }

    final now = DateTime.now().toUtc();
    int total = 0;
    int d7 = 0;
    int d15 = 0;
    int d30 = 0;

    final byId = <String, ContentEarning>{};

    for (final u in unlocks) {
      final coins = (u['coins_spent'] as num?)?.toInt() ?? 0;
      total += coins;

      final created = DateTime.tryParse(u['created_at']?.toString() ?? '');
      if (created != null) {
        final age = now.difference(created.toUtc());
        if (age.inDays <= 7) d7 += coins;
        if (age.inDays <= 15) d15 += coins;
        if (age.inDays <= 30) d30 += coins;
      }

      final storyId = u['story_id'] as String?;
      final episodeId = u['episode_id'] as String?;

      if (storyId != null && storyTitle.containsKey(storyId)) {
        final prev = byId[storyId];
        byId[storyId] = ContentEarning(
          id: storyId,
          title: storyTitle[storyId]!,
          kind: 'story',
          coins: (prev?.coins ?? 0) + coins,
          unlockCount: (prev?.unlockCount ?? 0) + 1,
        );
      } else if (episodeId != null && episodeTitle.containsKey(episodeId)) {
        final prev = byId[episodeId];
        byId[episodeId] = ContentEarning(
          id: episodeId,
          title: episodeTitle[episodeId]!,
          kind: 'episode',
          coins: (prev?.coins ?? 0) + coins,
          unlockCount: (prev?.unlockCount ?? 0) + 1,
        );
      }
    }

    final list = byId.values.toList()
      ..sort((a, b) => b.coins.compareTo(a.coins));

    return WriterEarningsSummary(
      totalCoins: total,
      days7: d7,
      days15: d15,
      days30: d30,
      byContent: list,
    );
  }
}
