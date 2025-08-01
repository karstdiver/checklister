import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'session_state.dart';
import '../data/session_repository.dart';
import '../../../core/services/analytics_service.dart';
import '../../achievements/domain/achievement_notifier.dart';

final logger = Logger();

class SessionNotifier extends StateNotifier<SessionState?> {
  final SessionRepository _repository;
  final AnalyticsService _analytics;
  final AchievementNotifier? _achievementNotifier;

  SessionNotifier(this._repository, {AchievementNotifier? achievementNotifier})
    : _analytics = AnalyticsService(),
      _achievementNotifier = achievementNotifier,
      super(null) {
    logger.d('SessionNotifier created: ${DateTime.now()}');
  }

  Future<void> startSession({
    required String checklistId,
    required String userId,
    required List<ChecklistItem> items,
  }) async {
    final now = DateTime.now();
    final sessionId =
        'session_${now.millisecondsSinceEpoch}_${now.microsecond}';

    logger.i('Starting new session: $sessionId at $now');
    logger.i('Items count: ${items.length}');
    logger.i('Items statuses: ${items.map((item) => item.status).toList()}');

    final session = SessionState(
      sessionId: sessionId,
      checklistId: checklistId,
      userId: userId,
      status: SessionStatus.inProgress,
      items: items,
      currentItemIndex: 0,
      startedAt: now,
      totalDuration: Duration.zero,
      activeDuration: Duration.zero,
      metadata: {},
    );

    state = session;

    logger.i('Session state set:');
    logger.i('  - Session ID: ${session.sessionId}');
    logger.i('  - Current item index: ${session.currentItemIndex}');
    logger.i(
      '  - Completed items: ${session.completedItems}/${session.totalItems}',
    );
    logger.i('  - Progress percentage: ${session.progressPercentage}');
    logger.i(
      '  - Item statuses: ${session.items.map((item) => item.status).toList()}',
    );
    logger.i(
      '  - Completed items count: ${session.items.where((item) => item.status == ItemStatus.completed).length}',
    );
    logger.i(
      '  - Skipped items count: ${session.items.where((item) => item.status == ItemStatus.skipped).length}',
    );
    logger.i(
      '  - Pending items count: ${session.items.where((item) => item.status == ItemStatus.pending).length}',
    );

    // Save session to database
    try {
      await _repository.saveSession(session);
    } catch (e) {
      logger.e('Failed to save session to database: $e');
      // Don't throw here, session can continue without being saved
    }
  }

  void nextItem() {
    if (state == null) return;

    final currentIndex = state!.currentItemIndex;
    if (currentIndex < state!.items.length - 1) {
      state = state!.copyWith(currentItemIndex: currentIndex + 1);
    }
  }

  void previousItem() {
    if (state == null) return;

    final currentIndex = state!.currentItemIndex;
    if (currentIndex > 0) {
      state = state!.copyWith(currentItemIndex: currentIndex - 1);
    }
  }

  Future<void> completeCurrentItem() async {
    if (state == null) return;

    final currentIndex = state!.currentItemIndex;
    if (currentIndex >= 0 && currentIndex < state!.items.length) {
      final updatedItems = List<ChecklistItem>.from(state!.items);
      updatedItems[currentIndex] = updatedItems[currentIndex].copyWith(
        status: ItemStatus.completed,
        completedAt: DateTime.now(),
      );

      final newState = state!.copyWith(items: updatedItems);

      state = newState;

      // Save to database immediately
      await _repository.saveSession(newState);
      logger.i(
        '💾 Saved completed item to database: ${newState.completedItems}/${newState.totalItems}',
      );

      // Check if session is complete
      if (newState.completedItems + newState.skippedItems >=
          newState.totalItems) {
        completeSession();
      }
    }
  }

  Future<void> skipCurrentItem() async {
    if (state == null) return;

    final currentIndex = state!.currentItemIndex;
    if (currentIndex >= 0 && currentIndex < state!.items.length) {
      final updatedItems = List<ChecklistItem>.from(state!.items);
      updatedItems[currentIndex] = updatedItems[currentIndex].copyWith(
        status: ItemStatus.skipped,
        skippedAt: DateTime.now(),
      );

      final newState = state!.copyWith(items: updatedItems);

      state = newState;

      // Save to database immediately
      await _repository.saveSession(newState);
      logger.i(
        '💾 Saved skipped item to database: ${newState.skippedItems}/${newState.totalItems}',
      );

      // Check if session is complete
      if (newState.completedItems + newState.skippedItems >=
          newState.totalItems) {
        completeSession();
      }
    }
  }

