import 'achievement.dart';

enum AchievementLoadingState { initial, loading, loaded, error }

class AchievementState {
  final AchievementLoadingState loadingState;
  final List<Achievement> achievements;
  final String? error;
  final int totalAchievements;
  final int unlockedAchievements;
  final int achievementPoints;
  final int currentStreak;
  final int longestStreak;

  const AchievementState({
    this.loadingState = AchievementLoadingState.initial,
    this.achievements = const [],
    this.error,
    this.totalAchievements = 0,
    this.unlockedAchievements = 0,
    this.achievementPoints = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
  });

  // Copy with method for updating state
  AchievementState copyWith({
    AchievementLoadingState? loadingState,
    List<Achievement>? achievements,
    String? error,
    int? totalAchievements,
    int? unlockedAchievements,
    int? achievementPoints,
    int? currentStreak,
    int? longestStreak,
  }) {
    return AchievementState(
      loadingState: loadingState ?? this.loadingState,
      achievements: achievements ?? this.achievements,
      error: error ?? this.error,
      totalAchievements: totalAchievements ?? this.totalAchievements,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      achievementPoints: achievementPoints ?? this.achievementPoints,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
    );
  }

  // Get achievements by category
  List<Achievement> getAchievementsByCategory(AchievementCategory category) {
    return achievements
        .where((achievement) => achievement.category == category)
        .toList();
  }

  // Get unlocked achievements
  List<Achievement> get unlockedAchievementsList {
    return achievements.where((achievement) => achievement.isUnlocked).toList();
  }

  // Get locked achievements
  List<Achievement> get lockedAchievementsList {
    return achievements
        .where((achievement) => !achievement.isUnlocked)
        .toList();
  }

  // Get achievements with progress
  List<Achievement> get achievementsWithProgress {
    return achievements
        .where((achievement) => achievement.progress > 0)
        .toList();
  }

  // Get completion percentage
  double get completionPercentage {
    if (totalAchievements == 0) return 0.0;
    return unlockedAchievements / totalAchievements;
  }

  // Get recent achievements (last 5 unlocked)
  List<Achievement> get recentAchievements {
    final unlocked = unlockedAchievementsList;
    unlocked.sort(
      (a, b) => (b.unlockedAt ?? DateTime.now()).compareTo(
        a.unlockedAt ?? DateTime.now(),
      ),
    );
    return unlocked.take(5).toList();
  }

  // Check if loading
  bool get isLoading => loadingState == AchievementLoadingState.loading;

  // Check if loaded
  bool get isLoaded => loadingState == AchievementLoadingState.loaded;

  // Check if error
  bool get hasError => loadingState == AchievementLoadingState.error;

  // Get achievement by ID
  Achievement? getAchievementById(String id) {
    try {
      return achievements.firstWhere((achievement) => achievement.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get achievements by rarity
  List<Achievement> getAchievementsByRarity(AchievementRarity rarity) {
    return achievements
        .where((achievement) => achievement.rarity == rarity)
        .toList();
  }

  // Get rarity counts
  Map<AchievementRarity, int> get rarityCounts {
    final counts = <AchievementRarity, int>{};
    for (final rarity in AchievementRarity.values) {
      counts[rarity] = getAchievementsByRarity(rarity).length;
    }
    return counts;
  }

  // Get unlocked rarity counts
  Map<AchievementRarity, int> get unlockedRarityCounts {
    final counts = <AchievementRarity, int>{};
    for (final rarity in AchievementRarity.values) {
      counts[rarity] = getAchievementsByRarity(
        rarity,
      ).where((achievement) => achievement.isUnlocked).length;
    }
    return counts;
  }
}
