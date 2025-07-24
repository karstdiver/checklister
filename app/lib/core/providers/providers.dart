import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/domain/auth_notifier.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/data/user_repository.dart';
import '../../features/auth/domain/profile_provider.dart';
import '../navigation/navigation_notifier.dart';
import '../navigation/navigation_state.dart';
import 'privilege_provider.dart';

// Firebase Auth provider with fallback
final firebaseAuthProvider = Provider<FirebaseAuth?>((ref) {
  try {
    return FirebaseAuth.instance;
  } catch (e) {
    // Return null if Firebase is not available
    return null;
  }
});

// User repository provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

// Authentication providers
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  final auth = ref.watch(firebaseAuthProvider);
  return AuthNotifier(auth);
});

final authStateProvider = Provider<AuthState>((ref) {
  return ref.watch(authNotifierProvider);
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).isAuthenticated;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).user;
});

// app/lib/core/providers/providers.dart (or a new file)
final showLogoutDialogProvider = StateProvider<bool>((ref) => false);

// Navigation providers
final navigationNotifierProvider =
    StateNotifierProvider<NavigationNotifier, NavigationState>((ref) {
      return NavigationNotifier();
    });

final navigationStateProvider = Provider<NavigationState>((ref) {
  return ref.watch(navigationNotifierProvider);
});

final currentRouteProvider = Provider<NavigationRoute>((ref) {
  return ref.watch(navigationStateProvider).currentRoute;
});

// Combined providers for common use cases
final authAndNavigationProvider =
    Provider<({AuthState auth, NavigationState navigation})>((ref) {
      return (
        auth: ref.watch(authStateProvider),
        navigation: ref.watch(navigationStateProvider),
      );
    });

// Add this at the end of the file to set up a global listener

// This should be called from your app's main widget (e.g., ChecklisterApp) in build or initState
void setupGlobalAuthProfileListener(WidgetRef ref) {
  ref.listen<User?>(currentUserProvider, (prev, next) async {
    if (next == null || next.isAnonymous) {
      await ref.read(profileNotifierProvider.notifier).clearProfile();
    }
  });
}
