class VideoPostModel {
  final String id;
  final String authorId;
  final String title;
  final String description;
  final String videoUrl;
  final String? thumbnailUrl;
  final int durationSeconds;
  final bool isPublished;
  final DateTime createdAt;
  final String? authorName;
  final String? authorAvatar;

  VideoPostModel({
    required this.id,
    required this.authorId,
    required this.title,
    required this.description,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.durationSeconds,
    required this.isPublished,
    required this.createdAt,
    this.authorName,
    this.authorAvatar,
  });

  factory VideoPostModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'];
    return VideoPostModel(
      id: json['id'] as String,
      authorId: json['author_id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      videoUrl: json['video_url'] as String? ?? '',
      thumbnailUrl: json['thumbnail_url'] as String?,
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
      isPublished: json['is_published'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      authorName: profile is Map
          ? profile['full_name'] as String?
          : json['author_name'] as String?,
      authorAvatar: profile is Map
          ? profile['avatar_url'] as String?
          : json['author_avatar'] as String?,
    );
  }
}
