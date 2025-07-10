import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'profile_image_service.dart';

final profileImageServiceProvider = Provider<ProfileImageService>((ref) {
  return ProfileImageService();
});