  void reviewCurrentItem() {
    if (state == null) return;

    final currentIndex = state!.currentItemIndex;
    if (currentIndex >= 0 && currentIndex < state!.items.length) {
      final updatedItems = List<ChecklistItem>.from(state!.items);
      updatedItems[currentIndex] = updatedItems[currentIndex].copyWith(
        status: ItemStatus.reviewed,
      );

      state = state!.copyWith(items: updatedItems);
    }
  }

  void pauseSession() {
    if (state == null) return;

    state = state!.copyWith(
      status: SessionStatus.paused,
      pausedAt: DateTime.now(),
    );
  }

  Future<void> resumeSession() async {
    if (state == null || !state!.isPaused) return;

    final newState = state!.copyWith(
      status: SessionStatus.inProgress,
      pausedAt: null,
    );

    state = newState;

    // Log analytics
    await _analytics.logCustomEvent(
      name: 'session_resumed',
      parameters: {
        'session_id': state!.sessionId,
        'current_item_index': newState.currentItemIndex,
      },
    );

    await _repository.saveSession(newState);
  }

  Future<void> completeSession() async {
    if (state == null) return;

    logger.i('🎯 Completing session: ${state!.sessionId}');

    final now = DateTime.now();
    final totalDuration = now.difference(state!.startedAt);

    final newState = state!.copyWith(
      status: SessionStatus.completed,
      completedAt: now,
      totalDuration: totalDuration,
    );

    state = newState;
    logger.i('🎯 Session status updated to: ${newState.status}');

    // Log analytics
    await _analytics.logCustomEvent(
      name: 'session_completed',
      parameters: {
        'session_id': state!.sessionId,
        'total_duration_seconds': totalDuration.inSeconds,
        'completed_items': newState.completedItems,
        'skipped_items': newState.skippedItems,
        'total_items': newState.totalItems,
      },
    );

    logger.i('🎯 Saving completed session to database...');
    await _repository.saveSession(newState);
    logger.i('🎯 Completed session saved successfully');

    // TODO: For paid tier, retain finished sessions for audit/history purposes instead of deleting.
    // For free tier, delete finished sessions to save storage and improve performance.
    logger.d(
      '🗑️ Deleting finished session from Firestore: ${state!.sessionId}',
    );
    await _repository.deleteSession(state!.sessionId);

    // Clean up any other active sessions for the same checklist
    await _cleanupOtherActiveSessions(state!.checklistId, state!.sessionId);

    // Check achievements for session completion
    if (_achievementNotifier != null) {
      try {
        await _achievementNotifier!.checkSessionCompletionAchievements(
          sessionStartedAt: state!.startedAt,
          sessionCompletedAt: now,
          totalItems: state!.totalItems,
          completedItems: state!.completedItems,
        );
        logger.i(
          '🎯 Achievement checking completed for session: ${state!.sessionId}',
        );
      } catch (e) {
        logger.e('Error checking achievements for session completion: $e');
        // Don't let achievement errors break session completion
      }
    } else {
      logger.w('Achievement notifier is null, skipping achievement checking');
    }
  }

  Future<void> abandonSession() async {
    if (state == null) return;

    final now = DateTime.now();
    final totalDuration = now.difference(state!.startedAt);

    final newState = state!.copyWith(
      status: SessionStatus.abandoned,
      completedAt: now,
      totalDuration: totalDuration,
    );

    state = newState;

    // Log analytics
    await _analytics.logCustomEvent(
      name: 'session_abandoned',
      parameters: {
        'session_id': state!.sessionId,
        'total_duration_seconds': totalDuration.inSeconds,
        'completed_items': newState.completedItems,
        'current_item_index': newState.currentItemIndex,
      },
    );

    await _repository.saveSession(newState);
  }

  void clearSession() {
    state = null;
  }

  // Swipe gesture handlers
  Future<void> handleSwipeLeft() async {
    if (state == null) return;

    logger.i('👈 Swipe LEFT - Completing current item');
    await completeCurrentItem();

    // Move to next item if available
    if (state != null && state!.canGoNext) {
      nextItem();
      logger.d(
        '➡️ Moved to next item: ${state!.currentItemIndex + 1}/${state!.totalItems}',
      );
    }
  }

