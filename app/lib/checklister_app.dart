import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart'; // For SystemNavigator.pop

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
import 'core/services/acceptance_service.dart';
import 'core/services/translation_service.dart';

class ChecklisterApp extends ConsumerWidget {
  const ChecklisterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch settings to get the saved language preference
    final settings = ref.watch(settingsProvider);

    // Use the saved language from settings, fallback to context.locale
    final currentLocale = settings.language ?? context.locale;

    return FutureBuilder<bool>(
      future: AcceptanceService.isAcceptanceRequired(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }
        final needsAcceptance = snapshot.data!;
        return MaterialApp(
          title: 'Checklister',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settings.themeMode,
          home: needsAcceptance
              ? const AcceptanceScreen()
              : const SplashScreen(),
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
      },
    );
  }
}

class AcceptanceScreen extends StatefulWidget {
  final VoidCallback? onDecline;
  const AcceptanceScreen({super.key, this.onDecline});

  @override
  State<AcceptanceScreen> createState() => _AcceptanceScreenState();
}

class _AcceptanceScreenState extends State<AcceptanceScreen> {
  bool _privacyAccepted = false;
  bool _tosAccepted = false;
  bool _isReauthenticating = false;
  bool _isAccepted = false;
  String? _error;

  void _showMarkdownDialog(String titleKey, String assetBase) async {
    final locale = Localizations.localeOf(context).languageCode;
    final assetPath = 'assets/${assetBase}_$locale.md';
    String data;
    try {
      data = await DefaultAssetBundle.of(context).loadString(assetPath);
    } catch (_) {
      data = await DefaultAssetBundle.of(
        context,
      ).loadString('assets/${assetBase}_en.md');
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(TranslationService.translate(titleKey)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(child: Text(data)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(TranslationService.translate('close')),
          ),
        ],
      ),
    );
  }

  Future<void> _reauthenticate() async {
    setState(() {
      _isReauthenticating = true;
      _error = null;
    });
    // TODO: Implement real re-authentication (e.g., Firebase Auth)
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isReauthenticating = false;
    });
  }

  Future<void> _accept() async {
    setState(() {
      _isAccepted = false;
      _error = null;
    });
    try {
      await AcceptanceService.saveAcceptance(
        privacyAccepted: _privacyAccepted,
        tosAccepted: _tosAccepted,
      );
      await AcceptanceService.saveAcceptanceRemote(
        privacyAccepted: _privacyAccepted,
        tosAccepted: _tosAccepted,
      );
      setState(() {
        _isAccepted = true;
      });
      // Restart app or navigate to splash/home
      Navigator.of(context).pushReplacementNamed('/splash');
    } catch (e) {
      setState(() {
        _error = 'Failed to save acceptance: $e';
      });
    }
  }

  // Helper to check both local and remote acceptance status
  Future<bool> isAcceptanceRequiredHybrid() async {
    final local = await AcceptanceService.loadAcceptance();
    final remote = await AcceptanceService.loadAcceptanceRemote();
    final localRequired =
        !local.privacyAccepted ||
        !local.tosAccepted ||
        local.acceptedVersion < AcceptanceService.currentPolicyVersion;
    final remoteRequired =
        remote == null ||
        !remote.privacyAccepted ||
        !remote.tosAccepted ||
        remote.acceptedVersion < AcceptanceService.currentPolicyVersion;
    return localRequired || remoteRequired;
  }

  @override
  Widget build(BuildContext context) {
    final isLogout = widget.onDecline != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(TranslationService.translate('accept_privacy_and_terms')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            CheckboxListTile(
              value: _privacyAccepted,
              onChanged: (v) => setState(() => _privacyAccepted = v ?? false),
              title: Text(
                TranslationService.translate('accept_privacy_policy'),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              secondary: TextButton(
                onPressed: () =>
                    _showMarkdownDialog('privacy_policy', 'privacy_policy'),
                child: Text(TranslationService.translate('read')),
              ),
            ),
            CheckboxListTile(
              value: _tosAccepted,
              onChanged: (v) => setState(() => _tosAccepted = v ?? false),
              title: Text(
                TranslationService.translate('accept_terms_of_service'),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              secondary: TextButton(
                onPressed: () =>
                    _showMarkdownDialog('terms_of_service', 'terms_of_service'),
                child: Text(TranslationService.translate('read')),
              ),
            ),
            const SizedBox(height: 24),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            ElevatedButton(
              onPressed:
                  (_privacyAccepted && _tosAccepted && !_isReauthenticating)
                  ? () async {
                      await _reauthenticate();
                      if (mounted && !_isReauthenticating) {
                        await _accept();
                      }
                    }
                  : null,
              child: _isReauthenticating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(TranslationService.translate('accept_and_continue')),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                print(
                  'Decline button pressed. onDecline is ${widget.onDecline != null ? 'provided' : 'not provided'}',
                );
                print('Context mounted: $mounted');
                if (widget.onDecline != null) {
                  print('Calling onDecline callback...');
                  widget.onDecline!();
                  print('onDecline callback finished.');
                } else {
                  print('No onDecline provided, calling SystemNavigator.pop()');
                  SystemNavigator.pop();
                }
              },
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              child: Text(TranslationService.translate('decline_and_exit')),
            ),
          ],
        ),
      ),
    );
  }
}
