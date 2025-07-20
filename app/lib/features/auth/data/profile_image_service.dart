import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import '../../../core/services/webp_image_service.dart';

class ProfileImageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();
  final WebPImageService _webpService = WebPImageService();

  /// Pick an image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick image from gallery: $e');
    }
  }

  /// Take a photo with camera
  Future<File?> takePhotoWithCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to take photo: $e');
    }
  }

  /// Upload image to Firebase Storage
  Future<String> uploadProfileImage(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      _logger.i('Uploading profile image: ${imageFile.path}');

      // Get original file size for logging
      final int originalSize = await _webpService.getFileSize(imageFile);
      _logger.i(
        'Original file size: ${_webpService.getFileSizeString(originalSize)}',
      );

      // Convert to WebP if not already WebP format
      File processedImage = imageFile;
      if (!_webpService.isWebPFormat(imageFile)) {
        _logger.i('Converting profile image to WebP format');
        processedImage = await _webpService.convertAndCompressToWebP(
          imageFile,
          quality: 85,
          maxWidth: 1024,
          maxHeight: 1024,
        );

        final int processedSize = await _webpService.getFileSize(
          processedImage,
        );
        _logger.i(
          'Processed file size: ${_webpService.getFileSizeString(processedSize)}',
        );
        _logger.i(
          'Size reduction: ${((originalSize - processedSize) / originalSize * 100).toStringAsFixed(1)}%',
        );
      }

      // Create a unique filename with WebP extension
      final fileName =
          'profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.webp';
      final storageRef = _storage.ref().child('profile_images/$fileName');

      // Upload the processed file
      final uploadTask = storageRef.putFile(processedImage);
      final snapshot = await uploadTask;

      // Get the download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Clean up temporary processed file if it's different from original
      if (processedImage.path != imageFile.path) {
        await _webpService.cleanupTempFiles([processedImage]);
      }

      _logger.i('Successfully uploaded profile image: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      _logger.e('Failed to upload profile image: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Delete old profile image from storage
  Future<void> deleteProfileImage(String imageUrl) async {
    try {
      if (imageUrl.isNotEmpty) {
        final ref = _storage.refFromURL(imageUrl);
        await ref.delete();
      }
    } catch (e) {
      // Don't throw error for deletion, just log it
      _logger.w('Failed to delete old profile image: $e');
    }
  }
}
