import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/content_block_model.dart';
import '../../../../core/services/story_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_colors.dart';

class CreateStoryScreen extends ConsumerStatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  ConsumerState<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends ConsumerState<CreateStoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentBeforeController = TextEditingController();
  final _contentAfterController = TextEditingController();

  String? _selectedCategory;
  File? _selectedImage;
  bool _isPublishing = false;
  bool _imageInserted = false;

  final _storyService = StoryService();
  final _storageService = StorageService();
  final _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contentBeforeController.dispose();
    _contentAfterController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
        _imageInserted = true;
      });
    }
  }

  void _removeImage() {
    setState(() {
      if (_contentAfterController.text.trim().isNotEmpty) {
        final before = _contentBeforeController.text;
        final after = _contentAfterController.text;
        _contentBeforeController.text =
            before.isEmpty ? after : '$before\n\n$after';
        _contentAfterController.clear();
      }
      _selectedImage = null;
      _imageInserted = false;
    });
  }

  List<ContentBlock> _buildBlocks({String? imageUrl}) {
    final blocks = <ContentBlock>[];
    final before = _contentBeforeController.text.trim();
    final after = _contentAfterController.text.trim();

    if (before.isNotEmpty) {
      blocks.add(ContentBlock(type: 'text', value: before));
    }
    if (imageUrl != null) {
      blocks.add(ContentBlock(type: 'image', value: imageUrl));
    }
    if (after.isNotEmpty) {
      blocks.add(ContentBlock(type: 'text', value: after));
    }
    return blocks;
  }

  Future<void> _save({required bool isDraft}) async {
    if (!isDraft) {
      if (!_formKey.currentState!.validate()) return;
      final hasText = _contentBeforeController.text.trim().isNotEmpty ||
          _contentAfterController.text.trim().isNotEmpty;
      if (!hasText) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('গল্পের মূল লেখা লিখুন')),
        );
        return;
      }
    }

    setState(() => _isPublishing = true);

    try {
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _storageService.uploadStoryImage(_selectedImage!);
      }

      final blocks = _buildBlocks(imageUrl: imageUrl);

      if (isDraft) {
        await _storyService.saveDraft(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          category: _selectedCategory,
          contentBlocks: blocks,
          coverUrl: imageUrl,
        );
      } else {
        await _storyService.createStory(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          category: _selectedCategory,
          contentBlocks: blocks,
          coverUrl: imageUrl,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isDraft ? 'খসড়া সেভ হয়েছে' : 'গল্প প্রকাশিত হয়েছে!'),
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('নতুন গল্প'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isPublishing ? null : () => _save(isDraft: true),
            child: const Text('খসড়া'),
          ),
          TextButton(
            onPressed: _isPublishing ? null : () => _save(isDraft: false),
            child: _isPublishing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'প্রকাশ করুন',
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
                hintText: 'গল্পের শিরোনাম',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'শিরোনাম আবশ্যক' : null,
            ),
            const Divider(),
            const SizedBox(height: 8),
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

            // ছবির আগের লেখা
            TextFormField(
              controller: _contentBeforeController,
              maxLines: null,
              minLines: _imageInserted ? 4 : 10,
              style: const TextStyle(fontSize: 16, height: 1.6),
              decoration: InputDecoration(
                hintText: _imageInserted
                    ? 'ছবির আগের লেখা (ঐচ্ছিক)...'
                    : 'এখানে গল্প লিখুন... ছবি যেকোনো সময় যোগ করতে পারবেন',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),

            if (_imageInserted && _selectedImage != null) ...[
              const SizedBox(height: 12),
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _selectedImage!,
                      width: double.infinity,
                      height: 200,
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
                        onPressed: _removeImage,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '↑ ছবি এখানে (আগের ও পরের লেখার মাঝে)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.primary),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contentAfterController,
                maxLines: null,
                minLines: 6,
                style: const TextStyle(fontSize: 16, height: 1.6),
                decoration: const InputDecoration(
                  hintText: 'ছবির পরের লেখা লিখুন...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image_outlined),
                label: const Text('ছবি যোগ করুন (সর্বোচ্চ ১টি)'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '• আগে লিখে ছবি দিলে → ছবি মাঝে\n'
                '• শুধু ছবি দিলে → ছবি শুরুতে\n'
                '• লেখা শেষে ছবি দিলে → ছবি শেষে',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
