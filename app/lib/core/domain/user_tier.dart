enum UserTier { anonymous, free, premium, pro }

class UserPrivileges {
  final UserTier tier;
  final bool isActive;
  final DateTime? expiresAt;
  final Map<String, dynamic> features;
  final Map<String, int> usage;

  const UserPrivileges({
    required this.tier,
    required this.isActive,
    this.expiresAt,
    required this.features,
    required this.usage,
  });

  // Feature access checks
  bool get canCreateChecklists =>
      tier != UserTier.anonymous &&
      (features['maxChecklists'] == -1 ||
          (usage['checklistsCreated'] ?? 0) <
              (features['maxChecklists'] as int));

  bool get canPersistSessions => features['sessionPersistence'] == true;

  bool get hasAnalytics => features['analytics'] == true;

  bool get canExport => features['export'] == true;

  bool get canShare => features['sharing'] == true;

  bool get hasCustomThemes => features['customThemes'] == true;

  bool get hasPrioritySupport => features['prioritySupport'] == true;

  // Enhanced feature checks for anonymous vs authenticated
  bool get canEditChecklists => features['canEditChecklists'] == true;

  bool get canDeleteChecklists => features['canDeleteChecklists'] == true;

  bool get canDuplicateChecklists => features['canDuplicateChecklists'] == true;

  bool get hasSessionHistory => features['sessionHistory'] == true;

  bool get hasChecklistTemplates => features['checklistTemplates'] == true;

  bool get hasDataBackup => features['dataBackup'] == true;

  bool get canUseAdvancedFeatures => features['canUseAdvancedFeatures'] == true;

  // Profile customization features
  bool get canCustomizeProfile => features['profileCustomization'] == true;
  bool get canUseProfilePictures => features['profilePictures'] == true;

  // Tier status getters
  bool get isAnonymous => tier == UserTier.anonymous;
  bool get isFree => tier == UserTier.free;
  bool get isPremium => tier == UserTier.premium;
  bool get isPro => tier == UserTier.pro;

  // Generic feature check
  bool hasFeature(String feature) {
    return features[feature] == true;
  }

  // Usage limit checks
  bool canCreateChecklistWithItems(int itemCount) {
    if (tier == UserTier.anonymous) return false;
    final maxItems = features['maxItemsPerChecklist'] as int;
    return maxItems == -1 || itemCount <= maxItems;
  }

  // Subscription status
  bool get isSubscriptionExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  // Tier-specific limits
  int get maxChecklists => features['maxChecklists'] as int;
  int get maxItemsPerChecklist => features['maxItemsPerChecklist'] as int;

  // Factory methods for different tiers
  factory UserPrivileges.anonymous() {
    return const UserPrivileges(
      tier: UserTier.anonymous,
      isActive: true,
      features: {
        'maxChecklists': 1,
        'maxItemsPerChecklist': 3,
        'sessionPersistence': false,
        'analytics': false,
        'export': false,
        'sharing': false,
        'customThemes': false,
        'prioritySupport': false,
        'canEditChecklists': false,
        'canDeleteChecklists': false,
        'canDuplicateChecklists': false,
        'sessionHistory': false,
        'checklistTemplates': false,
        'dataBackup': false,
        'canUseAdvancedFeatures': false,
        'profileCustomization': false,
        'profilePictures': false,
        // Notification features
        'basicNotifications': true,
        'reminderNotifications': true,
        'progressNotifications': false,
        'achievementNotifications': false,
        'weeklyReports': false,
        'customReminders': false,
        'smartSuggestions': false,
        'teamNotifications': false,
      },
      usage: {'checklistsCreated': 0, 'sessionsCompleted': 0},
    );
  }

  factory UserPrivileges.free() {
    return const UserPrivileges(
      tier: UserTier.free,
      isActive: true,
      features: {
        'maxChecklists': 5,
        'maxItemsPerChecklist': 15,
        'sessionPersistence': true,
        'analytics': false,
        'export': false,
        'sharing': false,
        'customThemes': false,
        'prioritySupport': false,
        'canEditChecklists': true,
        'canDeleteChecklists': true,
        'canDuplicateChecklists': true,
        'sessionHistory': true,
        'checklistTemplates': true,
        'dataBackup': true,
        'canUseAdvancedFeatures': true,
        'profileCustomization': true,
        'profilePictures': false,
        // Notification features
        'basicNotifications': true,
        'reminderNotifications': true,
        'progressNotifications': true,
        'achievementNotifications': true,
        'weeklyReports': false,
        'customReminders': false,
        'smartSuggestions': false,
        'teamNotifications': false,
      },
      usage: {'checklistsCreated': 0, 'sessionsCompleted': 0},
    );
  }

  factory UserPrivileges.premium() {
    return const UserPrivileges(
      tier: UserTier.premium,
      isActive: true,
      features: {
        'maxChecklists': 50,
        'maxItemsPerChecklist': 100,
        'sessionPersistence': true,
        'analytics': true,
        'export': true,
        'sharing': true,
        'customThemes': false,
        'prioritySupport': false,
        'canEditChecklists': true,
        'canDeleteChecklists': true,
        'canDuplicateChecklists': true,
        'sessionHistory': true,
        'checklistTemplates': true,
        'dataBackup': true,
        'canUseAdvancedFeatures': true,
        'profileCustomization': true,
        'profilePictures': true,
        // Notification features
        'basicNotifications': true,
        'reminderNotifications': true,
        'progressNotifications': true,
        'achievementNotifications': true,
        'weeklyReports': true,
        'customReminders': true,
        'smartSuggestions': true,
        'teamNotifications': false,
      },
      usage: {'checklistsCreated': 0, 'sessionsCompleted': 0},
    );
  }

  factory UserPrivileges.pro() {
    return const UserPrivileges(
      tier: UserTier.pro,
      isActive: true,
      features: {
        'maxChecklists': -1, // unlimited
        'maxItemsPerChecklist': -1, // unlimited
        'sessionPersistence': true,
        'analytics': true,
        'export': true,
        'sharing': true,
        'customThemes': true,
        'prioritySupport': true,
        'canEditChecklists': true,
        'canDeleteChecklists': true,
        'canDuplicateChecklists': true,
        'sessionHistory': true,
        'checklistTemplates': true,
        'dataBackup': true,
        'canUseAdvancedFeatures': true,
        'profileCustomization': true,
        'profilePictures': true,
        // Notification features
        'basicNotifications': true,
        'reminderNotifications': true,
        'progressNotifications': true,
        'achievementNotifications': true,
        'weeklyReports': true,
        'customReminders': true,
        'smartSuggestions': true,
        'teamNotifications': true,
      },
      usage: {'checklistsCreated': 0, 'sessionsCompleted': 0},
    );
  }

  // Copy with methods for updating usage
  UserPrivileges copyWith({
    UserTier? tier,
    bool? isActive,
    DateTime? expiresAt,
    Map<String, dynamic>? features,
    Map<String, int>? usage,
  }) {
    return UserPrivileges(
      tier: tier ?? this.tier,
      isActive: isActive ?? this.isActive,
      expiresAt: expiresAt ?? this.expiresAt,
      features: features ?? this.features,
      usage: usage ?? this.usage,
    );
  }

  // Update usage
  UserPrivileges incrementUsage(String key, [int amount = 1]) {
    final newUsage = Map<String, int>.from(usage);
    newUsage[key] = (newUsage[key] ?? 0) + amount;
    return copyWith(usage: newUsage);
  }
}
