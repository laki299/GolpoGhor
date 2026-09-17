import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/story_model.dart';
import '../../../../core/services/story_service.dart';
import '../../../../core/services/reaction_service.dart';
import '../../../../core/services/bookmark_service.dart';
import '../../../../core/services/follow_service.dart';
import '../../../../core/services/reading_progress_service.dart';
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
  final _followService = FollowService();
  final _progressService = ReadingProgressService();
  final _scrollController = ScrollController();

  StoryModel? _story;
  bool _isLoading = true;
  String? _error;
  String? _userReaction;
  bool _isBookmarked = false;
  bool _isFollowing = false;
  bool _isOwnStory = false;

  @override
  void initState() {
    super.initState();
    _loadStory();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _saveReadingProgress();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // স্ক্রল অনুসারে প্রগ্রেস আপডেট (ঐচ্ছিক)
    if (_scrollController.hasClients && _scrollController.position.maxScrollExtent > 0) {
      final percent = (_scrollController.offset /
              _scrollController.position.maxScrollExtent) *
          100;
      // খুব ঘন ঘন সেভ না করে শুধু মনে রাখা যায়
    }
  }

  Future<void> _saveReadingProgress() async {
    if (_story == null) return;
    try {
      double percent = 0.0;
      if (_scrollController.hasClients &&
          _scrollController.position.maxScrollExtent > 0) {
        percent = (_scrollController.offset /
                _scrollController.position.maxScrollExtent) *
            100;
      }
      await _progressService.saveProgress(
        storyId: widget.storyId,
        progressPercent: percent,
      );
    } catch (_) {}
  }

  Future<void> _loadStory() async {
    try {
      final story = await _storyService.getStoryById(widget.storyId);
      if (story == null) {
        setState(() {
          _error = 'গল্প পাওয়া যায়নি';
          _isLoading = false;
        });
        return;
      }

      final userId = Supabase.instance.client.auth.currentUser?.id;
      final reaction = await _reactionService.getUserReaction(
        storyId: widget.storyId,
      );
      final bookmarked = await _bookmarkService.isBookmarked(
        storyId: widget.storyId,
      );
      final following = userId != null && userId != story.authorId
          ? await _followService.isFollowing(story.authorId)
          : false;

      // গল্প খোলার পর প্রগ্রেস সেভ
      await _progressService.saveProgress(
        storyId: widget.storyId,
        progressPercent: 0.0,
      );

      setState(() {
        _story = story;
        _userReaction = reaction;
        _isBookmarked = bookmarked;
        _isFollowing = following;
        _isOwnStory = userId == story.authorId;
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
          setState(() {
            if (_userReaction == type) {
              _userReaction = null;
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

  Future<void> _toggleFollow() async {
    if (_story == null || _isOwnStory) return;
    try {
      await _followService.toggleFollow(_story!.authorId);
      setState(() => _isFollowing = !_isFollowing);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ফলো করতে সমস্যা হয়েছে')),
        );
      }
    }
  }

  @override
  void dispose() {
    _saveReadingProgress();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _saveReadingProgress() async {
    if (_story == null) return;
    try {
      double percent = 0.0;
      if (_scrollController.hasClients &&
          _scrollController.position.maxScrollExtent > 0) {
        percent = (_scrollController.offset /
                _scrollController.position.maxScrollExtent) *
            100;
      }
      await _progressService.saveProgress(
        storyId: widget.storyId,
        progressPercent: percent,
      );
    } catch (_) {}
  }

  // --- নতুন state ভ্যারিয়েবল ---
  final _followService = FollowService();
  final _progressService = ReadingProgressService();
  final _scrollController = ScrollController();
  bool _isFollowing = false;
  bool _isOwnStory = false;

  // ... (নিচের পুরো build ও অন্যান্য মেথড আগের মতোই থাকবে, শুধু Author Row-তে Follow বাটন যোগ করা হয়েছে)
