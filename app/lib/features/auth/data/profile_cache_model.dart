import 'package:cloud_firestore/cloud_firestore.dart';

/// Simplified profile data model for offline caching
/// Contains only essential data needed for offline functionality
class ProfileCacheModel {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final String? profileImageUrl;
  final bool emailVerified;
  final String providerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final Map<String, dynamic> preferences;
  final Map<String, dynamic> stats;
  final Map<String, dynamic> subscription;
  final Map<String, int> usage;

  const ProfileCacheModel({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    this.profileImageUrl,
    required this.emailVerified,
    required this.providerId,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    required this.preferences,
    required this.stats,
    required this.subscription,
    required this.usage,
  });

  /// Create from Firestore document
  factory ProfileCacheModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProfileCacheModel(
      uid: data['uid'] ?? '',
      email: data['email'],
      displayName: data['displayName'],
      photoURL: data['photoURL'],
      profileImageUrl: data['profileImageUrl'],
      emailVerified: data['emailVerified'] ?? false,
      providerId: data['providerId'] ?? 'anonymous',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      isActive: data['isActive'] ?? true,
      preferences: _convertTimestampsInMap(data['preferences'] ?? {}),
      stats: _convertTimestampsInMap(data['stats'] ?? {}),
      subscription: _convertTimestampsInMap(data['subscription'] ?? {}),
      usage: data['usage'] != null
          ? Map<String, int>.from(data['usage'])
          : {'checklistsCreated': 0, 'sessionsCompleted': 0},
    );
  }

  /// Helper method to recursively convert Timestamp objects to DateTime in maps
  static Map<String, dynamic> _convertTimestampsInMap(
    Map<String, dynamic> map,
  ) {
    final converted = <String, dynamic>{};
    for (final entry in map.entries) {
      if (entry.value is Timestamp) {
        converted[entry.key] = (entry.value as Timestamp).toDate();
      } else if (entry.value is Map<String, dynamic>) {
        converted[entry.key] = _convertTimestampsInMap(entry.value);
      } else {
        converted[entry.key] = entry.value;
      }
    }
    return converted;
  }

  /// Create from UserDocument
  factory ProfileCacheModel.fromUserDocument(dynamic userDoc) {
    return ProfileCacheModel(
      uid: userDoc.uid,
      email: userDoc.email,
      displayName: userDoc.displayName,
      photoURL: userDoc.photoURL,
      profileImageUrl: null, // UserDocument doesn't have profileImageUrl
      emailVerified: userDoc.emailVerified,
      providerId: userDoc.providerId,
      createdAt: userDoc.createdAt,
      updatedAt: userDoc.updatedAt,
      isActive: userDoc.isActive,
      preferences: userDoc.preferences,
      stats: userDoc.stats,
      subscription: userDoc.subscription?.toMap() ?? {},
      usage: userDoc.usage ?? {'checklistsCreated': 0, 'sessionsCompleted': 0},
    );
  }

  /// Convert to Map for Hive storage
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'profileImageUrl': profileImageUrl,
      'emailVerified': emailVerified,
      'providerId': providerId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
      'preferences': preferences,
      'stats': stats,
      'subscription': subscription,
      'usage': usage,
    };
  }

  /// Create from JSON (for Hive retrieval)
  factory ProfileCacheModel.fromJson(Map<String, dynamic> json) {
    return ProfileCacheModel(
      uid: json['uid'] ?? '',
      email: json['email'],
      displayName: json['displayName'],
      photoURL: json['photoURL'],
      profileImageUrl: json['profileImageUrl'],
      emailVerified: json['emailVerified'] ?? false,
      providerId: json['providerId'] ?? 'anonymous',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isActive: json['isActive'] ?? true,
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
      stats: Map<String, dynamic>.from(json['stats'] ?? {}),
      subscription: Map<String, dynamic>.from(json['subscription'] ?? {}),
      usage: Map<String, int>.from(json['usage'] ?? {}),
    );
  }

  /// Copy with method for updates
  ProfileCacheModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    String? profileImageUrl,
    bool? emailVerified,
    String? providerId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? stats,
    Map<String, dynamic>? subscription,
    Map<String, int>? usage,
  }) {
    return ProfileCacheModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      emailVerified: emailVerified ?? this.emailVerified,
      providerId: providerId ?? this.providerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      preferences: preferences ?? this.preferences,
      stats: stats ?? this.stats,
      subscription: subscription ?? this.subscription,
      usage: usage ?? this.usage,
    );
  }

  /// Check if profile is anonymous
  bool get isAnonymous => providerId == 'anonymous';

  /// Get display name with fallback
  String get displayNameOrEmail => displayName ?? email ?? 'Anonymous User';

  /// Get profile image URL with fallback
  String? get profileImageUrlOrPhotoURL => profileImageUrl ?? photoURL;
}
