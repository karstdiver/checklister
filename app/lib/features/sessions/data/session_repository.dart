import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../domain/session_state.dart';

final logger = Logger();

class SessionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Helper function to parse Firestore Timestamp or ISO8601 string
  // This can be used in SessionState.fromMap if needed
  DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) {
      throw Exception('Timestamp is null');
    }

    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is String) {
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        logger.e('Failed to parse timestamp string: $timestamp', error: e);
        throw Exception('Failed to parse timestamp string: $timestamp');
      }
    } else {
      logger.e(
        'Unexpected timestamp type: ${timestamp.runtimeType}',
        error: timestamp,
      );
      throw Exception('Unexpected timestamp type: ${timestamp.runtimeType}');
    }
  }

  Future<void> saveSession(SessionState session) async {
    try {
      await _firestore
          .collection('sessions')
          .doc(session.sessionId)
          .set(session.toMap());
      logger.i('💾 Session saved successfully to Firestore');
    } catch (e) {
      logger.e('💾 Error saving session to Firestore: $e');
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
