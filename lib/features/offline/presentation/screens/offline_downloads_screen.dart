import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/story_model.dart';
import '../../../../core/models/episode_model.dart';
import '../../../../core/services/offline_service.dart';
import '../../../../core/theme/app_colors.dart';

class OfflineDownloadsScreen extends StatefulWidget {
  const OfflineDownloadsScreen({super.key});

  @override
  State<OfflineDownloadsScreen> createState() => _OfflineDownloadsScreenState();
}

class _OfflineDownloadsScreenState extends State<OfflineDownloadsScreen>
    with SingleTickerProviderStateMixin {
  final _offlineService = OfflineService();
  late TabController _tabController;

  List<StoryModel> _stories = [];
  List<EpisodeModel> _episodes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final stories = await _offlineService.getOfflineStories();
    final episodes = await _offlineService.getOfflineEpisodes();
    setState(() {
      _stories = stories;
      _episodes = episodes;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ডাউনলোড করা'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'গল্প'),
            Tab(text: 'পর্ব'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildStories(isDark),
                _buildEpisodes(isDark),
              ],
            ),
    );
  }

  Widget _buildStories(bool isDark) {
    if (_stories.isEmpty) {
      return Center(
        child: Text(
          'কোনো গল্প ডাউনলোড নেই',
          style: TextStyle(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
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
            title: Text(story.title, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(story.category ?? ''),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () async {
                await _offlineService.removeStoryOffline(story.id);
                _load();
              },
            ),
            onTap: () => context.push('/story/${story.id}'),
          ),
        );
      },
    );
  }

  Widget _buildEpisodes(bool isDark) {
    if (_episodes.isEmpty) {
      return Center(
        child: Text(
          'কোনো পর্ব ডাউনলোড নেই',
          style: TextStyle(
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _episodes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final ep = _episodes[index];
        return Card(
          child: ListTile(
            title: Text(ep.title, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('পর্ব ${ep.episodeNumber}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () async {
                await _offlineService.removeEpisodeOffline(ep.id);
                _load();
              },
            ),
            onTap: () => context.push('/episode/${ep.id}'),
          ),
        );
      },
    );
  }
}
