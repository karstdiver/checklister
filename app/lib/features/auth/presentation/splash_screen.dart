import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/providers/providers.dart';
import '../domain/auth_state.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-navigate based on auth state after a short delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndNavigate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final navigationNotifier = ref.read(navigationNotifierProvider.notifier);

    // Listen for auth state changes and navigate accordingly
    ref.listen<AuthState>(authStateProvider, (previous, next) {
      if (next.isAuthenticated) {
        print(
          '🔍 DEBUG: SplashScreen detected authenticated user, navigating to home',
        );
        navigationNotifier.navigateToHome();
      } else if (next.hasError) {
        print(
          '🔍 DEBUG: SplashScreen detected auth error: ${next.errorMessage}',
        );
        // Stay on splash to show error
      } else if (!next.isLoading && next.status != AuthStatus.initial) {
        print(
          '🔍 DEBUG: SplashScreen detected unauthenticated user, navigating to login',
        );
        navigationNotifier.navigateToLogin();
      }
    });

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo/Icon
              const Icon(Icons.checklist, size: 80, color: Colors.blue),
              const SizedBox(height: 24),

              // App Title
              Text(
                tr('welcome_title'),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Subtitle
              Text(
                tr('welcome_subtitle'),
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Debug info
              Text(
                'Auth Status: ${authState.status}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              if (authState.user != null)
                Text(
                  'User: ${authState.user!.uid}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              const SizedBox(height: 24),

              // Loading indicator
              if (authState.isLoading)
                const CircularProgressIndicator()
              else
                // Manual navigation buttons
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: () => navigationNotifier.navigateToLogin(),
                      child: Text(tr('login')),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => navigationNotifier.navigateToAbout(),
                      child: Text(tr('about')),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => navigationNotifier.navigateToHelp(),
                      child: Text(tr('help')),
                    ),
                  ],
                ),

              // Error message
              if (authState.hasError) ...[
                const SizedBox(height: 24),
                Text(
                  authState.errorMessage ?? tr('error_unknown'),
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.read(authNotifierProvider.notifier).clearError();
                    _checkAuthAndNavigate();
                  },
                  child: Text(tr('retry')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _checkAuthAndNavigate() async {
    // Small delay to show splash screen
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final authState = ref.read(authStateProvider);
    final navigationNotifier = ref.read(navigationNotifierProvider.notifier);

    print(
      '🔍 DEBUG: SplashScreen _checkAuthAndNavigate - Status: ${authState.status}',
    );

    if (authState.isAuthenticated) {
      print('🔍 DEBUG: SplashScreen navigating to home');
      navigationNotifier.navigateToHome();
    } else {
      print('🔍 DEBUG: SplashScreen navigating to login');
      navigationNotifier.navigateToLogin();
    }
  }
}
