class ReadingProgressModel {
  final String id;
  final String userId;
  final String? storyId;
  final String? episodeId;
  final double progressPercent;
  final DateTime lastReadAt;

  ReadingProgressModel({
    required this.id,
    required this.userId,
    this.storyId,
    this.episodeId,
    this.progressPercent = 0.0,
    required this.lastReadAt,
  });

  factory ReadingProgressModel.fromJson(Map<String, dynamic> json) {
    return ReadingProgressModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      storyId: json['story_id'] as String?,
      episodeId: json['episode_id'] as String?,
      progressPercent: (json['progress_percent'] as num?)?.toDouble() ?? 0.0,
      lastReadAt: DateTime.parse(json['last_read_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'story_id': storyId,
      'episode_id': episodeId,
      'progress_percent': progressPercent,
      'last_read_at': lastReadAt.toIso8601String(),
    };
  }
}
