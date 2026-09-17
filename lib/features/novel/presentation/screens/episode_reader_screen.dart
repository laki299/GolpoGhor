import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/models/episode_model.dart';
import '../../../../core/services/novel_service.dart';
import '../../../../core/theme/app_colors.dart';

class EpisodeReaderScreen extends ConsumerStatefulWidget {
  final String episodeId;

  const EpisodeReaderScreen({super.key, required this.episodeId});

  @override
  ConsumerState<EpisodeReaderScreen> createState() =>
      _EpisodeReaderScreenState();
}

class _EpisodeReaderScreenState extends ConsumerState<EpisodeReaderScreen> {
  final _novelService = NovelService();
  EpisodeModel? _episode;
  List<EpisodeModel> _allEpisodes = [];
  bool _isLoading = true;
  String? _error;

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

      setState(() {
        _episode = episode;
        _allEpisodes = episodes;
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
    final currentIndex =
        _allEpisodes.indexWhere((e) => e.id == _episode!.id);
    if (currentIndex > 0) {
      final prev = _allEpisodes[currentIndex - 1];
      context.pushReplacement('/episode/${prev.id}');
    }
  }

  void _goToNext() {
    if (_episode == null) return;
    final currentIndex =
        _allEpisodes.indexWhere((e) => e.id == _episode!.id);
    if (currentIndex < _allEpisodes.length - 1) {
      final next = _allEpisodes[currentIndex + 1];
      context.pushReplacement('/episode/${next.id}');
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
        title: _episode != null
            ? Text('পর্ব ${_episode!.episodeNumber}')
            : null,
      ),
      body: _buildBody(isDark),
      bottomNavigationBar: _episode == null ? null : _buildNavigationBar(isDark),
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

    return SingleChildScrollView(
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
    );
  }

  Widget _buildNavigationBar(bool isDark) {
    final currentIndex =
        _allEpisodes.indexWhere((e) => e.id == _episode!.id);
    final hasPrevious = currentIndex > 0;
    final hasNext = currentIndex < _allEpisodes.length - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: hasPrevious ? _goToPrevious : null,
              icon: const Icon(Icons.arrow_back_ios, size: 16),
              label: const Text('পূর্বের পর্ব'),
            ),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('পর্ব তালিকা'),
            ),
            TextButton.icon(
              onPressed: hasNext ? _goToNext : null,
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              label: const Text('পরের পর্ব'),
            ),
          ],
        ),
      ),
    );
  }
}
