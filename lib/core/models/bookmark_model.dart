class BookmarkModel {
  final String id;
  final String userId;
  final String? storyId;
  final String? novelId;
  final DateTime createdAt;

  BookmarkModel({
    required this.id,
    required this.userId,
    this.storyId,
    this.novelId,
    required this.createdAt,
  });

  factory BookmarkModel.fromJson(Map<String, dynamic> json) {
    return BookmarkModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      storyId: json['story_id'] as String?,
      novelId: json['novel_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'story_id': storyId,
      'novel_id': novelId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
