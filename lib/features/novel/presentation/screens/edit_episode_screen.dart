import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/models/episode_model.dart';
import '../../../../core/models/content_block_model.dart';
import '../../../../core/services/novel_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_colors.dart';

class EditEpisodeScreen extends ConsumerStatefulWidget {
  final String episodeId;

  const EditEpisodeScreen({super.key, required this.episodeId});

  @override
  ConsumerState<EditEpisodeScreen> createState() => _EditEpisodeScreenState();
}

class _EditEpisodeScreenState extends ConsumerState<EditEpisodeScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _novelService = NovelService();
  final _storageService = StorageService();
  final _picker = ImagePicker();

  EpisodeModel? _episode;
  File? _newImage;
  String? _existingImageUrl;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _removeImage = false;

  @override
  void initState() {
    super.initState();
    _loadEpisode();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadEpisode() async {
    try {
      final episode = await _novelService.getEpisodeById(widget.episodeId);
      if (episode == null) {
        setState(() => _isLoading = false);
        return;
      }

      final textContent = episode.contentBlocks
          .where((b) => b.isText)
          .map((b) => b.value)
          .join('\n\n');

      final imageBlock = episode.contentBlocks.where((b) => b.isImage).toList();

      setState(() {
        _episode = episode;
        _titleController.text = episode.title;
        _contentController.text = textContent;
        _existingImageUrl = imageBlock.isNotEmpty ? imageBlock.first.value : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        _newImage = File(picked.path);
        _removeImage = false;
      });
    }
  }

  Future<void> _save() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('পর্বের লেখা খালি রাখা যাবে না')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      String? imageUrl = _existingImageUrl;

      if (_removeImage) {
        imageUrl = null;
      } else if (_newImage != null) {
        imageUrl = await _storageService.uploadStoryImage(_newImage!);
      }

      final blocks = <ContentBlock>[
        ContentBlock(type: 'text', value: _contentController.text.trim()),
      ];

      if (imageUrl != null) {
        blocks.add(ContentBlock(type: 'image', value: imageUrl));
      }

      await _novelService.updateEpisode(
        episodeId: widget.episodeId,
        title: _titleController.text.trim().isEmpty
            ? 'পর্ব ${_episode?.episodeNumber ?? ''}'
            : _titleController.text.trim(),
        contentBlocks: blocks,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('পর্ব আপডেট হয়েছে')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('সমস্যা: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_episode == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('পর্ব পাওয়া যায়নি')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('পর্ব ${_episode!.episodeNumber} এডিট'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'সেভ করুন',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextFormField(
            controller: _titleController,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              hintText: 'পর্বের শিরোনাম',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
          const Divider(),
          const SizedBox(height: 12),

          if (_newImage != null) ...[
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _newImage!,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    radius: 16,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.close, color: Colors.white, size: 18),
                      onPressed: () {
                        setState(() {
                          _newImage = null;
                          _removeImage = true;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ] else if (_existingImageUrl != null && !_removeImage) ...[
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: _existingImageUrl!,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    radius: 16,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.close, color: Colors.white, size: 18),
                      onPressed: () => setState(() => _removeImage = true),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image_outlined),
              label: const Text('ছবি যোগ করুন (সর্বোচ্চ ১টি)'),
            ),
          ],
          const SizedBox(height: 16),

          TextFormField(
            controller: _contentController,
            maxLines: null,
            minLines: 15,
            style: const TextStyle(fontSize: 16, height: 1.65),
            decoration: const InputDecoration(
              hintText: 'পর্বের লেখা...',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }
}
