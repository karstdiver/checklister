import 'package:shared_preferences/shared_preferences.dart';

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
