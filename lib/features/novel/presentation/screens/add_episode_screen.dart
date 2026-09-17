import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/models/content_block_model.dart';
import '../../../../core/services/novel_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_colors.dart';

class AddEpisodeScreen extends ConsumerStatefulWidget {
  final String novelId;

  const AddEpisodeScreen({super.key, required this.novelId});

  @override
  ConsumerState<AddEpisodeScreen> createState() => _AddEpisodeScreenState();
}

class _AddEpisodeScreenState extends ConsumerState<AddEpisodeScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  File? _selectedImage;
  bool _isPublishing = false;

  final _novelService = NovelService();
  final _storageService = StorageService();
  final _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _publish() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('পর্বের লেখা লিখুন')),
      );
      return;
    }

    setState(() => _isPublishing = true);

    try {
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _storageService.uploadStoryImage(_selectedImage!);
      }

      final blocks = <ContentBlock>[
        ContentBlock(type: 'text', value: _contentController.text.trim()),
      ];
      if (imageUrl != null) {
        blocks.add(ContentBlock(type: 'image', value: imageUrl));
      }

      await _novelService.addEpisode(
        novelId: widget.novelId,
        title: _titleController.text.trim().isEmpty
            ? 'নতুন পর্ব'
            : _titleController.text.trim(),
        contentBlocks: blocks,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('নতুন পর্ব যোগ হয়েছে!')),
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
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('নতুন পর্ব যোগ করুন'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isPublishing ? null : _publish,
            child: _isPublishing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'প্রকাশ',
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

          if (_selectedImage != null) ...[
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _selectedImage!,
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
                      onPressed: () => setState(() => _selectedImage = null),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ] else
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image_outlined),
              label: const Text('ছবি যোগ করুন (সর্বোচ্চ ১টি)'),
            ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _contentController,
            maxLines: null,
            minLines: 15,
            style: const TextStyle(fontSize: 16, height: 1.65),
            decoration: const InputDecoration(
              hintText: 'পর্বের সম্পূর্ণ লেখা এখানে লিখুন...',
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
