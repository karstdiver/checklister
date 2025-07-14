import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import 'session_state.dart';
import '../data/session_repository.dart';
import '../../../core/services/analytics_service.dart';

class SessionNotifier extends StateNotifier<SessionState?> {
  final SessionRepository _repository;
  final AnalyticsService _analytics;
  final Random _random = Random();
  DateTime? _sessionStartTime;
  DateTime? _lastActiveTime;

  SessionNotifier(this._repository)
    : _analytics = AnalyticsService(),
      super(null) {
    print('SessionNotifier created: ${DateTime.now()}');
  }

  // Initialize a new session
  Future<void> startSession({
    required String checklistId,
    required String userId,
    required List<ChecklistItem> items,
  }) async {
    // Clean up old incomplete sessions for this checklist
    await _cleanupOldSessions(checklistId, userId);

    final sessionId =
        'session_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(10000)}';
    final now = DateTime.now();
    print('Starting new session: $sessionId at $now');

    final sessionState = SessionState(
      sessionId: sessionId,
      checklistId: checklistId,
      userId: userId,
      status: SessionStatus.inProgress,
      items: items,
      currentItemIndex: 0,
      startedAt: now,
      totalDuration: Duration.zero,
      activeDuration: Duration.zero,
      metadata: {'deviceInfo': 'flutter_app', 'version': '1.0.0'},
    );

    state = sessionState;
    _sessionStartTime = now;
    _lastActiveTime = now;

    // Save session to repository
    await _repository.saveSession(sessionState);

    // Log analytics
    await _analytics.logCustomEvent(
      name: 'session_started',
      parameters: {
        'session_id': sessionId,
        'checklist_id': checklistId,
        'total_items': items.length,
      },
    );
  }

  // Handle swipe gestures
  Future<void> handleSwipeLeft() async {
    if (state == null || !state!.isActive) return;

    await _completeCurrentItem();
  }

  Future<void> handleSwipeRight() async {
    if (state == null || !state!.isActive) return;

    await _goToPreviousItem();
  }

  Future<void> handleSwipeUp() async {
    if (state == null || !state!.isActive) return;

    await _skipCurrentItem();
  }

  Future<void> handleSwipeDown() async {
    if (state == null || !state!.isActive) return;

    await _pauseSession();
  }

  // Complete current item and move to next
  Future<void> _completeCurrentItem() async {
    if (state == null || state!.currentItem == null) return;

    final currentIndex = state!.currentItemIndex;
    final updatedItems = List<ChecklistItem>.from(state!.items);
    final now = DateTime.now();

    updatedItems[currentIndex] = updatedItems[currentIndex].copyWith(
      status: ItemStatus.completed,
      completedAt: now,
    );

    final newState = state!.copyWith(
      items: updatedItems,
      currentItemIndex: currentIndex + 1,
    );

    state = newState;
    _updateActiveTime();

    // Log analytics
    await _analytics.logCustomEvent(
      name: 'item_completed',
      parameters: {
        'session_id': state!.sessionId,
        'item_id': updatedItems[currentIndex].id,
        'item_index': currentIndex,
      },
    );

    // Check if session is complete
    if (newState.currentItemIndex >= newState.totalItems) {
      await _completeSession();
    } else {
      await _repository.saveSession(newState);
    }
  }

  // Skip current item
  Future<void> _skipCurrentItem() async {
    print('Skip current item called at index: ${state?.currentItemIndex}');
    if (state == null || state!.currentItem == null) return;

    final currentIndex = state!.currentItemIndex;
    final updatedItems = List<ChecklistItem>.from(state!.items);
    final now = DateTime.now();

    updatedItems[currentIndex] = updatedItems[currentIndex].copyWith(
      status: ItemStatus.skipped,
      skippedAt: now,
    );

    final newState = state!.copyWith(
      items: updatedItems,
      currentItemIndex: currentIndex + 1,
    );

    state = newState;
    _updateActiveTime();

    // Log analytics
    await _analytics.logCustomEvent(
      name: 'item_skipped',
      parameters: {
        'session_id': state!.sessionId,
        'item_id': updatedItems[currentIndex].id,
        'item_index': currentIndex,
      },
    );

    // Check if session is complete
    if (newState.currentItemIndex >= newState.totalItems) {
      await _completeSession();
    } else {
      await _repository.saveSession(newState);
    }
  }

  // Go to previous item
  Future<void> _goToPreviousItem() async {
    if (state == null || !state!.canGoPrevious) return;

    final newState = state!.copyWith(
      currentItemIndex: state!.currentItemIndex - 1,
    );

    state = newState;
    _updateActiveTime();

    // Log analytics
    await _analytics.logCustomEvent(
      name: 'item_reviewed',
      parameters: {
        'session_id': state!.sessionId,
        'item_index': newState.currentItemIndex,
      },
    );

    await _repository.saveSession(newState);
  }

  // Pause session
  Future<void> _pauseSession() async {
    if (state == null || !state!.isActive) return;

    final now = DateTime.now();
    final newState = state!.copyWith(
      status: SessionStatus.paused,
      pausedAt: now,
    );

    state = newState;
    _updateActiveTime();

    // Log analytics
    await _analytics.logCustomEvent(
      name: 'session_paused',
      parameters: {
        'session_id': state!.sessionId,
        'current_item_index': newState.currentItemIndex,
      },
    );

    await _repository.saveSession(newState);
  }

