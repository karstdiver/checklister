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
    print('[DEBUG] PrivilegeNotifier: constructor called');
    _initializePrivileges();
  }

  Future<void> _initializePrivileges() async {
    final user = _authNotifier.state.user;
    if (user == null) {
      state = UserPrivileges.anonymous();
      print('[DEBUG] PrivilegeNotifier: Set state to ANONYMOUS (user==null)');
    } else if (user.isAnonymous) {
      state = UserPrivileges.anonymous();
      print(
        '[DEBUG] PrivilegeNotifier: Set state to ANONYMOUS (user.isAnonymous, uid=${user.uid})',
      );
    } else {
      print(
        '[DEBUG] PrivilegeNotifier: Loading privileges for user uid=${user.uid}',
      );
      await _loadUserPrivileges(user.uid);
    }
  }

  Future<void> _loadUserPrivileges(String userId) async {
    try {
      final userDoc = await _userRepository.getUserDocument(userId);
      if (userDoc != null) {
        state = _buildPrivilegesFromUserDoc(userDoc);
        print(
          '[DEBUG] PrivilegeNotifier: Set state from userDoc for uid=$userId, tier=${state?.tier}',
        );
      } else {
        // Only assign free tier for real (non-anonymous) users
        state = UserPrivileges.free();
        print(
          '[DEBUG] PrivilegeNotifier: Set state to FREE (no userDoc, uid=$userId)',
        );
        await _createUserDocumentWithTier(userId);
      }
    } catch (e) {
      print('🔍 DEBUG: Error loading user privileges: $e');
      // Fallback to anonymous if user is anonymous, else free
      final user = _authNotifier.state.user;
      if (user != null && user.isAnonymous) {
        state = UserPrivileges.anonymous();
        print(
          '[DEBUG] PrivilegeNotifier: Set state to ANONYMOUS (error fallback, uid=${user.uid})',
        );
      } else {
        state = UserPrivileges.free();
        print(
          '[DEBUG] PrivilegeNotifier: Set state to FREE (error fallback, uid=${user?.uid})',
        );
      }
    }
  }

  UserPrivileges _buildPrivilegesFromUserDoc(UserDocument userDoc) {
    final subscription = userDoc.subscription;
    final tier = _getTierFromSubscription(subscription);
    final usage =
        userDoc.usage ?? {'checklistsCreated': 0, 'sessionsCompleted': 0};

    // Use the factory methods from UserPrivileges to ensure all features are included
    UserPrivileges basePrivileges;
    switch (tier) {
      case UserTier.anonymous:
        basePrivileges = UserPrivileges.anonymous();
        break;
      case UserTier.free:
        basePrivileges = UserPrivileges.free();
        break;
      case UserTier.premium:
        basePrivileges = UserPrivileges.premium();
        break;
      case UserTier.pro:
        basePrivileges = UserPrivileges.pro();
        break;
    }

    return basePrivileges.copyWith(
      isActive: subscription?.status == 'active',
      expiresAt: subscription?.endDate,
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
    UserPrivileges basePrivileges;
    switch (newTier) {
      case UserTier.anonymous:
        basePrivileges = UserPrivileges.anonymous();
        break;
      case UserTier.free:
        basePrivileges = UserPrivileges.free();
        break;
      case UserTier.premium:
        basePrivileges = UserPrivileges.premium();
        break;
      case UserTier.pro:
        basePrivileges = UserPrivileges.pro();
        break;
    }

    state = basePrivileges.copyWith(
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
