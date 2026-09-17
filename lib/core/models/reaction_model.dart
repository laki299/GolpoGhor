class ReactionModel {
  final String id;
  final String userId;
  final String? storyId;
  final String? episodeId;
  final String reactionType;
  final DateTime createdAt;

  ReactionModel({
    required this.id,
    required this.userId,
    this.storyId,
    this.episodeId,
    required this.reactionType,
    required this.createdAt,
  });

  factory ReactionModel.fromJson(Map<String, dynamic> json) {
    return ReactionModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      storyId: json['story_id'] as String?,
      episodeId: json['episode_id'] as String?,
      reactionType: json['reaction_type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'story_id': storyId,
      'episode_id': episodeId,
      'reaction_type': reactionType,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
