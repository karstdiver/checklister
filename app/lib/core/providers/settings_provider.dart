import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/auth/data/user_repository.dart';

// Keys for SharedPreferences
const String kThemeModeKey = 'theme_mode';
const String kLanguageKey = 'language';

class SettingsState {
  final ThemeMode themeMode;
  final Locale? language;

  SettingsState({required this.themeMode, this.language});

  SettingsState copyWith({ThemeMode? themeMode, Locale? language}) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final UserRepository _userRepository = UserRepository();

  SettingsNotifier() : super(SettingsState(themeMode: ThemeMode.system)) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Load theme mode
    final themeIndex = prefs.getInt(kThemeModeKey);
    if (themeIndex != null) {
      state = state.copyWith(themeMode: ThemeMode.values[themeIndex]);
    }

    // Load language
    final languageCode = prefs.getString(kLanguageKey);
    print('🔍 DEBUG: Settings provider - loading language code: $languageCode');
    if (languageCode != null) {
      // Handle both old hyphenated format and new underscore format
      final parts = languageCode.contains('-')
          ? languageCode.split('-')
          : languageCode.split('_');
      if (parts.length == 2) {
        final loadedLocale = Locale(parts[0], parts[1]);
        state = state.copyWith(language: loadedLocale);
        print(
          '🔍 DEBUG: Settings provider - loaded locale: ${loadedLocale.languageCode}_${loadedLocale.countryCode}',
        );

        // If we loaded from hyphenated format, save it in the new underscore format
        if (languageCode.contains('-')) {
          await prefs.setString(
            kLanguageKey,
            '${loadedLocale.languageCode}_${loadedLocale.countryCode}',
          );
          print(
            '🔍 DEBUG: Settings provider - migrated from hyphenated to underscore format',
          );
        }
      }
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(kThemeModeKey, mode.index);
  }

  Future<void> setLanguage(Locale locale) async {
    print(
      '🔍 DEBUG: Settings provider - setting language to ${locale.languageCode}_${locale.countryCode}',
    );
    state = state.copyWith(language: locale);

    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      kLanguageKey,
      '${locale.languageCode}_${locale.countryCode}',
    );
    print('🔍 DEBUG: Settings provider - language saved to SharedPreferences');

    // Save to Firestore if user is authenticated
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final languageCode = '${locale.languageCode}_${locale.countryCode}';
        await _userRepository.updateUserPreferences(currentUser.uid, {
          'language': languageCode,
        });
        print('🔍 DEBUG: Settings provider - language saved to Firestore');
      }
    } catch (e) {
      print(
        '🔍 DEBUG: Settings provider - failed to save language to Firestore: $e',
      );
      // Don't throw here, local settings are more important
    }
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) {
    return SettingsNotifier();
  },
);
