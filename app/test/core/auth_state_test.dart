import 'package:flutter_test/flutter_test.dart';
import 'package:checklister/features/auth/domain/auth_state.dart';

void main() {
  group('AuthState', () {
    test('should create initial state correctly', () {
      const state = AuthState();

      expect(state.status, AuthStatus.initial);
      expect(state.user, isNull);
      expect(state.errorMessage, isNull);
    });

    test('should create state with custom values', () {
      const state = AuthState(
        status: AuthStatus.authenticated,
        user: null,
        errorMessage: null,
      );

      expect(state.status, AuthStatus.authenticated);
      expect(state.user, isNull);
      expect(state.errorMessage, isNull);
    });

    test('should copy with new values', () {
      const initialState = AuthState();

      final newState = initialState.copyWith(
        status: AuthStatus.authenticated,
        user: null,
        errorMessage: 'Test error',
      );

      expect(newState.status, AuthStatus.authenticated);
      expect(newState.user, isNull);
      expect(newState.errorMessage, 'Test error');
    });

    test('should copy with partial values', () {
      const initialState = AuthState(
        status: AuthStatus.authenticated,
        errorMessage: 'Old error',
      );

      final newState = initialState.copyWith(status: AuthStatus.loading);

      expect(newState.status, AuthStatus.loading);
      expect(newState.errorMessage, 'Old error'); // Should remain unchanged
    });

    test('should compute isAuthenticated correctly', () {
      // Authenticated state (without user for now)
      const authenticatedState = AuthState(
        status: AuthStatus.authenticated,
        user: null,
      );
      expect(
        authenticatedState.isAuthenticated,
        isFalse,
      ); // False because user is null

      // Unauthenticated state
      const unauthenticatedState = AuthState(
        status: AuthStatus.unauthenticated,
        user: null,
      );
      expect(unauthenticatedState.isAuthenticated, isFalse);

      // Loading state
      const loadingState = AuthState(status: AuthStatus.loading, user: null);
      expect(loadingState.isAuthenticated, isFalse);
    });

    test('should compute isLoading correctly', () {
      const loadingState = AuthState(status: AuthStatus.loading);
      expect(loadingState.isLoading, isTrue);

      const authenticatedState = AuthState(status: AuthStatus.authenticated);
      expect(authenticatedState.isLoading, isFalse);
    });

    test('should compute hasError correctly', () {
      const errorState = AuthState(status: AuthStatus.error);
      expect(errorState.hasError, isTrue);

      const authenticatedState = AuthState(status: AuthStatus.authenticated);
      expect(authenticatedState.hasError, isFalse);
    });
  });
}
