import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/story_model.dart';
import '../../../../core/models/content_block_model.dart';
import '../../../../core/services/story_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_colors.dart';

class EditStoryScreen extends ConsumerStatefulWidget {
  final String storyId;

  const EditStoryScreen({super.key, required this.storyId});

  @override
  ConsumerState<EditStoryScreen> createState() => _EditStoryScreenState();
}

class _EditStoryScreenState extends ConsumerState<EditStoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();

  final _storyService = StoryService();
  final _storageService = StorageService();
  final _picker = ImagePicker();

  StoryModel? _story;
  String? _selectedCategory;
  File? _newImage;
  String? _existingImageUrl;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _removeImage = false;

  @override
  void initState() {
    super.initState();
    _loadStory();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadStory() async {
    try {
      final story = await _storyService.getStoryById(widget.storyId);
      if (story == null) {
        setState(() => _isLoading = false);
        return;
      }

      final textContent = story.contentBlocks
          .where((b) => b.isText)
          .map((b) => b.value)
          .join('\n\n');

      final imageBlock = story.contentBlocks.where((b) => b.isImage).toList();

      setState(() {
        _story = story;
        _titleController.text = story.title;
        _descriptionController.text = story.description ?? '';
        _contentController.text = textContent;
        _selectedCategory = story.category;
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
    if (!_formKey.currentState!.validate()) return;
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('গল্পের লেখা খালি রাখা যাবে না')),
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

      await _storyService.updateStory(
        storyId: widget.storyId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        category: _selectedCategory,
        contentBlocks: blocks,
        coverUrl: imageUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('গল্প আপডেট হয়েছে')),
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

    if (_story == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('গল্প পাওয়া যায়নি')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('গল্প এডিট করুন'),
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

            // Image Section
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
                        onPressed: () {
                          setState(() => _removeImage = true);
                        },
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
            const SizedBox(height: 20),

            TextFormField(
              controller: _contentController,
              maxLines: null,
              minLines: 12,
              style: const TextStyle(fontSize: 16, height: 1.6),
              decoration: const InputDecoration(
                hintText: 'গল্পের লেখা...',
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
