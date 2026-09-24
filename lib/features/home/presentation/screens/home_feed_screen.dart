import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/models/story_model.dart';
import '../../../../core/models/novel_model.dart';
import '../../../../core/services/story_service.dart';
import '../../../../core/constants/supabase_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/story_card.dart';
import '../widgets/novel_card.dart';

class HomeFeedScreen extends ConsumerStatefulWidget {
  /// true = HomeShell-এর ভিতরে (নিজের AppBar/FAB নেই)
  final bool embedded;

  const HomeFeedScreen({super.key, this.embedded = false});

  @override
  ConsumerState<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends ConsumerState<HomeFeedScreen> {
  final _storyService = StoryService();
  final _client = Supabase.instance.client;
  final _scrollController = ScrollController();

  List<dynamic> _feedItems = [];
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

      final novelData = await _client
          .from(SupabaseConstants.novels)
          .select('''
            *,
            profiles:author_id (
              full_name,
              username,
              avatar_url
            )
          ''')
          .eq('is_published', true)
          .order('created_at', ascending: false)
          .limit(10);

      final novels = (novelData as List).map((json) {
        final map = Map<String, dynamic>.from(json);
        if (map['profiles'] != null) {
          map['author_name'] = map['profiles']['full_name'];
          map['author_username'] = map['profiles']['username'];
          map['author_avatar'] = map['profiles']['avatar_url'];
        }
        return NovelModel.fromJson(map);
      }).toList();

      final combined = <dynamic>[...stories, ...novels];
      combined.sort((a, b) {
        final aDate =
            a is StoryModel ? a.createdAt : (a as NovelModel).createdAt;
        final bDate =
            b is StoryModel ? b.createdAt : (b as NovelModel).createdAt;
        return bDate.compareTo(aDate);
      });

      setState(() {
        _feedItems = combined;
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
        _feedItems.addAll(moreStories);
        _offset += moreStories.length;
        _hasMore = moreStories.length >= _limit;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
    }
  }

  void _showCreateSheet() {
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
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Shell-এর ভিতরে: শুধু body
    if (widget.embedded) {
      return _buildBody(isDark);
    }

    // আলাদা রুট হলে পুরো Scaffold
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'গল্পঘর',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: _buildBody(isDark),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateSheet,
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

    if (_feedItems.isEmpty) {
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
            const Text('এখনো কোনো গল্প নেই'),
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
        itemCount: _feedItems.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _feedItems.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final item = _feedItems[index];

          if (item is StoryModel) {
            return StoryCard(
              story: item,
              onTap: () => context.push('/story/${item.id}'),
            );
          } else if (item is NovelModel) {
            return NovelCard(
              novel: item,
              onTap: () => context.push('/novel/${item.id}'),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
