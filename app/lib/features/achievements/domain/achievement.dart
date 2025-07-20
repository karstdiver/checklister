import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/translation_service.dart';

enum AchievementCategory {
  gettingStarted,
  productivity,
  advanced,
  premium,
  special,
}

enum AchievementRarity {
  common, // Bronze badge
  uncommon, // Silver badge
  rare, // Gold badge
  epic, // Purple badge
  legendary, // Rainbow badge
}

class Achievement {
  final String id;
  final String titleKey;
  final String descriptionKey;
  final String icon;
  final AchievementCategory category;
  final AchievementRarity rarity;
  final int requirement;
  final String requirementType;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int progress;
  final int maxProgress;

  const Achievement({
    required this.id,
    required this.titleKey,
    required this.descriptionKey,
    required this.icon,
    required this.category,
    required this.rarity,
    required this.requirement,
    required this.requirementType,
    this.isUnlocked = false,
    this.unlockedAt,
    this.progress = 0,
    required this.maxProgress,
  });

  // Get translated title
  String get title => TranslationService.translate(titleKey);

  // Get translated description
  String get description => TranslationService.translate(descriptionKey);

  // Create from Firestore document
  factory Achievement.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Achievement(
      id: doc.id,
      titleKey: data['titleKey'] ?? 'achievement_${doc.id}',
      descriptionKey: data['descriptionKey'] ?? 'achievement_desc_${doc.id}',
      icon: data['icon'] ?? 'emoji_events',
      category: AchievementCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => AchievementCategory.gettingStarted,
      ),
      rarity: AchievementRarity.values.firstWhere(
        (e) => e.name == data['rarity'],
        orElse: () => AchievementRarity.common,
      ),
      requirement: data['requirement'] ?? 1,
      requirementType: data['requirementType'] ?? '',
      isUnlocked: data['isUnlocked'] ?? false,
      unlockedAt: data['unlockedAt'] != null
          ? (data['unlockedAt'] as Timestamp).toDate()
          : null,
      progress: data['progress'] ?? 0,
      maxProgress: data['maxProgress'] ?? 1,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'titleKey': titleKey,
      'descriptionKey': descriptionKey,
      'icon': icon,
      'category': category.name,
      'rarity': rarity.name,
      'requirement': requirement,
      'requirementType': requirementType,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt != null ? Timestamp.fromDate(unlockedAt!) : null,
      'progress': progress,
      'maxProgress': maxProgress,
    };
  }

  // Copy with method for updating
  Achievement copyWith({
    String? id,
    String? titleKey,
    String? descriptionKey,
    String? icon,
    AchievementCategory? category,
    AchievementRarity? rarity,
    int? requirement,
    String? requirementType,
    bool? isUnlocked,
    DateTime? unlockedAt,
    int? progress,
    int? maxProgress,
  }) {
    return Achievement(
      id: id ?? this.id,
      titleKey: titleKey ?? this.titleKey,
      descriptionKey: descriptionKey ?? this.descriptionKey,
      icon: icon ?? this.icon,
      category: category ?? this.category,
      rarity: rarity ?? this.rarity,
      requirement: requirement ?? this.requirement,
      requirementType: requirementType ?? this.requirementType,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      progress: progress ?? this.progress,
      maxProgress: maxProgress ?? this.maxProgress,
    );
  }

  // Get progress percentage
  double get progressPercentage =>
      maxProgress > 0 ? progress / maxProgress : 0.0;

  // Get rarity color
  int get rarityColor {
    switch (rarity) {
      case AchievementRarity.common:
        return 0xFFCD7F32; // Bronze
      case AchievementRarity.uncommon:
        return 0xFFC0C0C0; // Silver
      case AchievementRarity.rare:
        return 0xFFFFD700; // Gold
      case AchievementRarity.epic:
        return 0xFF800080; // Purple
      case AchievementRarity.legendary:
        return 0xFFFF1493; // Deep Pink (Rainbow-like)
    }
  }

  // Get category display name
  String get categoryDisplayName {
    switch (category) {
      case AchievementCategory.gettingStarted:
        return TranslationService.translate('achievement_getting_started');
      case AchievementCategory.productivity:
        return TranslationService.translate('achievement_productivity');
      case AchievementCategory.advanced:
        return TranslationService.translate('achievement_advanced');
      case AchievementCategory.premium:
        return TranslationService.translate('achievement_premium');
      case AchievementCategory.special:
        return TranslationService.translate('achievement_special');
    }
  }

  // Get rarity display name
  String get rarityDisplayName {
    switch (rarity) {
      case AchievementRarity.common:
        return TranslationService.translate('achievement_common');
      case AchievementRarity.uncommon:
        return TranslationService.translate('achievement_uncommon');
      case AchievementRarity.rare:
        return TranslationService.translate('achievement_rare');
      case AchievementRarity.epic:
        return TranslationService.translate('achievement_epic');
      case AchievementRarity.legendary:
        return TranslationService.translate('achievement_legendary');
    }
  }
}
