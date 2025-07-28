import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../domain/session_state.dart';
import '../../../core/constants/ttl_config.dart';
import '../../../core/domain/user_tier.dart';

final logger = Logger();

class SessionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveSession(SessionState session, {UserTier? userTier}) async {
    try {
      // Prepare session data
      final sessionData = session.toMap();

      // Add Firestore native TTL if user tier is provided and TTL should be enabled
      if (userTier != null && TTLConfig.shouldEnableNativeTTL(userTier)) {
        final ttl = TTLConfig.calculateFirestoreTTL(userTier);
        if (ttl != null) {
          sessionData['ttl'] = ttl;
          logger.d(
            '🕒 Set Firestore native TTL for session ${session.sessionId}: ${ttl.toDate()}',
          );
        }
      }

      await _firestore
          .collection('sessions')
          .doc(session.sessionId)
          .set(sessionData);
      logger.i('💾 Session saved successfully to Firestore');
    } catch (e) {
      logger.e('💾 Error saving session to Firestore: $e');
      rethrow;
    }
  }

  Future<void> updateSessionTTL(String sessionId, UserTier userTier) async {
    try {
      if (TTLConfig.shouldEnableNativeTTL(userTier)) {
        final ttl = TTLConfig.calculateFirestoreTTL(userTier);
        if (ttl != null) {
          await _firestore.collection('sessions').doc(sessionId).update({
            'ttl': ttl,
          });
          logger.d(
            '🕒 Updated Firestore native TTL for session $sessionId: ${ttl.toDate()}',
          );
        }
      } else {
        // Remove TTL for unlimited tiers
        await _firestore.collection('sessions').doc(sessionId).update({
          'ttl': FieldValue.delete(),
        });
        logger.d(
          '🕒 Removed Firestore native TTL for session $sessionId (unlimited tier)',
        );
      }
    } catch (e) {
      logger.e('❌ Error updating session TTL: $e');
      rethrow;
    }
  }

  Future<SessionState?> getSession(String sessionId) async {
    try {
      final doc = await _firestore.collection('sessions').doc(sessionId).get();
      if (doc.exists) {
        try {
          return SessionState.fromMap(doc.data()!);
        } catch (e) {
          logger.e('Error parsing session document $sessionId: $e');
          logger.d('Document data: ${doc.data()}');
          rethrow;
        }
      }
      return null;
    } catch (e) {
      logger.e('Error getting session: $e');
      return null;
    }
  }

  Future<List<SessionState>> getUserSessions(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('sessions')
          .where('userId', isEqualTo: userId)
          .get();

      final sessions = querySnapshot.docs.map((doc) {
        try {
          return SessionState.fromMap(doc.data());
        } catch (e) {
          logger.e('Error parsing session document ${doc.id}: $e');
          logger.d('Document data: ${doc.data()}');
          rethrow;
        }
      }).toList();

      // Sort by startedAt descending in memory
      // Note: For better performance in production, create a composite index:
      // Collection: sessions, Fields: userId (Ascending), startedAt (Descending)
      sessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));

      return sessions;
    } catch (e) {
      logger.e('Error getting user sessions: $e');
      return [];
    }
  }

  Future<List<SessionState>> getChecklistSessions(String checklistId) async {
    try {
      final querySnapshot = await _firestore
          .collection('sessions')
          .where('checklistId', isEqualTo: checklistId)
          .where('status', whereIn: ['inProgress', 'paused'])
          .get();

      final sessions = querySnapshot.docs.map((doc) {
        try {
          return SessionState.fromMap(doc.data());
        } catch (e) {
          logger.e('Error parsing session document ${doc.id}: $e');
          logger.d('Document data: ${doc.data()}');
          rethrow;
        }
      }).toList();

      // Sort by startedAt descending in memory
      sessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));

      return sessions;
    } catch (e) {
      logger.e('Error getting checklist sessions: $e');
      return [];
    }
  }

  Future<void> deleteSession(String sessionId) async {
    try {
      await _firestore.collection('sessions').doc(sessionId).delete();
      logger.i('Session deleted successfully');
    } catch (e) {
      logger.e('Error deleting session: $e');
      rethrow;
    }
  }
}
