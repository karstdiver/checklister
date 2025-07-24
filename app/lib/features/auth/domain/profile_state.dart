import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../data/profile_cache_model.dart';
import '../data/profile_cache_service.dart';

enum ProfileStatus { initial, loading, loaded, error, offline }

class ProfileState {
  final ProfileStatus status;
  final ProfileCacheModel? profile;
  final String? errorMessage;
  final bool isOffline;
  final bool hasPendingSync;

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.profile,
    this.errorMessage,
    this.isOffline = false,
    this.hasPendingSync = false,
  });

  ProfileState copyWith({
    ProfileStatus? status,
    ProfileCacheModel? profile,
    String? errorMessage,
    bool? isOffline,
    bool? hasPendingSync,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: errorMessage ?? this.errorMessage,
      isOffline: isOffline ?? this.isOffline,
      hasPendingSync: hasPendingSync ?? this.hasPendingSync,
    );
  }

  bool get isLoading => status == ProfileStatus.loading;
  bool get hasError => status == ProfileStatus.error;
  bool get isLoaded => status == ProfileStatus.loaded;
  bool get isInitial => status == ProfileStatus.initial;
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileCacheService _cacheService;

  ProfileNotifier(this._cacheService) : super(const ProfileState());

  /// Load profile for a user with offline-first strategy
  Future<void> loadProfile(
    String userId, {
    ConnectivityResult? connectivity,
    bool forceRemote = false,
  }) async {
    print(
      '[DEBUG] ProfileNotifier: loadProfile called for userId=$userId, connectivity=$connectivity, forceRemote=$forceRemote',
    );

    try {
      state = state.copyWith(status: ProfileStatus.loading);

      final conn = connectivity;
      print('[DEBUG] ProfileNotifier: Connectivity value = $conn');

      if (forceRemote) {
        print(
          '[DEBUG] ProfileNotifier: Forcing Firestore fetch (bypassing cache)',
        );
        try {
          final firestoreProfile = await _cacheService.loadProfileFromFirestore(
            userId,
          );
          if (firestoreProfile != null) {
            await _cacheService.saveProfileToLocal(firestoreProfile);
            print(
              '[DEBUG] ProfileNotifier: Saved profile to local cache (forceRemote)',
            );
            state = state.copyWith(
              status: ProfileStatus.loaded,
              profile: firestoreProfile,
              isOffline: false,
            );
            print(
              '[DEBUG] ProfileNotifier: Set state to loaded (Firestore, forceRemote)',
            );
          } else {
            state = state.copyWith(
              status: ProfileStatus.error,
              errorMessage: 'Profile not found',
              isOffline: false,
            );
            print(
              '[DEBUG] ProfileNotifier: Set state to error (not found, forceRemote)',
            );
          }
        } catch (firestoreError) {
          print(
            '[DEBUG] ProfileNotifier: Firestore load failed (forceRemote): $firestoreError',
          );
          state = state.copyWith(
            status: ProfileStatus.error,
            errorMessage: 'Failed to load profile: $firestoreError',
            isOffline: false,
          );
          print(
            '[DEBUG] ProfileNotifier: Set state to error (Firestore failed, forceRemote)',
          );
        }
        return;
      }

      // Always try local first
      try {
        final localProfile = await _cacheService.loadProfileFromLocal(userId);
        print(
          '[DEBUG] ProfileNotifier: Local profile result: ${localProfile != null ? "found" : "not found"}',
        );

        if (localProfile != null) {
          // Local data available, use it immediately
          state = state.copyWith(
            status: ProfileStatus.loaded,
            profile: localProfile,
            isOffline: conn == ConnectivityResult.none,
          );
          print('[DEBUG] ProfileNotifier: Set state to loaded (local)');

          // If online, try to sync in background (disabled to prevent infinite loops)
          // if (conn != ConnectivityResult.none) {
          //   _syncInBackground(userId);
          // }
        } else if (conn != ConnectivityResult.none) {
          // No local data but online, try Firestore
          print('[DEBUG] ProfileNotifier: No local data, trying Firestore...');
          try {
            final firestoreProfile = await _cacheService
                .loadProfileFromFirestore(userId);
            if (firestoreProfile != null) {
              // Save to local cache
              await _cacheService.saveProfileToLocal(firestoreProfile);
              print('[DEBUG] ProfileNotifier: Saved profile to local cache');

              state = state.copyWith(
                status: ProfileStatus.loaded,
                profile: firestoreProfile,
                isOffline: false,
              );
              print('[DEBUG] ProfileNotifier: Set state to loaded (Firestore)');
            } else {
              // No profile found anywhere
              state = state.copyWith(
                status: ProfileStatus.error,
                errorMessage: 'Profile not found',
                isOffline: false,
              );
              print('[DEBUG] ProfileNotifier: Set state to error (not found)');
            }
          } catch (firestoreError) {
            print(
              '[DEBUG] ProfileNotifier: Firestore load failed: $firestoreError',
            );
            state = state.copyWith(
              status: ProfileStatus.error,
              errorMessage: 'Failed to load profile: $firestoreError',
              isOffline: false,
            );
            print(
              '[DEBUG] ProfileNotifier: Set state to error (Firestore failed)',
            );
          }
        } else {
          // Offline and no local data
          state = state.copyWith(
            status: ProfileStatus.offline,
            isOffline: true,
          );
          print(
            '[DEBUG] ProfileNotifier: Set state to offline (no local data)',
          );
        }
      } catch (localError) {
        print('[DEBUG] ProfileNotifier: Local load failed: $localError');

        // If local fails and online, try Firestore
        if (conn != ConnectivityResult.none) {
          try {
            print(
              '[DEBUG] ProfileNotifier: Trying Firestore after local failure...',
            );
            final firestoreProfile = await _cacheService
                .loadProfileFromFirestore(userId);
            if (firestoreProfile != null) {
              await _cacheService.saveProfileToLocal(firestoreProfile);
              state = state.copyWith(
                status: ProfileStatus.loaded,
                profile: firestoreProfile,
                isOffline: false,
              );
              print(
                '[DEBUG] ProfileNotifier: Set state to loaded (Firestore fallback)',
              );
            } else {
              state = state.copyWith(
                status: ProfileStatus.error,
                errorMessage: 'Profile not found',
                isOffline: false,
              );
              print('[DEBUG] ProfileNotifier: Set state to error (not found)');
            }
          } catch (firestoreError) {
            print(
              '[DEBUG] ProfileNotifier: Firestore fallback failed: $firestoreError',
            );
            state = state.copyWith(
              status: ProfileStatus.error,
              errorMessage: 'Failed to load profile: $firestoreError',
              isOffline: false,
            );
            print('[DEBUG] ProfileNotifier: Set state to error (both failed)');
          }
        } else {
          // Offline and local failed
          state = state.copyWith(
            status: ProfileStatus.offline,
            isOffline: true,
          );
          print('[DEBUG] ProfileNotifier: Set state to offline (local failed)');
        }
      }
    } catch (error) {
      print('[DEBUG] ProfileNotifier: Unexpected error: $error');
      state = state.copyWith(
        status: ProfileStatus.error,
        errorMessage: 'Unexpected error: $error',
      );
    }
  }

  /// Update profile data
  Future<void> updateProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    print('[DEBUG] ProfileNotifier: updateProfile called for userId=$userId');

    if (state.profile == null) {
      print('[DEBUG] ProfileNotifier: No profile to update');
      return;
    }

    try {
      // Update local cache immediately
      final updatedProfile = state.profile!.copyWith(updatedAt: DateTime.now());

      // Apply updates to the profile
      final newProfile = _applyUpdates(updatedProfile, updates);

      // Save to local cache
      await _cacheService.saveProfileToLocal(newProfile);

      // Update state immediately
      state = state.copyWith(profile: newProfile);
      print('[DEBUG] ProfileNotifier: Updated local profile');

      // Try to sync to Firestore
      try {
        await _cacheService.updateProfileInFirestore(userId, updates);
        print('[DEBUG] ProfileNotifier: Successfully synced to Firestore');
      } catch (e) {
        print(
          '[DEBUG] ProfileNotifier: Firestore sync failed, adding to queue: $e',
        );
        // Add to sync queue for later
        await _cacheService.addToSyncQueue(userId, updates);
        state = state.copyWith(hasPendingSync: true);
      }
    } catch (e) {
      print('[DEBUG] ProfileNotifier: Error updating profile: $e');
      state = state.copyWith(
        status: ProfileStatus.error,
        errorMessage: 'Failed to update profile: $e',
      );
    }
  }

  /// Sync profile from Firestore (refresh)
  Future<void> refreshFromFirestore(String userId) async {
    print(
      '[DEBUG] ProfileNotifier: refreshFromFirestore called for userId=$userId',
    );

    try {
      state = state.copyWith(status: ProfileStatus.loading);

      final profile = await _cacheService.loadProfileFromFirestore(userId);
      if (profile != null) {
        await _cacheService.saveProfileToLocal(profile);
        state = state.copyWith(
          status: ProfileStatus.loaded,
          profile: profile,
          isOffline: false,
        );
        print('[DEBUG] ProfileNotifier: Successfully refreshed from Firestore');
      } else {
        state = state.copyWith(
          status: ProfileStatus.error,
          errorMessage: 'Profile not found in Firestore',
        );
        print('[DEBUG] ProfileNotifier: Profile not found in Firestore');
      }
    } catch (e) {
      print('[DEBUG] ProfileNotifier: Error refreshing from Firestore: $e');
      state = state.copyWith(
        status: ProfileStatus.error,
        errorMessage: 'Failed to refresh profile: $e',
      );
    }
  }

  /// Process pending sync queue
  Future<void> processSyncQueue() async {
    print('[DEBUG] ProfileNotifier: processSyncQueue called');

    try {
      await _cacheService.processSyncQueue();
      final hasPending = await _cacheService.hasPendingSync();
      state = state.copyWith(hasPendingSync: hasPending);
      print(
        '[DEBUG] ProfileNotifier: Sync queue processed, hasPending: $hasPending',
      );
    } catch (e) {
      print('[DEBUG] ProfileNotifier: Error processing sync queue: $e');
    }
  }

  /// Clear profile data (for logout)
  Future<void> clearProfile() async {
    print('[DEBUG] ProfileNotifier: clearProfile called');

    if (state.profile != null) {
      await _cacheService.clearProfileFromLocal(state.profile!.uid);
    }

    state = const ProfileState();
    print('[DEBUG] ProfileNotifier: Profile cleared');
  }

  /// Clear all profiles (for multi-user cleanup)
  Future<void> clearAllProfiles() async {
    print('[DEBUG] ProfileNotifier: clearAllProfiles called');

    await _cacheService.clearAllProfiles();
    state = const ProfileState();
    print('[DEBUG] ProfileNotifier: All profiles cleared');
  }

  /// Background sync when online
  Future<void> _syncInBackground(String userId) async {
    try {
      print('[DEBUG] ProfileNotifier: Background sync for userId=$userId');
      final profile = await _cacheService.loadProfileFromFirestore(userId);
      if (profile != null) {
        await _cacheService.saveProfileToLocal(profile);
        state = state.copyWith(profile: profile);
        print('[DEBUG] ProfileNotifier: Background sync completed');
      }
    } catch (e) {
      print('[DEBUG] ProfileNotifier: Background sync failed: $e');
    }
  }

  /// Apply updates to profile model
  ProfileCacheModel _applyUpdates(
    ProfileCacheModel profile,
    Map<String, dynamic> updates,
  ) {
    return profile.copyWith(
      displayName: updates['displayName'] ?? profile.displayName,
      email: updates['email'] ?? profile.email,
      photoURL: updates['photoURL'] ?? profile.photoURL,
      profileImageUrl: updates['profileImageUrl'] ?? profile.profileImageUrl,
      preferences: updates['preferences'] ?? profile.preferences,
      stats: updates['stats'] ?? profile.stats,
      subscription: updates['subscription'] ?? profile.subscription,
      usage: updates['usage'] != null
          ? Map<String, int>.from(updates['usage'])
          : profile.usage,
    );
  }
}
