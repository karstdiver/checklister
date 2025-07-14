import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/providers/providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../../../shared/widgets/app_pulse_animation.dart';
//import 'package:animated_text_kit/animated_text_kit.dart';

class SplashScreen extends ConsumerStatefulWidget {
  final Duration delay;
  const SplashScreen({super.key, this.delay = const Duration(seconds: 4)});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _authCheckTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final firebaseAuth = FirebaseAuth.instance;
      final currentUser = firebaseAuth.currentUser;
      if (currentUser != null && mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      } else if (mounted) {
        // Add a short delay for branding effect
        Future.delayed(widget.delay, () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/login');
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _authCheckTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (authState.isAuthenticated) {
            Navigator.pushReplacementNamed(context, '/home');
          } else {
            Navigator.pushReplacementNamed(context, '/login');
          }
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 64),
              // Logo at the top
              AppPulseAnimation(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.15),
                  ),
                  padding: const EdgeInsets.all(32),
                  child: Image.asset(
                    'assets/icons/icon.png',
                    width: 80,
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Large tagline
              Text(
                'Controlling Your Life',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Animated CHECKLISTS (custom scale from 0.1x to 2.0x)
              _ChecklistsScaleText(),
              const SizedBox(height: 32),
              // The rest of the splash content (centered vertically)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Subtitle
                        Text(
                          tr('welcome_subtitle'),
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),
                        if (authState.isLoading) ...[
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        Text(
                          'Auth Status: ${authState.status}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                        if (authState.user != null)
                          Text(
                            'User: ${authState.user!.uid}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        const SizedBox(height: 24),
                        if (authState.hasError) ...[
                          const SizedBox(height: 16),
                          Text(
                            authState.errorMessage ?? tr('error_unknown'),
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              ref
                                  .read(authNotifierProvider.notifier)
                                  .clearError();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.blue,
                            ),
                            child: Text(tr('retry')),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChecklistsScaleText extends StatefulWidget {
  @override
  State<_ChecklistsScaleText> createState() => _ChecklistsScaleTextState();
}

class _ChecklistsScaleTextState extends State<_ChecklistsScaleText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _scaleAnim = Tween<double>(
      begin: 0.1,
      end: 1.5,
      //).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutExpo));
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.bounceOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: Text(
            tr('checklists'),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2.0,
            ),
          ),
        );
      },
    );
  }
}
