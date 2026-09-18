import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/story_model.dart';
import '../models/episode_model.dart';
import '../models/content_block_model.dart';

class OfflineService {
  static const String _storiesKey = 'offline_stories';
  static const String _episodesKey = 'offline_episodes';

  // ======================
  // Story Offline
  // ======================
  Future<void> saveStoryOffline(StoryModel story) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getOfflineStories();

    existing.removeWhere((s) => s.id == story.id);
    existing.insert(0, story);

    final jsonList = existing.map((s) => s.toJson()).toList();
    await prefs.setString(_storiesKey, jsonEncode(jsonList));
  }

  Future<List<StoryModel>> getOfflineStories() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storiesKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => StoryModel.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> isStoryDownloaded(String storyId) async {
    final stories = await getOfflineStories();
    return stories.any((s) => s.id == storyId);
  }

  Future<void> removeStoryOffline(String storyId) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getOfflineStories();
    existing.removeWhere((s) => s.id == storyId);
    final jsonList = existing.map((s) => s.toJson()).toList();
    await prefs.setString(_storiesKey, jsonEncode(jsonList));
  }

  // ======================
  // Episode Offline
  // ======================
  Future<void> saveEpisodeOffline(EpisodeModel episode) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getOfflineEpisodes();

    existing.removeWhere((e) => e.id == episode.id);
    existing.insert(0, episode);

    final jsonList = existing.map((e) => e.toJson()).toList();
    await prefs.setString(_episodesKey, jsonEncode(jsonList));
  }

  Future<List<EpisodeModel>> getOfflineEpisodes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_episodesKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => EpisodeModel.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> isEpisodeDownloaded(String episodeId) async {
    final episodes = await getOfflineEpisodes();
    return episodes.any((e) => e.id == episodeId);
  }

  Future<void> removeEpisodeOffline(String episodeId) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getOfflineEpisodes();
    existing.removeWhere((e) => e.id == episodeId);
    final jsonList = existing.map((e) => e.toJson()).toList();
    await prefs.setString(_episodesKey, jsonEncode(jsonList));
  }
}
