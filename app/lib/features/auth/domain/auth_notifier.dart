import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_state.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../data/user_repository.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth? _auth;
  final UserRepository _userRepository = UserRepository();

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
        // TODO: Add Firebase Analytics event
        // FirebaseAnalytics.instance.logEvent(name: 'user_signed_in', parameters: {
        //   'method': 'email_password',
        //   'user_id': userCredential.user!.uid,
        // });
        // Create user document in Firestore if not exists
        print(
          '🔍 DEBUG: Creating user doc for UID: ${userCredential.user!.uid}',
        );
        try {
          await _userRepository.createUserDocumentIfNotExists(
            userCredential.user!,
          );
        } catch (e) {
          print('🔍 DEBUG: Failed to create user document: $e');
          // TODO: Add Sentry error reporting
          // Sentry.captureException(e, extras: {
          //   'user_id': userCredential.user!.uid,
          //   'operation': 'user_document_creation',
          //   'auth_method': 'email_password',
          // });
          // Don't fail the sign-in if Firestore fails
        }
        // Manually update state to authenticated
        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: userCredential.user,
          errorMessage: null,
        );
      }
    } catch (e) {
      print('🔍 DEBUG: Email/password sign in failed: $e');

      // Handle specific Firebase Auth errors
      String userFriendlyMessage;
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            userFriendlyMessage =
                'No account found with this email. Please sign up instead.';
            break;
          case 'wrong-password':
            userFriendlyMessage = 'Incorrect password. Please try again.';
            break;
          case 'invalid-email':
            userFriendlyMessage = 'Please enter a valid email address.';
            break;
          case 'user-disabled':
            userFriendlyMessage =
                'This account has been disabled. Please contact support.';
            break;
          case 'too-many-requests':
            userFriendlyMessage =
                'Too many failed attempts. Please try again later.';
            break;
          case 'network-request-failed':
            userFriendlyMessage =
                'Network error. Please check your internet connection and try again.';
            break;
          default:
            userFriendlyMessage =
                'Sign in failed. Please check your credentials and try again.';
        }
      } else {
        userFriendlyMessage = 'An unexpected error occurred. Please try again.';
      }

      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: userFriendlyMessage,
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

      // Create the user account (let Firebase handle duplicate emails)
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('🔍 DEBUG: Email/password sign up completed successfully');

      // TODO: Add Firebase Analytics event
      // FirebaseAnalytics.instance.logEvent(name: 'user_signed_up', parameters: {
      //   'method': 'email_password',
      //   'user_id': userCredential.user!.uid,
      // });

      // Create user document in Firestore if not exists
      if (userCredential.user != null) {
        print('🔍 DEBUG: Create user doc for UID: ${userCredential.user!.uid}');
        // Here you would create the user document in Firestore
        await _userRepository.createUserDocumentIfNotExists(
          userCredential.user!,
        );
      }
    } catch (e) {
      print('🔍 DEBUG: Email/password sign up failed: $e');

      // Handle specific Firebase Auth errors
      String userFriendlyMessage;
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            userFriendlyMessage =
                'An account with this email already exists. Please sign in instead.';
            break;
          case 'weak-password':
            userFriendlyMessage =
                'Password is too weak. Please choose a stronger password.';
            break;
          case 'invalid-email':
            userFriendlyMessage = 'Please enter a valid email address.';
            break;
          case 'operation-not-allowed':
            userFriendlyMessage =
                'Email/password sign up is not enabled. Please contact support.';
            break;
          case 'network-request-failed':
            userFriendlyMessage =
                'Network error. Please check your internet connection and try again.';
            break;
          default:
            userFriendlyMessage = 'Sign up failed. Please try again.';
        }
      } else {
        userFriendlyMessage = 'An unexpected error occurred. Please try again.';
      }

      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: userFriendlyMessage,
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
        // TODO: Add Firebase Analytics event
        // FirebaseAnalytics.instance.logEvent(name: 'user_signed_in', parameters: {
        //   'method': 'google',
        //   'user_id': userCredential.user!.uid,
        // });

        // Create user document in Firestore if not exists
        print(
          '🔍 DEBUG: Create user doc for UID: \\${userCredential.user!.uid}',
        );
        await _userRepository.createUserDocumentIfNotExists(
          userCredential.user!,
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

  Future<void> sendPasswordResetEmail(String email) async {
    if (_auth == null) {
      print(
        '🔍 DEBUG: Firebase Auth is null, cannot send password reset email',
      );
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Firebase not available',
      );
      return;
    }

    try {
      print('🔍 DEBUG: Sending password reset email to: $email');
      state = state.copyWith(status: AuthStatus.loading);

      await _auth.sendPasswordResetEmail(email: email);

      // Always show success message for security (prevents email enumeration)
      print('🔍 DEBUG: Password reset email sent successfully');
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage:
            'If an account exists with this email, a password reset link has been sent.',
      );
    } catch (e) {
      print('🔍 DEBUG: Password reset email failed: $e');

      // Only show errors for actual failures (network, invalid email format, etc.)
      String userFriendlyMessage;
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'invalid-email':
            userFriendlyMessage = 'Please enter a valid email address.';
            break;
          case 'network-request-failed':
            userFriendlyMessage =
                'Network error. Please check your connection and try again.';
            break;
          case 'too-many-requests':
            userFriendlyMessage = 'Too many requests. Please try again later.';
            break;
          default:
            userFriendlyMessage =
                'Failed to send reset email. Please try again.';
        }
      } else {
        userFriendlyMessage = 'An unexpected error occurred. Please try again.';
      }

      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: userFriendlyMessage,
      );
    }
  }
}
