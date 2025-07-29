import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/user_tier.dart';

class LimitManagementService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache for system limits
  static Map<String, dynamic>? _cachedSystemLimits;
  static DateTime? _lastCacheUpdate;
  static const Duration _cacheExpiry = Duration(minutes: 5);

  /// Get system-wide limits for a specific tier
  static Future<Map<String, int>> getTierLimits(UserTier tier) async {
    try {
      final systemLimits = await _getSystemLimits();
      final tierLimits =
          systemLimits['tier_limits']?[tier.name] as Map<String, dynamic>?;

      if (tierLimits != null) {
        return {
          'maxChecklists':
              (tierLimits['maxChecklists'] as int?) ??
              _getDefaultLimit(tier, 'maxChecklists'),
          'maxItemsPerChecklist':
              (tierLimits['maxItemsPerChecklist'] as int?) ??
              _getDefaultLimit(tier, 'maxItemsPerChecklist'),
        };
      }

      // Fallback to default limits
      return {
        'maxChecklists': _getDefaultLimit(tier, 'maxChecklists'),
        'maxItemsPerChecklist': _getDefaultLimit(tier, 'maxItemsPerChecklist'),
      };
    } catch (e) {
      print('Error getting tier limits: $e');
      // Fallback to default limits
      return {
        'maxChecklists': _getDefaultLimit(tier, 'maxChecklists'),
        'maxItemsPerChecklist': _getDefaultLimit(tier, 'maxItemsPerChecklist'),
      };
    }
  }

  /// Get user-specific overrides
  static Future<Map<String, int>?> getUserOverrides(String userId) async {
    try {
      final systemLimits = await _getSystemLimits();
      final userOverrides =
          systemLimits['admin_overrides']?[userId] as Map<String, dynamic>?;

      if (userOverrides != null) {
        final maxChecklists = userOverrides['maxChecklists'] as int?;
        final maxItemsPerChecklist =
            userOverrides['maxItemsPerChecklist'] as int?;

        if (maxChecklists != null || maxItemsPerChecklist != null) {
          return {
            if (maxChecklists != null) 'maxChecklists': maxChecklists,
            if (maxItemsPerChecklist != null)
              'maxItemsPerChecklist': maxItemsPerChecklist,
          };
        }
      }

      return null;
    } catch (e) {
      print('Error getting user overrides: $e');
      return null;
    }
  }

  /// Check if user can create more checklists
  static Future<bool> canCreateChecklist(
    String userId,
    UserTier tier,
    int currentCount,
  ) async {
    try {
      final tierLimits = await getTierLimits(tier);
      final userOverrides = await getUserOverrides(userId);

      final maxChecklists =
          userOverrides?['maxChecklists'] ?? tierLimits['maxChecklists']!;

      // -1 means unlimited
      if (maxChecklists == -1) return true;

      return currentCount < maxChecklists;
    } catch (e) {
      print('Error checking checklist creation limit: $e');
      return false;
    }
  }

  /// Check if user can add more items to a checklist
  static Future<bool> canAddItemsToChecklist(
    String userId,
    UserTier tier,
    int currentItemCount,
  ) async {
    try {
      final tierLimits = await getTierLimits(tier);
      final userOverrides = await getUserOverrides(userId);

      final maxItems =
          userOverrides?['maxItemsPerChecklist'] ??
          tierLimits['maxItemsPerChecklist']!;

      // -1 means unlimited
      if (maxItems == -1) return true;

      return currentItemCount < maxItems;
    } catch (e) {
      print('Error checking item limit: $e');
      return false;
    }
  }

  /// Get the effective limit for a user
  static Future<int> getEffectiveLimit(
    String userId,
    UserTier tier,
    String limitType,
  ) async {
    try {
      final tierLimits = await getTierLimits(tier);
      final userOverrides = await getUserOverrides(userId);

      return userOverrides?[limitType] ?? tierLimits[limitType]!;
    } catch (e) {
      print('Error getting effective limit: $e');
      return _getDefaultLimit(tier, limitType);
    }
  }

  /// Update system limits (admin only)
  static Future<void> updateSystemLimits(Map<String, dynamic> newLimits) async {
    try {
      await _firestore.collection('system_config').doc('limits').set({
        'tier_limits': newLimits['tier_limits'],
        'admin_overrides': newLimits['admin_overrides'] ?? {},
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': 'admin', // TODO: Get actual admin user ID
      });

      // Clear cache
      _cachedSystemLimits = null;
      _lastCacheUpdate = null;

      print('System limits updated successfully');
    } catch (e) {
      print('Error updating system limits: $e');
      rethrow;
    }
  }

  /// Add user override (admin only)
  static Future<void> addUserOverride(
    String userId,
    Map<String, int> overrides,
    String reason,
  ) async {
    try {
      final docRef = _firestore.collection('system_config').doc('limits');

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        final data = doc.data() ?? {};
        final adminOverrides = Map<String, dynamic>.from(
          data['admin_overrides'] ?? {},
        );

        adminOverrides[userId] = {
          ...overrides,
          'overrideReason': reason,
          'overrideDate': FieldValue.serverTimestamp(),
          'overrideBy': 'admin', // TODO: Get actual admin user ID
        };

        transaction.update(docRef, {
          'admin_overrides': adminOverrides,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      // Clear cache
      _cachedSystemLimits = null;
      _lastCacheUpdate = null;

      print('User override added successfully for user: $userId');
    } catch (e) {
      print('Error adding user override: $e');
      rethrow;
    }
  }

  /// Remove user override (admin only)
  static Future<void> removeUserOverride(String userId) async {
    try {
      final docRef = _firestore.collection('system_config').doc('limits');

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        final data = doc.data() ?? {};
        final adminOverrides = Map<String, dynamic>.from(
          data['admin_overrides'] ?? {},
        );

        adminOverrides.remove(userId);

        transaction.update(docRef, {
          'admin_overrides': adminOverrides,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      // Clear cache
      _cachedSystemLimits = null;
      _lastCacheUpdate = null;

      print('User override removed successfully for user: $userId');
    } catch (e) {
      print('Error removing user override: $e');
      rethrow;
    }
  }

  /// Get system limits with caching
  static Future<Map<String, dynamic>> _getSystemLimits() async {
    // Check if cache is still valid
    if (_cachedSystemLimits != null && _lastCacheUpdate != null) {
      final timeSinceUpdate = DateTime.now().difference(_lastCacheUpdate!);
      if (timeSinceUpdate < _cacheExpiry) {
        return _cachedSystemLimits!;
      }
    }

    try {
      final doc = await _firestore
          .collection('system_config')
          .doc('limits')
          .get();

      if (doc.exists) {
        _cachedSystemLimits = doc.data();
        _lastCacheUpdate = DateTime.now();
        return _cachedSystemLimits!;
      } else {
        // Initialize with default limits if document doesn't exist
        final defaultLimits = _getDefaultSystemLimits();
        await _firestore
            .collection('system_config')
            .doc('limits')
            .set(defaultLimits);
        _cachedSystemLimits = defaultLimits;
        _lastCacheUpdate = DateTime.now();
        return defaultLimits;
      }
    } catch (e) {
      print('Error getting system limits: $e');
      // Return default limits as fallback
      return _getDefaultSystemLimits();
    }
  }

  /// Get default system limits
  static Map<String, dynamic> _getDefaultSystemLimits() {
    return {
      'tier_limits': {
        'anonymous': {'maxChecklists': 1, 'maxItemsPerChecklist': 3},
        'free': {'maxChecklists': 5, 'maxItemsPerChecklist': 15},
        'premium': {'maxChecklists': 50, 'maxItemsPerChecklist': 100},
        'pro': {
          'maxChecklists': -1, // unlimited
          'maxItemsPerChecklist': -1, // unlimited
        },
      },
      'admin_overrides': {},
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Get default limit for a tier and limit type
  static int _getDefaultLimit(UserTier tier, String limitType) {
    switch (tier) {
      case UserTier.anonymous:
        return limitType == 'maxChecklists' ? 1 : 3;
      case UserTier.free:
        return limitType == 'maxChecklists' ? 5 : 15;
      case UserTier.premium:
        return limitType == 'maxChecklists' ? 50 : 100;
      case UserTier.pro:
        return -1; // unlimited
    }
  }

  /// Clear cache (useful for testing or manual cache invalidation)
  static void clearCache() {
    _cachedSystemLimits = null;
    _lastCacheUpdate = null;
  }
}
