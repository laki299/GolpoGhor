class NovelModel {
  final String id;
  final String authorId;
  final String title;
  final String? description;
  final String? category;
  final List<String> tags;
  final String? coverUrl;
  final int episodeCount;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Optional joined data
  final String? authorName;
  final String? authorUsername;
  final String? authorAvatar;

  NovelModel({
    required this.id,
    required this.authorId,
    required this.title,
    this.description,
    this.category,
    this.tags = const [],
    this.coverUrl,
    this.episodeCount = 0,
    this.isPublished = true,
    required this.createdAt,
    required this.updatedAt,
    this.authorName,
    this.authorUsername,
    this.authorAvatar,
  });

  factory NovelModel.fromJson(Map<String, dynamic> json) {
    return NovelModel(
      id: json['id'] as String,
      authorId: json['author_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      coverUrl: json['cover_url'] as String?,
      episodeCount: json['episode_count'] as int? ?? 0,
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
      'cover_url': coverUrl,
      'episode_count': episodeCount,
      'is_published': isPublished,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
