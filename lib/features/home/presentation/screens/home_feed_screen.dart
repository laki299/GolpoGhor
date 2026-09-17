import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/story_model.dart';
import '../../../../core/services/story_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/story_card.dart';

class HomeFeedScreen extends ConsumerStatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  ConsumerState<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends ConsumerState<HomeFeedScreen> {
  final _storyService = StoryService();
  final _scrollController = ScrollController();

  List<StoryModel> _stories = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  int _offset = 0;
  final int _limit = 15;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadFeed();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadFeed() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _offset = 0;
      _hasMore = true;
    });

    try {
      final stories = await _storyService.getFeed(limit: _limit, offset: 0);
      setState(() {
        _stories = stories;
        _offset = stories.length;
        _hasMore = stories.length >= _limit;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'ফিড লোড করতে সমস্যা হয়েছে';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final moreStories =
          await _storyService.getFeed(limit: _limit, offset: _offset);
      setState(() {
        _stories.addAll(moreStories);
        _offset += moreStories.length;
        _hasMore = moreStories.length >= _limit;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'গল্পঘর',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Navigate to Search
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              // TODO: Navigate to Profile
            },
          ),
        ],
      ),
      body: _buildBody(isDark),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/create-story');
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFeed,
              child: const Text('আবার চেষ্টা করুন'),
            ),
          ],
        ),
      );
    }

    if (_stories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 64,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'এখনো কোনো গল্প নেই',
              style: TextStyle(
                fontSize: 16,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'প্রথম গল্পটি আপনিই লিখুন!',
              style: TextStyle(color: AppColors.primary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFeed,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: _stories.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _stories.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final story = _stories[index];
          return StoryCard(
            story: story,
            onTap: () {
              context.push('/story/${story.id}');
            },
            onCommentTap: () {
              // TODO: Open comments
            },
            onReactionTap: () {
              // TODO: Show reaction picker
            },
          );
        },
      ),
    );
  }
}
