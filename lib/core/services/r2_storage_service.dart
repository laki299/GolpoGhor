import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/r2_constants.dart';
import '../constants/supabase_constants.dart';
import 'media_compress_service.dart';

/// এখন: ছবি কম্প্রেস → Supabase fallback।
/// R2 কনফিগ + PutObject → ল্যাপটপ ধাপ।
class R2StorageService {
  final _compress = MediaCompressService();
  final _client = Supabase.instance.client;

  Future<String> uploadImage({
    required File file,
    required String folder, // stories | avatars | covers
    bool isAvatar = false,
  }) async {
    final compressed = await _compress.compressImageFile(
      file,
      isAvatar: isAvatar,
    );

    if (R2Constants.isConfigured) {
      throw UnimplementedError(
        'R2 আপলোড ল্যাপটপে শেষ হবে। '
        'এখন isConfigured false রেখে Supabase path ব্যবহার করুন।',
      );
    }

    final uid = _client.auth.currentUser?.id ?? 'anon';
    final name =
        '$folder/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg';

    await _client.storage.from(SupabaseConstants.storyImagesBucket).upload(
          name,
          compressed,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/jpeg',
          ),
        );

    return _client.storage
        .from(SupabaseConstants.storyImagesBucket)
        .getPublicUrl(name);
  }

  Future<String> uploadAudio({required File file}) async {
    await _compress.prepareAudioFile(file);
    if (!R2Constants.isConfigured) {
      throw Exception('অডিও আপলোডের জন্য R2 কনফিগ লাগবে (পরে)।');
    }
    throw UnimplementedError('R2 audio upload — ল্যাপটপ ধাপ');
  }

  Future<String> uploadVideo({required File file}) async {
    await _compress.prepareVideoFile(file);
    if (!R2Constants.isConfigured) {
      throw Exception('ভিডিও আপলোডের জন্য R2 কনফিগ লাগবে (পরে)।');
    }
    throw UnimplementedError('R2 video upload — ল্যাপটপ ধাপ');
  }
}