  void handleSwipeRight() {
    if (state == null) return;

    logger.i('👉 Swipe RIGHT - Moving to previous item');
    if (state!.canGoPrevious) {
      previousItem();
      logger.d(
        '⬅️ Moved to previous item: ${state!.currentItemIndex + 1}/${state!.totalItems}',
      );
    } else {
      logger.d('⬅️ Already at first item, cannot go back');
    }
  }

  Future<void> handleSwipeUp() async {
    if (state == null) return;

    logger.i('⬆️ Swipe UP - Skipping current item');
    await skipCurrentItem();

    // Move to next item if available
    if (state != null && state!.canGoNext) {
      nextItem();
      logger.d(
        '➡️ Moved to next item after skip: ${state!.currentItemIndex + 1}/${state!.totalItems}',
      );
    }
  }

  void handleSwipeDown() {
    if (state == null) return;

    if (state!.isPaused) {
      logger.i('⬇️ Swipe DOWN - Resuming session');
      resumeSession();
    } else {
      logger.i('⬇️ Swipe DOWN - Pausing session');
      pauseSession();
    }
  }

  Future<void> loadSession(String sessionId) async {
    try {
      logger.i('🔄 Loading session: $sessionId');
      final session = await _repository.getSession(sessionId);
      if (session != null) {
        logger.i('🔄 Session found in database: ${session.sessionId}');
        logger.i('🔄 Session status: ${session.status}');
        logger.i(
          '🔄 Completed items: ${session.completedItems}/${session.totalItems}',
        );
        logger.i('🔄 Current item index: ${session.currentItemIndex}');

        // Find the first incomplete item
        int firstIncomplete = session.items.indexWhere(
          (item) =>
              item.status != ItemStatus.completed &&
              item.status != ItemStatus.skipped,
        );
        if (firstIncomplete == -1) firstIncomplete = 0; // fallback
        final adjustedSession = session.copyWith(
          currentItemIndex: firstIncomplete,
        );

        state = adjustedSession;
        logger.i(
          '🔄 Session state updated in notifier (adjusted for first incomplete item)',
        );

        // Verify the state was set correctly
        if (state != null) {
          logger.i('🔄 State verification - Session ID: ${state!.sessionId}');
          logger.i(
            '🔄 State verification - Completed items: ${state!.completedItems}/${state!.totalItems}',
          );
          logger.i(
            '🔄 State verification - Current item index: ${state!.currentItemIndex}',
          );
        } else {
          logger.e(
            '🔄 State verification failed - state is null after setting',
          );
        }
      } else {
        logger.e('🔄 Session not found: $sessionId');
      }
    } catch (e) {
      logger.e('Error loading session: $e');
    }
  }

  Future<SessionState?> getActiveSession(
    String userId,
    String checklistId,
  ) async {
    try {
      final sessions = await _repository.getUserSessions(userId);

      // Filter for active sessions for this checklist (exclude completed and abandoned)
      final activeSessions = sessions
          .where(
            (session) =>
                session.checklistId == checklistId &&
                (session.status == SessionStatus.inProgress ||
                    session.status == SessionStatus.paused),
          )
          .toList();

      // Clean up any old incomplete sessions
      for (final session in activeSessions) {
        if (session.status == SessionStatus.inProgress) {
          // Mark old sessions as completed if they're too old
          final sessionAge = DateTime.now().difference(session.startedAt);
          if (sessionAge.inHours > 24) {
            await _repository.saveSession(
              session.copyWith(
                status: SessionStatus.completed,
                completedAt: DateTime.now(),
              ),
            );
          }
        }
      }

      // Return the most recent active session
      if (activeSessions.isNotEmpty) {
        activeSessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));
        return activeSessions.first;
      }

