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

    await _repository.saveSession(newState);
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
      // Find active sessions for this specific checklist
      final activeSession = sessions
          .where(
            (session) =>
                session.checklistId == checklistId &&
                (session.status == SessionStatus.inProgress ||
                    session.status == SessionStatus.paused),
          )
          .toList();

      if (activeSession.isNotEmpty) {
        // Return the most recent active session
        activeSession.sort((a, b) => b.startedAt.compareTo(a.startedAt));
        return activeSession.first;
      }
      return null;
    } catch (e) {
      print('Error checking for active session: $e');
      return null;
    }
  }
}
