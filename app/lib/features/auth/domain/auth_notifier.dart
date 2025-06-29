import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth? _auth;

  AuthNotifier(this._auth) : super(const AuthState()) {
    // Only listen to auth state changes if Firebase is available
    if (_auth != null) {
      try {
        print('🔍 DEBUG: Attempting to listen to auth state changes');
        _auth.authStateChanges().listen((User? user) {
          if (user != null) {
            print('🔍 DEBUG: User authenticated: ${user.uid}');
            state = state.copyWith(
              status: AuthStatus.authenticated,
              user: user,
              errorMessage: null,
            );
          } else {
            print('🔍 DEBUG: User unauthenticated');
            state = state.copyWith(
              status: AuthStatus.unauthenticated,
              user: null,
              errorMessage: null,
            );
          }
        });
        print('🔍 DEBUG: Successfully set up auth state listener');
      } catch (e) {
        print('🔍 DEBUG: Error setting up auth state listener: $e');
        // Firebase not available, set to unauthenticated
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          user: null,
          errorMessage: 'Firebase not available',
        );
      }
    } else {
      print('🔍 DEBUG: Firebase Auth is null, setting unauthenticated state');
      // No Firebase Auth available, set to unauthenticated
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        user: null,
        errorMessage: 'Firebase not available',
      );
    }
  }

  Future<void> signInAnonymously() async {
    if (_auth == null) {
      print('🔍 DEBUG: Firebase Auth is null, cannot sign in anonymously');
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Firebase not available',
      );
      return;
    }

    try {
      print('🔍 DEBUG: Starting anonymous sign in');
      state = state.copyWith(status: AuthStatus.loading);
      await _auth.signInAnonymously();
      print('🔍 DEBUG: Anonymous sign in completed successfully');
    } catch (e) {
      print('🔍 DEBUG: Anonymous sign in failed: $e');
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    if (_auth == null) {
      print(
        '🔍 DEBUG: Firebase Auth is null, cannot sign in with email/password',
      );
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Firebase not available',
      );
      return;
    }

    try {
      print('🔍 DEBUG: Starting email/password sign in for: $email');
      state = state.copyWith(status: AuthStatus.loading);
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      print('🔍 DEBUG: Email/password sign in completed successfully');
    } catch (e) {
      print('🔍 DEBUG: Email/password sign in failed: $e');
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> signUpWithEmailAndPassword(String email, String password) async {
    if (_auth == null) {
      print(
        '🔍 DEBUG: Firebase Auth is null, cannot sign up with email/password',
      );
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Firebase not available',
      );
      return;
    }

    try {
      print('🔍 DEBUG: Starting email/password sign up for: $email');
      state = state.copyWith(status: AuthStatus.loading);
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('🔍 DEBUG: Email/password sign up completed successfully');
    } catch (e) {
      print('🔍 DEBUG: Email/password sign up failed: $e');
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> signOut() async {
    if (_auth == null) {
      print('🔍 DEBUG: Firebase Auth is null, cannot sign out');
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Firebase not available',
      );
      return;
    }

    try {
      print('🔍 DEBUG: Starting sign out');
      await _auth.signOut();
      print('🔍 DEBUG: Sign out completed successfully');
    } catch (e) {
      print('🔍 DEBUG: Sign out failed: $e');
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void clearError() {
    print('🔍 DEBUG: Clearing error state');
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      errorMessage: null,
    );
  }
}
