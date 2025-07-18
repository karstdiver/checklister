import 'package:flutter_test/flutter_test.dart';
import 'package:checklister/core/domain/user_tier.dart';

void main() {
  group('UserPrivileges', () {
    test('should create anonymous privileges correctly', () {
      final privileges = UserPrivileges.anonymous();

      expect(privileges.tier, UserTier.anonymous);
      expect(privileges.isAnonymous, true);
      expect(privileges.isFree, false);
      expect(privileges.isPremium, false);
      expect(privileges.hasFeature('profilePictures'), false);
      expect(privileges.hasFeature('itemPhotos'), false);
      expect(privileges.hasFeature('publicChecklists'), false);
    });

    test('should create free privileges correctly', () {
      final privileges = UserPrivileges.free();

      expect(privileges.tier, UserTier.free);
      expect(privileges.isAnonymous, false);
      expect(privileges.isFree, true);
      expect(privileges.isPremium, false);
      expect(privileges.hasFeature('profilePictures'), false);
      expect(privileges.hasFeature('itemPhotos'), false);
      expect(privileges.hasFeature('publicChecklists'), false);
      expect(privileges.hasFeature('profileCustomization'), true);
    });

    test('should create premium privileges correctly', () {
      final privileges = UserPrivileges.premium();

      expect(privileges.tier, UserTier.premium);
      expect(privileges.isAnonymous, false);
      expect(privileges.isFree, false);
      expect(privileges.isPremium, true);
      expect(privileges.hasFeature('profilePictures'), true);
      expect(privileges.hasFeature('profileCustomization'), true);
      // Note: itemPhotos and publicChecklists are not in factory methods
      // but are added by the PrivilegeProvider
    });

    test('should handle unknown features gracefully', () {
      final privileges = UserPrivileges.premium();
      expect(privileges.hasFeature('unknownFeature'), false);
    });

    test('should provide correct feature access for different tiers', () {
      // Anonymous user
      final anonymous = UserPrivileges.anonymous();
      expect(anonymous.hasFeature('profilePictures'), false);
      expect(anonymous.hasFeature('itemPhotos'), false);
      expect(anonymous.hasFeature('publicChecklists'), false);
      expect(anonymous.hasFeature('canEditChecklists'), false);

      // Free user
      final free = UserPrivileges.free();
      expect(free.hasFeature('profilePictures'), false);
      expect(free.hasFeature('itemPhotos'), false);
      expect(free.hasFeature('publicChecklists'), false);
      expect(free.hasFeature('canEditChecklists'), true);

      // Premium user
      final premium = UserPrivileges.premium();
      expect(premium.hasFeature('profilePictures'), true);
      expect(premium.hasFeature('canEditChecklists'), true);
      // Note: itemPhotos and publicChecklists are not in factory methods
      // but are added by the PrivilegeProvider
    });

    test('should handle usage limits correctly', () {
      final anonymous = UserPrivileges.anonymous();
      final free = UserPrivileges.free();
      final premium = UserPrivileges.premium();

      // Anonymous user limits
      expect(anonymous.maxChecklists, 1);
      expect(anonymous.maxItemsPerChecklist, 3);
      expect(anonymous.canCreateChecklists, false);

      // Free user limits
      expect(free.maxChecklists, 5);
      expect(free.maxItemsPerChecklist, 15);
      expect(free.canCreateChecklists, true);

      // Premium user limits
      expect(premium.maxChecklists, 50);
      expect(premium.maxItemsPerChecklist, 100);
      expect(premium.canCreateChecklists, true);
    });

    test('should update usage correctly', () {
      final privileges = UserPrivileges.free();
      final updated = privileges.incrementUsage('checklistsCreated', 2);

      expect(updated.usage['checklistsCreated'], 2);
      expect(updated.usage['sessionsCompleted'], 0);
    });

    test('should copy with new values correctly', () {
      final original = UserPrivileges.free();
      final copied = original.copyWith(tier: UserTier.premium, isActive: false);

      expect(copied.tier, UserTier.premium);
      expect(copied.isActive, false);
      expect(copied.features, original.features);
      expect(copied.usage, original.usage);
    });
  });
}
