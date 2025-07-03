import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_state.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth? _auth;

  AuthNotifier(this._auth) : super(const AuthState()) {
    // Only listen to auth state changes if Firebase is available
    if (_auth != null) {
      try {
        _auth.authStateChanges().listen((User? user) {
          if (user != null) {
            state = state.copyWith(
              status: AuthStatus.authenticated,
              user: user,
              errorMessage: null,
            );
          } else {
            // Don't automatically update state to unauthenticated during initialization
            // Only update if we're not in the initial setup phase
            if (state.status != AuthStatus.initial) {
              state = state.copyWith(
                status: AuthStatus.unauthenticated,
                user: null,
                errorMessage: null,
              );
            }
          }
        });
      } catch (e) {
        // Firebase not available, set to unauthenticated
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          user: null,
          errorMessage: 'Firebase not available',
        );
      }
    } else {
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
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Firebase not available',
      );
      return;
    }

    try {
      state = state.copyWith(status: AuthStatus.loading);
      final userCredential = await _auth.signInAnonymously();

      // Manually update state in case listener doesn't fire immediately
      if (userCredential.user != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: userCredential.user,
          errorMessage: null,
        );
      }
    } catch (e) {
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
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('🔍 DEBUG: Email/password sign in completed successfully');
      if (userCredential.user != null) {
        // TODO: Create user document in Firestore if not exists
        print(
          '🔍 DEBUG: [TODO] Create user doc for UID: ${userCredential.user!.uid}',
        );
        // Manually update state to authenticated
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: userCredential.user,
          errorMessage: null,
        );
      }
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
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Firebase not available',
      );
      return;
    }

    try {
      await _auth.signOut();
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> signInWithGoogle() async {
    if (_auth == null) {
      print('🔍 DEBUG: Firebase Auth is null, cannot sign in with Google');
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Firebase not available',
      );
      return;
    }

    try {
      print('🔍 DEBUG: Starting Google sign in');
      state = state.copyWith(status: AuthStatus.loading);
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // User cancelled the sign-in
        state = state.copyWith(status: AuthStatus.unauthenticated);
        print('🔍 DEBUG: Google sign in cancelled by user');
        return;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      print('🔍 DEBUG: Google sign in completed successfully');
      if (userCredential.user != null) {
        // TODO: Create user document in Firestore if not exists
        print(
          '🔍 DEBUG: [TODO] Create user doc for UID: \\${userCredential.user!.uid}',
        );
      }
    } catch (e) {
      print('🔍 DEBUG: Google sign in failed: $e');
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
