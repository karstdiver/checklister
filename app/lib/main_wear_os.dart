/* M A I N  W E A R  O S  P R O G R A M */

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';

//import 'package:checklister/checklister.dart'; // be sure to add new code to the lib/checklister.dart exports
import 'checklister_wear_os_app.dart';

// imports for google firebase backend
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'core/services/analytics_service.dart';


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
    logger.e('Widget build error', error: details.exception);
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            'Something went wrong: ${details.exception}',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  };

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize analytics
  await AnalyticsService().initialize();

  // Initialize localization
  await EasyLocalization.ensureInitialized();

  // Get language preference
  final prefs = await SharedPreferences.getInstance();
  final savedLanguage = prefs.getString(kLanguageKey) ?? 'en';

  // Set up localization
  await EasyLocalization.ensureInitialized();

  // Run the Wear OS app
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en', 'US'), Locale('es', 'ES')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en', 'US'),
      assetLoader: UnderscoreAssetLoader(),
      startLocale: Locale(savedLanguage.split('_')[0], savedLanguage.split('_')[1]),
      child: ProviderScope(
        child: ChecklisterWearOSApp(),
      ),
    ),
  );
}
