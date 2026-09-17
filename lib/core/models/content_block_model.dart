class ContentBlock {
  final String type; // "text" or "image"
  final String value; // text content or image url

  ContentBlock({
    required this.type,
    required this.value,
  });

  factory ContentBlock.fromJson(Map<String, dynamic> json) {
    return ContentBlock(
      type: json['type'] as String,
      value: json['value'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'value': value,
    };
  }

  bool get isText => type == 'text';
  bool get isImage => type == 'image';
}
