import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:checklister/core/providers/settings_provider.dart';

// Mock SharedPreferences
class MockSharedPreferences implements SharedPreferences {
  final Map<String, dynamic> _data = {};

  @override
  Future<bool> clear() async {
    _data.clear();
    return true;
  }

  @override
  Future<bool> commit() async => true;

  @override
  bool containsKey(String key) => _data.containsKey(key);

  @override
  Object? get(String key) => _data[key];

  @override
  bool? getBool(String key) => _data[key] as bool?;

  @override
  double? getDouble(String key) => _data[key] as double?;

  @override
  int? getInt(String key) => _data[key] as int?;

  @override
  Set<String> getKeys() => _data.keys.toSet();

  @override
  String? getString(String key) => _data[key] as String?;

  @override
  List<String>? getStringList(String key) => _data[key] as List<String>?;

  @override
  Future<bool> reload() async => true;

  @override
  Future<bool> remove(String key) async {
    _data.remove(key);
    return true;
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    _data[key] = value;
    return true;
  }

  @override
  Future<bool> setDouble(String key, double value) async {
    _data[key] = value;
    return true;
  }

  @override
  Future<bool> setInt(String key, int value) async {
    _data[key] = value;
    return true;
  }

  @override
  Future<bool> setString(String key, String value) async {
    _data[key] = value;
    return true;
  }

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    _data[key] = value;
    return true;
  }

  // Mock static method
  static Future<SharedPreferences> getInstance() async {
    return MockSharedPreferences();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsProvider', () {
    late ProviderContainer container;

    setUp(() {
      // Override SharedPreferences.getInstance to return our mock
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should have default theme mode', () {
      final settings = container.read(settingsProvider);
      expect(settings.themeMode, isNotNull);
      expect(settings.themeMode, ThemeMode.system);
    });

    test('should update theme mode', () async {
      final notifier = container.read(settingsProvider.notifier);

      // Test updating theme mode
      await notifier.setThemeMode(ThemeMode.dark);

      final updatedSettings = container.read(settingsProvider);
      expect(updatedSettings.themeMode, ThemeMode.dark);
    });

    test('should handle multiple theme mode updates', () async {
      final notifier = container.read(settingsProvider.notifier);

      // Test multiple updates
      await notifier.setThemeMode(ThemeMode.dark);
      await notifier.setThemeMode(ThemeMode.light);
      await notifier.setThemeMode(ThemeMode.system);

      final finalSettings = container.read(settingsProvider);
      expect(finalSettings.themeMode, ThemeMode.system);
    });

    test('should update theme mode and persist it', () async {
      final notifier = container.read(settingsProvider.notifier);

      // Update theme mode
      await notifier.setThemeMode(ThemeMode.light);

      final updatedSettings = container.read(settingsProvider);
      expect(updatedSettings.themeMode, ThemeMode.light);
    });
  });
}