  // Resume session
  Future<void> resumeSession() async {
    if (state == null || !state!.isPaused) return;

    final newState = state!.copyWith(
      status: SessionStatus.inProgress,
      pausedAt: null,
    );

    state = newState;
    _lastActiveTime = DateTime.now();

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

  // Complete session
  Future<void> _completeSession() async {
    if (state == null) return;

    print('🎯 Completing session: ${state!.sessionId}');

    final now = DateTime.now();
    final totalDuration = _sessionStartTime != null
        ? now.difference(_sessionStartTime!)
        : Duration.zero;

    final newState = state!.copyWith(
      status: SessionStatus.completed,
      completedAt: now,
      totalDuration: totalDuration,
    );

    state = newState;
    print('🎯 Session status updated to: ${newState.status}');

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

    print('🎯 Saving completed session to database...');
    await _repository.saveSession(newState);
    print('🎯 Completed session saved successfully');
  }

  // Abandon session
  Future<void> abandonSession() async {
    if (state == null) return;

    final now = DateTime.now();
    final totalDuration = _sessionStartTime != null
        ? now.difference(_sessionStartTime!)
        : Duration.zero;

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

  // Update active time tracking
  void _updateActiveTime() {
    final now = DateTime.now();
    if (_lastActiveTime != null && state != null) {
      final activeDuration =
          state!.activeDuration + now.difference(_lastActiveTime!);
      state = state!.copyWith(activeDuration: activeDuration);
    }
    _lastActiveTime = now;
  }

  // Load existing session
  Future<void> loadSession(String sessionId) async {
    try {
      final session = await _repository.getSession(sessionId);
      if (session != null) {
        state = session;
        _sessionStartTime = session.startedAt;
        _lastActiveTime = session.completedAt ?? DateTime.now();
      }
    } catch (e) {
      // Handle error loading session
      print('Error loading session: $e');
    }
  }

  // Clear current session
  void clearSession() {
    state = null;
    _sessionStartTime = null;
    _lastActiveTime = null;
  }

  // Check if there's an active session for a user
  Future<SessionState?> getActiveSession(
    String userId,
    String checklistId,
  ) async {
    try {
      final sessions = await _repository.getUserSessions(userId);
      print('🔍 Found ${sessions.length} total sessions for user $userId');

      // Find active sessions for this specific checklist
      final activeSession = sessions
          .where(
            (session) =>
                session.checklistId == checklistId &&
                (session.status == SessionStatus.inProgress ||
                    session.status == SessionStatus.paused),
          )
          .toList();

      print(
        '🔍 Found ${activeSession.length} active sessions for checklist $checklistId',
      );
      for (final session in activeSession) {
        print(
          '🔍 Active session: ${session.sessionId} - Status: ${session.status} - Completed: ${session.completedItems}/${session.totalItems}',
        );

        // Check if this session should actually be completed
        if (session.completedItems + session.skippedItems >=
            session.totalItems) {
          print(
            '🔍 Session ${session.sessionId} should be completed - marking as completed',
          );
          final completedSession = session.copyWith(
            status: SessionStatus.completed,
            completedAt: DateTime.now(),
          );
          await _repository.saveSession(completedSession);
          print('🔍 Session ${session.sessionId} marked as completed');
        }
      }

      // Re-filter after potential updates
      final updatedSessions = await _repository.getUserSessions(userId);
      final trulyActiveSessions = updatedSessions
          .where(
            (session) =>
                session.checklistId == checklistId &&
                (session.status == SessionStatus.inProgress ||
                    session.status == SessionStatus.paused),
          )
          .toList();

      print(
        '🔍 After cleanup: Found ${trulyActiveSessions.length} truly active sessions',
      );

      if (trulyActiveSessions.isNotEmpty) {
        // Return the most recent active session
        trulyActiveSessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));
        final mostRecent = trulyActiveSessions.first;
        print(
          '🔍 Returning most recent active session: ${mostRecent.sessionId}',
        );
        return mostRecent;
      }
      print('🔍 No active sessions found for checklist $checklistId');
      return null;
    } catch (e) {
      print('Error checking for active session: $e');
      return null;
    }
  }

  // Clean up old incomplete sessions for a checklist
  Future<void> _cleanupOldSessions(String checklistId, String userId) async {
    try {
      final sessions = await _repository.getUserSessions(userId);
      final incompleteSessions = sessions
          .where(
            (session) =>
                session.checklistId == checklistId &&
                (session.status == SessionStatus.inProgress ||
                    session.status == SessionStatus.paused),
          )
          .toList();

      print(
        '🧹 Found ${incompleteSessions.length} incomplete sessions to clean up',
      );

      for (final session in incompleteSessions) {
        print('🧹 Abandoning old session: ${session.sessionId}');
        final abandonedSession = session.copyWith(
          status: SessionStatus.abandoned,
          completedAt: DateTime.now(),
        );
        await _repository.saveSession(abandonedSession);
        print('🧹 Session ${session.sessionId} marked as abandoned');
      }
    } catch (e) {
      print('Error cleaning up old sessions: $e');
    }
  }
}
