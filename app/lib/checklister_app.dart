import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import 'core/providers/providers.dart';
import 'core/providers/settings_provider.dart';
import 'features/auth/presentation/splash_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/checklists/presentation/home_screen.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'features/settings/presentation/profile_overview_screen.dart';
import 'features/settings/presentation/profile_edit_screen.dart';
import 'features/settings/presentation/language_screen.dart';
import 'features/settings/presentation/notification_screen.dart';
import 'features/achievements/presentation/achievement_screen.dart';
import 'features/settings/presentation/about_screen.dart';
import 'features/settings/presentation/help_screen.dart';
import 'shared/themes/app_theme.dart';

class ChecklisterApp extends ConsumerWidget {
  const ChecklisterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch settings to get the saved language preference
    final settings = ref.watch(settingsProvider);

    // Use the saved language from settings, fallback to context.locale
    final currentLocale = settings.language ?? context.locale;

    return MaterialApp(
      title: 'Checklister',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: currentLocale,
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/profile': (context) => const ProfileOverviewScreen(),
        '/profile/edit': (context) => const ProfileEditScreen(),
        '/language': (context) => const LanguageScreen(),
        '/notifications': (context) => const NotificationScreen(),
        '/achievements': (context) => const AchievementScreen(),
        '/about': (context) => const AboutScreen(),
        '/help': (context) => const HelpScreen(),
      },
    );
  }
}
