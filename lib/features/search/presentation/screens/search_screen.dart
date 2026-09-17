import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/models/story_model.dart';
import '../../../../core/models/novel_model.dart';
import '../../../../core/theme/app_colors.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _client = Supabase.instance.client;

  List<StoryModel> _stories = [];
  List<NovelModel> _novels = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _stories = [];
        _novels = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      // Partial search on title
      final storyData = await _client
          .from(SupabaseConstants.stories)
          .select()
          .ilike('title', '%${query.trim()}%')
          .eq('is_published', true)
          .limit(20);

      final novelData = await _client
          .from(SupabaseConstants.novels)
          .select()
          .ilike('title', '%${query.trim()}%')
          .eq('is_published', true)
          .limit(20);

      setState(() {
        _stories = (storyData as List)
            .map((e) => StoryModel.fromJson(e))
            .toList();
        _novels = (novelData as List)
            .map((e) => NovelModel.fromJson(e))
            .toList();
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'গল্প, উপন্যাস বা লেখক খুঁজুন...',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
          onSubmitted: _performSearch,
          textInputAction: TextInputAction.search,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _performSearch(_searchController.text),
          ),
        ],
      ),
      body: _isSearching
          ? const Center(child: CircularProgressIndicator())
          : !_hasSearched
              ? Center(
                  child: Text(
                    'কিছু খুঁজে দেখুন',
                    style: TextStyle(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                )
              : (_stories.isEmpty && _novels.isEmpty)
                  ? const Center(child: Text('কোনো ফলাফল পাওয়া যায়নি'))
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
                          ..._stories.map((story) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(story.title),
                                subtitle: Text(story.category ?? ''),
                                onTap: () =>
                                    context.push('/story/${story.id}'),
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
                          ..._novels.map((novel) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(novel.title),
                                subtitle: Text(
                                    '${novel.episodeCount} পর্ব • ${novel.category ?? ''}'),
                                onTap: () =>
                                    context.push('/novel/${novel.id}'),
                              )),
                        ],
                      ],
                    ),
    );
  }
}
