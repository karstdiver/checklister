import 'package:checklister/core/domain/user_tier.dart';

/// TTL (Time To Live) configuration for different user tiers and document types
class TTLConfig {
  /// TTL periods in days for different user tiers
  static const Map<UserTier, int> _userTierTTL = {
    UserTier.anonymous: 7, // 7 days for anonymous users
    UserTier.free: 30, // 30 days for free users
    UserTier.premium: 365, // 1 year for premium users
    UserTier.pro: -1, // -1 means no expiration for pro users
  };

  /// Get TTL period in days for a user tier
  static int getTTLDaysForTier(UserTier tier) {
    return _userTierTTL[tier] ?? 7; // Default to 7 days
  }

  /// Check if a user tier has unlimited TTL (no expiration)
  static bool hasUnlimitedTTL(UserTier tier) {
    return _userTierTTL[tier] == -1;
  }

  /// Calculate expiration date for a given user tier
  static DateTime? calculateExpirationDate(UserTier tier) {
    if (hasUnlimitedTTL(tier)) {
      return null; // No expiration
    }

    final ttlDays = getTTLDaysForTier(tier);
    return DateTime.now().add(Duration(days: ttlDays));
  }

  /// Check if a document is expired
  static bool isExpired(DateTime? expiresAt) {
    if (expiresAt == null) {
      return false; // No expiration set
    }
    return DateTime.now().isAfter(expiresAt);
  }

  /// Get days until expiration
  static int? getDaysUntilExpiration(DateTime? expiresAt) {
    if (expiresAt == null) {
      return null; // No expiration
    }

    final now = DateTime.now();
    if (now.isAfter(expiresAt)) {
      return 0; // Already expired
    }

    return expiresAt.difference(now).inDays;
  }

  /// Get warning threshold in days (when to show expiration warnings)
  static int getWarningThreshold(UserTier tier) {
    switch (tier) {
      case UserTier.anonymous:
        return 1; // Warn 1 day before
      case UserTier.free:
        return 3; // Warn 3 days before
      case UserTier.premium:
        return 7; // Warn 1 week before
      case UserTier.pro:
        return -1; // No warnings for pro users
    }
  }

  /// Check if expiration warning should be shown
  static bool shouldShowExpirationWarning(DateTime? expiresAt, UserTier tier) {
    if (expiresAt == null || hasUnlimitedTTL(tier)) {
      return false;
    }

    final daysUntilExpiration = getDaysUntilExpiration(expiresAt);
    if (daysUntilExpiration == null) {
      return false;
    }

    final warningThreshold = getWarningThreshold(tier);
    return daysUntilExpiration <= warningThreshold;
  }
}
