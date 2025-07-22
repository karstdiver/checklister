import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AcceptanceService {
  static const String _privacyAcceptedKey = 'privacyAccepted';
  static const String _tosAcceptedKey = 'tosAccepted';
  static const String _acceptedVersionKey = 'acceptedVersion';
  static const String _acceptedAtKey = 'acceptedAt';
  static const int currentPolicyVersion =
      1; // Increment when policy/ToS changes

  /// Save acceptance locally
  static Future<void> saveAcceptance({
    required bool privacyAccepted,
    required bool tosAccepted,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().toUtc().toIso8601String();
    await prefs.setBool(_privacyAcceptedKey, privacyAccepted);
    await prefs.setBool(_tosAcceptedKey, tosAccepted);
    await prefs.setInt(_acceptedVersionKey, currentPolicyVersion);
    await prefs.setString(_acceptedAtKey, now);
  }

  /// Save acceptance to Firestore for the current user
  static Future<void> saveAcceptanceRemote({
    required bool privacyAccepted,
    required bool tosAccepted,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final now = DateTime.now().toUtc().toIso8601String();
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'policyAcceptance': {
        'privacyAccepted': privacyAccepted,
        'tosAccepted': tosAccepted,
        'acceptedVersion': currentPolicyVersion,
        'acceptedAt': now,
      },
    }, SetOptions(merge: true));
  }

  /// Load acceptance status from local storage
  static Future<AcceptanceStatus> loadAcceptance() async {
    final prefs = await SharedPreferences.getInstance();
    final privacyAccepted = prefs.getBool(_privacyAcceptedKey) ?? false;
    final tosAccepted = prefs.getBool(_tosAcceptedKey) ?? false;
    final acceptedVersion = prefs.getInt(_acceptedVersionKey) ?? 0;
    final acceptedAt = prefs.getString(_acceptedAtKey);
    return AcceptanceStatus(
      privacyAccepted: privacyAccepted,
      tosAccepted: tosAccepted,
      acceptedVersion: acceptedVersion,
      acceptedAt: acceptedAt,
    );
  }

  /// Load acceptance status from Firestore for the current user
  static Future<AcceptanceStatus?> loadAcceptanceRemote() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = doc.data()?['policyAcceptance'];
    if (data == null) return null;
    return AcceptanceStatus(
      privacyAccepted: data['privacyAccepted'] ?? false,
      tosAccepted: data['tosAccepted'] ?? false,
      acceptedVersion: data['acceptedVersion'] ?? 0,
      acceptedAt: data['acceptedAt'],
    );
  }

  /// Check if acceptance is required (e.g., on app start)
  static Future<bool> isAcceptanceRequired() async {
    final status = await loadAcceptance();
    return !status.privacyAccepted ||
        !status.tosAccepted ||
        status.acceptedVersion < currentPolicyVersion;
  }
}

class AcceptanceStatus {
  final bool privacyAccepted;
  final bool tosAccepted;
  final int acceptedVersion;
  final String? acceptedAt;

  AcceptanceStatus({
    required this.privacyAccepted,
    required this.tosAccepted,
    required this.acceptedVersion,
    required this.acceptedAt,
  });
}
