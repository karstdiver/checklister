import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'session_notifier.dart';
import 'session_state.dart';
import '../data/session_repository.dart';
import '../../../core/providers/providers.dart';
import '../../achievements/domain/achievement_providers.dart';

// Repository provider
final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository();
});

// Session notifier provider
// Note: Using StateNotifierProvider (not autoDispose) to persist session state across navigation
// This ensures sessions are not lost when navigating back to home screen
final sessionNotifierProvider =
    StateNotifierProvider<SessionNotifier, SessionState?>((ref) {
      final repository = ref.watch(sessionRepositoryProvider);

      // Ensure achievement notifier is initialized
      ref.watch(achievementNotifierProvider);
      final achievementNotifier = ref.read(
        achievementNotifierProvider.notifier,
      );

      return SessionNotifier(
        repository,
        achievementNotifier: achievementNotifier,
      );
    });

// Current session state provider
final currentSessionProvider = Provider<SessionState?>((ref) {
  return ref.watch(sessionNotifierProvider);
});

// Session status provider
final sessionStatusProvider = Provider<SessionStatus?>((ref) {
  final session = ref.watch(currentSessionProvider);
  return session?.status;
});

// Current item provider
final currentItemProvider = Provider<ChecklistItem?>((ref) {
  final session = ref.watch(currentSessionProvider);
  return session?.currentItem;
});

// Progress provider
final sessionProgressProvider = Provider<double>((ref) {
  final session = ref.watch(currentSessionProvider);
  return session?.progressPercentage ?? 0.0;
});

// Session statistics provider
final sessionStatsProvider =
    Provider<({int total, int completed, int skipped})>((ref) {
      final session = ref.watch(currentSessionProvider);
      if (session == null) {
        return (total: 0, completed: 0, skipped: 0);
      }
      return (
        total: session.totalItems,
        completed: session.completedItems,
        skipped: session.skippedItems,
      );
    });

// Navigation state provider
final sessionNavigationProvider =
    Provider<({bool canGoNext, bool canGoPrevious})>((ref) {
      final session = ref.watch(currentSessionProvider);
      if (session == null) {
        return (canGoNext: false, canGoPrevious: false);
      }
      return (
        canGoNext: session.canGoNext,
        canGoPrevious: session.canGoPrevious,
      );
    });

// Active session provider for a specific checklist
final activeSessionProvider = Provider.family<SessionState?, String>((
  ref,
  checklistId,
) {
  final currentSession = ref.watch(currentSessionProvider);

  // If there's a current session for this checklist, return it
  if (currentSession != null && currentSession.checklistId == checklistId) {
    return currentSession;
  }

  // Otherwise, return null (no active session)
  return null;
});

// Active session progress provider for a specific checklist
final activeSessionProgressProvider =
    Provider.family<
      ({int completed, int total, bool hasActiveSession})?,
      String
    >((ref, checklistId) {
      final currentUser = ref.watch(currentUserProvider);
      if (currentUser == null) return null;

      // Watch the current session state to make this reactive
      final currentSession = ref.watch(sessionNotifierProvider);

      // If there's a current session for this checklist, use it
      if (currentSession != null && currentSession.checklistId == checklistId) {
        if (currentSession.status == SessionStatus.inProgress ||
            currentSession.status == SessionStatus.paused) {
          return (
            completed: currentSession.completedItems,
            total: currentSession.totalItems,
            hasActiveSession: true,
          );
        }
      }

      // Otherwise, return null - the checklist's own progress will be shown
      return null;
    });
