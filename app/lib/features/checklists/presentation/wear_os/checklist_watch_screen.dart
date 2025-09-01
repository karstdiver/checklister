import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

final Logger logger = Logger();

class ChecklistWatchScreen extends ConsumerWidget {
  const ChecklistWatchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    logger.i('⌚ ChecklistWatchScreen initialized');

    // For now, show a simple test screen without complex state management
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.checklist, color: Colors.white, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Checklister Watch',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Wear OS Companion App',
                style: TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const Text(
                '✅ Foundation Complete',
                style: TextStyle(color: Colors.green, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Ready for next phase',
                style: TextStyle(color: Colors.grey, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
