import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../constants/supabase_constants.dart';

class StorageService {
  final SupabaseClient _client = Supabase.instance.client;
  final _uuid = const Uuid();

  /// Story image compress + upload
  Future<String> uploadStoryImage(File imageFile) async {
    try {
      final compressedBytes = await _compressImage(imageFile, maxWidth: 1200, quality: 80);
      final fileName = '${_uuid.v4()}.jpg';
      final filePath = 'stories/$fileName';

      await _client.storage.from(SupabaseConstants.storyImagesBucket).uploadBinary(
            filePath,
            compressedBytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
              contentType: 'image/jpeg',
            ),
          );

      return _client.storage
          .from(SupabaseConstants.storyImagesBucket)
          .getPublicUrl(filePath);
    } catch (e) {
      throw Exception('Image upload failed: $e');
    }
  }

  /// Profile avatar: compress + upload
  /// [oldAvatarUrl] থাকলে আগে সেটা ডিলিট করে
  Future<String> uploadAvatar({
    required File imageFile,
    String? oldAvatarUrl,
  }) async {
    try {
      // 1. পুরনো avatar ডিলিট
      if (oldAvatarUrl != null && oldAvatarUrl.isNotEmpty) {
        await deleteImage(oldAvatarUrl);
      }

      // 2. Compress (avatar ছোট রাখি)
      final compressedBytes = await _compressImage(imageFile, maxWidth: 512, quality: 85);
      final userId = _client.auth.currentUser?.id ?? _uuid.v4();
      final fileName = '\( {userId}_ \){_uuid.v4()}.jpg';
      final filePath = 'avatars/$fileName';

      // 3. Upload
      await _client.storage.from(SupabaseConstants.storyImagesBucket).uploadBinary(
            filePath,
            compressedBytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
              contentType: 'image/jpeg',
            ),
          );

      // 4. Public URL
      return _client.storage
          .from(SupabaseConstants.storyImagesBucket)
          .getPublicUrl(filePath);
    } catch (e) {
      throw Exception('Avatar upload failed: $e');
    }
  }

  /// Compress image
  Future<Uint8List> _compressImage(
    File file, {
    int maxWidth = 1200,
    int quality = 80,
  }) async {
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception('Invalid image file');
    }

    img.Image resized = image;
    if (image.width > maxWidth) {
      resized = img.copyResize(
        image,
        width: maxWidth,
        interpolation: img.Interpolation.average,
      );
    }

    final compressed = img.encodeJpg(resized, quality: quality);
    return Uint8List.fromList(compressed);
  }

  /// URL থেকে storage path বের করে ডিলিট
  Future<void> deleteImage(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      final segments = uri.pathSegments;

      final bucketIndex = segments.indexOf(SupabaseConstants.storyImagesBucket);
      if (bucketIndex == -1 || bucketIndex + 1 >= segments.length) return;

      final filePath = segments.sublist(bucketIndex + 1).join('/');

      await _client.storage
          .from(SupabaseConstants.storyImagesBucket)
          .remove([filePath]);
    } catch (e) {
      // পুরনো ফাইল না থাকলে ignore
      print('Failed to delete image: $e');
    }
  }
}
