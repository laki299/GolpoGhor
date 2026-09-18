import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/models/novel_model.dart';
import '../../../../core/models/episode_model.dart';
import '../../../../core/services/novel_service.dart';
import '../../../../core/services/bookmark_service.dart';
import '../../../../core/theme/app_colors.dart';

class NovelDetailsScreen extends ConsumerStatefulWidget {
  final String novelId;

  const NovelDetailsScreen({super.key, required this.novelId});

  @override
  ConsumerState<NovelDetailsScreen> createState() => _NovelDetailsScreenState();
}

class _NovelDetailsScreenState extends ConsumerState<NovelDetailsScreen> {
  final _novelService = NovelService();
  final _bookmarkService = BookmarkService();

  NovelModel? _novel;
  List<EpisodeModel> _episodes = [];
  bool _isLoading = true;
  String? _error;
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final novel = await _novelService.getNovelById(widget.novelId);
      final episodes = await _novelService.getEpisodes(widget.novelId);
      final bookmarked =
          await _bookmarkService.isBookmarked(novelId: widget.novelId);

      setState(() {
        _novel = novel;
        _episodes = episodes;
        _isBookmarked = bookmarked;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'ডেটা লোড করতে সমস্যা হয়েছে';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleBookmark() async {
    try {
      await _bookmarkService.toggleBookmark(novelId: widget.novelId);
      setState(() => _isBookmarked = !_isBookmarked);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isBookmarked ? 'সংরক্ষণ করা হয়েছে' : 'সংরক্ষণ সরানো হয়েছে',
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('সংরক্ষণ করতে সমস্যা হয়েছে')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: _isBookmarked ? AppColors.primary : null,
            ),
            onPressed: _toggleBookmark,
          ),
        ],
      ),
      body: _buildBody(isDark),
      floatingActionButton: _novel != null
          ? FloatingActionButton.extended(
              onPressed: () {
                context.push('/add-episode/${_novel!.id}');
              },
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'নতুন পর্ব',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null || _novel == null) {
      return Center(child: Text(_error ?? 'উপন্যাস পাওয়া যায়নি'));
    }

    final novel = _novel!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        Text(
          novel.title,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            height: 1.3,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withOpacity(0.15),
              backgroundImage: novel.authorAvatar != null
                  ? CachedNetworkImageProvider(novel.authorAvatar!)
                  : null,
              child: novel.authorAvatar == null
                  ? Text(
                      (novel.authorName ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Text(
              novel.authorName ?? 'অজানা লেখক',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (novel.description != null && novel.description!.isNotEmpty) ...[
          Text(
            novel.description!,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 20),
        ],
        Text(
          'মোট পর্ব: ${novel.episodeCount}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        ..._episodes.map((ep) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                '${ep.episodeNumber}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              ep.title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            subtitle: Text(
              ep.previewText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () {
                context.push('/edit-episode/${ep.id}');
              },
            ),
            onTap: () {
              context.push('/episode/${ep.id}');
            },
          );
        }),
      ],
    );
  }
}
