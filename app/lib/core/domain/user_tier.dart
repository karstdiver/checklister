enum UserTier { anonymous, free, premium, pro }

/// Admin role enum - separate from business tiers
enum AdminRole { none, moderator, admin, superAdmin }

class UserPrivileges {
  final UserTier tier;
  final AdminRole adminRole; // NEW: Separate admin role
  final bool isActive;
  final DateTime? expiresAt;
  final Map<String, dynamic> features;
  final Map<String, int> usage;

  const UserPrivileges({
    required this.tier,
    this.adminRole = AdminRole.none, // Default to no admin role
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

  // Achievement features
  bool get hasAchievements => features['achievements'] == true;
  bool get hasAchievementNotifications =>
      features['achievementNotifications'] == true;

  bool get hasAchievementLeaderboards =>
      features['achievementLeaderboards'] == true;

  // NEW: Admin privilege checks
  bool get isAdmin => adminRole != AdminRole.none;
  bool get isModerator =>
      adminRole == AdminRole.moderator ||
      adminRole == AdminRole.admin ||
      adminRole == AdminRole.superAdmin;
  bool get isFullAdmin =>
      adminRole == AdminRole.admin || adminRole == AdminRole.superAdmin;
  bool get isSuperAdmin => adminRole == AdminRole.superAdmin;

  // NEW: Admin-specific permissions
  bool get canManageUsers => isFullAdmin;
  bool get canManageSystem => isFullAdmin;
  bool get canViewAnalytics => isModerator;
  bool get canCleanupAllData => isFullAdmin;
  bool get canManageTTL => isFullAdmin;
  bool get canAccessAdminPanel => isModerator;

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
      adminRole: AdminRole.none, // No admin role for anonymous users
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
        'itemPhotos': false,
        // Notification features
        'basicNotifications': true,
        'reminderNotifications': true,
        'progressNotifications': false,
        'achievementNotifications': false,
        'weeklyReports': false,
        'customReminders': false,
        'smartSuggestions': false,
        'teamNotifications': false,
        // Achievement features
        'achievements': false,
        'achievementSharing': false,
        'achievementLeaderboards': false,
      },
      usage: {'checklistsCreated': 0, 'sessionsCompleted': 0},
    );
  }

  factory UserPrivileges.free() {
    return const UserPrivileges(
      tier: UserTier.free,
      adminRole: AdminRole.none, // No admin role for free users
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
        'itemPhotos': false,
        // Notification features
        'basicNotifications': true,
        'reminderNotifications': true,
        'progressNotifications': true,
        'achievementNotifications': true,
        'weeklyReports': false,
        'customReminders': false,
        'smartSuggestions': false,
        'teamNotifications': false,
        // Achievement features
        'achievements': true,
        'achievementSharing': false,
        'achievementLeaderboards': false,
      },
      usage: {'checklistsCreated': 0, 'sessionsCompleted': 0},
    );
  }

  factory UserPrivileges.premium() {
    return const UserPrivileges(
      tier: UserTier.premium,
      adminRole: AdminRole.none, // No admin role for premium users
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
        'itemPhotos': true,
        // Notification features
        'basicNotifications': true,
        'reminderNotifications': true,
        'progressNotifications': true,
        'achievementNotifications': true,
        'weeklyReports': true,
        'customReminders': true,
        'smartSuggestions': true,
        'teamNotifications': false,
        // Achievement features
        'achievements': true,
        'achievementSharing': true,
        'achievementLeaderboards': false,
      },
      usage: {'checklistsCreated': 0, 'sessionsCompleted': 0},
    );
  }

  factory UserPrivileges.pro() {
    return const UserPrivileges(
      tier: UserTier.pro,
      adminRole: AdminRole.none, // Pro users are NOT admins by default
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
        'itemPhotos': true,
        // Notification features
        'basicNotifications': true,
        'reminderNotifications': true,
        'progressNotifications': true,
        'achievementNotifications': true,
        'weeklyReports': true,
        'customReminders': true,
        'smartSuggestions': true,
        'teamNotifications': true,
        // Achievement features
        'achievements': true,
        'achievementSharing': true,
        'achievementLeaderboards': true,
      },
      usage: {'checklistsCreated': 0, 'sessionsCompleted': 0},
    );
  }

  // NEW: Admin factory methods
  factory UserPrivileges.moderator({UserTier tier = UserTier.free}) {
    final basePrivileges = _getBasePrivileges(tier);
    return basePrivileges.copyWith(adminRole: AdminRole.moderator);
  }

  factory UserPrivileges.admin({UserTier tier = UserTier.free}) {
    final basePrivileges = _getBasePrivileges(tier);
    return basePrivileges.copyWith(adminRole: AdminRole.admin);
  }

  factory UserPrivileges.superAdmin({UserTier tier = UserTier.free}) {
    final basePrivileges = _getBasePrivileges(tier);
    return basePrivileges.copyWith(adminRole: AdminRole.superAdmin);
  }

  // Helper method to get base privileges for admin roles
  static UserPrivileges _getBasePrivileges(UserTier tier) {
    switch (tier) {
      case UserTier.anonymous:
        return UserPrivileges.anonymous();
      case UserTier.free:
        return UserPrivileges.free();
      case UserTier.premium:
        return UserPrivileges.premium();
      case UserTier.pro:
        return UserPrivileges.pro();
    }
  }

  // Copy with methods for updating usage
  UserPrivileges copyWith({
    UserTier? tier,
    AdminRole? adminRole,
    bool? isActive,
    DateTime? expiresAt,
    Map<String, dynamic>? features,
    Map<String, int>? usage,
  }) {
    return UserPrivileges(
      tier: tier ?? this.tier,
      adminRole: adminRole ?? this.adminRole,
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
