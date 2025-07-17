import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/user_tier.dart';
import '../../features/auth/domain/auth_notifier.dart';
import '../../features/auth/data/user_repository.dart';
import '../../features/auth/data/user_models.dart';
import 'providers.dart';

final privilegeProvider =
    StateNotifierProvider<PrivilegeNotifier, UserPrivileges?>(
      (ref) => PrivilegeNotifier(
        ref.watch(userRepositoryProvider),
        ref.watch(authNotifierProvider.notifier),
      ),
    );

class PrivilegeNotifier extends StateNotifier<UserPrivileges?> {
  final UserRepository _userRepository;
  final AuthNotifier _authNotifier;

  PrivilegeNotifier(this._userRepository, this._authNotifier) : super(null) {
    _initializePrivileges();
  }

  Future<void> _initializePrivileges() async {
    final user = _authNotifier.state.user;
    if (user == null) {
      state = UserPrivileges.anonymous();
    } else {
      await _loadUserPrivileges(user.uid);
    }
  }

  Future<void> _loadUserPrivileges(String userId) async {
    try {
      final userDoc = await _userRepository.getUserDocument(userId);
      if (userDoc != null) {
        state = _buildPrivilegesFromUserDoc(userDoc);
      } else {
        // New authenticated user - default to free tier
        state = UserPrivileges.free();
        await _createUserDocumentWithTier(userId);
      }
    } catch (e) {
      // Fallback to free tier if there's an error
      state = UserPrivileges.free();
    }
  }

  UserPrivileges _buildPrivilegesFromUserDoc(UserDocument userDoc) {
    final subscription = userDoc.subscription;
    final tier = _getTierFromSubscription(subscription);
    final features = _getFeaturesForTier(tier);
    final usage =
        userDoc.usage ?? {'checklistsCreated': 0, 'sessionsCompleted': 0};

    return UserPrivileges(
      tier: tier,
      isActive: subscription?.status == 'active',
      expiresAt: subscription?.endDate,
      features: features,
      usage: usage,
    );
  }

  UserTier _getTierFromSubscription(SubscriptionData? subscription) {
    if (subscription == null) return UserTier.free;

    switch (subscription.tier) {
      case 'premium':
        return UserTier.premium;
      case 'pro':
        return UserTier.pro;
      case 'free':
      default:
        return UserTier.free;
    }
  }

  Map<String, dynamic> _getFeaturesForTier(UserTier tier) {
    switch (tier) {
      case UserTier.anonymous:
        return {
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
        };
      case UserTier.free:
        return {
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
        };
      case UserTier.premium:
        return {
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
        };
      case UserTier.pro:
        return {
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
        };
    }
  }

  Future<void> _createUserDocumentWithTier(String userId) async {
    try {
      await _userRepository.createUserDocumentWithTier(
        userId: userId,
        tier: UserTier.free,
      );
    } catch (e) {
      // Log error but don't fail the privilege loading
      print('Failed to create user document with tier: $e');
    }
  }

  // Public methods
  Future<void> refresh() async {
    await _initializePrivileges();
  }

  Future<void> updateUsage(String key, int amount) async {
    if (state == null) return;

    final newPrivileges = state!.incrementUsage(key, amount);
    state = newPrivileges;

    // Update in database
    final user = _authNotifier.state.user;
    if (user != null) {
      try {
        await _userRepository.updateUserUsage(user.uid, newPrivileges.usage);
      } catch (e) {
        print('Failed to update usage in database: $e');
      }
    }
  }

  Future<void> upgradeTier(UserTier newTier) async {
    final user = _authNotifier.state.user;
    if (user == null) return;

    try {
      await _userRepository.updateUserTier(user.uid, newTier);
      await refresh();
    } catch (e) {
      print('Failed to upgrade tier: $e');
    }
  }

  // TESTING ONLY - Switch tier without database update
  void testSwitchTier(UserTier newTier) {
    final features = _getFeaturesForTier(newTier);
    state = UserPrivileges(
      tier: newTier,
      isActive: true,
      features: features,
      usage: state?.usage ?? {'checklistsCreated': 0, 'sessionsCompleted': 0},
    );
  }

  // Convenience getters
  bool get canCreateChecklists => state?.canCreateChecklists ?? false;
  bool get canPersistSessions => state?.canPersistSessions ?? false;
  bool get hasAnalytics => state?.hasAnalytics ?? false;
  bool get canExport => state?.canExport ?? false;
  bool get canShare => state?.canShare ?? false;
  bool get hasCustomThemes => state?.hasCustomThemes ?? false;
  bool get hasPrioritySupport => state?.hasPrioritySupport ?? false;

  // Enhanced feature getters
  bool get canEditChecklists => state?.canEditChecklists ?? false;
  bool get canDeleteChecklists => state?.canDeleteChecklists ?? false;
  bool get canDuplicateChecklists => state?.canDuplicateChecklists ?? false;
  bool get hasSessionHistory => state?.hasSessionHistory ?? false;
  bool get hasChecklistTemplates => state?.hasChecklistTemplates ?? false;
  bool get hasDataBackup => state?.hasDataBackup ?? false;
  bool get canUseAdvancedFeatures => state?.canUseAdvancedFeatures ?? false;

  UserTier get currentTier => state?.tier ?? UserTier.anonymous;
  bool get isAnonymous => currentTier == UserTier.anonymous;
  bool get isFree => currentTier == UserTier.free;
  bool get isPremium => currentTier == UserTier.premium;
  bool get isPro => currentTier == UserTier.pro;
}
