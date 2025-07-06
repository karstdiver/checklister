import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_state.dart';

// Example 1: Simple function to get current user UID
String? getCurrentUserUid() {
  final user = FirebaseAuth.instance.currentUser;
  return user?.uid;
}

// Example 2: Using Riverpod provider to get user UID
final currentUserUidProvider = Provider<String?>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  return user?.uid;
});

// Example 3: Stream-based provider that updates when auth state changes
final currentUserUidStreamProvider = StreamProvider<String?>((ref) {
  return FirebaseAuth.instance.authStateChanges().map((user) => user?.uid);
});

// Example 4: Complete user info provider
final currentUserProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// Example 5: Widget that displays user UID
class UserUidDisplay extends ConsumerWidget {
  const UserUidDisplay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Method 1: Using the simple provider
    final uid = ref.watch(currentUserUidProvider);

    // Method 2: Using the stream provider (auto-updates)
    final uidAsync = ref.watch(currentUserUidStreamProvider);

    return Column(
      children: [
        // Simple display
        if (uid != null) ...[
          Text('User UID: $uid'),
          const SizedBox(height: 16),
        ],

        // Async display with loading states
        uidAsync.when(
          data: (uid) => uid != null
              ? Text('Current UID: $uid')
              : const Text('No user logged in'),
          loading: () => const CircularProgressIndicator(),
          error: (error, stack) => Text('Error: $error'),
        ),

        const SizedBox(height: 16),

        // Button to get UID manually
        ElevatedButton(
          onPressed: () {
            final currentUid = getCurrentUserUid();
            if (currentUid != null) {
              print('Current UID: $currentUid');
            } else {
              print('No user logged in');
            }
          },
          child: const Text('Print Current UID'),
        ),
      ],
    );
  }
}

// Example 6: Function that uses UID for Firestore operations
Future<void> createUserDocument(String uid) async {
  // This is what you'd implement in the TODO sections
  print('Creating user document for UID: $uid');

  // Example Firestore operation:
  // await FirebaseFirestore.instance
  //   .collection('users')
  //   .doc(uid)
  //   .set({
  //     'uid': uid,
  //     'createdAt': FieldValue.serverTimestamp(),
  //     'updatedAt': FieldValue.serverTimestamp(),
  //   });
}

// Example 7: Complete user management class
class UserService {
  static String? getCurrentUid() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  static User? getCurrentUser() {
    return FirebaseAuth.instance.currentUser;
  }

  static bool isUserLoggedIn() {
    return FirebaseAuth.instance.currentUser != null;
  }

  static Future<void> createUserDocumentIfNotExists() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await createUserDocument(user.uid);
    }
  }
}

// Example 8: Usage in auth notifier (similar to your existing code)
class ExampleAuthNotifier extends StateNotifier<AuthState> {
  ExampleAuthNotifier() : super(const AuthState());

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      state = state.copyWith(status: AuthStatus.loading);

      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        final uid = userCredential.user!.uid;
        print('User signed in with UID: $uid');

        // Create user document in Firestore
        await createUserDocument(uid);

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
}
