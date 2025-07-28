import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:checklister/core/constants/ttl_config.dart';
import 'package:checklister/core/domain/user_tier.dart';
import 'package:checklister/features/sessions/domain/session_state.dart';
import 'package:checklister/features/checklists/domain/checklist.dart';
import 'package:logger/logger.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Service for handling TTL (Time To Live) cleanup of expired documents
class TTLCleanupService {
  static final Logger _logger = Logger();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Clean up expired sessions for a specific user tier with cascading delete
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

      // Delete expired sessions with cascading cleanup
      int deletedCount = 0;
      for (final session in expiredSessions) {
        try {
          // Perform cascading delete for session-related documents
          await _deleteSessionCascade(session.sessionId);

          // Delete the main session document
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

  /// Delete session-related documents to prevent orphans
  static Future<void> _deleteSessionCascade(String sessionId) async {
    try {
      // Delete session analytics (if they exist)
      await _deleteSessionAnalytics(sessionId);

      // Delete session media/photos (if they exist)
      await _deleteSessionMedia(sessionId);

      // Delete session achievements (if they exist)
      await _deleteSessionAchievements(sessionId);

      // Delete session comments/notes (if they exist)
      await _deleteSessionComments(sessionId);

      _logger.d('🔄 Cascading delete completed for session: $sessionId');
    } catch (e) {
      _logger.e('❌ Error during cascading delete for session $sessionId: $e');
    }
  }

  /// Delete session analytics documents
  static Future<void> _deleteSessionAnalytics(String sessionId) async {
    try {
      final analyticsQuery = await _firestore
          .collection('session_analytics')
          .where('sessionId', isEqualTo: sessionId)
          .get();

      for (final doc in analyticsQuery.docs) {
        await doc.reference.delete();
        _logger.d('🗑️ Deleted session analytics: ${doc.id}');
      }
    } catch (e) {
      // Collection might not exist, which is fine
      _logger.d('ℹ️ No session analytics to delete for session: $sessionId');
    }
  }

  /// Delete session media documents
  static Future<void> _deleteSessionMedia(String sessionId) async {
    try {
      final mediaQuery = await _firestore
          .collection('session_media')
          .where('sessionId', isEqualTo: sessionId)
          .get();

      for (final doc in mediaQuery.docs) {
        await doc.reference.delete();
        _logger.d('🗑️ Deleted session media: ${doc.id}');
      }
    } catch (e) {
      // Collection might not exist, which is fine
      _logger.d('ℹ️ No session media to delete for session: $sessionId');
    }
  }

  /// Delete session achievements documents
  static Future<void> _deleteSessionAchievements(String sessionId) async {
    try {
      final achievementsQuery = await _firestore
          .collection('session_achievements')
          .where('sessionId', isEqualTo: sessionId)
          .get();

      for (final doc in achievementsQuery.docs) {
        await doc.reference.delete();
        _logger.d('🗑️ Deleted session achievement: ${doc.id}');
      }
    } catch (e) {
      // Collection might not exist, which is fine
      _logger.d('ℹ️ No session achievements to delete for session: $sessionId');
    }
  }

  /// Delete session comments documents
  static Future<void> _deleteSessionComments(String sessionId) async {
    try {
      final commentsQuery = await _firestore
          .collection('session_comments')
          .where('sessionId', isEqualTo: sessionId)
          .get();

      for (final doc in commentsQuery.docs) {
        await doc.reference.delete();
        _logger.d('🗑️ Deleted session comment: ${doc.id}');
      }
    } catch (e) {
      // Collection might not exist, which is fine
      _logger.d('ℹ️ No session comments to delete for session: $sessionId');
    }
  }

  /// Clean up expired checklists for a specific user tier with cascading delete
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

      // Delete expired checklists with cascading cleanup
      int deletedCount = 0;
      for (final checklist in expiredChecklists) {
        try {
          // Perform cascading delete for checklist-related documents
          await _deleteChecklistCascade(checklist.id);

          // Delete the main checklist document
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

  /// Delete checklist-related documents to prevent orphans
  static Future<void> _deleteChecklistCascade(String checklistId) async {
    try {
      // Delete checklist media/photos (if they exist)
      await _deleteChecklistMedia(checklistId);

      // Delete checklist comments/notes (if they exist)
      await _deleteChecklistComments(checklistId);

      // Delete checklist sharing/invites (if they exist)
      await _deleteChecklistSharing(checklistId);

      // Delete checklist templates (if they exist)
      await _deleteChecklistTemplates(checklistId);

      _logger.d('🔄 Cascading delete completed for checklist: $checklistId');
    } catch (e) {
      _logger.e(
        '❌ Error during cascading delete for checklist $checklistId: $e',
      );
    }
  }

  /// Delete checklist media documents
  static Future<void> _deleteChecklistMedia(String checklistId) async {
    try {
      final mediaQuery = await _firestore
          .collection('checklist_media')
          .where('checklistId', isEqualTo: checklistId)
          .get();

      for (final doc in mediaQuery.docs) {
        await doc.reference.delete();
        _logger.d('🗑️ Deleted checklist media: ${doc.id}');
      }
    } catch (e) {
      // Collection might not exist, which is fine
      _logger.d('ℹ️ No checklist media to delete for checklist: $checklistId');
    }
  }

  /// Delete checklist comments documents
  static Future<void> _deleteChecklistComments(String checklistId) async {
    try {
      final commentsQuery = await _firestore
          .collection('checklist_comments')
          .where('checklistId', isEqualTo: checklistId)
          .get();

      for (final doc in commentsQuery.docs) {
        await doc.reference.delete();
        _logger.d('🗑️ Deleted checklist comment: ${doc.id}');
      }
    } catch (e) {
      // Collection might not exist, which is fine
      _logger.d(
        'ℹ️ No checklist comments to delete for checklist: $checklistId',
      );
    }
  }

  /// Delete checklist sharing documents
  static Future<void> _deleteChecklistSharing(String checklistId) async {
    try {
      final sharingQuery = await _firestore
          .collection('checklist_sharing')
          .where('checklistId', isEqualTo: checklistId)
          .get();

      for (final doc in sharingQuery.docs) {
        await doc.reference.delete();
        _logger.d('🗑️ Deleted checklist sharing: ${doc.id}');
      }
    } catch (e) {
      // Collection might not exist, which is fine
      _logger.d(
        'ℹ️ No checklist sharing to delete for checklist: $checklistId',
      );
    }
  }

  /// Delete checklist templates documents
  static Future<void> _deleteChecklistTemplates(String checklistId) async {
    try {
      final templatesQuery = await _firestore
          .collection('checklist_templates')
          .where('sourceChecklistId', isEqualTo: checklistId)
          .get();

      for (final doc in templatesQuery.docs) {
        await doc.reference.delete();
        _logger.d('🗑️ Deleted checklist template: ${doc.id}');
      }
    } catch (e) {
      // Collection might not exist, which is fine
      _logger.d(
        'ℹ️ No checklist templates to delete for checklist: $checklistId',
      );
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

  /// Trigger Cloud Function for cascading delete when TTL deletes a document
  static Future<void> triggerCascadingDelete(
    String documentId,
    String collectionName,
  ) async {
    try {
      // Call Cloud Function to handle cascading delete
      final httpsCallable = FirebaseFunctions.instance.httpsCallable(
        'cascadingDelete',
      );

      await httpsCallable.call({
        'documentId': documentId,
        'collectionName': collectionName,
        'timestamp': DateTime.now().toIso8601String(),
      });

      _logger.d(
        '🔄 Triggered cascading delete for $collectionName/$documentId',
      );
    } catch (e) {
      _logger.e('❌ Failed to trigger cascading delete: $e');
    }
  }

  /// Manual cleanup of orphaned documents (run periodically)
  static Future<Map<String, int>> cleanupOrphanedDocuments() async {
    final results = <String, int>{};

    try {
      _logger.i('🧹 Starting orphaned document cleanup');

      // Clean up orphaned session-related documents
      final orphanedSessionAnalytics = await _cleanupOrphanedSessionAnalytics();
      final orphanedSessionMedia = await _cleanupOrphanedSessionMedia();
      final orphanedSessionAchievements =
          await _cleanupOrphanedSessionAchievements();

      // Clean up orphaned checklist-related documents
      final orphanedChecklistMedia = await _cleanupOrphanedChecklistMedia();
      final orphanedChecklistComments =
          await _cleanupOrphanedChecklistComments();

      results['orphaned_session_analytics'] = orphanedSessionAnalytics;
      results['orphaned_session_media'] = orphanedSessionMedia;
      results['orphaned_session_achievements'] = orphanedSessionAchievements;
      results['orphaned_checklist_media'] = orphanedChecklistMedia;
      results['orphaned_checklist_comments'] = orphanedChecklistComments;

      _logger.i('✅ Orphaned document cleanup completed: $results');
    } catch (e) {
      _logger.e('❌ Error during orphaned document cleanup: $e');
    }

    return results;
  }

  /// Clean up orphaned session analytics
  static Future<int> _cleanupOrphanedSessionAnalytics() async {
    try {
      final analyticsQuery = await _firestore
          .collection('session_analytics')
          .get();
      int deletedCount = 0;

      for (final doc in analyticsQuery.docs) {
        final sessionId = doc.data()['sessionId'] as String?;
        if (sessionId != null) {
          final sessionDoc = await _firestore
              .collection('sessions')
              .doc(sessionId)
              .get();
          if (!sessionDoc.exists) {
            await doc.reference.delete();
            deletedCount++;
            _logger.d('🗑️ Deleted orphaned session analytics: ${doc.id}');
          }
        }
      }

      return deletedCount;
    } catch (e) {
      _logger.e('❌ Error cleaning up orphaned session analytics: $e');
      return 0;
    }
  }

  /// Clean up orphaned session media
  static Future<int> _cleanupOrphanedSessionMedia() async {
    try {
      final mediaQuery = await _firestore.collection('session_media').get();
      int deletedCount = 0;

      for (final doc in mediaQuery.docs) {
        final sessionId = doc.data()['sessionId'] as String?;
        if (sessionId != null) {
          final sessionDoc = await _firestore
              .collection('sessions')
              .doc(sessionId)
              .get();
          if (!sessionDoc.exists) {
            await doc.reference.delete();
            deletedCount++;
            _logger.d('🗑️ Deleted orphaned session media: ${doc.id}');
          }
        }
      }

      return deletedCount;
    } catch (e) {
      _logger.e('❌ Error cleaning up orphaned session media: $e');
      return 0;
    }
  }

  /// Clean up orphaned session achievements
  static Future<int> _cleanupOrphanedSessionAchievements() async {
    try {
      final achievementsQuery = await _firestore
          .collection('session_achievements')
          .get();
      int deletedCount = 0;

      for (final doc in achievementsQuery.docs) {
        final sessionId = doc.data()['sessionId'] as String?;
        if (sessionId != null) {
          final sessionDoc = await _firestore
              .collection('sessions')
              .doc(sessionId)
              .get();
          if (!sessionDoc.exists) {
            await doc.reference.delete();
            deletedCount++;
            _logger.d('🗑️ Deleted orphaned session achievement: ${doc.id}');
          }
        }
      }

      return deletedCount;
    } catch (e) {
      _logger.e('❌ Error cleaning up orphaned session achievements: $e');
      return 0;
    }
  }

  /// Clean up orphaned checklist media
  static Future<int> _cleanupOrphanedChecklistMedia() async {
    try {
      final mediaQuery = await _firestore.collection('checklist_media').get();
      int deletedCount = 0;

      for (final doc in mediaQuery.docs) {
        final checklistId = doc.data()['checklistId'] as String?;
        if (checklistId != null) {
          final checklistDoc = await _firestore
              .collection('checklists')
              .doc(checklistId)
              .get();
          if (!checklistDoc.exists) {
            await doc.reference.delete();
            deletedCount++;
            _logger.d('🗑️ Deleted orphaned checklist media: ${doc.id}');
          }
        }
      }

      return deletedCount;
    } catch (e) {
      _logger.e('❌ Error cleaning up orphaned checklist media: $e');
      return 0;
    }
  }

  /// Clean up orphaned checklist comments
  static Future<int> _cleanupOrphanedChecklistComments() async {
    try {
      final commentsQuery = await _firestore
          .collection('checklist_comments')
          .get();
      int deletedCount = 0;

      for (final doc in commentsQuery.docs) {
        final checklistId = doc.data()['checklistId'] as String?;
        if (checklistId != null) {
          final checklistDoc = await _firestore
              .collection('checklists')
              .doc(checklistId)
              .get();
          if (!checklistDoc.exists) {
            await doc.reference.delete();
            deletedCount++;
            _logger.d('🗑️ Deleted orphaned checklist comment: ${doc.id}');
          }
        }
      }

      return deletedCount;
    } catch (e) {
      _logger.e('❌ Error cleaning up orphaned checklist comments: $e');
      return 0;
    }
  }
}
