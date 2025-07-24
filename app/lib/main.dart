/* M A I N  P R O G R A M */

import 'package:flutter/material.dart';
//import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';

//import 'package:checklister/checklister.dart'; // be sure to add new code to the lib/checklister.dart exports
import 'checklister_app.dart';

// imports for google firebase backend
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
//import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'core/services/analytics_service.dart';
import 'core/services/translation_service.dart';

final Logger logger = Logger();

// Keys for SharedPreferences
const String kLanguageKey = 'language';

// Custom asset loader for underscore-named translation files
class UnderscoreAssetLoader extends AssetLoader {
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    // Convert locale to underscore format for filename
    final fileName = '${locale.languageCode}_${locale.countryCode}.json';
    final fullPath = '$path/$fileName';

    logger.i('🔍 DEBUG: Custom asset loader - loading: $fullPath');
    logger.i(
      '🔍 DEBUG: Custom asset loader - locale: ${locale.languageCode}_${locale.countryCode}',
    );

    try {
      final data = await rootBundle.loadString(fullPath);
      logger.i('🔍 DEBUG: Custom asset loader - successfully loaded $fullPath');
      final decoded = json.decode(data) as Map<String, dynamic>;
      logger.i(
        '🔍 DEBUG: Custom asset loader - decoded ${decoded.length} keys',
      );
      logger.i(
        '🔍 DEBUG: Custom asset loader - sample keys: ${decoded.keys.take(3).toList()}',
      );

      // Log some specific translations to verify content
      if (decoded.containsKey('language')) {
        logger.i(
          '🔍 DEBUG: Custom asset loader - "language" translation: ${decoded['language']}',
        );
      }
      if (decoded.containsKey('home')) {
        logger.i(
          '🔍 DEBUG: Custom asset loader - "home" translation: ${decoded['home']}',
        );
      }

      return decoded;
    } catch (e) {
      logger.e('🔍 DEBUG: Custom asset loader - failed to load $fullPath: $e');
      rethrow;
    }
  }
}

/*vvvvvv--------------------------------------------*/
/* M A I N   R O U T I N E                          */
void main() async {
  // Initialize Flutter bindings first (outside of any zone)
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('checklists');
  await Hive.openBox('profiles');
  await Hive.openBox('profile_sync_queue');

  // Global Flutter error handler
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
    logger.e(
      'Flutter framework error',
      error: details.exception,
      stackTrace: details.stack,
    );

    // TODO: Add Sentry error reporting
    // Sentry.captureException(
    //   details.exception,
    //   stackTrace: details.stack,
    //   extras: {'source': 'flutter_error_handler'},
    // );
  };

  // Handle widget build errors
  ErrorWidget.builder = (FlutterErrorDetails details) {
    logger.e(
      'Widget build error',
      error: details.exception,
      stackTrace: details.stack,
    );

    return Material(
      child: Container(
        color: Colors.red[50],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please restart the app',
              style: TextStyle(color: Colors.red[600], fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Force app restart by calling main again
                main();
              },
              child: const Text('Restart App'),
            ),
          ],
        ),
      ),
    );
  };

  // Load saved language preference before initializing EasyLocalization
  Locale? savedLocale;
  try {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(kLanguageKey);
    logger.i(
      '🔍 DEBUG: Main - loaded language code from SharedPreferences: $languageCode',
    );
    if (languageCode != null) {
      // Handle both old hyphenated format and new underscore format
      final parts = languageCode.contains('-')
          ? languageCode.split('-')
          : languageCode.split('_');
      if (parts.length == 2) {
        savedLocale = Locale(parts[0], parts[1]);
        logger.i(
          '🔍 DEBUG: Main - parsed saved locale: ${savedLocale.languageCode}_${savedLocale.countryCode}',
        );
      }
    }
  } catch (e) {
    logger.w('Failed to load saved language preference: $e');
  }

  // Initialize EasyLocalization
  await EasyLocalization.ensureInitialized();

  // Initialize Firebase
  try {
    // Try to initialize Firebase, but handle duplicate app gracefully
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    logger.i('Firebase initialized successfully');

    // TODO: Fix Firebase Analytics channel error
    // Initialize Firebase App Check (disabled for development)
    // TODO: Enable App Check for production
    /*
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.debug,
      );
      logger.i('Firebase App Check initialized successfully');
    } catch (appCheckError) {
      logger.w('Firebase App Check initialization failed: $appCheckError');
      logger.i('App will continue without App Check');
    }
    */
    logger.i('Firebase App Check disabled for development');

    // Initialize Firebase Analytics with error handling
    try {
      FirebaseAnalytics analytics = FirebaseAnalytics.instance;
      await analytics.setAnalyticsCollectionEnabled(true);
      logger.i('Firebase Analytics initialized successfully');

      // Initialize AnalyticsService
      await AnalyticsService().initialize();
    } catch (analyticsError) {
      logger.w('Firebase Analytics initialization failed: $analyticsError');
      logger.i('App will continue without Analytics');
    }

    // TODO: Initialize Sentry
    // import 'package:sentry_flutter/sentry_flutter.dart';
    // await SentryFlutter.init(
    //   (options) {
    //     options.dsn = 'YOUR_SENTRY_DSN';
    //     options.tracesSampleRate = 1.0;
    //     options.enableAutoSessionTracking = true;
    //   },
    // );
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      logger.i('Firebase already initialized (duplicate app error handled)');
    } else {
      logger.e('Firebase initialization failed: $e');
    }
    // Continue without Firebase for now
  }

  // Load initial translations
  await TranslationService.loadTranslations(
    savedLocale ?? const Locale('en', 'US'),
  );
  logger.i('🔍 DEBUG: Main - initial translations loaded');

  // Run the app in the same zone as ensureInitialized
  logger.i(
    '🔍 DEBUG: Main - setting up EasyLocalization with custom asset loader',
  );
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en', 'US'), Locale('es', 'ES')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en', 'US'),
      startLocale: savedLocale ?? const Locale('en', 'US'),
      assetLoader: UnderscoreAssetLoader(),
      useOnlyLangCode: false,
      child: const ProviderScope(child: ChecklisterApp()),
    ),
  );
} // main

/*^^^^^^--------------------------------------------*/
