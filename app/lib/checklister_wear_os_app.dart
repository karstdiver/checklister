import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:logger/logger.dart';

import 'core/shared/platform_detector.dart';
import 'core/providers/providers.dart';
import 'features/auth/domain/auth_state.dart';
import 'features/checklists/presentation/wear_os/checklist_watch_screen.dart';
import 'shared/themes/app_theme.dart';

final Logger logger = Logger();

class ChecklisterWearOSApp extends ConsumerWidget {
  const ChecklisterWearOSApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    logger.i('🚀 Starting Checklister Wear OS App');
    logger.i('📱 Platform: ${PlatformDetector.platformType}');
    logger.i('⌚ Wear OS Support: ${PlatformDetector.supportsWatchFeatures}');

    return MaterialApp(
      title: 'Checklister Watch',
      debugShowCheckedModeBanner: false,

      // Localization
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      // Theme
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // Home screen - simplified for testing
      home: const ChecklistWatchScreen(),

      // Navigation
      routes: {
        '/checklist': (context) => const ChecklistWatchScreen(),
        // Add more Wear OS specific routes here
      },
    );
  }
}
