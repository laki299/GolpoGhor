import 'content_block_model.dart';

class EpisodeModel {
  final String id;
  final String novelId;
  final int episodeNumber;
  final String title;
  final List<ContentBlock> contentBlocks;
  final int viewCount;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;

  EpisodeModel({
    required this.id,
    required this.novelId,
    required this.episodeNumber,
    required this.title,
    this.contentBlocks = const [],
    this.viewCount = 0,
    this.isPublished = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EpisodeModel.fromJson(Map<String, dynamic> json) {
    final blocks = (json['content_blocks'] as List<dynamic>?)
            ?.map((e) => ContentBlock.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return EpisodeModel(
      id: json['id'] as String,
      novelId: json['novel_id'] as String,
      episodeNumber: json['episode_number'] as int,
      title: json['title'] as String,
      contentBlocks: blocks,
      viewCount: json['view_count'] as int? ?? 0,
      isPublished: json['is_published'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'novel_id': novelId,
      'episode_number': episodeNumber,
      'title': title,
      'content_blocks': contentBlocks.map((e) => e.toJson()).toList(),
      'view_count': viewCount,
      'is_published': isPublished,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get previewText {
    final textBlocks = contentBlocks.where((b) => b.isText).toList();
    if (textBlocks.isEmpty) return '';
    final full = textBlocks.map((e) => e.value).join('\n');
    if (full.length <= 180) return full;
    return '${full.substring(0, 180)}...';
  }
}
