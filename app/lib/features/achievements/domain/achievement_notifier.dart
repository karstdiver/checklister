import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'achievement.dart';
import 'achievement_state.dart';
import '../data/achievement_repository.dart';

class AchievementNotifier extends StateNotifier<AchievementState> {
  final AchievementRepository _repository;

  AchievementNotifier(this._repository) : super(const AchievementState());

  // Load achievements
  Future<void> loadAchievements() async {
    try {
      state = state.copyWith(loadingState: AchievementLoadingState.loading);

      // Initialize default achievements if needed
      await _repository.initializeDefaultAchievements();

      // Load achievements and stats
      final achievements = await _repository.loadUserAchievements();
      final stats = await _repository.loadAchievementStats();

      state = state.copyWith(
        loadingState: AchievementLoadingState.loaded,
        achievements: achievements,
        totalAchievements: stats['totalAchievements'] ?? 0,
        unlockedAchievements: stats['unlockedAchievements'] ?? 0,
        achievementPoints: stats['achievementPoints'] ?? 0,
        currentStreak: stats['currentStreak'] ?? 0,
        longestStreak: stats['longestStreak'] ?? 0,
      );
    } catch (e) {
      state = state.copyWith(
        loadingState: AchievementLoadingState.error,
        error: e.toString(),
      );
    }
  }

  // Update achievement progress
  Future<void> updateProgress(String achievementId, int progress) async {
    try {
      final achievement = state.getAchievementById(achievementId);
      if (achievement == null) return;

      // Update progress
      await _repository.updateAchievementProgress(achievementId, progress);

      // Check if achievement should be unlocked
      if (!achievement.isUnlocked && progress >= achievement.requirement) {
        await unlockAchievement(achievementId);
      } else {
        // Just update progress in state
        final updatedAchievements = state.achievements.map((a) {
          if (a.id == achievementId) {
            return a.copyWith(progress: progress);
          }
          return a;
        }).toList();

        state = state.copyWith(achievements: updatedAchievements);
      }
    } catch (e) {
      // Handle error silently for progress updates
      print('Error updating achievement progress: $e');
    }
  }

  // Unlock achievement
  Future<void> unlockAchievement(String achievementId) async {
    try {
      final achievement = state.getAchievementById(achievementId);
      if (achievement == null || achievement.isUnlocked) return;

      // Unlock in repository
      await _repository.unlockAchievement(achievementId);

      // Update state
      final updatedAchievements = state.achievements.map((a) {
        if (a.id == achievementId) {
          return a.copyWith(
            isUnlocked: true,
            unlockedAt: DateTime.now(),
            progress: a.requirement, // Set to max progress
          );
        }
        return a;
      }).toList();

      // Calculate new stats
      final unlockedCount = updatedAchievements
          .where((a) => a.isUnlocked)
          .length;
      final achievementPoints = _calculateAchievementPoints(
        updatedAchievements,
      );

      // Update stats in repository
      await _repository.updateAchievementStats({
        'unlockedAchievements': unlockedCount,
        'achievementPoints': achievementPoints,
      });

      // Update state
      state = state.copyWith(
        achievements: updatedAchievements,
        unlockedAchievements: unlockedCount,
        achievementPoints: achievementPoints,
      );
    } catch (e) {
      print('Error unlocking achievement: $e');
    }
  }

  // Calculate achievement points
  int _calculateAchievementPoints(List<Achievement> achievements) {
    int points = 0;
    for (final achievement in achievements) {
      if (achievement.isUnlocked) {
        switch (achievement.rarity) {
          case AchievementRarity.common:
            points += 10;
            break;
          case AchievementRarity.uncommon:
            points += 25;
            break;
          case AchievementRarity.rare:
            points += 50;
            break;
          case AchievementRarity.epic:
            points += 100;
            break;
          case AchievementRarity.legendary:
            points += 250;
            break;
        }
      }
    }
    return points;
  }

  // Check and update achievements based on user actions
  Future<void> checkAchievements({
    int? checklistsCreated,
    int? checklistsCompleted,
    int? itemsCompleted,
    int? consecutiveDays,
    int? dailyCompletions,
    bool? isEarlyCompletion,
    bool? isLateCompletion,
    bool? isWeekendCompletion,
    bool? isPremiumUpgrade,
    bool? isProUpgrade,
    bool? isFastCompletion,
  }) async {
    try {
      for (final achievement in state.achievements) {
        if (achievement.isUnlocked) continue;

        bool shouldUpdate = false;
        int newProgress = achievement.progress;

        switch (achievement.requirementType) {
          case 'checklistsCreated':
            if (checklistsCreated != null) {
              newProgress = checklistsCreated;
              shouldUpdate = true;
            }
            break;
          case 'checklistsCompleted':
            if (checklistsCompleted != null) {
              newProgress = checklistsCompleted;
              shouldUpdate = true;
            }
            break;
          case 'itemsCompleted':
            if (itemsCompleted != null) {
              newProgress = itemsCompleted;
              shouldUpdate = true;
            }
            break;
          case 'consecutiveDays':
            if (consecutiveDays != null) {
              newProgress = consecutiveDays;
              shouldUpdate = true;
            }
            break;
          case 'dailyCompletions':
            if (dailyCompletions != null) {
              newProgress = dailyCompletions;
              shouldUpdate = true;
            }
            break;
          case 'earlyCompletions':
            if (isEarlyCompletion == true) {
              newProgress = 1;
              shouldUpdate = true;
            }
            break;
          case 'lateCompletions':
            if (isLateCompletion == true) {
              newProgress = 1;
              shouldUpdate = true;
            }
            break;
          case 'weekendCompletions':
            if (isWeekendCompletion == true) {
              newProgress = 1;
              shouldUpdate = true;
            }
            break;
          case 'premiumUpgrade':
            if (isPremiumUpgrade == true) {
              newProgress = 1;
              shouldUpdate = true;
            }
            break;
          case 'proUpgrade':
            if (isProUpgrade == true) {
              newProgress = 1;
              shouldUpdate = true;
            }
            break;
          case 'fastCompletions':
            if (isFastCompletion == true) {
              newProgress = 1;
              shouldUpdate = true;
            }
            break;
        }

        if (shouldUpdate) {
          await updateProgress(achievement.id, newProgress);
        }
      }
    } catch (e) {
      print('Error checking achievements: $e');
    }
  }

