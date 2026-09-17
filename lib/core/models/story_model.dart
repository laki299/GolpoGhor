import 'content_block_model.dart';

class StoryModel {
  final String id;
  final String authorId;
  final String title;
  final String? description;
  final String? category;
  final List<String> tags;
  final List<ContentBlock> contentBlocks;
  final String? coverUrl;
  final int viewCount;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Optional joined data
  final String? authorName;
  final String? authorUsername;
  final String? authorAvatar;

  StoryModel({
    required this.id,
    required this.authorId,
    required this.title,
    this.description,
    this.category,
    this.tags = const [],
    this.contentBlocks = const [],
    this.coverUrl,
    this.viewCount = 0,
    this.isPublished = true,
    required this.createdAt,
    required this.updatedAt,
    this.authorName,
    this.authorUsername,
    this.authorAvatar,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    final blocks = (json['content_blocks'] as List<dynamic>?)
            ?.map((e) => ContentBlock.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return StoryModel(
      id: json['id'] as String,
      authorId: json['author_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      contentBlocks: blocks,
      coverUrl: json['cover_url'] as String?,
      viewCount: json['view_count'] as int? ?? 0,
      isPublished: json['is_published'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      authorName: json['author_name'] as String?,
      authorUsername: json['author_username'] as String?,
      authorAvatar: json['author_avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author_id': authorId,
      'title': title,
      'description': description,
      'category': category,
      'tags': tags,
      'content_blocks': contentBlocks.map((e) => e.toJson()).toList(),
      'cover_url': coverUrl,
      'view_count': viewCount,
      'is_published': isPublished,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Preview text for Home Feed (first few lines)
  String get previewText {
    final textBlocks = contentBlocks.where((b) => b.isText).toList();
    if (textBlocks.isEmpty) return description ?? '';
    final full = textBlocks.map((e) => e.value).join('\n');
    if (full.length <= 180) return full;
    return '${full.substring(0, 180)}...';
  }
}
