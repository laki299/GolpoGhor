import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/story_model.dart';
import '../../../../core/constants/coin_constants.dart';
import '../../../../core/services/story_service.dart';
import '../../../../core/services/reaction_service.dart';
import '../../../../core/services/bookmark_service.dart';
import '../../../../core/services/follow_service.dart';
import '../../../../core/services/reading_progress_service.dart';
import '../../../../core/services/offline_service.dart';
import '../../../../core/services/monetization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../social/presentation/widgets/reaction_picker.dart';
import '../../../social/presentation/widgets/comment_section.dart';
import '../../../wallet/presentation/widgets/unlock_paywall.dart';
import '../../../wallet/presentation/widgets/earn_coins_popup.dart';

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
  final _followService = FollowService();
  final _progressService = ReadingProgressService();
  final _offlineService = OfflineService();
  final _monetization = MonetizationService();

  StoryModel? _story;
  bool _isLoading = true;
  String? _error;
  bool _isOfflineMode = false;
  bool _hasAccess = true;
  int _userCoins = 0;

  String? _userReaction;
  bool _isBookmarked = false;
  bool _isFollowing = false;
  bool _isDownloaded = false;
  double _progressPercent = 0;

  @override
  void initState() {
    super.initState();
    _loadStory();
  }

  Future<void> _loadStory() async {
    try {
      final story = await _storyService.getStoryById(widget.storyId);

      if (story != null) {
        final reaction =
            await _reactionService.getUserReaction(storyId: widget.storyId);
        final bookmarked =
            await _bookmarkService.isBookmarked(storyId: widget.storyId);
        final following = await _followService.isFollowing(story.authorId);
        final downloaded =
            await _offlineService.isStoryDownloaded(widget.storyId);
        final progress =
            await _progressService.getProgress(storyId: widget.storyId);
        final access = await _monetization.canAccessStory(widget.storyId);
        final coins = await _monetization.getMyCoins();

        setState(() {
          _story = story;
          _userReaction = reaction;
          _isBookmarked = bookmarked;
          _isFollowing = following;
          _isDownloaded = downloaded;
          _progressPercent = progress?.progressPercent ?? 0;
          _hasAccess = access;
          _userCoins = coins;
          _isOfflineMode = false;
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}

    final offlineStories = await _offlineService.getOfflineStories();
    final offline =
        offlineStories.where((s) => s.id == widget.storyId).toList();

    if (offline.isNotEmpty) {
      setState(() {
        _story = offline.first;
        _isOfflineMode = true;
        _isDownloaded = true;
        _hasAccess = true;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = 'গল্প লোড করা যায়নি (অফলাইনেও নেই)';
        _isLoading = false;
      });
    }
  }

  Future<void> _tryUnlock() async {
    try {
      await _monetization.spendCoins(
        type: 'spend_story',
        amount: CoinConstants.storyOpen,
        refType: 'story',
        refId: widget.storyId,
      );
      final coins = await _monetization.getMyCoins();
      if (mounted) {
        setState(() {
          _hasAccess = true;
          _userCoins = coins;
        });
      }
    } catch (e) {
      if (!mounted) return;
      if (EarnCoinsPopup.isInsufficientError(e)) {
        await EarnCoinsPopup.show(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('আনলক সমস্যা: $e')),
        );
      }
    }
  }

  void _showReactionPicker() {
    if (_isOfflineMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('অফলাইনে রিয়্যাকশন দেওয়া যাবে না')),
      );
      return;
    }
    ReactionPicker.show(
      context,
      current: _userReaction,
      onSelected: (type) async {
        try {
          await _reactionService.toggleReaction(
            reactionType: type,
            storyId: widget.storyId,
          );
          setState(() {
            _userReaction = _userReaction == type ? null : type;
          });
        } catch (e) {
          if (!mounted) return;
          if (EarnCoinsPopup.isInsufficientError(e)) {
            await EarnCoinsPopup.show(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('রিয়্যাকশন দিতে সমস্যা হয়েছে')),
            );
          }
        }
      },
    );
  }

  void _showComments() {
    if (_isOfflineMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('অফলাইনে কমেন্ট দেখা যাবে না')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (_, __) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
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
                  Expanded(child: CommentSection(storyId: widget.storyId)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _toggleBookmark() async {
    if (_isOfflineMode) return;
    try {
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
    } catch (_) {}
  }

  Future<void> _toggleFollow() async {
    if (_isOfflineMode || _story == null) return;
    try {
      await _followService.toggleFollow(_story!.authorId);
      setState(() => _isFollowing = !_isFollowing);
    } catch (_) {}
  }

  Future<void> _toggleDownload() async {
    if (_story == null || !_hasAccess) return;
    if (_isDownloaded) {
      await _offlineService.removeStoryOffline(widget.storyId);
      setState(() => _isDownloaded = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ডাউনলোড সরানো হয়েছে')),
        );
      }
    } else {
      await _offlineService.saveStoryOffline(_story!);
      setState(() => _isDownloaded = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('অফলাইনে সেভ হয়েছে')),
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
        title: _isOfflineMode
            ? const Text('অফলাইন', style: TextStyle(fontSize: 14))
            : null,
        actions: [
          if (_hasAccess && _progressPercent > 0)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Center(
                child: Text(
                  '${_progressPercent.toInt()}%',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          if (_hasAccess)
            IconButton(
              icon: Icon(
                _isDownloaded ? Icons.download_done : Icons.download_outlined,
                color: _isDownloaded ? AppColors.primary : null,
              ),
              onPressed: _toggleDownload,
            ),
          if (_hasAccess && !_isOfflineMode)
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
      bottomNavigationBar:
          _story == null || _isOfflineMode || !_hasAccess
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

    if (!_hasAccess) {
      return UnlockPaywall(
        title: _story!.title,
        cost: CoinConstants.storyOpen,
        userCoins: _userCoins,
        onUnlockPressed: _tryUnlock,
      );
    }

    final story = _story!;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification && !_isOfflineMode) {
          final metrics = notification.metrics;
          if (metrics.maxScrollExtent > 0) {
            final percent =
                (metrics.pixels / metrics.maxScrollExtent * 100)
                    .clamp(0.0, 100.0);
            if ((percent - _progressPercent).abs() > 5) {
              _progressPercent = percent;
              _progressService.saveProgress(
                storyId: widget.storyId,
                progressPercent: _progressPercent,
              );
              setState(() {});
            }
          }
        }
        return false;
      },
      child: Column(
        children: [
          if (_progressPercent > 0)
            LinearProgressIndicator(
              value: _progressPercent / 100,
              backgroundColor:
                  isDark ? AppColors.darkBorder : AppColors.lightBorder,
              color: AppColors.primary,
              minHeight: 3,
            ),
          Expanded(
            child: SelectionContainer.disabled(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
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
                        Expanded(
                          child: Text(
                            story.authorName ?? 'অজানা লেখক',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                        ),
                        if (!_isOfflineMode)
                          SizedBox(
                            height: 34,
                            child: OutlinedButton(
                              onPressed: _toggleFollow,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side:
                                    const BorderSide(color: AppColors.primary),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Text(
                                _isFollowing ? 'আনফলো' : 'ফলো',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
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
                              placeholder: (_, __) => Container(
                                height: 200,
                                color: isDark
                                    ? AppColors.darkSurface
                                    : AppColors.lightBorder,
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (_, __, ___) =>
                                  const Icon(Icons.broken_image, size: 48),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                  ],
                ),
              ),
            ),
          ),
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
            InkWell(
              onTap: _showReactionPicker,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
            const SizedBox(width: 20),
            InkWell(
              onTap: _showComments,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