  // Refresh achievements
  Future<void> refresh() async {
    await loadAchievements();
  }

  // Get achievement by ID
  Achievement? getAchievementById(String id) {
    return state.getAchievementById(id);
  }

  // Get achievements by category
  List<Achievement> getAchievementsByCategory(AchievementCategory category) {
    return state.getAchievementsByCategory(category);
  }

  // Get recent achievements
  List<Achievement> get recentAchievements {
    return state.recentAchievements;
  }

  // Get achievements with progress
  List<Achievement> get achievementsWithProgress {
    return state.achievementsWithProgress;
  }

  // Check if session completion is fast (under 5 minutes)
  bool _isFastCompletion(DateTime startedAt, DateTime completedAt) {
    final duration = completedAt.difference(startedAt);
    return duration.inMinutes < 5;
  }

  // Check if completion time is early (before 9 AM)
  bool _isEarlyCompletion(DateTime completedAt) {
    return completedAt.hour < 9;
  }

  // Check if completion time is late (after 10 PM)
  bool _isLateCompletion(DateTime completedAt) {
    return completedAt.hour >= 22;
  }

  // Check if completion is on weekend
  bool _isWeekendCompletion(DateTime completedAt) {
    final weekday = completedAt.weekday;
    return weekday == DateTime.saturday || weekday == DateTime.sunday;
  }

  // Check achievements when session is completed
  Future<void> checkSessionCompletionAchievements({
    required DateTime sessionStartedAt,
    required DateTime sessionCompletedAt,
    required int totalItems,
    required int completedItems,
  }) async {
    try {
      // Validate inputs
      if (completedItems < 0) {
        print('Warning: completedItems is negative: $completedItems');
        return;
      }

      // First, increment the session completion stats
      await _repository.incrementSessionCompleted(
        completedItems: completedItems,
        completedAt: sessionCompletedAt,
      );

      // Track daily completion for efficiency achievements
      await _repository.trackDailyCompletion(sessionCompletedAt);

      // Check time-based achievements
      final isEarly = _isEarlyCompletion(sessionCompletedAt);
      final isLate = _isLateCompletion(sessionCompletedAt);
      final isWeekend = _isWeekendCompletion(sessionCompletedAt);
      final isFast = _isFastCompletion(sessionStartedAt, sessionCompletedAt);

      // Get updated stats after incrementing
      final stats = await _repository.loadAchievementStats();
      final totalCompletions = stats['totalCompletions'] ?? 0;
      final totalItemsCompleted = stats['totalItemsCompleted'] ?? 0;
      final consecutiveDays = stats['currentStreak'] ?? 0;
      final dailyCompletions = stats['dailyCompletions'] ?? 0;

      await checkAchievements(
        checklistsCompleted: totalCompletions,
        itemsCompleted: totalItemsCompleted,
        consecutiveDays: consecutiveDays,
        dailyCompletions: dailyCompletions,
        isEarlyCompletion: isEarly,
        isLateCompletion: isLate,
        isWeekendCompletion: isWeekend,
        isFastCompletion: isFast,
      );
    } catch (e) {
      print('Error checking session completion achievements: $e');
      // Don't rethrow - achievements shouldn't break session completion
    }
  }

  // Check achievements when checklist is created
  Future<void> checkChecklistCreationAchievements() async {
    try {
      // First, increment the checklist creation count
      await _repository.incrementChecklistCreated();

      // Get updated stats after incrementing
      final stats = await _repository.loadAchievementStats();
      final totalCreated = stats['totalCreated'] ?? 0;

      await checkAchievements(checklistsCreated: totalCreated);
    } catch (e) {
      print('Error checking checklist creation achievements: $e');
      // Don't rethrow - achievements shouldn't break checklist creation
    }
  }

  // Check achievements when user tier changes
  Future<void> checkUserTierAchievements({
    required bool isPremiumUpgrade,
    required bool isProUpgrade,
  }) async {
    try {
      await checkAchievements(
        isPremiumUpgrade: isPremiumUpgrade,
        isProUpgrade: isProUpgrade,
      );
    } catch (e) {
      print('Error checking user tier achievements: $e');
    }
  }

  // Clear all achievements (for testing)
  Future<void> clearAllAchievements() async {
    try {
      // Reset all achievements to initial state
      final resetAchievements = state.achievements.map((achievement) {
        return achievement.copyWith(
          isUnlocked: false,
          unlockedAt: null,
          progress: 0,
        );
      }).toList();

      // Update state
      state = state.copyWith(
        achievements: resetAchievements,
        unlockedAchievements: 0,
        achievementPoints: 0,
        currentStreak: 0,
        longestStreak: 0,
      );

      // Clear from repository
      await _repository.clearAllAchievements();
    } catch (e) {
      print('Error clearing achievements: $e');
      rethrow;
    }
  }
}
