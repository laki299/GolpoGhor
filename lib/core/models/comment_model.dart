class CommentModel {
  final String id;
  final String userId;
  final String? storyId;
  final String? episodeId;
  final String? parentId; // null হলে মূল কমেন্ট, নাহলে রিপ্লাই
  final String content;
  final DateTime createdAt;

  // Joined data
  final String? userName;
  final String? userAvatar;
  final List<CommentModel> replies;

  CommentModel({
    required this.id,
    required this.userId,
    this.storyId,
    this.episodeId,
    this.parentId,
    required this.content,
    required this.createdAt,
    this.userName,
    this.userAvatar,
    this.replies = const [],
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      storyId: json['story_id'] as String?,
      episodeId: json['episode_id'] as String?,
      parentId: json['parent_id'] as String?,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      userName: json['user_name'] as String?,
      userAvatar: json['user_avatar'] as String?,
      replies: (json['replies'] as List<dynamic>?)
              ?.map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'story_id': storyId,
      'episode_id': episodeId,
      'parent_id': parentId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isReply => parentId != null;
}
