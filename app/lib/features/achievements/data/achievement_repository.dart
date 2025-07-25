import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/achievement.dart';

class AchievementRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Load user achievements
  Future<List<Achievement>> loadUserAchievements() async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .get();

      return doc.docs.map((doc) => Achievement.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to load achievements: $e');
    }
  }

  // Load achievement stats
  Future<Map<String, dynamic>> loadAchievementStats() async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final doc = await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final achievementStats =
            data['achievementStats'] as Map<String, dynamic>? ?? {};

        return {
          'totalAchievements': achievementStats['totalAchievements'] ?? 0,
          'unlockedAchievements': achievementStats['unlockedAchievements'] ?? 0,
          'achievementPoints': achievementStats['achievementPoints'] ?? 0,
          'currentStreak': achievementStats['currentStreak'] ?? 0,
          'longestStreak': achievementStats['longestStreak'] ?? 0,
        };
      }

      return {
        'totalAchievements': 0,
        'unlockedAchievements': 0,
        'achievementPoints': 0,
        'currentStreak': 0,
        'longestStreak': 0,
      };
    } catch (e) {
      throw Exception('Failed to load achievement stats: $e');
    }
  }

  // Save achievement
  Future<void> saveAchievement(Achievement achievement) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .doc(achievement.id)
          .set(achievement.toFirestore());
    } catch (e) {
      throw Exception('Failed to save achievement: $e');
    }
  }

  // Update achievement progress
  Future<void> updateAchievementProgress(
    String achievementId,
    int progress,
  ) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .doc(achievementId)
          .update({
            'progress': progress,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Failed to update achievement progress: $e');
    }
  }

  // Unlock achievement
  Future<void> unlockAchievement(String achievementId) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .doc(achievementId)
          .update({
            'isUnlocked': true,
            'unlockedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Failed to unlock achievement: $e');
    }
  }

  // Update achievement stats
  Future<void> updateAchievementStats(Map<String, dynamic> stats) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore.collection('users').doc(userId).update({
        'achievementStats': stats,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update achievement stats: $e');
    }
  }

  // Initialize default achievements for a user
  Future<void> initializeDefaultAchievements() async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Check if achievements already exist
      final existingAchievements = await loadUserAchievements();
      if (existingAchievements.isNotEmpty) {
        return; // Already initialized
      }

      // Create default achievements
      final defaultAchievements = _getDefaultAchievements();

      // Save each achievement
      for (final achievement in defaultAchievements) {
        await saveAchievement(achievement);
      }

      // Initialize stats
      await updateAchievementStats({
        'totalAchievements': defaultAchievements.length,
        'unlockedAchievements': 0,
        'achievementPoints': 0,
        'currentStreak': 0,
        'longestStreak': 0,
      });
    } catch (e) {
      throw Exception('Failed to initialize default achievements: $e');
    }
  }

  // Get default achievements
  List<Achievement> _getDefaultAchievements() {
    return [
      // Getting Started
      const Achievement(
        id: 'first_checklist',
        titleKey: 'achievement_first_checklist',
        descriptionKey: 'achievement_desc_first_checklist',
        icon: 'add_task',
        category: AchievementCategory.gettingStarted,
        rarity: AchievementRarity.common,
        requirement: 1,
        requirementType: 'checklistsCreated',
        maxProgress: 1,
      ),
      const Achievement(
        id: 'first_completion',
        titleKey: 'achievement_first_completion',
        descriptionKey: 'achievement_desc_first_completion',
        icon: 'task_alt',
        category: AchievementCategory.gettingStarted,
        rarity: AchievementRarity.common,
        requirement: 1,
        requirementType: 'checklistsCompleted',
        maxProgress: 1,
      ),
      const Achievement(
        id: 'early_bird',
        titleKey: 'achievement_early_bird',
        descriptionKey: 'achievement_desc_early_bird',
        icon: 'wb_sunny',
        category: AchievementCategory.gettingStarted,
        rarity: AchievementRarity.uncommon,
        requirement: 1,
        requirementType: 'earlyCompletions',
        maxProgress: 1,
      ),
      const Achievement(
        id: 'night_owl',
        titleKey: 'achievement_night_owl',
        descriptionKey: 'achievement_desc_night_owl',
        icon: 'nightlight',
        category: AchievementCategory.gettingStarted,
        rarity: AchievementRarity.uncommon,
        requirement: 1,
        requirementType: 'lateCompletions',
        maxProgress: 1,
      ),

      // Productivity
      const Achievement(
        id: 'checklist_master',
        titleKey: 'achievement_checklist_master',
        descriptionKey: 'achievement_desc_checklist_master',
        icon: 'library_books',
        category: AchievementCategory.productivity,
        rarity: AchievementRarity.uncommon,
        requirement: 10,
        requirementType: 'checklistsCreated',
        maxProgress: 10,
      ),
      const Achievement(
        id: 'completionist',
        titleKey: 'achievement_completionist',
        descriptionKey: 'achievement_desc_completionist',
        icon: 'assignment_turned_in',
        category: AchievementCategory.productivity,
        rarity: AchievementRarity.rare,
        requirement: 25,
        requirementType: 'checklistsCompleted',
        maxProgress: 25,
      ),
      const Achievement(
        id: 'item_champion',
        titleKey: 'achievement_item_champion',
        descriptionKey: 'achievement_desc_item_champion',
        icon: 'check_circle',
        category: AchievementCategory.productivity,
        rarity: AchievementRarity.rare,
        requirement: 100,
        requirementType: 'itemsCompleted',
        maxProgress: 100,
      ),
      const Achievement(
        id: 'streak_master',
        titleKey: 'achievement_streak_master',
        descriptionKey: 'achievement_desc_streak_master',
        icon: 'local_fire_department',
        category: AchievementCategory.productivity,
        rarity: AchievementRarity.rare,
        requirement: 7,
        requirementType: 'consecutiveDays',
        maxProgress: 7,
      ),
      const Achievement(
        id: 'speed_demon',
        titleKey: 'achievement_speed_demon',
        descriptionKey: 'achievement_desc_speed_demon',
        icon: 'speed',
        category: AchievementCategory.productivity,
        rarity: AchievementRarity.uncommon,
        requirement: 1,
        requirementType: 'fastCompletions',
        maxProgress: 1,
      ),

      // Advanced
      const Achievement(
        id: 'checklist_creator',
        titleKey: 'achievement_checklist_creator',
        descriptionKey: 'achievement_desc_checklist_creator',
        icon: 'create',
        category: AchievementCategory.advanced,
        rarity: AchievementRarity.epic,
        requirement: 50,
        requirementType: 'checklistsCreated',
        maxProgress: 50,
      ),
      const Achievement(
        id: 'completion_legend',
        titleKey: 'achievement_completion_legend',
        descriptionKey: 'achievement_desc_completion_legend',
        icon: 'emoji_events',
        category: AchievementCategory.advanced,
        rarity: AchievementRarity.epic,
        requirement: 100,
        requirementType: 'checklistsCompleted',
        maxProgress: 100,
      ),
      const Achievement(
        id: 'item_legend',
        titleKey: 'achievement_item_legend',
        descriptionKey: 'achievement_desc_item_legend',
        icon: 'stars',
        category: AchievementCategory.advanced,
        rarity: AchievementRarity.epic,
        requirement: 500,
        requirementType: 'itemsCompleted',
        maxProgress: 500,
      ),
      const Achievement(
        id: 'streak_legend',
        titleKey: 'achievement_streak_legend',
        descriptionKey: 'achievement_desc_streak_legend',
        icon: 'whatshot',
        category: AchievementCategory.advanced,
        rarity: AchievementRarity.legendary,
        requirement: 30,
        requirementType: 'consecutiveDays',
        maxProgress: 30,
      ),
      const Achievement(
        id: 'efficiency_expert',
        titleKey: 'achievement_efficiency_expert',
        descriptionKey: 'achievement_desc_efficiency_expert',
        icon: 'rocket_launch',
        category: AchievementCategory.advanced,
        rarity: AchievementRarity.epic,
        requirement: 10,
        requirementType: 'dailyCompletions',
        maxProgress: 10,
      ),

      // Premium
      const Achievement(
        id: 'premium_pioneer',
        titleKey: 'achievement_premium_pioneer',
        descriptionKey: 'achievement_desc_premium_pioneer',
        icon: 'workspace_premium',
        category: AchievementCategory.premium,
        rarity: AchievementRarity.rare,
        requirement: 1,
        requirementType: 'premiumUpgrade',
        maxProgress: 1,
      ),
      const Achievement(
        id: 'pro_power',
        titleKey: 'achievement_pro_power',
        descriptionKey: 'achievement_desc_pro_power',
        icon: 'diamond',
        category: AchievementCategory.premium,
        rarity: AchievementRarity.epic,
        requirement: 1,
        requirementType: 'proUpgrade',
        maxProgress: 1,
      ),

      // Special
      const Achievement(
        id: 'weekend_warrior',
        titleKey: 'achievement_weekend_warrior',
        descriptionKey: 'achievement_desc_weekend_warrior',
        icon: 'weekend',
        category: AchievementCategory.special,
        rarity: AchievementRarity.uncommon,
        requirement: 1,
        requirementType: 'weekendCompletions',
        maxProgress: 1,
      ),
      const Achievement(
        id: 'consistency_king',
        titleKey: 'achievement_consistency_king',
        descriptionKey: 'achievement_desc_consistency_king',
        icon: 'calendar_today',
        category: AchievementCategory.special,
        rarity: AchievementRarity.legendary,
        requirement: 100,
        requirementType: 'consecutiveDays',
        maxProgress: 100,
      ),
    ];
  }

  // Increment checklist creation count
  Future<void> incrementChecklistCreated() async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final stats = await loadAchievementStats();
      final currentCount = stats['totalCreated'] ?? 0;

      await updateAchievementStats({
        ...stats,
        'totalCreated': currentCount + 1,
      });
    } catch (e) {
      throw Exception('Failed to increment checklist created count: $e');
    }
  }

  // Increment session completion count
  Future<void> incrementSessionCompleted({
    required int completedItems,
    required DateTime completedAt,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final stats = await loadAchievementStats();
      final currentCompletions = stats['totalCompletions'] ?? 0;
      final currentItemsCompleted = stats['totalItemsCompleted'] ?? 0;
      final currentStreak = stats['currentStreak'] ?? 0;
      final longestStreak = stats['longestStreak'] ?? 0;

      // Update completion counts
      final newStats = {
        ...stats,
        'totalCompletions': currentCompletions + 1,
        'totalItemsCompleted': currentItemsCompleted + completedItems,
      };

      // Update streak logic
      final today = DateTime.now();
      final lastCompletionDate = stats['lastCompletionDate'];

      if (lastCompletionDate != null) {
        final lastDate = (lastCompletionDate as Timestamp).toDate();
        final daysDifference = today.difference(lastDate).inDays;

        if (daysDifference == 1) {
          // Consecutive day
          final newStreak = currentStreak + 1;
          newStats['currentStreak'] = newStreak;
          newStats['longestStreak'] = newStreak > longestStreak
              ? newStreak
              : longestStreak;
        } else if (daysDifference > 1) {
          // Streak broken
          newStats['currentStreak'] = 1;
        }
      } else {
        // First completion
        newStats['currentStreak'] = 1;
        newStats['longestStreak'] = 1;
      }

      newStats['lastCompletionDate'] = Timestamp.fromDate(today);

      await updateAchievementStats(newStats);
    } catch (e) {
      throw Exception('Failed to increment session completed count: $e');
    }
  }

  // Track daily completions for efficiency achievements
  Future<void> trackDailyCompletion(DateTime completedAt) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final stats = await loadAchievementStats();
      final today = DateTime(
        completedAt.year,
        completedAt.month,
        completedAt.day,
      );
      final lastCompletionDate = stats['lastCompletionDate'];

      int dailyCompletions = stats['dailyCompletions'] ?? 0;

      if (lastCompletionDate != null) {
        final lastDate = (lastCompletionDate as Timestamp).toDate();
        final lastDateOnly = DateTime(
          lastDate.year,
          lastDate.month,
          lastDate.day,
        );

        if (today.isAtSameMomentAs(lastDateOnly)) {
          // Same day, increment count
          dailyCompletions++;
        } else {
          // New day, reset count
          dailyCompletions = 1;
        }
      } else {
        // First completion ever
        dailyCompletions = 1;
      }

      await updateAchievementStats({
        ...stats,
        'dailyCompletions': dailyCompletions,
        'lastCompletionDate': Timestamp.fromDate(completedAt),
      });
    } catch (e) {
      throw Exception('Failed to track daily completion: $e');
    }
  }

  // Clear all achievements (for testing)
  Future<void> clearAllAchievements() async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get all user achievements
      final achievements = await loadUserAchievements();

      // Reset each achievement
      for (final achievement in achievements) {
        final resetAchievement = achievement.copyWith(
          isUnlocked: false,
          unlockedAt: null,
          progress: 0,
        );
        await saveAchievement(resetAchievement);
      }

      // Reset stats
      await updateAchievementStats({
        'unlockedAchievements': 0,
        'achievementPoints': 0,
        'currentStreak': 0,
        'longestStreak': 0,
      });
    } catch (e) {
      throw Exception('Failed to clear achievements: $e');
    }
  }
}
