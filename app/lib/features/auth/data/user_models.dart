import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/domain/user_tier.dart';

/// User document model for Firestore
class UserDocument {
  final String id;
  final String email;
  final String? displayName;
  final String? photoURL;
  final SubscriptionData? subscription;
  final Map<String, int>? usage;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  // NEW: Admin role fields
  final String? adminRole; // 'none', 'moderator', 'admin', 'superAdmin'
  final String? adminRoleAssignedBy;
  final DateTime? adminRoleAssignedAt;
  final String? adminRoleNotes;

  const UserDocument({
    required this.id,
    required this.email,
    this.displayName,
    this.photoURL,
    this.subscription,
    this.usage,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    // NEW: Admin role fields
    this.adminRole,
    this.adminRoleAssignedBy,
    this.adminRoleAssignedAt,
    this.adminRoleNotes,
  });

  factory UserDocument.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserDocument(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      photoURL: data['photoURL'],
      subscription: data['subscription'] != null
          ? SubscriptionData.fromMap(data['subscription'])
          : null,
      usage: data['usage'] != null
          ? Map<String, int>.from(data['usage'])
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      // NEW: Admin role fields
      adminRole: data['adminRole'],
      adminRoleAssignedBy: data['adminRoleAssignedBy'],
      adminRoleAssignedAt: data['adminRoleAssignedAt'] != null
          ? (data['adminRoleAssignedAt'] as Timestamp).toDate()
          : null,
      adminRoleNotes: data['adminRoleNotes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'subscription': subscription?.toMap(),
      'usage': usage,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      // NEW: Admin role fields
      'adminRole': adminRole,
      'adminRoleAssignedBy': adminRoleAssignedBy,
      'adminRoleAssignedAt': adminRoleAssignedAt != null
          ? Timestamp.fromDate(adminRoleAssignedAt!)
          : null,
      'adminRoleNotes': adminRoleNotes,
    };
  }

  UserDocument copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoURL,
    SubscriptionData? subscription,
    Map<String, int>? usage,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    // NEW: Admin role fields
    String? adminRole,
    String? adminRoleAssignedBy,
    DateTime? adminRoleAssignedAt,
    String? adminRoleNotes,
  }) {
    return UserDocument(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      subscription: subscription ?? this.subscription,
      usage: usage ?? this.usage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      // NEW: Admin role fields
      adminRole: adminRole ?? this.adminRole,
      adminRoleAssignedBy: adminRoleAssignedBy ?? this.adminRoleAssignedBy,
      adminRoleAssignedAt: adminRoleAssignedAt ?? this.adminRoleAssignedAt,
      adminRoleNotes: adminRoleNotes ?? this.adminRoleNotes,
    );
  }
}

class SubscriptionData {
  final String tier;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool autoRenew;
  final String? platform;
  final String? transactionId;

  SubscriptionData({
    required this.tier,
    required this.status,
    this.startDate,
    this.endDate,
    required this.autoRenew,
    this.platform,
    this.transactionId,
  });

  factory SubscriptionData.fromMap(Map<String, dynamic> data) {
    return SubscriptionData(
      tier: data['tier'] ?? 'free',
      status: data['status'] ?? 'inactive',
      startDate: data['startDate'] != null
          ? (data['startDate'] as Timestamp).toDate()
          : null,
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      autoRenew: data['autoRenew'] ?? false,
      platform: data['platform'],
      transactionId: data['transactionId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tier': tier,
      'status': status,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'autoRenew': autoRenew,
      'platform': platform,
      'transactionId': transactionId,
    };
  }
}
