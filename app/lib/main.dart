/* M A I N  P R O G R A M */

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:logger/logger.dart';

import 'package:checklister/checklister.dart'; // be sure to add new code to the lib/checklister.dart exports
import 'checklister_app.dart';

// imports for google firebase backend
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

final Logger logger = Logger();

/*vvvvvv--------------------------------------------*/
/* M A I N   R O U T I N E                          */
void main() async {
  // Initialize Flutter bindings first (outside of any zone)
  WidgetsFlutterBinding.ensureInitialized();

  // Global Flutter error handler
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
    logger.e(
      'Flutter framework error',
      error: details.exception,
      stackTrace: details.stack,
    );
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

  // Initialize EasyLocalization
  await EasyLocalization.ensureInitialized();

  // Initialize Firebase
  try {
    // Try to initialize Firebase, but handle duplicate app gracefully
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    logger.i('Firebase initialized successfully');
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      logger.i('Firebase already initialized (duplicate app error handled)');
    } else {
      logger.e('Firebase initialization failed: $e');
    }
    // Continue without Firebase for now
  }

  // Run the app in the same zone as ensureInitialized
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en', 'US'), Locale('es', 'ES')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en', 'US'),
      child: const ProviderScope(child: ChecklisterApp()),
    ),
  );
} // main

/*^^^^^^--------------------------------------------*/
