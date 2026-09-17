import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/story_model.dart';
import '../../../../core/models/content_block_model.dart';
import '../../../../core/services/story_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/reaction_types.dart';

class StoryReaderScreen extends ConsumerStatefulWidget {
  final String storyId;

  const StoryReaderScreen({super.key, required this.storyId});

  @override
  ConsumerState<StoryReaderScreen> createState() => _StoryReaderScreenState();
}

class _StoryReaderScreenState extends ConsumerState<StoryReaderScreen> {
  final _storyService = StoryService();
  StoryModel? _story;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStory();
  }

  Future<void> _loadStory() async {
    try {
      final story = await _storyService.getStoryById(widget.storyId);
      setState(() {
        _story = story;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'গল্প লোড করতে সমস্যা হয়েছে';
        _isLoading = false;
      });
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
            icon: const Icon(Icons.bookmark_border),
            onPressed: () {
              // TODO: Bookmark
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: _buildBody(isDark),
      bottomNavigationBar: _story == null
          ? null
          : _buildBottomBar(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null || _story == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error ?? 'গল্প পাওয়া যায়নি'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadStory,
              child: const Text('আবার চেষ্টা করুন'),
            ),
          ],
        ),
      );
    }

    final story = _story!;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            story.title,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              height: 1.35,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // Author
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withOpacity(0.15),
                backgroundImage: story.authorAvatar != null
                    ? CachedNetworkImageProvider(story.authorAvatar!)
                    : null,
                child: story.authorAvatar == null
                    ? Text(
                        (story.authorName ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 14,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Text(
                story.authorName ?? 'অজানা লেখক',
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
          const SizedBox(height: 24),

          // Content Blocks
          ...story.contentBlocks.map((block) {
            if (block.isText) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  block.value,
                  style: TextStyle(
                    fontSize: 17,
                    height: 1.75,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              );
            } else if (block.isImage) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: block.value,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 200,
                      color: isDark
                          ? AppColors.darkSurface
                          : AppColors.lightBorder,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 200,
                      color: isDark
                          ? AppColors.darkSurface
                          : AppColors.lightBorder,
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  Widget _buildBottomBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 0.6,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            _BottomAction(
              icon: Icons.favorite_border,
              label: 'রিয়্যাকশন',
              onTap: () {
                // TODO: Show reaction bottom sheet
              },
            ),
            const SizedBox(width: 24),
            _BottomAction(
              icon: Icons.chat_bubble_outline,
              label: 'কমেন্ট',
              onTap: () {
                // TODO: Open comments
              },
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BottomAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
