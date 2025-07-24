import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/profile_cache_service.dart';
import '../data/profile_cache_model.dart';
import 'profile_state.dart';

// Service provider
final profileCacheServiceProvider = Provider<ProfileCacheService>((ref) {
  return ProfileCacheService();
});

// Profile notifier provider
final profileNotifierProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
      final cacheService = ref.watch(profileCacheServiceProvider);
      return ProfileNotifier(cacheService);
    });

// Profile state provider
final profileStateProvider = Provider<ProfileState>((ref) {
  return ref.watch(profileNotifierProvider);
});

// Profile data provider (convenience)
final profileDataProvider = Provider<ProfileCacheModel?>((ref) {
  return ref.watch(profileStateProvider).profile;
});

// Profile status provider (convenience)
final profileStatusProvider = Provider<ProfileStatus>((ref) {
  return ref.watch(profileStateProvider).status;
});

// Profile loading state provider (convenience)
final profileLoadingProvider = Provider<bool>((ref) {
  return ref.watch(profileStateProvider).isLoading;
});

// Profile error provider (convenience)
final profileErrorProvider = Provider<String?>((ref) {
  return ref.watch(profileStateProvider).errorMessage;
});

// Profile offline state provider (convenience)
final profileOfflineProvider = Provider<bool>((ref) {
  return ref.watch(profileStateProvider).isOffline;
});

// Profile sync queue provider (convenience)
final profileSyncQueueProvider = Provider<bool>((ref) {
  return ref.watch(profileStateProvider).hasPendingSync;
});

// Profile display name provider (convenience)
final profileDisplayNameProvider = Provider<String>((ref) {
  final profile = ref.watch(profileDataProvider);
  return profile?.displayNameOrEmail ?? 'Anonymous User';
});

// Profile image URL provider (convenience)
final profileImageUrlProvider = Provider<String?>((ref) {
  final profile = ref.watch(profileDataProvider);
  return profile?.profileImageUrlOrPhotoURL;
});

// Profile preferences provider (convenience)
final profilePreferencesProvider = Provider<Map<String, dynamic>>((ref) {
  final profile = ref.watch(profileDataProvider);
  return profile?.preferences ?? {};
});

// Profile stats provider (convenience)
final profileStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final profile = ref.watch(profileDataProvider);
  return profile?.stats ?? {};
});

// Profile subscription provider (convenience)
final profileSubscriptionProvider = Provider<Map<String, dynamic>>((ref) {
  final profile = ref.watch(profileDataProvider);
  return profile?.subscription ?? {};
});

// Profile usage provider (convenience)
final profileUsageProvider = Provider<Map<String, int>>((ref) {
  final profile = ref.watch(profileDataProvider);
  return profile?.usage ?? {'checklistsCreated': 0, 'sessionsCompleted': 0};
});
