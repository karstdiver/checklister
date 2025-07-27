import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:checklister/core/constants/ttl_config.dart';
import 'package:checklister/core/domain/user_tier.dart';
import 'package:checklister/features/sessions/domain/session_state.dart';
import 'package:checklister/features/checklists/domain/checklist.dart';
import 'package:logger/logger.dart';

/// Service for handling TTL (Time To Live) cleanup of expired documents
class TTLCleanupService {
  static final Logger _logger = Logger();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Clean up expired sessions for a specific user tier
  static Future<int> cleanupExpiredSessions(UserTier userTier) async {
    try {
      _logger.i(
        '🧹 Starting TTL cleanup for sessions (tier: ${userTier.name})',
      );

      // Get TTL configuration for this tier
      final ttlDays = TTLConfig.getTTLDaysForTier(userTier);
      if (TTLConfig.hasUnlimitedTTL(userTier)) {
        _logger.i(
          '⏭️ Skipping cleanup for unlimited TTL tier: ${userTier.name}',
        );
        return 0;
      }

      // Calculate cutoff date
      final cutoffDate = DateTime.now().subtract(Duration(days: ttlDays));
      _logger.i(
        '📅 Cutoff date for cleanup: $cutoffDate (${ttlDays} days ago)',
      );

      // Query for expired sessions
      final querySnapshot = await _firestore
          .collection('sessions')
          .where('expiresAt', isLessThan: Timestamp.fromDate(DateTime.now()))
          .get();

      final expiredSessions = querySnapshot.docs
          .map((doc) => SessionState.fromMap(doc.data()))
          .where((session) => session.expiresAt != null)
          .where((session) => TTLConfig.isExpired(session.expiresAt))
          .toList();

      _logger.i('📊 Found ${expiredSessions.length} expired sessions');

      // Delete expired sessions
      int deletedCount = 0;
      for (final session in expiredSessions) {
        try {
          await _firestore
              .collection('sessions')
              .doc(session.sessionId)
              .delete();
          deletedCount++;
          _logger.d('🗑️ Deleted expired session: ${session.sessionId}');
        } catch (e) {
          _logger.e('❌ Failed to delete session ${session.sessionId}: $e');
        }
      }

      _logger.i('✅ TTL cleanup completed: $deletedCount sessions deleted');
      return deletedCount;
    } catch (e) {
      _logger.e('❌ Error during TTL cleanup: $e');
      return 0;
    }
  }

  /// Clean up expired checklists for a specific user tier
  static Future<int> cleanupExpiredChecklists(UserTier userTier) async {
    try {
      _logger.i(
        '🧹 Starting TTL cleanup for checklists (tier: ${userTier.name})',
      );

      // Get TTL configuration for this tier
      final ttlDays = TTLConfig.getTTLDaysForTier(userTier);
      if (TTLConfig.hasUnlimitedTTL(userTier)) {
        _logger.i(
          '⏭️ Skipping cleanup for unlimited TTL tier: ${userTier.name}',
        );
        return 0;
      }

      // Calculate cutoff date
      final cutoffDate = DateTime.now().subtract(Duration(days: ttlDays));
      _logger.i(
        '📅 Cutoff date for cleanup: $cutoffDate (${ttlDays} days ago)',
      );

      // Query for expired checklists
      final querySnapshot = await _firestore
          .collection('checklists')
          .where('expiresAt', isLessThan: Timestamp.fromDate(DateTime.now()))
          .get();

      final expiredChecklists = querySnapshot.docs
          .map((doc) => Checklist.fromFirestore(doc))
          .where((checklist) => checklist.expiresAt != null)
          .where((checklist) => TTLConfig.isExpired(checklist.expiresAt))
          .toList();

      _logger.i('📊 Found ${expiredChecklists.length} expired checklists');

      // Delete expired checklists
      int deletedCount = 0;
      for (final checklist in expiredChecklists) {
        try {
          await _firestore.collection('checklists').doc(checklist.id).delete();
          deletedCount++;
          _logger.d('🗑️ Deleted expired checklist: ${checklist.id}');
        } catch (e) {
          _logger.e('❌ Failed to delete checklist ${checklist.id}: $e');
        }
      }

      _logger.i('✅ TTL cleanup completed: $deletedCount checklists deleted');
      return deletedCount;
    } catch (e) {
      _logger.e('❌ Error during TTL cleanup: $e');
      return 0;
    }
  }

  /// Clean up all expired documents for all user tiers
  static Future<Map<String, int>> cleanupAllExpiredDocuments() async {
    final results = <String, int>{};

    for (final tier in UserTier.values) {
      final sessionCount = await cleanupExpiredSessions(tier);
      final checklistCount = await cleanupExpiredChecklists(tier);

      results['${tier.name}_sessions'] = sessionCount;
      results['${tier.name}_checklists'] = checklistCount;
    }

    _logger.i('🎯 TTL cleanup summary: $results');
    return results;
  }

  /// Update lastActiveAt timestamp for a session
  static Future<void> updateSessionLastActive(String sessionId) async {
    try {
      await _firestore.collection('sessions').doc(sessionId).update({
        'lastActiveAt': Timestamp.fromDate(DateTime.now()),
      });
      _logger.d('🔄 Updated lastActiveAt for session: $sessionId');
    } catch (e) {
      _logger.e('❌ Failed to update lastActiveAt for session $sessionId: $e');
    }
  }

  /// Update lastActiveAt timestamp for a checklist
  static Future<void> updateChecklistLastActive(String checklistId) async {
    try {
      await _firestore.collection('checklists').doc(checklistId).update({
        'lastActiveAt': Timestamp.fromDate(DateTime.now()),
      });
      _logger.d('🔄 Updated lastActiveAt for checklist: $checklistId');
    } catch (e) {
      _logger.e(
        '❌ Failed to update lastActiveAt for checklist $checklistId: $e',
      );
    }
  }
}
