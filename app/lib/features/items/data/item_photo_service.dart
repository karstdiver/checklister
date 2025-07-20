import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import '../../../core/services/translation_service.dart';
import '../../../core/services/webp_image_service.dart';

class ItemPhotoService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
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

  /// Show image source selection dialog
  Future<File?> showImageSourceDialog(BuildContext context) async {
    final result = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              TranslationService.translate('select_image_source'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildImageSourceOption(
                    context,
                    icon: Icons.photo_library,
                    title: TranslationService.translate('gallery'),
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildImageSourceOption(
                    context,
                    icon: Icons.camera_alt,
                    title: TranslationService.translate('camera'),
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );

    if (result == ImageSource.gallery) {
      return await pickImageFromGallery();
    } else if (result == ImageSource.camera) {
      return await takePhotoWithCamera();
    }
    return null;
  }

  Widget _buildImageSourceOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
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

  /// Upload image to Firebase Storage for a checklist item
  Future<String> uploadItemPhoto(File imageFile, String itemId) async {
    try {
      _logger.i('Uploading item photo: ${imageFile.path}');

      // Get original file size for logging
      final int originalSize = await _webpService.getFileSize(imageFile);
      _logger.i(
        'Original file size: ${_webpService.getFileSizeString(originalSize)}',
      );

      // Convert to WebP if not already WebP format
      File processedImage = imageFile;
      if (!_webpService.isWebPFormat(imageFile)) {
        _logger.i('Converting image to WebP format');
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

      // Create filename with WebP extension
      final fileName =
          'item_${itemId}_${DateTime.now().millisecondsSinceEpoch}.webp';
      final storageRef = _storage.ref().child('item_photos/$fileName');

      // Upload the processed image
      final uploadTask = storageRef.putFile(processedImage);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Clean up temporary processed file if it's different from original
      if (processedImage.path != imageFile.path) {
        await _webpService.cleanupTempFiles([processedImage]);
      }

      _logger.i('Successfully uploaded item photo: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      _logger.e('Failed to upload item photo: $e');
      throw Exception('Failed to upload item photo: $e');
    }
  }

  /// Delete item photo from storage
  Future<void> deleteItemPhoto(String imageUrl) async {
    try {
      if (imageUrl.isNotEmpty) {
        final ref = _storage.refFromURL(imageUrl);
        await ref.delete();
      }
    } catch (e) {
      _logger.w('Failed to delete item photo: $e');
    }
  }
}
