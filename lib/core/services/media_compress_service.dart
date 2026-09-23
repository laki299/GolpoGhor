import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// ছবি জোরালোভাবে ছোট করে। অডিও/ভিডিও: সাইজ লিমিট + পরে ffmpeg।
class MediaCompressService {
  /// Max dimension (px) for story/cover images
  static const int maxImageSide = 1280;

  /// JPEG quality 1–100 (নিচু = ছোট ফাইল)
  static const int jpegQuality = 72;

  /// Avatar আরও ছোট
  static const int maxAvatarSide = 512;
  static const int avatarJpegQuality = 70;

  /// Soft limits (bytes) — অতিক্রম করলে exception
  static const int maxAudioBytes = 15 * 1024 * 1024; // 15 MB
  static const int maxVideoBytes = 40 * 1024 * 1024; // 40 MB
  static const int maxImageBytesAfter = 400 * 1024; // target \~400KB

  /// ছবি কম্প্রেস → temp File (JPEG)
  Future<File> compressImageFile(
    File file, {
    bool isAvatar = false,
  }) async {
    final bytes = await file.readAsBytes();
    final compressed = await compressImageBytes(
      bytes,
      isAvatar: isAvatar,
    );
    final dir = await getTemporaryDirectory();
    final out = File(
      p.join(
        dir.path,
        'cmp_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ),
    );
    await out.writeAsBytes(compressed, flush: true);
    return out;
  }

  Future<Uint8List> compressImageBytes(
    Uint8List bytes, {
    bool isAvatar = false,
  }) async {
    final maxSide = isAvatar ? maxAvatarSide : maxImageSide;
    var quality = isAvatar ? avatarJpegQuality : jpegQuality;

    img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('ছবি পড়া যায়নি');
    }

    // Resize if large
    if (decoded.width > maxSide || decoded.height > maxSide) {
      decoded = img.copyResize(
        decoded,
        width: decoded.width >= decoded.height ? maxSide : null,
        height: decoded.height > decoded.width ? maxSide : null,
        interpolation: img.Interpolation.average,
      );
    }

    Uint8List encoded = Uint8List.fromList(
      img.encodeJpg(decoded, quality: quality),
    );

    // Still big? drop quality stepwise
    while (encoded.lengthInBytes > maxImageBytesAfter && quality > 40) {
      quality -= 8;
      encoded = Uint8List.fromList(
        img.encodeJpg(decoded, quality: quality),
      );
    }

    return encoded;
  }

  /// অডিও: শুধু সাইজ চেক (রি-এনকোড পরে)
  Future<File> prepareAudioFile(File file) async {
    final len = await file.length();
    if (len > maxAudioBytes) {
      throw Exception(
        'অডিও খুব বড় (${(len / (1024 * 1024)).toStringAsFixed(1)} MB)। '
        'সর্বোচ্চ ${maxAudioBytes \~/ (1024 * 1024)} MB।',
      );
    }
    return file;
  }

  /// ভিডিও: সাইজ চেক (কম্প্রেস ল্যাপটপে video_compress / ffmpeg)
  Future<File> prepareVideoFile(File file) async {
    final len = await file.length();
    if (len > maxVideoBytes) {
      throw Exception(
        'ভিডিও খুব বড় (${(len / (1024 * 1024)).toStringAsFixed(1)} MB)। '
        'সর্বোচ্চ ${maxVideoBytes \~/ (1024 * 1024)} MB।',
      );
    }
    return file;
  }
}
