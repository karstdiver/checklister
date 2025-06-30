import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import 'core/providers/providers.dart';
import 'features/auth/presentation/splash_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/checklists/presentation/home_screen.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'shared/themes/app_theme.dart';

class ChecklisterApp extends ConsumerWidget {
  const ChecklisterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Checklister',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}

// Placeholder screens for About and Help
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationNotifier = ref.read(navigationNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('about'.tr()),
        leading: IconButton(
          onPressed: () => navigationNotifier.goBack(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info, size: 64, color: Colors.blue),
              SizedBox(height: 24),
              Text(
                'Checklister App',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                'A checklist-driven task management app',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HelpScreen extends ConsumerWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationNotifier = ref.read(navigationNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('help'.tr()),
        leading: IconButton(
          onPressed: () => navigationNotifier.goBack(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.help, size: 64, color: Colors.blue),
              SizedBox(height: 24),
              Text(
                'Help & Support',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                'Need help? Contact our support team.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
