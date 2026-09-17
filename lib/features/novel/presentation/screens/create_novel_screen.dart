import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/content_block_model.dart';
import '../../../../core/services/novel_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_colors.dart';

class CreateNovelScreen extends ConsumerStatefulWidget {
  const CreateNovelScreen({super.key});

  @override
  ConsumerState<CreateNovelScreen> createState() => _CreateNovelScreenState();
}

class _CreateNovelScreenState extends ConsumerState<CreateNovelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _episodeTitleController = TextEditingController();
  final _episodeContentController = TextEditingController();

  String? _selectedCategory;
  File? _selectedImage;
  bool _isPublishing = false;

  final _novelService = NovelService();
  final _storageService = StorageService();
  final _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _episodeTitleController.dispose();
    _episodeContentController.dispose();
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
    if (!_formKey.currentState!.validate()) return;

    if (_episodeContentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('প্রথম পর্বের লেখা লিখুন')),
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
        ContentBlock(
          type: 'text',
          value: _episodeContentController.text.trim(),
        ),
      ];

      if (imageUrl != null) {
        blocks.add(ContentBlock(type: 'image', value: imageUrl));
      }

      await _novelService.createNovel(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        category: _selectedCategory,
        coverUrl: imageUrl,
        firstEpisodeTitle: _episodeTitleController.text.trim().isEmpty
            ? 'পর্ব ১'
            : _episodeTitleController.text.trim(),
        firstEpisodeBlocks: blocks,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('উপন্যাস সফলভাবে তৈরি হয়েছে!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('সমস্যা হয়েছে: $e')),
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
        title: const Text('নতুন উপন্যাস'),
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
                    'তৈরি করুন',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _titleController,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: 'উপন্যাসের নাম',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'নাম আবশ্যক' : null,
            ),
            const Divider(),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'ক্যাটাগরি',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: AppConstants.categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'সংক্ষিপ্ত বিবরণ (ঐচ্ছিক)',
              ),
            ),
            const SizedBox(height: 20),

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
                label: const Text('কভার ছবি যোগ করুন (ঐচ্ছিক)'),
              ),
            const SizedBox(height: 24),

            const Text(
              'প্রথম পর্ব',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _episodeTitleController,
              decoration: const InputDecoration(
                labelText: 'পর্বের শিরোনাম',
                hintText: 'পর্ব ১',
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _episodeContentController,
              maxLines: null,
              minLines: 10,
              style: const TextStyle(fontSize: 16, height: 1.6),
              decoration: const InputDecoration(
                hintText: 'প্রথম পর্বের লেখা এখানে লিখুন...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
