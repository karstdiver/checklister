import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import '../domain/user_tier.dart';

/// Service for managing admin roles and permissions
/// This service can only be used by existing admins
class AdminManagementService {
  static final Logger _logger = Logger();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Assign admin role to a user (only callable by existing admins)
  ///
  /// [targetUserId] - The user ID to assign the role to
  /// [adminRole] - The admin role to assign
  /// [assignedByUserId] - The user ID of the admin making the assignment
  /// [notes] - Optional notes about the assignment
  static Future<bool> assignAdminRole({
    required String targetUserId,
    required AdminRole adminRole,
    required String assignedByUserId,
    String? notes,
  }) async {
    try {
      // SECURITY: Verify that the assigning user has admin privileges
      final assigningUserDoc = await _firestore
          .collection('users')
          .doc(assignedByUserId)
          .get();

      if (!assigningUserDoc.exists) {
        _logger.e('❌ Assigning user does not exist: $assignedByUserId');
        return false;
      }

      final assigningUserData = assigningUserDoc.data()!;
      final assigningUserAdminRole = assigningUserData['adminRole'] as String?;

      // Check if assigning user has sufficient privileges
      if (!_hasPermissionToAssignRole(assigningUserAdminRole, adminRole)) {
        _logger.e(
          '❌ User $assignedByUserId lacks permission to assign $adminRole role',
        );
        return false;
      }

      // Convert AdminRole enum to string
      final adminRoleString = _adminRoleToString(adminRole);

      // Update the target user's admin role
      await _firestore.collection('users').doc(targetUserId).update({
        'adminRole': adminRoleString,
        'adminRoleAssignedBy': assignedByUserId,
        'adminRoleAssignedAt': FieldValue.serverTimestamp(),
        'adminRoleNotes': notes,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _logger.i(
        '✅ Successfully assigned $adminRoleString role to user $targetUserId',
      );
      return true;
    } catch (e) {
      _logger.e('❌ Error assigning admin role: $e');
      return false;
    }
  }

  /// Remove admin role from a user (only callable by existing admins)
  static Future<bool> removeAdminRole({
    required String targetUserId,
    required String removedByUserId,
    String? notes,
  }) async {
    try {
      // SECURITY: Verify that the removing user has admin privileges
      final removingUserDoc = await _firestore
          .collection('users')
          .doc(removedByUserId)
          .get();

      if (!removingUserDoc.exists) {
        _logger.e('❌ Removing user does not exist: $removedByUserId');
        return false;
      }

      final removingUserData = removingUserDoc.data()!;
      final removingUserAdminRole = removingUserData['adminRole'] as String?;

      // Get target user's current admin role
      final targetUserDoc = await _firestore
          .collection('users')
          .doc(targetUserId)
          .get();

      if (!targetUserDoc.exists) {
        _logger.e('❌ Target user does not exist: $targetUserId');
        return false;
      }

      final targetUserData = targetUserDoc.data()!;
      final targetUserAdminRole = targetUserData['adminRole'] as String?;

      // Check if removing user has permission to remove this role
      if (!_hasPermissionToRemoveRole(
        removingUserAdminRole,
        targetUserAdminRole,
      )) {
        _logger.e(
          '❌ User $removedByUserId lacks permission to remove role from user $targetUserId',
        );
        return false;
      }

      // Remove the admin role
      await _firestore.collection('users').doc(targetUserId).update({
        'adminRole': 'none',
        'adminRoleAssignedBy': removedByUserId,
        'adminRoleAssignedAt': FieldValue.serverTimestamp(),
        'adminRoleNotes': notes ?? 'Admin role removed',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _logger.i('✅ Successfully removed admin role from user $targetUserId');
      return true;
    } catch (e) {
      _logger.e('❌ Error removing admin role: $e');
      return false;
    }
  }

  /// Get all users with admin roles (only callable by existing admins)
  static Future<List<Map<String, dynamic>>> getAdminUsers({
    required String requestingUserId,
  }) async {
    try {
      // SECURITY: Verify that the requesting user has admin privileges
      final requestingUserDoc = await _firestore
          .collection('users')
          .doc(requestingUserId)
          .get();

      if (!requestingUserDoc.exists) {
        _logger.e('❌ Requesting user does not exist: $requestingUserId');
        return [];
      }

      final requestingUserData = requestingUserDoc.data()!;
      final requestingUserAdminRole =
          requestingUserData['adminRole'] as String?;

      if (!_isAdmin(requestingUserAdminRole)) {
        _logger.e(
          '❌ User $requestingUserId lacks permission to view admin users',
        );
        return [];
      }

      // Query for users with admin roles
      final querySnapshot = await _firestore
          .collection('users')
          .where('adminRole', whereIn: ['moderator', 'admin', 'superAdmin'])
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'userId': doc.id,
          'email': data['email'] ?? '',
          'displayName': data['displayName'] ?? '',
          'adminRole': data['adminRole'] ?? 'none',
          'adminRoleAssignedBy': data['adminRoleAssignedBy'],
          'adminRoleAssignedAt': data['adminRoleAssignedAt'],
          'adminRoleNotes': data['adminRoleNotes'],
        };
      }).toList();
    } catch (e) {
      _logger.e('❌ Error getting admin users: $e');
      return [];
    }
  }

  /// Check if a user has permission to assign a specific admin role
  static bool _hasPermissionToAssignRole(
    String? assigningUserRole,
    AdminRole targetRole,
  ) {
    if (!_isAdmin(assigningUserRole)) return false;

    // SuperAdmin can assign any role
    if (assigningUserRole == 'superAdmin') return true;

    // Admin can assign moderator and admin roles
    if (assigningUserRole == 'admin') {
      return targetRole == AdminRole.moderator || targetRole == AdminRole.admin;
    }

    // Moderator cannot assign any admin roles
    if (assigningUserRole == 'moderator') return false;

    return false;
  }

  /// Check if a user has permission to remove a specific admin role
  static bool _hasPermissionToRemoveRole(
    String? removingUserRole,
    String? targetUserRole,
  ) {
    if (!_isAdmin(removingUserRole)) return false;

    // SuperAdmin can remove any role
    if (removingUserRole == 'superAdmin') return true;

    // Admin can remove moderator and admin roles (but not superAdmin)
    if (removingUserRole == 'admin') {
      return targetUserRole == 'moderator' || targetUserRole == 'admin';
    }

    // Moderator cannot remove any admin roles
    if (removingUserRole == 'moderator') return false;

    return false;
  }

  /// Check if a user has any admin role
  static bool _isAdmin(String? adminRole) {
    return adminRole == 'moderator' ||
        adminRole == 'admin' ||
        adminRole == 'superAdmin';
  }

  /// Convert AdminRole enum to string
  static String _adminRoleToString(AdminRole adminRole) {
    switch (adminRole) {
      case AdminRole.none:
        return 'none';
      case AdminRole.moderator:
        return 'moderator';
      case AdminRole.admin:
        return 'admin';
      case AdminRole.superAdmin:
        return 'superAdmin';
    }
  }
}
