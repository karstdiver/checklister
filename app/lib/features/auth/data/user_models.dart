import 'package:cloud_firestore/cloud_firestore.dart';

class UserDocument {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final bool emailVerified;
  final String providerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final Map<String, dynamic> preferences;
  final Map<String, dynamic> stats;
  final SubscriptionData? subscription;
  final Map<String, int>? usage;

  UserDocument({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    required this.emailVerified,
    required this.providerId,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    required this.preferences,
    required this.stats,
    this.subscription,
    this.usage,
  });

  factory UserDocument.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserDocument(
      uid: data['uid'] ?? '',
      email: data['email'],
      displayName: data['displayName'],
      photoURL: data['photoURL'],
      emailVerified: data['emailVerified'] ?? false,
      providerId: data['providerId'] ?? 'anonymous',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      isActive: data['isActive'] ?? true,
      preferences: data['preferences'] ?? {},
      stats: data['stats'] ?? {},
      subscription: data['subscription'] != null
          ? SubscriptionData.fromMap(data['subscription'])
          : null,
      usage: data['usage'] != null
          ? Map<String, int>.from(data['usage'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'emailVerified': emailVerified,
      'providerId': providerId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'preferences': preferences,
      'stats': stats,
      'subscription': subscription?.toMap(),
      'usage': usage,
    };
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
