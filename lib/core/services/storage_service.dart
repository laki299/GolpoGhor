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

  /// Image compress + upload
  /// Returns public URL
  Future<String> uploadStoryImage(File imageFile) async {
    try {
      // 1. Compress image
      final compressedBytes = await _compressImage(imageFile);

      // 2. Generate unique filename
      final fileName =
          '\( {_uuid.v4()} \){path.extension(imageFile.path).toLowerCase()}';
      final filePath = 'stories/$fileName';

      // 3. Upload
      await _client.storage.from(SupabaseConstants.storyImagesBucket).uploadBinary(
            filePath,
            compressedBytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      // 4. Get public URL
      final publicUrl = _client.storage
          .from(SupabaseConstants.storyImagesBucket)
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Image upload failed: $e');
    }
  }

  /// Compress image to reduce size (max width 1200px, quality 80)
  Future<Uint8List> _compressImage(File file) async {
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception('Invalid image file');
    }

    // Resize if too large
    img.Image resized = image;
    if (image.width > 1200) {
      resized = img.copyResize(
        image,
        width: 1200,
        interpolation: img.Interpolation.average,
      );
    }

    // Encode as JPEG with quality 80
    final compressed = img.encodeJpg(resized, quality: 80);
    return Uint8List.fromList(compressed);
  }

  /// Delete image from storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      // URL থেকে path বের করা
      final uri = Uri.parse(imageUrl);
      final segments = uri.pathSegments;

      // story-images/stories/xxxx.jpg → stories/xxxx.jpg
      final bucketIndex = segments.indexOf(SupabaseConstants.storyImagesBucket);
      if (bucketIndex == -1 || bucketIndex + 1 >= segments.length) return;

      final filePath = segments.sublist(bucketIndex + 1).join('/');

      await _client.storage
          .from(SupabaseConstants.storyImagesBucket)
          .remove([filePath]);
    } catch (e) {
      // Delete fail হলে ignore (optional)
      print('Failed to delete image: $e');
    }
  }
}
