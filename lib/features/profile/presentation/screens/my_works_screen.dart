import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/models/story_model.dart';
import '../../../../core/models/novel_model.dart';
import '../../../../core/services/story_service.dart';
import '../../../../core/services/novel_service.dart';
import '../../../../core/theme/app_colors.dart';

class MyWorksScreen extends ConsumerStatefulWidget {
  const MyWorksScreen({super.key});

  @override
  ConsumerState<MyWorksScreen> createState() => _MyWorksScreenState();
}

class _MyWorksScreenState extends ConsumerState<MyWorksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _storyService = StoryService();
  final _novelService = NovelService();

  List<StoryModel> _stories = [];
  List<NovelModel> _novels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadWorks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadWorks() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final stories = await _storyService.getStoriesByAuthor(userId);
      final novels = await _novelService.getNovelsByAuthor(userId);
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
        title: const Text('আমার লেখা'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'গল্প'),
            Tab(text: 'উপন্যাস'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildStoriesList(isDark),
                _buildNovelsList(isDark),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (ctx) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.article_outlined),
                    title: const Text('নতুন গল্প লিখুন'),
                    onTap: () {
                      Navigator.pop(ctx);
                      context.push('/create-story');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.menu_book_outlined),
                    title: const Text('নতুন উপন্যাস শুরু করুন'),
                    onTap: () {
                      Navigator.pop(ctx);
                      context.push('/create-novel');
                    },
                  ),
                ],
              ),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStoriesList(bool isDark) {
    if (_stories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 56,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
            const SizedBox(height: 12),
            const Text('এখনো কোনো গল্প লেখেননি'),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _stories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final story = _stories[index];
        return Card(
          child: ListTile(
            title: Text(
              story.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              story.category ?? '',
              style: TextStyle(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/story/${story.id}'),
          ),
        );
      },
    );
  }

  Widget _buildNovelsList(bool isDark) {
    if (_novels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 56,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
            const SizedBox(height: 12),
            const Text('এখনো কোনো উপন্যাস শুরু করেননি'),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _novels.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final novel = _novels[index];
        return Card(
          child: ListTile(
            title: Text(
              novel.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${novel.episodeCount} টি পর্ব • ${novel.category ?? ''}',
              style: TextStyle(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/novel/${novel.id}'),
          ),
        );
      },
    );
  }
}
