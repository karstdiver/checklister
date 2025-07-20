import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:checklister/core/services/webp_image_service.dart';

void main() {
  group('WebPImageService', () {
    late WebPImageService service;

    setUp(() {
      service = WebPImageService();
    });

    test('should be instantiated correctly', () {
      expect(service, isNotNull);
      expect(service, isA<WebPImageService>());
    });

    test('should have required methods', () {
      expect(service.convertToWebP, isA<Function>());
      expect(service.compressImage, isA<Function>());
      expect(service.convertAndCompressToWebP, isA<Function>());
      expect(service.getFileSize, isA<Function>());
      expect(service.getFileSizeString, isA<Function>());
      expect(service.isWebPFormat, isA<Function>());
      expect(service.isImageFormat, isA<Function>());
      expect(service.getImageDimensions, isA<Function>());
      expect(service.cleanupTempFiles, isA<Function>());
    });

    test('should format file size correctly', () {
      expect(service.getFileSizeString(500), '500 B');
      expect(service.getFileSizeString(1024), '1.0 KB');
      expect(service.getFileSizeString(2048), '2.0 KB');
      expect(service.getFileSizeString(1024 * 1024), '1.0 MB');
      expect(service.getFileSizeString(2 * 1024 * 1024), '2.0 MB');
    });

    test('should detect WebP format correctly', () {
      final webpFile = File('test.webp');
      final jpgFile = File('test.jpg');
      final pngFile = File('test.png');

      expect(service.isWebPFormat(webpFile), isTrue);
      expect(service.isWebPFormat(jpgFile), isFalse);
      expect(service.isWebPFormat(pngFile), isFalse);
    });

    test('should detect image formats correctly', () {
      final webpFile = File('test.webp');
      final jpgFile = File('test.jpg');
      final jpegFile = File('test.jpeg');
      final pngFile = File('test.png');
      final gifFile = File('test.gif');
      final bmpFile = File('test.bmp');
      final txtFile = File('test.txt');

      expect(service.isImageFormat(webpFile), isTrue);
      expect(service.isImageFormat(jpgFile), isTrue);
      expect(service.isImageFormat(jpegFile), isTrue);
      expect(service.isImageFormat(pngFile), isTrue);
      expect(service.isImageFormat(gifFile), isTrue);
      expect(service.isImageFormat(bmpFile), isTrue);
      expect(service.isImageFormat(txtFile), isFalse);
    });

    test('should handle file size calculation', () async {
      // Create a temporary file for testing
      final tempFile = File('${Directory.systemTemp.path}/test_file.txt');
      await tempFile.writeAsString('test content');

      final size = await service.getFileSize(tempFile);
      expect(size, greaterThan(0));

      // Clean up
      await tempFile.delete();
    });

    // Note: These tests would require actual image files and mocking
    // for full integration testing. The current tests verify the service
    // structure and utility methods.
  });
}
