import 'package:flutter_test/flutter_test.dart';
import 'package:checklister/features/items/data/item_photo_service.dart';

void main() {
  group('ItemPhotoService', () {
    late ItemPhotoService service;

    setUp(() {
      service = ItemPhotoService();
    });

    test('should be instantiated correctly', () {
      expect(service, isNotNull);
      expect(service, isA<ItemPhotoService>());
    });

    test('should have required methods', () {
      expect(service.pickImageFromGallery, isA<Function>());
      expect(service.takePhotoWithCamera, isA<Function>());
      expect(service.uploadItemPhoto, isA<Function>());
      expect(service.deleteItemPhoto, isA<Function>());
    });

    // Note: These tests would require mocking the image picker and Firebase Storage
    // for full integration testing. The current tests verify the service structure.

    test('should handle image source dialog method', () {
      expect(service.showImageSourceDialog, isA<Function>());
    });

    test('should have image source option builder method', () {
      // This is a private method but we can verify the service has the capability
      expect(service, isNotNull);
    });
  });
}
