import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:logger/logger.dart';

class WebPImageService {
  final Logger _logger = Logger();

  /// Convert image to WebP format with compression
  Future<File> convertToWebP(
    File imageFile, {
    int quality = 85,
    int maxWidth = 1024,
    int maxHeight = 1024,
  }) async {
    try {
      _logger.i('Converting image to WebP: ${imageFile.path}');

      // Use flutter_image_compress to convert to WebP
      final Uint8List webpBytes =
          await FlutterImageCompress.compressWithFile(
            imageFile.path,
            quality: quality,
            minWidth: maxWidth,
            minHeight: maxHeight,
            format: CompressFormat.webp,
          ) ??
          Uint8List(0);

      if (webpBytes.isEmpty) {
        throw Exception('WebP conversion failed - empty result');
      }

      // Create temporary file with WebP extension
      final String tempPath = imageFile.path.replaceAll(
        RegExp(r'\.[^.]+$'),
        '.webp',
      );
      final File webpFile = File(tempPath);
      await webpFile.writeAsBytes(webpBytes);

      _logger.i('Successfully converted to WebP: ${webpFile.path}');
      return webpFile;
    } catch (e) {
      _logger.e('Error converting to WebP: $e');
      rethrow;
    }
  }

  /// Compress image using flutter_image_compress
  Future<File> compressImage(
    File imageFile, {
    int quality = 85,
    int maxWidth = 1024,
    int maxHeight = 1024,
  }) async {
    try {
      _logger.i('Compressing image: ${imageFile.path}');

      final Uint8List compressedBytes =
          await FlutterImageCompress.compressWithFile(
            imageFile.path,
            quality: quality,
            minWidth: maxWidth,
            minHeight: maxHeight,
          ) ??
          Uint8List(0);

      if (compressedBytes.isEmpty) {
        throw Exception('Compression failed - empty result');
      }

      // Create temporary file for compressed image
      final String tempPath = imageFile.path.replaceAll(
        RegExp(r'\.[^.]+$'),
        '_compressed.jpg',
      );
      final File compressedFile = File(tempPath);
      await compressedFile.writeAsBytes(compressedBytes);

      _logger.i('Successfully compressed image: ${compressedFile.path}');
      return compressedFile;
    } catch (e) {
      _logger.e('Error compressing image: $e');
      rethrow;
    }
  }

  /// Convert image to WebP and compress it
  Future<File> convertAndCompressToWebP(
    File imageFile, {
    int quality = 85,
    int maxWidth = 1024,
    int maxHeight = 1024,
  }) async {
    try {
      _logger.i('Converting and compressing image to WebP: ${imageFile.path}');

      // First compress the image
      final File compressedFile = await compressImage(
        imageFile,
        quality: quality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

      // Then convert to WebP
      final File webpFile = await convertToWebP(
        compressedFile,
        quality: quality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

      // Clean up temporary compressed file
      await compressedFile.delete();

      _logger.i(
        'Successfully converted and compressed to WebP: ${webpFile.path}',
      );
      return webpFile;
    } catch (e) {
      _logger.e('Error converting and compressing to WebP: $e');
      rethrow;
    }
  }

  /// Get file size in bytes
  Future<int> getFileSize(File file) async {
    try {
      return await file.length();
    } catch (e) {
      _logger.e('Error getting file size: $e');
      return 0;
    }
  }

  /// Get file size in human readable format
  String getFileSizeString(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Check if file is already WebP format
  bool isWebPFormat(File file) {
    final String extension = file.path.split('.').last.toLowerCase();
    return extension == 'webp';
  }

  /// Check if file is an image format
  bool isImageFormat(File file) {
    final String extension = file.path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'].contains(extension);
  }

  /// Get image dimensions
  Future<Map<String, int>> getImageDimensions(File imageFile) async {
    try {
      final Uint8List imageBytes = await imageFile.readAsBytes();
      final img.Image? image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      return {'width': image.width, 'height': image.height};
    } catch (e) {
      _logger.e('Error getting image dimensions: $e');
      rethrow;
    }
  }

  /// Clean up temporary files
  Future<void> cleanupTempFiles(List<File> files) async {
    for (final File file in files) {
      try {
        if (await file.exists()) {
          await file.delete();
          _logger.d('Cleaned up temp file: ${file.path}');
        }
      } catch (e) {
        _logger.w('Failed to cleanup temp file: ${file.path}, error: $e');
      }
    }
  }
}
