import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/story_model.dart';
import '../../../../core/services/story_service.dart';
import '../../../../core/services/reaction_service.dart';
import '../../../../core/services/bookmark_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../social/presentation/widgets/reaction_picker.dart';
import '../../../social/presentation/widgets/comment_section.dart';

class StoryReaderScreen extends ConsumerStatefulWidget {
  final String storyId;

  const StoryReaderScreen({super.key, required this.storyId});

  @override
  ConsumerState<StoryReaderScreen> createState() => _StoryReaderScreenState();
}

class _StoryReaderScreenState extends ConsumerState<StoryReaderScreen> {
  final _storyService = StoryService();
  final _reactionService = ReactionService();
  final _bookmarkService = BookmarkService();

  StoryModel? _story;
  bool _isLoading = true;
  String? _error;
  String? _userReaction;
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _loadStory();
  }

  Future<void> _loadStory() async {
    try {
      final story = await _storyService.getStoryById(widget.storyId);
      final reaction = await _reactionService.getUserReaction(
        storyId: widget.storyId,
      );
      final bookmarked = await _bookmarkService.isBookmarked(
        storyId: widget.storyId,
      );

      setState(() {
        _story = story;
        _userReaction = reaction;
        _isBookmarked = bookmarked;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'গল্প লোড করতে সমস্যা হয়েছে';
        _isLoading = false;
      });
    }
  }

  void _showReactionPicker() {
    ReactionPicker.show(
      context,
      current: _userReaction,
      onSelected: (type) async {
        try {
          await _reactionService.toggleReaction(
            reactionType: type,
            storyId: widget.storyId,
          );

          // UI আপডেট
          setState(() {
            if (_userReaction == type) {
              _userReaction = null; // toggle off
            } else {
              _userReaction = type;
            }
          });
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('রিয়্যাকশন দিতে সমস্যা হয়েছে')),
            );
          }
        }
      },
    );
  }

  void _showComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (_, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: CommentSection(storyId: widget.storyId),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
            onPressed: () async {
              await _bookmarkService.toggleBookmark(storyId: widget.storyId);
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
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: _buildBody(isDark),
      bottomNavigationBar: _story == null ? null : _buildBottomBar(isDark),
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
            // Reaction Button
            InkWell(
              onTap: _showReactionPicker,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      _userReaction != null
                          ? Icons.favorite
                          : Icons.favorite_border,
                      size: 22,
                      color: _userReaction != null
                          ? Colors.redAccent
                          : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'রিয়্যাকশন',
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
            ),
            const SizedBox(width: 24),

            // Comment Button
            InkWell(
              onTap: _showComments,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 22,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'কমেন্ট',
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
