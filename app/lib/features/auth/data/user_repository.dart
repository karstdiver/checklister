// app/lib/features/auth/data/user_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
        'preferences': {
          'themeMode': 'system',
          'language': 'en-US',
          'notifications': {'email': true, 'push': true},
        },
        'stats': {
          'totalChecklists': 0,
          'completedChecklists': 0,
          'totalItems': 0,
          'completedItems': 0,
          'lastActivity': FieldValue.serverTimestamp(),
        },
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
}
