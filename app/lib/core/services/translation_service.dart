import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TranslationService {
  static final Logger _logger = Logger();
  static Map<String, Map<String, dynamic>> _translations = {};
  static Locale? _currentLocale;

  static Future<void> loadTranslations(Locale locale) async {
    final localeKey = '${locale.languageCode}_${locale.countryCode}';

    if (_translations.containsKey(localeKey)) {
      _logger.i(
        '🔍 DEBUG: TranslationService - using cached translations for $localeKey',
      );
      _currentLocale = locale;
      return;
    }

    try {
      final fileName = '${locale.languageCode}_${locale.countryCode}.json';
      final path = 'assets/translations/$fileName';

      _logger.i(
        '🔍 DEBUG: TranslationService - loading translations from $path',
      );

      final data = await rootBundle.loadString(path);
      final translations = json.decode(data) as Map<String, dynamic>;

      _translations[localeKey] = translations;
      _currentLocale = locale;

      _logger.i(
        '🔍 DEBUG: TranslationService - loaded ${translations.length} translations for $localeKey',
      );
      _logger.i(
        '🔍 DEBUG: TranslationService - sample translations: ${translations.keys.take(3).toList()}',
      );
    } catch (e) {
      _logger.e(
        '🔍 DEBUG: TranslationService - failed to load translations for $localeKey: $e',
      );
      rethrow;
    }
  }

  static String translate(String key, [List<String>? args]) {
    if (_currentLocale == null) {
      return key;
    }

    final localeKey =
        '${_currentLocale!.languageCode}_${_currentLocale!.countryCode}';
    final translations = _translations[localeKey];

    if (translations == null) {
      print(
        'WARNING: translate() - No translations loaded for localeKey: $localeKey',
      );
      return key;
    }
    if (!translations.containsKey(key)) {
      print(
        'WARNING: translate() - Missing translation key "$key" for localeKey: $localeKey',
      );
    }

    if (translations == null) {
      return key;
    }

    final translation = translations[key];
    if (translation == null) {
      return key;
    }

    String result = translation.toString();

    // Handle interpolation if args are provided
    if (args != null) {
      for (final arg in args) {
        result = result.replaceFirst('{}', arg);
      }
    }

    return result;
  }

  static void clearCache() {
    _translations.clear();
    _currentLocale = null;
    _logger.i('🔍 DEBUG: TranslationService - cache cleared');
  }

  static Locale? get currentLocale => _currentLocale;
}

// Riverpod providers for reactive translations
class TranslationNotifier extends StateNotifier<Locale?> {
  TranslationNotifier() : super(null);

  Future<void> setLocale(Locale locale) async {
    await TranslationService.loadTranslations(locale);
    state = locale;
  }

  String translate(String key, [List<String>? args]) {
    return TranslationService.translate(key, args);
  }

  Locale? get currentLocale => TranslationService.currentLocale;
}

final translationProvider = StateNotifierProvider<TranslationNotifier, Locale?>(
  (ref) => TranslationNotifier(),
);

// Helper function to translate with reactive updates
String tr(WidgetRef ref, String key, [List<String>? args]) {
  // Watch the translation provider to trigger rebuilds
  ref.watch(translationProvider);
  return TranslationService.translate(key, args);
}
