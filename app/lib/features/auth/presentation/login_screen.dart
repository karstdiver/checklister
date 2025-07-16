import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../auth/domain/auth_state.dart';
import '../../../core/services/translation_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _resetEmailController = TextEditingController();
  bool _isSignUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _resetEmailController.dispose();
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

  Future<void> _showForgotPasswordDialog() async {
    _resetEmailController.text =
        _emailController.text; // Pre-fill with current email

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return _PasswordResetDialog(
          emailController: _resetEmailController,
          onSend: _sendPasswordResetEmail,
          onCancel: _closeResetDialog,
          isLoading: ref.watch(authStateProvider).isLoading,
          errorMessage: ref.watch(authStateProvider).errorMessage,
        );
      },
    );
  }

  Future<void> _sendPasswordResetEmail() async {
    if (_resetEmailController.text.trim().isEmpty) {
      return; // Don't send if email is empty
    }

    final authNotifier = ref.read(authNotifierProvider.notifier);
    await authNotifier.sendPasswordResetEmail(
      _resetEmailController.text.trim(),
    );

    // Don't close the dialog immediately - let user read the message
    // Dialog will be closed when user clicks Cancel or after a delay
  }

  void _closeResetDialog() {
    Navigator.of(context).pop();
    ref.read(authNotifierProvider.notifier).clearError();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the translation provider to trigger rebuilds when language changes
    ref.watch(translationProvider);
    final authState = ref.watch(authStateProvider);

    ref.listen<AuthState>(authNotifierProvider, (prev, next) {
      if (next.status == AuthStatus.authenticated) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isSignUp
              ? TranslationService.translate('signup')
              : TranslationService.translate('login'),
        ),
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
                _isSignUp
                    ? TranslationService.translate('create_account')
                    : TranslationService.translate('welcome_back'),
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
                  labelText: TranslationService.translate('email'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return TranslationService.translate('email_required');
                  }
                  if (!value.contains('@')) {
                    return TranslationService.translate('email_invalid');
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
                  labelText: TranslationService.translate('password'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return TranslationService.translate('password_required');
                  }
                  if (value.length < 6) {
                    return TranslationService.translate('password_too_short');
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
                      : Text(
                          _isSignUp
                              ? TranslationService.translate('signup')
                              : TranslationService.translate('login'),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Toggle Sign Up/Login
              TextButton(
                onPressed: () => setState(() => _isSignUp = !_isSignUp),
                child: Text(
                  _isSignUp
                      ? TranslationService.translate('already_have_account')
                      : TranslationService.translate('create_account'),
                ),
              ),

              const SizedBox(height: 16),

              // Forgot Password (only show for login mode)
              if (!_isSignUp) ...[
                TextButton(
                  onPressed: _showForgotPasswordDialog,
                  child: Text(TranslationService.translate('forgot_password')),
                ),
                const SizedBox(height: 16),
              ],

              // Anonymous Login
              TextButton(
                onPressed: authState.isLoading ? null : _signInAnonymously,
                child: Text(
                  TranslationService.translate('continue_anonymously'),
                ),
              ),

              // Error Message
              if (authState.hasError) ...[
                const SizedBox(height: 16),
                Text(
                  authState.errorMessage == 'sign_in_failed'
                      ? TranslationService.translate('sign_in_failed')
                      : authState.errorMessage ??
                            TranslationService.translate('error_unknown'),
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () =>
                      ref.read(authNotifierProvider.notifier).clearError(),
                  child: Text(TranslationService.translate('dismiss')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// If _PasswordResetDialog uses tr, update it as well
class _PasswordResetDialog extends ConsumerWidget {
  final TextEditingController emailController;
  final VoidCallback onSend;
  final VoidCallback onCancel;
  final bool isLoading;
  final String? errorMessage;

  const _PasswordResetDialog({
    required this.emailController,
    required this.onSend,
    required this.onCancel,
    required this.isLoading,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the translation provider to trigger rebuilds when language changes
    ref.watch(translationProvider);
    return AlertDialog(
      title: Text(TranslationService.translate('forgot_password')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: TranslationService.translate('email'),
            ),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(errorMessage!, style: const TextStyle(color: Colors.red)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: Text(TranslationService.translate('cancel')),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : onSend,
          child: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(TranslationService.translate('retry')),
        ),
      ],
    );
  }
}
