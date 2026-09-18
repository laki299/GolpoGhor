import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/models/episode_model.dart';
import '../../../../core/services/novel_service.dart';
import '../../../../core/services/offline_service.dart';
import '../../../../core/services/reading_progress_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../social/presentation/widgets/comment_section.dart';

class EpisodeReaderScreen extends ConsumerStatefulWidget {
  final String episodeId;

  const EpisodeReaderScreen({super.key, required this.episodeId});

  @override
  ConsumerState<EpisodeReaderScreen> createState() =>
      _EpisodeReaderScreenState();
}

class _EpisodeReaderScreenState extends ConsumerState<EpisodeReaderScreen> {
  final _novelService = NovelService();
  final _offlineService = OfflineService();
  final _progressService = ReadingProgressService();

  EpisodeModel? _episode;
  List<EpisodeModel> _allEpisodes = [];
  bool _isLoading = true;
  String? _error;
  bool _isDownloaded = false;
  double _progressPercent = 0;

  @override
  void initState() {
    super.initState();
    _loadEpisode();
  }

  Future<void> _loadEpisode() async {
    try {
      final episode = await _novelService.getEpisodeById(widget.episodeId);
      if (episode == null) {
        setState(() {
          _error = 'পর্ব পাওয়া যায়নি';
          _isLoading = false;
        });
        return;
      }

      final episodes = await _novelService.getEpisodes(episode.novelId);
      final downloaded =
          await _offlineService.isEpisodeDownloaded(widget.episodeId);
      final progress = await _progressService.getProgress(
        episodeId: widget.episodeId,
      );

      await _progressService.saveProgress(
        episodeId: widget.episodeId,
        progressPercent: progress?.progressPercent ?? 0,
      );

      setState(() {
        _episode = episode;
        _allEpisodes = episodes;
        _isDownloaded = downloaded;
        _progressPercent = progress?.progressPercent ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'পর্ব লোড করতে সমস্যা হয়েছে';
        _isLoading = false;
      });
    }
  }

  void _goToPrevious() {
    if (_episode == null) return;
    final i = _allEpisodes.indexWhere((e) => e.id == _episode!.id);
    if (i > 0) {
      context.pushReplacement('/episode/${_allEpisodes[i - 1].id}');
    }
  }

  void _goToNext() {
    if (_episode == null) return;
    final i = _allEpisodes.indexWhere((e) => e.id == _episode!.id);
    if (i < _allEpisodes.length - 1) {
      context.pushReplacement('/episode/${_allEpisodes[i + 1].id}');
    }
  }

  Future<void> _toggleDownload() async {
    if (_episode == null) return;
    if (_isDownloaded) {
      await _offlineService.removeEpisodeOffline(widget.episodeId);
      setState(() => _isDownloaded = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ডাউনলোড সরানো হয়েছে')),
        );
      }
    } else {
      await _offlineService.saveEpisodeOffline(_episode!);
      setState(() => _isDownloaded = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('অফলাইনে সেভ হয়েছে')),
        );
      }
    }
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
          builder: (_, __) {
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
                    child: CommentSection(episodeId: widget.episodeId),
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
        title: _episode != null
            ? Text('পর্ব ${_episode!.episodeNumber}')
            : null,
        actions: [
          if (_progressPercent > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
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
          IconButton(
            icon: Icon(
              _isDownloaded ? Icons.download_done : Icons.download_outlined,
              color: _isDownloaded ? AppColors.primary : null,
            ),
            onPressed: _toggleDownload,
          ),
        ],
      ),
      body: _buildBody(isDark),
      bottomNavigationBar: _episode == null ? null : _buildBottomBar(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null || _episode == null) {
      return Center(child: Text(_error ?? 'পর্ব পাওয়া যায়নি'));
    }

    final ep = _episode!;

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          final metrics = notification.metrics;
          if (metrics.maxScrollExtent > 0) {
            final percent =
                (metrics.pixels / metrics.maxScrollExtent * 100).clamp(0, 100);
            if ((percent - _progressPercent).abs() > 5) {
              _progressPercent = percent.toDouble();
              _progressService.saveProgress(
                episodeId: widget.episodeId,
                progressPercent: _progressPercent,
              );
            }
          }
        }
        return false;
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ep.title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                height: 1.35,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 24),
            ...ep.contentBlocks.map((block) {
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
                        child: const Center(child: CircularProgressIndicator()),
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
    );
  }

  Widget _buildBottomBar(bool isDark) {
    final currentIndex =
        _allEpisodes.indexWhere((e) => e.id == _episode!.id);
    final hasPrevious = currentIndex > 0;
    final hasNext = currentIndex < _allEpisodes.length - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            TextButton.icon(
              onPressed: hasPrevious ? _goToPrevious : null,
              icon: const Icon(Icons.arrow_back_ios, size: 14),
              label: const Text('আগের', style: TextStyle(fontSize: 13)),
            ),
            IconButton(
              onPressed: _showComments,
              icon: const Icon(Icons.chat_bubble_outline, size: 22),
            ),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('তালিকা', style: TextStyle(fontSize: 13)),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: hasNext ? _goToNext : null,
              icon: const Icon(Icons.arrow_forward_ios, size: 14),
              label: const Text('পরের', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}
