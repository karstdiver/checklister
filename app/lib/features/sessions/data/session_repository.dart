import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/session_state.dart';

class SessionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save session to Firestore
  Future<void> saveSession(SessionState session) async {
    try {
      await _firestore
          .collection('sessions')
          .doc(session.sessionId)
          .set(_sessionToMap(session));
    } catch (e) {
      throw Exception('Failed to save session: $e');
    }
  }

  // Get session by ID
  Future<SessionState?> getSession(String sessionId) async {
    try {
      final doc = await _firestore.collection('sessions').doc(sessionId).get();

      if (doc.exists) {
        return _mapToSession(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get session: $e');
    }
  }

  // Get user's active sessions
  Future<List<SessionState>> getUserSessions(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('sessions')
          .where('userId', isEqualTo: userId)
          .get();

      final sessions = querySnapshot.docs
          .map((doc) => _mapToSession(doc.data()))
          .toList();

      // Sort by startedAt descending in memory
      sessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));

      return sessions;
    } catch (e) {
      throw Exception('Failed to get user sessions: $e');
    }
  }

  // Get active sessions for a checklist
  Future<List<SessionState>> getChecklistSessions(String checklistId) async {
    try {
      final querySnapshot = await _firestore
          .collection('sessions')
          .where('checklistId', isEqualTo: checklistId)
          .where('status', whereIn: ['inProgress', 'paused'])
          .get();

      final sessions = querySnapshot.docs
          .map((doc) => _mapToSession(doc.data()))
          .toList();

      // Sort by startedAt descending in memory
      sessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));

      return sessions;
    } catch (e) {
      throw Exception('Failed to get checklist sessions: $e');
    }
  }

  // Delete session
  Future<void> deleteSession(String sessionId) async {
    try {
      await _firestore.collection('sessions').doc(sessionId).delete();
    } catch (e) {
      throw Exception('Failed to delete session: $e');
    }
  }

  // Convert SessionState to Map for Firestore
  Map<String, dynamic> _sessionToMap(SessionState session) {
    return {
      'sessionId': session.sessionId,
      'checklistId': session.checklistId,
      'userId': session.userId,
      'status': session.status.name,
      'items': session.items.map((item) => _itemToMap(item)).toList(),
      'currentItemIndex': session.currentItemIndex,
      'startedAt': Timestamp.fromDate(session.startedAt),
      'pausedAt': session.pausedAt != null
          ? Timestamp.fromDate(session.pausedAt!)
          : null,
      'completedAt': session.completedAt != null
          ? Timestamp.fromDate(session.completedAt!)
          : null,
      'totalDuration': session.totalDuration.inMilliseconds,
      'activeDuration': session.activeDuration.inMilliseconds,
      'metadata': session.metadata,
    };
  }

  // Convert Map from Firestore to SessionState
  SessionState _mapToSession(Map<String, dynamic> map) {
    return SessionState(
      sessionId: map['sessionId'],
      checklistId: map['checklistId'],
      userId: map['userId'],
      status: SessionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => SessionStatus.notStarted,
      ),
      items: (map['items'] as List).map((item) => _mapToItem(item)).toList(),
      currentItemIndex: map['currentItemIndex'],
      startedAt: (map['startedAt'] as Timestamp).toDate(),
      pausedAt: map['pausedAt'] != null
          ? (map['pausedAt'] as Timestamp).toDate()
          : null,
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
      totalDuration: Duration(milliseconds: map['totalDuration']),
      activeDuration: Duration(milliseconds: map['activeDuration']),
      metadata: Map<String, dynamic>.from(map['metadata']),
    );
  }

  // Convert ChecklistItem to Map
  Map<String, dynamic> _itemToMap(ChecklistItem item) {
    return {
      'id': item.id,
      'text': item.text,
      'imageUrl': item.imageUrl,
      'status': item.status.name,
      'completedAt': item.completedAt != null
          ? Timestamp.fromDate(item.completedAt!)
          : null,
      'skippedAt': item.skippedAt != null
          ? Timestamp.fromDate(item.skippedAt!)
          : null,
      'notes': item.notes,
    };
  }

  // Convert Map to ChecklistItem
  ChecklistItem _mapToItem(Map<String, dynamic> map) {
    return ChecklistItem(
      id: map['id'],
      text: map['text'],
      imageUrl: map['imageUrl'],
      status: ItemStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ItemStatus.pending,
      ),
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
      skippedAt: map['skippedAt'] != null
          ? (map['skippedAt'] as Timestamp).toDate()
          : null,
      notes: map['notes'],
    );
  }
}
