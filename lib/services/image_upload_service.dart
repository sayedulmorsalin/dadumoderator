import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Compress [file] and upload to Firebase Storage under [storagePath].
  /// Returns the download URL or throws on error.
  Future<String> compressAndUpload({
    required File file,
    required String storagePath,
  }) async {
    // 1. Compress
    final compressed = await _compressImage(file);

    // 2. Upload
    final ref = _storage.ref().child(storagePath);
    final uploadTask = await ref.putFile(compressed);
    final url = await uploadTask.ref.getDownloadURL();
    return url;
  }

  Future<File> _compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final ext = p.extension(file.path).toLowerCase();
    final targetPath =
        '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}$ext';

    final CompressFormat format =
        ext == '.png' ? CompressFormat.png : CompressFormat.jpeg;

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 60,
      minWidth: 1024,
      minHeight: 1024,
      format: format,
    );

    if (result == null) return file; // fallback: return original
    return File(result.path);
  }

  /// Delete an image from storage by its download URL.
  Future<void> deleteByUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {
      // Ignore if not found
    }
  }
}
