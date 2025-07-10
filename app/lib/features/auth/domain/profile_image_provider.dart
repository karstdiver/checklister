import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/profile_image_provider.dart';
import 'profile_image_notifier.dart';

final profileImageNotifierProvider =
    StateNotifierProvider<ProfileImageNotifier, ProfileImageState>((ref) {
      final imageService = ref.watch(profileImageServiceProvider);
      return ProfileImageNotifier(
        imageService,
        FirebaseFirestore.instance,
        FirebaseAuth.instance,
      );
    });
