import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:checklister/features/auth/data/profile_image_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:checklister/firebase_options.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (_) {
      // Ignore if already initialized in this test run
    }
  });

  group('ProfileImageService', () {
    late ProfileImageService service;

    setUp(() {
      service = ProfileImageService();
    });

    test('should be instantiated correctly', () {
      expect(service, isNotNull);
      expect(service, isA<ProfileImageService>());
    });

    test('should have required methods', () {
      expect(service.pickImageFromGallery, isA<Function>());
      expect(service.takePhotoWithCamera, isA<Function>());
      expect(service.uploadProfileImage, isA<Function>());
      expect(service.deleteProfileImage, isA<Function>());
    });

    test('should have correct return types', () {
      // These methods return Future<File?> for picking
      expect(service.pickImageFromGallery, isA<Future<File?> Function()>());
      expect(service.takePhotoWithCamera, isA<Future<File?> Function()>());

      // These methods return Future<String> and Future<void> for upload/delete
      expect(service.uploadProfileImage, isA<Future<String> Function(File)>());
      expect(service.deleteProfileImage, isA<Future<void> Function(String)>());
    });

    // Note: These tests would require mocking the image picker, Firebase Auth,
    // and Firebase Storage for full integration testing. The current tests
    // verify the service structure and method signatures.
  });
}
