import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/models/story_model.dart';
import '../../../../core/models/novel_model.dart';
import '../../../../core/services/bookmark_service.dart';
import '../../../../core/theme/app_colors.dart';

class SavedStoriesScreen extends ConsumerStatefulWidget {
  const SavedStoriesScreen({super.key});

  @override
  ConsumerState<SavedStoriesScreen> createState() => _SavedStoriesScreenState();
}

class _SavedStoriesScreenState extends ConsumerState<SavedStoriesScreen> {
  final _bookmarkService = BookmarkService();
  final _client = Supabase.instance.client;

  List<StoryModel> _stories = [];
  List<NovelModel> _novels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    try {
      final bookmarks = await _bookmarkService.getUserBookmarks();

      final storyIds = bookmarks
          .where((b) => b.storyId != null)
          .map((b) => b.storyId!)
          .toList();

      final novelIds = bookmarks
          .where((b) => b.novelId != null)
          .map((b) => b.novelId!)
          .toList();

      List<StoryModel> stories = [];
      List<NovelModel> novels = [];

      if (storyIds.isNotEmpty) {
        final data = await _client
            .from(SupabaseConstants.stories)
            .select()
            .inFilter('id', storyIds);
        stories = (data as List).map((e) => StoryModel.fromJson(e)).toList();
      }

      if (novelIds.isNotEmpty) {
        final data = await _client
            .from(SupabaseConstants.novels)
            .select()
            .inFilter('id', novelIds);
        novels = (data as List).map((e) => NovelModel.fromJson(e)).toList();
      }

      setState(() {
        _stories = stories;
        _novels = novels;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('সংরক্ষিত'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_stories.isEmpty && _novels.isEmpty)
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bookmark_border,
                        size: 64,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'এখনো কিছু সংরক্ষণ করেননি',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_stories.isNotEmpty) ...[
                      const Text(
                        'গল্প',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._stories.map((story) => Card(
                            child: ListTile(
                              title: Text(
                                story.title,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(story.category ?? ''),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => context.push('/story/${story.id}'),
                            ),
                          )),
                      const SizedBox(height: 20),
                    ],
                    if (_novels.isNotEmpty) ...[
                      const Text(
                        'উপন্যাস',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._novels.map((novel) => Card(
                            child: ListTile(
                              title: Text(
                                novel.title,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                '${novel.episodeCount} পর্ব • ${novel.category ?? ''}',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => context.push('/novel/${novel.id}'),
                            ),
                          )),
                    ],
                  ],
                ),
    );
  }
}
