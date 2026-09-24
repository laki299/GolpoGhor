import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_constants.dart';
import 'media_compress_service.dart';

class StorageService {
  final SupabaseClient _client = Supabase.instance.client;
  final _compress = MediaCompressService();

  String get _bucket => SupabaseConstants.storyImagesBucket;

  /// গল্প/কভার ছবি — কম্প্রেস করে আপলোড
  Future<String> uploadStoryImage(File file) async {
    final compressed = await _compress.compressImageFile(file);
    final uid = _client.auth.currentUser?.id ?? 'anon';
    final path =
        'stories/\( uid/ \){DateTime.now().millisecondsSinceEpoch}.jpg';

    await _client.storage.from(_bucket).upload(
          path,
          compressed,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/jpeg',
          ),
        );

    return _client.storage.from(_bucket).getPublicUrl(path);
  }

  /// প্রোফাইল ছবি — কম্প্রেস + পুরনো ডিলিট
  Future<String> uploadAvatar({
    required File imageFile,
    String? oldAvatarUrl,
  }) async {
    final compressed = await _compress.compressImageFile(
      imageFile,
      isAvatar: true,
    );
    final uid = _client.auth.currentUser?.id ?? 'anon';
    final path =
        'avatars/\( uid/ \){DateTime.now().millisecondsSinceEpoch}.jpg';

    await _client.storage.from(_bucket).upload(
          path,
          compressed,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/jpeg',
          ),
        );

    final url = _client.storage.from(_bucket).getPublicUrl(path);

    if (oldAvatarUrl != null &&
        oldAvatarUrl.isNotEmpty &&
        oldAvatarUrl != url) {
      try {
        await deleteImage(oldAvatarUrl);
      } catch (_) {}
    }

    return url;
  }

  /// Public URL থেকে path বের করে স্টোরেজ থেকে ডিলিট
  Future<void> deleteImage(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      final segments = uri.pathSegments;
      // .../object/public/story_images/<path>
      final idx = segments.indexOf(_bucket);
      if (idx < 0 || idx >= segments.length - 1) return;
      final objectPath = segments.sublist(idx + 1).join('/');
      if (objectPath.isEmpty) return;
      await _client.storage.from(_bucket).remove([objectPath]);
    } catch (_) {
      // ignore
    }
  }
}
