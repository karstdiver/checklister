import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/auth/data/user_repository.dart';

class NotificationSettings {
  final bool basicNotificationsEnabled;
  final bool reminderNotificationsEnabled;
  final bool progressNotificationsEnabled;
  final bool achievementNotificationsEnabled;
  final bool weeklyReportsEnabled;
  final bool customRemindersEnabled;
  final bool smartSuggestionsEnabled;
  final bool teamNotificationsEnabled;

  const NotificationSettings({
    this.basicNotificationsEnabled = true,
    this.reminderNotificationsEnabled = false,
    this.progressNotificationsEnabled = false,
    this.achievementNotificationsEnabled = false,
    this.weeklyReportsEnabled = false,
    this.customRemindersEnabled = false,
    this.smartSuggestionsEnabled = false,
    this.teamNotificationsEnabled = false,
  });

  NotificationSettings copyWith({
    bool? basicNotificationsEnabled,
    bool? reminderNotificationsEnabled,
    bool? progressNotificationsEnabled,
    bool? achievementNotificationsEnabled,
    bool? weeklyReportsEnabled,
    bool? customRemindersEnabled,
    bool? smartSuggestionsEnabled,
    bool? teamNotificationsEnabled,
  }) {
    return NotificationSettings(
      basicNotificationsEnabled:
          basicNotificationsEnabled ?? this.basicNotificationsEnabled,
      reminderNotificationsEnabled:
          reminderNotificationsEnabled ?? this.reminderNotificationsEnabled,
      progressNotificationsEnabled:
          progressNotificationsEnabled ?? this.progressNotificationsEnabled,
      achievementNotificationsEnabled:
          achievementNotificationsEnabled ??
          this.achievementNotificationsEnabled,
      weeklyReportsEnabled: weeklyReportsEnabled ?? this.weeklyReportsEnabled,
      customRemindersEnabled:
          customRemindersEnabled ?? this.customRemindersEnabled,
      smartSuggestionsEnabled:
          smartSuggestionsEnabled ?? this.smartSuggestionsEnabled,
      teamNotificationsEnabled:
          teamNotificationsEnabled ?? this.teamNotificationsEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'basicNotificationsEnabled': basicNotificationsEnabled,
      'reminderNotificationsEnabled': reminderNotificationsEnabled,
      'progressNotificationsEnabled': progressNotificationsEnabled,
      'achievementNotificationsEnabled': achievementNotificationsEnabled,
      'weeklyReportsEnabled': weeklyReportsEnabled,
      'customRemindersEnabled': customRemindersEnabled,
      'smartSuggestionsEnabled': smartSuggestionsEnabled,
      'teamNotificationsEnabled': teamNotificationsEnabled,
    };
  }

  factory NotificationSettings.fromMap(Map<String, dynamic> map) {
    return NotificationSettings(
      basicNotificationsEnabled: map['basicNotificationsEnabled'] ?? true,
      reminderNotificationsEnabled:
          map['reminderNotificationsEnabled'] ?? false,
      progressNotificationsEnabled:
          map['progressNotificationsEnabled'] ?? false,
      achievementNotificationsEnabled:
          map['achievementNotificationsEnabled'] ?? false,
      weeklyReportsEnabled: map['weeklyReportsEnabled'] ?? false,
      customRemindersEnabled: map['customRemindersEnabled'] ?? false,
      smartSuggestionsEnabled: map['smartSuggestionsEnabled'] ?? false,
      teamNotificationsEnabled: map['teamNotificationsEnabled'] ?? false,
    );
  }
}

class NotificationSettingsNotifier extends StateNotifier<NotificationSettings> {
  final UserRepository _userRepository = UserRepository();

  NotificationSettingsNotifier() : super(const NotificationSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await _userRepository.getUserDocument(user.uid);
        if (userDoc != null) {
          final notificationSettings =
              userDoc.preferences['notificationSettings']
                  as Map<String, dynamic>?;
          if (notificationSettings != null) {
            state = NotificationSettings.fromMap(notificationSettings);
          }
        }
      }
    } catch (e) {
      // Keep default settings if loading fails
      print('Failed to load notification settings: $e');
    }
  }

  Future<void> saveSettings() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Get current user preferences
        final userDoc = await _userRepository.getUserDocument(user.uid);
        if (userDoc != null) {
          final currentPreferences = Map<String, dynamic>.from(
            userDoc.preferences,
          );
          currentPreferences['notificationSettings'] = state.toMap();

          await _userRepository.updateUserPreferences(
            user.uid,
            currentPreferences,
          );
        }
      }
    } catch (e) {
      print('Failed to save notification settings: $e');
      rethrow;
    }
  }

  void updateBasicNotifications(bool enabled) {
    state = state.copyWith(basicNotificationsEnabled: enabled);
  }

  void updateReminderNotifications(bool enabled) {
    state = state.copyWith(reminderNotificationsEnabled: enabled);
  }

  void updateProgressNotifications(bool enabled) {
    state = state.copyWith(progressNotificationsEnabled: enabled);
  }

  void updateAchievementNotifications(bool enabled) {
    state = state.copyWith(achievementNotificationsEnabled: enabled);
  }

  void updateWeeklyReports(bool enabled) {
    state = state.copyWith(weeklyReportsEnabled: enabled);
  }

  void updateCustomReminders(bool enabled) {
    state = state.copyWith(customRemindersEnabled: enabled);
  }

  void updateSmartSuggestions(bool enabled) {
    state = state.copyWith(smartSuggestionsEnabled: enabled);
  }

  void updateTeamNotifications(bool enabled) {
    state = state.copyWith(teamNotificationsEnabled: enabled);
  }
}

final notificationSettingsProvider =
    StateNotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
      (ref) => NotificationSettingsNotifier(),
    );
