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
  final _contentBeforeController = TextEditingController();
  final _contentAfterController = TextEditingController();

  final _storyService = StoryService();
  final _storageService = StorageService();
  final _picker = ImagePicker();

  StoryModel? _story;
  String? _selectedCategory;
  File? _newImage;
  String? _existingImageUrl;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _imageInserted = false;
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
    _contentBeforeController.dispose();
    _contentAfterController.dispose();
    super.dispose();
  }

  Future<void> _loadStory() async {
    try {
      final story = await _storyService.getStoryById(widget.storyId);
      if (story == null) {
        setState(() => _isLoading = false);
        return;
      }

      final texts = story.contentBlocks.where((b) => b.isText).toList();
      final images = story.contentBlocks.where((b) => b.isImage).toList();

      String before = '';
      String after = '';

      if (images.isEmpty) {
        before = texts.map((t) => t.value).join('\n\n');
      } else {
        // প্রথম image-এর আগের সব text = before, পরের = after
        final imgIndex = story.contentBlocks.indexWhere((b) => b.isImage);
        final beforeBlocks = story.contentBlocks.take(imgIndex).where((b) => b.isText);
        final afterBlocks = story.contentBlocks.skip(imgIndex + 1).where((b) => b.isText);
        before = beforeBlocks.map((t) => t.value).join('\n\n');
        after = afterBlocks.map((t) => t.value).join('\n\n');
        _existingImageUrl = images.first.value;
        _imageInserted = true;
      }

      setState(() {
        _story = story;
        _titleController.text = story.title;
        _descriptionController.text = story.description ?? '';
        _contentBeforeController.text = before;
        _contentAfterController.text = after;
        _selectedCategory = story.category;
        _isLoading = false;
      });
    } catch (_) {
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
        _imageInserted = true;
        _removeImage = false;
      });
    }
  }

  void _clearImage() {
    setState(() {
      if (_contentAfterController.text.trim().isNotEmpty) {
        final before = _contentBeforeController.text;
        final after = _contentAfterController.text;
        _contentBeforeController.text =
            before.isEmpty ? after : '$before\n\n$after';
        _contentAfterController.clear();
      }
      _newImage = null;
      _existingImageUrl = null;
      _imageInserted = false;
      _removeImage = true;
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final hasText = _contentBeforeController.text.trim().isNotEmpty ||
        _contentAfterController.text.trim().isNotEmpty;
    if (!hasText) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('গল্পের লেখা খালি রাখা যাবে না')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      String? imageUrl;
      if (_removeImage) {
        imageUrl = null;
      } else if (_newImage != null) {
        imageUrl = await _storageService.uploadStoryImage(_newImage!);
      } else {
        imageUrl = _existingImageUrl;
      }

      final blocks = _buildBlocks(imageUrl: imageUrl);

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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_story == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('গল্প পাওয়া যায়নি')),
      );
    }

    final showImage = _imageInserted &&
        ((_newImage != null) || (_existingImageUrl != null && !_removeImage));

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
            TextFormField(
              controller: _contentBeforeController,
              maxLines: null,
              minLines: showImage ? 4 : 10,
              style: const TextStyle(fontSize: 16, height: 1.6),
              decoration: InputDecoration(
                hintText: showImage
                    ? 'ছবির আগের লেখা...'
                    : 'গল্পের লেখা...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
            if (showImage) ...[
              const SizedBox(height: 12),
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _newImage != null
                        ? Image.file(
                            _newImage!,
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                          )
                        : CachedNetworkImage(
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
                        onPressed: _clearImage,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contentAfterController,
                maxLines: null,
                minLines: 6,
                style: const TextStyle(fontSize: 16, height: 1.6),
                decoration: const InputDecoration(
                  hintText: 'ছবির পরের লেখা...',
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
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
