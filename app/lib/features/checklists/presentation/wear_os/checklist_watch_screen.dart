import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../domain/checklist.dart';
import '../../domain/checklist_providers.dart';
import '../../data/checklist_repository.dart';
import '../../../../core/providers/providers.dart';

final Logger logger = Logger();

class ChecklistWatchScreen extends ConsumerStatefulWidget {
  const ChecklistWatchScreen({super.key});

  @override
  ConsumerState<ChecklistWatchScreen> createState() =>
      _ChecklistWatchScreenState();
}

class _ChecklistWatchScreenState extends ConsumerState<ChecklistWatchScreen> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    logger.i('⌚ ChecklistWatchScreen initialized');

    try {
      // Get current user
      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null) {
        logger.i('⌚ User authenticated: ${currentUser.uid}');

        // Create sample data if needed
        final repository = ref.read(checklistRepositoryProvider);
        await repository.createSampleChecklists(currentUser.uid);

        // Load checklists
        final checklistNotifier = ref.read(checklistNotifierProvider.notifier);
        await checklistNotifier.loadUserChecklists(currentUser.uid);

        logger.i('⌚ Sample data created and loaded successfully');
      } else {
        logger.w('⌚ No authenticated user found');
      }
    } catch (e) {
      logger.e('⌚ Error initializing data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final checklistsAsync = ref.watch(checklistNotifierProvider);

    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(height: 16),
              Text(
                'Loading checklists...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: checklistsAsync.when(
          data: (checklists) => _buildChecklistContent(checklists),
          loading: () => _buildLoadingState(),
          error: (error, stack) => _buildErrorState(error),
        ),
      ),
    );
  }

  Widget _buildChecklistContent(List<Checklist> checklists) {
    if (checklists.isEmpty) {
      return _buildEmptyState();
    }

    // Show the first checklist for now
    final activeChecklist = checklists.first;

    return Column(
      children: [
        // Header with checklist title
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                activeChecklist.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Progress indicator
              Text(
                '${activeChecklist.completedItems} / ${activeChecklist.totalItems}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),

        // Checklist items
        Expanded(
          child: ListView.builder(
            itemCount: activeChecklist.items.length,
            itemBuilder: (context, index) {
              final item = activeChecklist.items[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: item.status == ItemStatus.completed
                      ? Colors.green.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: item.status == ItemStatus.completed
                        ? Colors.green
                        : Colors.grey.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      item.status == ItemStatus.completed
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: item.status == ItemStatus.completed
                          ? Colors.green
                          : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.text,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          decoration: item.status == ItemStatus.completed
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: Colors.grey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          SizedBox(height: 16),
          Text('Loading checklists...', style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    logger.e('Error loading checklists: $error');
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            'Error loading checklists',
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: const TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.checklist, color: Colors.grey, size: 48),
          SizedBox(height: 16),
          Text('No checklists found', style: TextStyle(color: Colors.white)),
          SizedBox(height: 8),
          Text(
            'Sample data should be created automatically',
            style: TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
