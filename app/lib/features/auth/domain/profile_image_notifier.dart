import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/profile_image_service.dart';

enum ProfileImageState { idle, loading, success, error }

class ProfileImageNotifier extends StateNotifier<ProfileImageState> {
  final ProfileImageService _imageService;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ProfileImageNotifier(this._imageService, this._firestore, this._auth)
    : super(ProfileImageState.idle);

  /// Pick image from gallery and upload
  Future<void> pickAndUploadFromGallery() async {
    try {
      state = ProfileImageState.loading;

      // Pick image from gallery
      final File? imageFile = await _imageService.pickImageFromGallery();
      if (imageFile == null) {
        state = ProfileImageState.idle;
        return;
      }

      // Upload to Firebase Storage
      final String imageUrl = await _imageService.uploadProfileImage(imageFile);

      // Update user profile in Firestore
      await _updateUserProfileImage(imageUrl);

      state = ProfileImageState.success;
    } catch (e) {
      state = ProfileImageState.error;
      rethrow;
    }
  }

  /// Take photo with camera and upload
  Future<void> takePhotoAndUpload() async {
    try {
      state = ProfileImageState.loading;

      // Take photo with camera
      final File? imageFile = await _imageService.takePhotoWithCamera();
      if (imageFile == null) {
        state = ProfileImageState.idle;
        return;
      }

      // Upload to Firebase Storage
      final String imageUrl = await _imageService.uploadProfileImage(imageFile);

      // Update user profile in Firestore
      await _updateUserProfileImage(imageUrl);

      state = ProfileImageState.success;
    } catch (e) {
      state = ProfileImageState.error;
      rethrow;
    }
  }

  /// Update user profile image in Firestore
  Future<void> _updateUserProfileImage(String imageUrl) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Get current user data to preserve existing profile image URL for deletion
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final currentImageUrl = userDoc.data()?['profileImageUrl'] ?? '';

    // Update Firestore with new image URL
    await _firestore.collection('users').doc(user.uid).update({
      'profileImageUrl': imageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    print(
      '[DEBUG] ProfileImageNotifier: Updated Firestore with new profileImageUrl: $imageUrl',
    );

    // Delete old profile image from storage
    if (currentImageUrl.isNotEmpty) {
      await _imageService.deleteProfileImage(currentImageUrl);
    }
  }

  /// Reset state to idle
  void resetState() {
    state = ProfileImageState.idle;
  }
}
