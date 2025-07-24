import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_cache_model.dart';
import 'user_models.dart';

/// Service for managing profile data caching with Hive
/// Follows the same pattern as checklist caching
class ProfileCacheService {
  static const String _boxName = 'profiles';
  static const String _syncQueueBoxName = 'profile_sync_queue';

  /// Save profile to local cache
  Future<void> saveProfileToLocal(ProfileCacheModel profile) async {
    try {
      print(
        '[DEBUG] ProfileCacheService: Saving profile to Hive for UID: ${profile.uid}',
      );
      final box = await Hive.openBox(_boxName);
      await box.put(profile.uid, profile.toJson());
      print('[DEBUG] ProfileCacheService: Successfully saved profile to Hive');
    } catch (e) {
      print('[DEBUG] ProfileCacheService: Error saving profile to Hive: $e');
      rethrow;
    }
  }

  /// Load profile from local cache
  Future<ProfileCacheModel?> loadProfileFromLocal(String userId) async {
    try {
      print(
        '[DEBUG] ProfileCacheService: Loading profile from Hive for UID: $userId',
      );
      final box = await Hive.openBox(_boxName);
      final data = box.get(userId);

      if (data != null) {
        final profile = ProfileCacheModel.fromJson(
          Map<String, dynamic>.from(data),
        );
        print(
          '[DEBUG] ProfileCacheService: Successfully loaded profile from Hive',
        );
        return profile;
      } else {
        print(
          '[DEBUG] ProfileCacheService: No profile found in Hive for UID: $userId',
        );
        return null;
      }
    } catch (e) {
      print('[DEBUG] ProfileCacheService: Error loading profile from Hive: $e');
      return null;
    }
  }

  /// Clear profile from local cache
  Future<void> clearProfileFromLocal(String userId) async {
    try {
      print(
        '[DEBUG] ProfileCacheService: Clearing profile from Hive for UID: $userId',
      );
      final box = await Hive.openBox(_boxName);
      await box.delete(userId);
      print(
        '[DEBUG] ProfileCacheService: Successfully cleared profile from Hive',
      );
    } catch (e) {
      print(
        '[DEBUG] ProfileCacheService: Error clearing profile from Hive: $e',
      );
      rethrow;
    }
  }

  /// Clear all profiles from local cache
  Future<void> clearAllProfiles() async {
    try {
      print('[DEBUG] ProfileCacheService: Clearing ALL profiles from Hive');
      final box = await Hive.openBox(_boxName);
      await box.clear();
      print(
        '[DEBUG] ProfileCacheService: Successfully cleared ALL profiles from Hive',
      );
    } catch (e) {
      print(
        '[DEBUG] ProfileCacheService: Error clearing all profiles from Hive: $e',
      );
      rethrow;
    }
  }

  /// Load profile from Firestore
  Future<ProfileCacheModel?> loadProfileFromFirestore(String userId) async {
    try {
      print(
        '[DEBUG] ProfileCacheService: Loading profile from Firestore for UID: $userId',
      );
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      print('[DEBUG] ProfileCacheService: Document exists: ${doc.exists}');
      if (doc.exists) {
        final data = doc.data();
        print('[DEBUG] ProfileCacheService: Document data: $data');
        final profile = ProfileCacheModel.fromFirestore(doc);
        print(
          '[DEBUG] ProfileCacheService: Successfully loaded profile from Firestore',
        );
        return profile;
      } else {
        print(
          '[DEBUG] ProfileCacheService: No profile found in Firestore for UID: $userId',
        );
        return null;
      }
    } catch (e) {
      print(
        '[DEBUG] ProfileCacheService: Error loading profile from Firestore: $e',
      );
      rethrow;
    }
  }

  /// Update profile in Firestore
  Future<void> updateProfileInFirestore(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      print(
        '[DEBUG] ProfileCacheService: Updating profile in Firestore for UID: $userId',
      );
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print(
        '[DEBUG] ProfileCacheService: Successfully updated profile in Firestore',
      );
    } catch (e) {
      print(
        '[DEBUG] ProfileCacheService: Error updating profile in Firestore: $e',
      );
      rethrow;
    }
  }

  /// Add profile update to sync queue for offline scenarios
  Future<void> addToSyncQueue(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      print(
        '[DEBUG] ProfileCacheService: Adding to sync queue for UID: $userId',
      );
      final box = await Hive.openBox(_syncQueueBoxName);
      final queueKey = '${userId}_${DateTime.now().millisecondsSinceEpoch}';
      await box.put(queueKey, {
        'userId': userId,
        'updates': updates,
        'timestamp': DateTime.now().toIso8601String(),
      });
      print('[DEBUG] ProfileCacheService: Successfully added to sync queue');
    } catch (e) {
      print('[DEBUG] ProfileCacheService: Error adding to sync queue: $e');
      rethrow;
    }
  }

  /// Process sync queue when online
  Future<void> processSyncQueue() async {
    try {
      print('[DEBUG] ProfileCacheService: Processing sync queue');
      final box = await Hive.openBox(_syncQueueBoxName);
      final keys = box.keys.toList();

      for (final key in keys) {
        try {
          final data = box.get(key) as Map<String, dynamic>;
          final userId = data['userId'] as String;
          final updates = Map<String, dynamic>.from(data['updates']);

          await updateProfileInFirestore(userId, updates);
          await box.delete(key);
          print(
            '[DEBUG] ProfileCacheService: Successfully synced update for UID: $userId',
          );
        } catch (e) {
          print(
            '[DEBUG] ProfileCacheService: Error processing sync queue item: $e',
          );
          // Keep failed items in queue for retry
        }
      }
      print('[DEBUG] ProfileCacheService: Sync queue processing completed');
    } catch (e) {
      print('[DEBUG] ProfileCacheService: Error processing sync queue: $e');
      rethrow;
    }
  }

  /// Check if sync queue has pending items
  Future<bool> hasPendingSync() async {
    try {
      final box = await Hive.openBox(_syncQueueBoxName);
      return box.isNotEmpty;
    } catch (e) {
      print('[DEBUG] ProfileCacheService: Error checking sync queue: $e');
      return false;
    }
  }

  /// Convert UserDocument to ProfileCacheModel
  ProfileCacheModel userDocumentToCacheModel(UserDocument userDoc) {
    return ProfileCacheModel.fromUserDocument(userDoc);
  }
}
