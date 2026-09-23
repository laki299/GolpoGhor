import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/models/audio_post_model.dart';
import '../../../../core/services/media_service.dart';
import '../../../../core/theme/app_colors.dart';

class AudioFeedScreen extends StatefulWidget {
  const AudioFeedScreen({super.key});

  @override
  State<AudioFeedScreen> createState() => _AudioFeedScreenState();
}

class _AudioFeedScreenState extends State<AudioFeedScreen> {
  final _media = MediaService();
  List<AudioPostModel> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _media.getAudioFeed();
      setState(() {
        _items = list;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty) {
      return const Center(child: Text('এখনো কোনো অডিও নেই'));
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final a = _items[i];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.15),
                backgroundImage: a.coverUrl != null
                    ? CachedNetworkImageProvider(a.coverUrl!)
                    : null,
                child: a.coverUrl == null
                    ? const Icon(Icons.audiotrack, color: AppColors.primary)
                    : null,
              ),
              title: Text(
                a.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${a.authorName ?? "লেখক"} • ${a.durationSeconds}s',
              ),
              trailing: const Icon(Icons.play_circle_outline),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'অডিও প্লেয়ার ল্যাপটপ ধাপে যুক্ত হবে',
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
