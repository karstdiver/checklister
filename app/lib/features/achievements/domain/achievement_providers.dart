import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'achievement_notifier.dart';
import 'achievement_state.dart';
import 'achievement.dart';
import '../data/achievement_repository.dart';

// Repository provider
final achievementRepositoryProvider = Provider<AchievementRepository>((ref) {
  return AchievementRepository();
});

// Notifier provider
final achievementNotifierProvider =
    StateNotifierProvider<AchievementNotifier, AchievementState>((ref) {
      final repository = ref.watch(achievementRepositoryProvider);
      return AchievementNotifier(repository);
    });

// Convenience providers for specific data
final achievementsProvider = Provider<List<Achievement>>((ref) {
  final state = ref.watch(achievementNotifierProvider);
  return state.achievements;
});

final unlockedAchievementsProvider = Provider<List<Achievement>>((ref) {
  final state = ref.watch(achievementNotifierProvider);
  return state.unlockedAchievementsList;
});

final lockedAchievementsProvider = Provider<List<Achievement>>((ref) {
  final state = ref.watch(achievementNotifierProvider);
  return state.lockedAchievementsList;
});

final recentAchievementsProvider = Provider<List<Achievement>>((ref) {
  final state = ref.watch(achievementNotifierProvider);
  return state.recentAchievements;
});

final achievementsWithProgressProvider = Provider<List<Achievement>>((ref) {
  final state = ref.watch(achievementNotifierProvider);
  return state.achievementsWithProgress;
});

// Stats providers
final achievementStatsProvider = Provider<Map<String, int>>((ref) {
  final state = ref.watch(achievementNotifierProvider);
  return {
    'totalAchievements': state.totalAchievements,
    'unlockedAchievements': state.unlockedAchievements,
    'achievementPoints': state.achievementPoints,
    'currentStreak': state.currentStreak,
    'longestStreak': state.longestStreak,
  };
});

final completionPercentageProvider = Provider<double>((ref) {
  final state = ref.watch(achievementNotifierProvider);
  return state.completionPercentage;
});

// Category-based providers
final achievementsByCategoryProvider =
    Provider.family<List<Achievement>, AchievementCategory>((ref, category) {
      final state = ref.watch(achievementNotifierProvider);
      return state.getAchievementsByCategory(category);
    });

// Rarity-based providers
final rarityCountsProvider = Provider<Map<AchievementRarity, int>>((ref) {
  final state = ref.watch(achievementNotifierProvider);
  return state.rarityCounts;
});

final unlockedRarityCountsProvider = Provider<Map<AchievementRarity, int>>((
  ref,
) {
  final state = ref.watch(achievementNotifierProvider);
  return state.unlockedRarityCounts;
});

// Loading state providers
final isLoadingAchievementsProvider = Provider<bool>((ref) {
  final state = ref.watch(achievementNotifierProvider);
  return state.isLoading;
});

final hasAchievementErrorProvider = Provider<bool>((ref) {
  final state = ref.watch(achievementNotifierProvider);
  return state.hasError;
});

final achievementErrorProvider = Provider<String?>((ref) {
  final state = ref.watch(achievementNotifierProvider);
  return state.error;
});
