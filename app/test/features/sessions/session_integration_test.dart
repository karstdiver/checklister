import 'package:flutter_test/flutter_test.dart';
import 'package:checklister/features/sessions/domain/session_state.dart';

void main() {
  group('Session Integration Tests', () {
    late List<ChecklistItem> testItems;

    setUp(() {
      testItems = [
        ChecklistItem(
          id: 'item_1',
          text: 'Test item 1',
          status: ItemStatus.pending,
        ),
        ChecklistItem(
          id: 'item_2',
          text: 'Test item 2',
          status: ItemStatus.pending,
        ),
        ChecklistItem(
          id: 'item_3',
          text: 'Test item 3',
          status: ItemStatus.pending,
        ),
      ];
    });

    test('should create session with correct initial state', () {
      final session = SessionState(
        sessionId: 'test_session',
        checklistId: 'test_checklist',
        userId: 'test_user',
        status: SessionStatus.inProgress,
        items: testItems,
        currentItemIndex: 0,
        startedAt: DateTime.now(),
        totalDuration: Duration.zero,
        activeDuration: Duration.zero,
        metadata: {},
      );

      expect(session.totalItems, 3);
      expect(session.currentItemIndex, 0);
      expect(session.currentItem?.text, 'Test item 1');
      expect(session.completedItems, 0);
      expect(session.skippedItems, 0);
      expect(session.isActive, true);
      expect(session.progressPercentage, 0.0);
    });

    test('should track progress correctly through session', () {
      final session = SessionState(
        sessionId: 'test_session',
        checklistId: 'test_checklist',
        userId: 'test_user',
        status: SessionStatus.inProgress,
        items: testItems,
        currentItemIndex: 0,
        startedAt: DateTime.now(),
        totalDuration: Duration.zero,
        activeDuration: Duration.zero,
        metadata: {},
      );

      // Complete first item
      final updatedItems = List<ChecklistItem>.from(session.items);
      updatedItems[0] = updatedItems[0].copyWith(
        status: ItemStatus.completed,
        completedAt: DateTime.now(),
      );

      final sessionAfterComplete = session.copyWith(
        items: updatedItems,
        currentItemIndex: 1,
      );

      expect(sessionAfterComplete.completedItems, 1);
      expect(sessionAfterComplete.skippedItems, 0);
      expect(sessionAfterComplete.currentItem?.text, 'Test item 2');
      expect(sessionAfterComplete.progressPercentage, 1 / 3);

      // Skip second item
      final updatedItems2 = List<ChecklistItem>.from(
        sessionAfterComplete.items,
      );
      updatedItems2[1] = updatedItems2[1].copyWith(
        status: ItemStatus.skipped,
        skippedAt: DateTime.now(),
      );

      final sessionAfterSkip = sessionAfterComplete.copyWith(
        items: updatedItems2,
        currentItemIndex: 2,
      );

      expect(sessionAfterSkip.completedItems, 1);
      expect(sessionAfterSkip.skippedItems, 1);
      expect(sessionAfterSkip.currentItem?.text, 'Test item 3');
      expect(
        sessionAfterSkip.progressPercentage,
        1 / 3,
      ); // Only completed items count for progress
    });

    test('should handle session completion', () {
      final completedItems = [
        ChecklistItem(
          id: 'item_1',
          text: 'Test item 1',
          status: ItemStatus.completed,
        ),
        ChecklistItem(
          id: 'item_2',
          text: 'Test item 2',
          status: ItemStatus.completed,
        ),
      ];

      final session = SessionState(
        sessionId: 'test_session',
        checklistId: 'test_checklist',
        userId: 'test_user',
        status: SessionStatus.completed,
        items: completedItems,
        currentItemIndex: 2, // Past the last item
        startedAt: DateTime.now(),
        completedAt: DateTime.now(),
        totalDuration: Duration(minutes: 30),
        activeDuration: Duration(minutes: 25),
        metadata: {},
      );

      expect(session.isCompleted, true);
      expect(session.isActive, false);
      expect(session.completedItems, 2);
      expect(session.skippedItems, 0);
      expect(session.progressPercentage, 1.0);
      expect(session.currentItem, null);
    });

    test('should handle navigation boundaries', () {
      final session = SessionState(
        sessionId: 'test_session',
        checklistId: 'test_checklist',
        userId: 'test_user',
        status: SessionStatus.inProgress,
        items: testItems,
        currentItemIndex: 0,
        startedAt: DateTime.now(),
        totalDuration: Duration.zero,
        activeDuration: Duration.zero,
        metadata: {},
      );

      // At first item
      expect(session.canGoPrevious, false);
      expect(session.canGoNext, true);

      // At middle item
      final middleSession = session.copyWith(currentItemIndex: 1);
      expect(middleSession.canGoPrevious, true);
      expect(middleSession.canGoNext, true);

      // At last item
      final lastSession = session.copyWith(currentItemIndex: 2);
      expect(lastSession.canGoPrevious, true);
      expect(lastSession.canGoNext, false);
    });

    test('should handle session status transitions', () {
      final session = SessionState(
        sessionId: 'test_session',
        checklistId: 'test_checklist',
        userId: 'test_user',
        status: SessionStatus.inProgress,
        items: testItems,
        currentItemIndex: 0,
        startedAt: DateTime.now(),
        totalDuration: Duration.zero,
        activeDuration: Duration.zero,
        metadata: {},
      );

      // Pause session
      final pausedSession = session.copyWith(
        status: SessionStatus.paused,
        pausedAt: DateTime.now(),
      );
      expect(pausedSession.isPaused, true);
      expect(pausedSession.isActive, false);

      // Resume session
      final resumedSession = pausedSession.copyWith(
        status: SessionStatus.inProgress,
        pausedAt: null,
      );
      expect(resumedSession.isPaused, false);
      expect(resumedSession.isActive, true);

      // Abandon session
      final abandonedSession = session.copyWith(
        status: SessionStatus.abandoned,
        completedAt: DateTime.now(),
      );
      expect(abandonedSession.isActive, false);
      expect(abandonedSession.isCompleted, false);
    });

    test('should handle edge cases', () {
      // Empty items list
      final emptySession = SessionState(
        sessionId: 'test_session',
        checklistId: 'test_checklist',
        userId: 'test_user',
        status: SessionStatus.inProgress,
        items: [],
        currentItemIndex: 0,
        startedAt: DateTime.now(),
        totalDuration: Duration.zero,
        activeDuration: Duration.zero,
        metadata: {},
      );

      expect(emptySession.totalItems, 0);
      expect(emptySession.currentItem, null);
      expect(emptySession.progressPercentage, 0.0);

      // Out of bounds index
      final outOfBoundsSession = SessionState(
        sessionId: 'test_session',
        checklistId: 'test_checklist',
        userId: 'test_user',
        status: SessionStatus.inProgress,
        items: testItems,
        currentItemIndex: 10, // Out of bounds
        startedAt: DateTime.now(),
        totalDuration: Duration.zero,
        activeDuration: Duration.zero,
        metadata: {},
      );

      expect(outOfBoundsSession.currentItem, null);
    });
  });
}
