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
        'maxItemsPerChecklist': 5,
        'sessionPersistence': false,
        'analytics': false,
        'export': false,
        'sharing': false,
        'customThemes': false,
        'prioritySupport': false,
      },
      usage: {'checklistsCreated': 0, 'sessionsCompleted': 0},
    );
  }

  factory UserPrivileges.free() {
    return const UserPrivileges(
      tier: UserTier.free,
      isActive: true,
      features: {
        'maxChecklists': 3,
        'maxItemsPerChecklist': 10,
        'sessionPersistence': false,
        'analytics': false,
        'export': false,
        'sharing': false,
        'customThemes': false,
        'prioritySupport': false,
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