      return null;
    } catch (e) {
      logger.e('Error checking for active session: $e');
      return null;
    }
  }

  Future<void> _cleanupOtherActiveSessions(
    String checklistId,
    String currentSessionId,
  ) async {
    try {
      logger.i(
        '🧹 Cleaning up other active sessions for checklist: $checklistId',
      );

      final sessions = await _repository.getUserSessions(state!.userId);

      for (final session in sessions) {
        if (session.sessionId != currentSessionId &&
            session.checklistId == checklistId &&
            (session.status == SessionStatus.inProgress ||
                session.status == SessionStatus.paused)) {
          logger.i('🧹 Abandoning other active session: ${session.sessionId}');
          await _repository.saveSession(
            session.copyWith(
              status: SessionStatus.abandoned,
              completedAt: DateTime.now(),
            ),
          );
          logger.i('🧹 Session ${session.sessionId} marked as abandoned');
        }
      }
    } catch (e) {
      logger.e('Error cleaning up other active sessions: $e');
    }
  }

  Future<void> cleanupOldSessions(String userId) async {
    try {
      final sessions = await _repository.getUserSessions(userId);

      for (final session in sessions) {
        if (session.status == SessionStatus.inProgress) {
          final sessionAge = DateTime.now().difference(session.startedAt);
          if (sessionAge.inHours > 24) {
            logger.d('🧹 Abandoning old session: ${session.sessionId}');
            await _repository.saveSession(
              session.copyWith(
                status: SessionStatus.abandoned,
                completedAt: DateTime.now(),
              ),
            );
            logger.d('🧹 Session ${session.sessionId} marked as abandoned');
          }
        }
      }
    } catch (e) {
      logger.e('Error cleaning up old sessions: $e');
    }
  }

  /// Update session with latest checklist items (e.g., new photos)
  Future<void> updateSessionWithLatestItems(
    List<ChecklistItem> latestItems,
  ) async {
    if (state == null) return;

    logger.i('🔄 Updating session with latest items');
    logger.i('🔄 Current items count: ${state!.items.length}');
    logger.i('🔄 Latest items count: ${latestItems.length}');

    // Create a map of current items by ID to preserve their status
    final currentItemsMap = <String, ChecklistItem>{};
    for (final item in state!.items) {
      currentItemsMap[item.id] = item;
    }

    // Update items with latest data while preserving status
    final updatedItems = <ChecklistItem>[];
    for (int i = 0; i < latestItems.length; i++) {
      final latestItem = latestItems[i];
      final currentItem = currentItemsMap[latestItem.id];

      if (currentItem != null) {
        // Preserve the current status and timestamps, but update other fields
        updatedItems.add(
          latestItem.copyWith(
            status: currentItem.status,
            completedAt: currentItem.completedAt,
            skippedAt: currentItem.skippedAt,
          ),
        );
      } else {
        // New item, add with pending status
        updatedItems.add(latestItem.copyWith(status: ItemStatus.pending));
      }
    }

    // Update the session state
    final updatedSession = state!.copyWith(items: updatedItems);

    state = updatedSession;
    logger.i('🔄 Session updated with latest items');

    // Save to database
    try {
      await _repository.saveSession(updatedSession);
      logger.i('🔄 Updated session saved to database');
    } catch (e) {
      logger.e('🔄 Failed to save updated session: $e');
    }
  }

  // TODO: Tech Debt - Implement automatic session cleanup and analytics
  //
  // Current Issue: Sessions accumulate indefinitely in Firestore without cleanup,
  // leading to storage costs and performance degradation. Current cleanup only
  // marks sessions as abandoned but doesn't delete them.
  //
  // Tech Debt Impact:
  // - Firestore storage costs increase over time
  // - Query performance degrades with large session collections
  // - No session analytics or insights available
  // - Manual cleanup required to manage database size
  //
  // Implementation Plan:
  // 1. Create SessionAnalyticsService to extract insights before deletion:
  //    - Session completion rates by checklist
  //    - Average session duration
  //    - Most/least completed items
  //    - User engagement patterns
  // 2. Implement automatic cleanup with configurable retention policy:
  //    - Delete completed sessions older than 30 days
  //    - Delete abandoned sessions older than 7 days
  //    - Archive important analytics data before deletion
  // 3. Add scheduled cleanup triggers:
  //    - Daily cleanup job for old sessions
  //    - Weekly analytics generation
  //    - Monthly retention policy review
  // 4. Create admin dashboard for session management:
  //    - View session statistics
  //    - Manual cleanup controls
  //    - Retention policy configuration
  //
  // Priority: High - affects storage costs and app performance
  // Estimated effort: 2-3 days for basic implementation
  // Dependencies: Analytics service, admin dashboard, scheduled jobs
}
