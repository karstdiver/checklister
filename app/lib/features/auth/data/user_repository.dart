// app/lib/features/auth/data/user_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_models.dart';
import '../../../core/domain/user_tier.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createUserDocument(User user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'emailVerified': user.emailVerified,
        'providerId': user.providerData.isNotEmpty
            ? user.providerData.first.providerId
            : 'anonymous',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
        // NEW: Admin role fields with default values
        'adminRole': 'none',
        'adminRoleAssignedBy': 'system',
        'adminRoleAssignedAt': FieldValue.serverTimestamp(),
        'adminRoleNotes': 'Default admin role assigned during user creation',
        'preferences': {
          'themeMode': 'system',
          'language': 'en_US',
          'notifications': {'email': true, 'push': true},
        },
        'stats': {
          'totalChecklists': 0,
          'completedChecklists': 0,
          'totalItems': 0,
          'completedItems': 0,
          'lastActivity': FieldValue.serverTimestamp(),
        },
        'subscription': {
          'tier': 'free',
          'status': 'active',
          'autoRenew': false,
        },
        'usage': {'checklistsCreated': 0, 'sessionsCompleted': 0},
      });
    } catch (e) {
      throw Exception('Failed to create user document: $e');
    }
  }

  Future<void> createUserDocumentIfNotExists(User user) async {
    try {
      print('🔍 DEBUG: Checking if user document exists for UID: ${user.uid}');
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        print('🔍 DEBUG: User document does not exist, creating...');
        await createUserDocument(user);
        print('🔍 DEBUG: User document created successfully');
      } else {
        print('🔍 DEBUG: User document already exists');
      }
    } catch (e) {
      print('🔍 DEBUG: Error in createUserDocumentIfNotExists: $e');
      throw Exception('Failed to create user document: $e');
    }
  }

  Future<void> createUserDocumentWithTier({
    required String userId,
    required UserTier tier,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'uid': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
        // NEW: Admin role fields with default values
        'adminRole': 'none',
        'adminRoleAssignedBy': 'system',
        'adminRoleAssignedAt': FieldValue.serverTimestamp(),
        'adminRoleNotes': 'Default admin role assigned during user creation',
        'preferences': {
          'themeMode': 'system',
          'language': 'en_US',
          'notifications': {'email': true, 'push': true},
        },
        'stats': {
          'totalChecklists': 0,
          'completedChecklists': 0,
          'totalItems': 0,
          'completedItems': 0,
          'lastActivity': FieldValue.serverTimestamp(),
        },
        'subscription': {
          'tier': tier.name,
          'status': 'active',
          'autoRenew': false,
        },
        'usage': {'checklistsCreated': 0, 'sessionsCompleted': 0},
      });
    } catch (e) {
      throw Exception('Failed to create user document with tier: $e');
    }
  }

  Future<UserDocument?> getUserDocument(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserDocument.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user document: $e');
    }
  }

  Future<void> updateUserUsage(String userId, Map<String, int> usage) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'usage': usage,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user usage: $e');
    }
  }

  Future<void> updateUserTier(String userId, UserTier tier) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'subscription.tier': tier.name,
        'subscription.status': 'active',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user tier: $e');
    }
  }

  Future<void> updateUserPreferences(
    String userId,
    Map<String, dynamic> preferences,
  ) async {
    try {
      print('🔍 DEBUG: Updating user preferences for UID: $userId');
      print('🔍 DEBUG: Preferences to update: $preferences');

      await _firestore.collection('users').doc(userId).update({
        'preferences': preferences,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('🔍 DEBUG: User preferences updated successfully');
    } catch (e) {
      print('🔍 DEBUG: Error updating user preferences: $e');
      throw Exception('Failed to update user preferences: $e');
    }
  }
}
