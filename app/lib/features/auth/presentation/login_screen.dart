import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/providers/providers.dart';
import '../domain/auth_state.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final authNotifier = ref.read(authNotifierProvider.notifier);

      if (_isSignUp) {
        await authNotifier.signUpWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        await authNotifier.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }
    }
  }

  Future<void> _signInAnonymously() async {
    final authNotifier = ref.read(authNotifierProvider.notifier);
    await authNotifier.signInAnonymously();

    // Navigate to home after successful anonymous sign-in
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isSignUp ? tr('signup') : tr('login')),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Navigate to about screen
            },
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo
              const Icon(Icons.checklist, size: 64, color: Colors.blue),
              const SizedBox(height: 32),

              // Title
              Text(
                _isSignUp ? tr('create_account') : tr('welcome_back'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

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
              const SizedBox(height: 16),

              // Email Field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: tr('email'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return tr('email_required');
                  }
                  if (!value.contains('@')) {
                    return tr('email_invalid');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password Field
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: tr('password'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return tr('password_required');
                  }
                  if (value.length < 6) {
                    return tr('password_too_short');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: authState.isLoading ? null : _submitForm,
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isSignUp ? tr('signup') : tr('login')),
                ),
              ),
              const SizedBox(height: 16),

              // Toggle Sign Up/Login
              TextButton(
                onPressed: () => setState(() => _isSignUp = !_isSignUp),
                child: Text(
                  _isSignUp ? tr('already_have_account') : tr('create_account'),
                ),
              ),

              const SizedBox(height: 16),

              // Anonymous Login
              TextButton(
                onPressed: authState.isLoading ? null : _signInAnonymously,
                child: Text(tr('continue_anonymously')),
              ),

              // Error Message
              if (authState.hasError) ...[
                const SizedBox(height: 16),
                Text(
                  authState.errorMessage ?? tr('error_unknown'),
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () =>
                      ref.read(authNotifierProvider.notifier).clearError(),
                  child: Text(tr('dismiss')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
