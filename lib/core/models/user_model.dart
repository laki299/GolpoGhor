class UserModel {
  final String id;
  final String? username;
  final String? fullName;
  final String? bio;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    this.username,
    this.fullName,
    this.bio,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String?,
      fullName: json['full_name'] as String?,
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'bio': bio,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? username,
    String? fullName,
    String? bio,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
