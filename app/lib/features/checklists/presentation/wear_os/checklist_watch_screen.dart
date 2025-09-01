import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../domain/checklist.dart';
import '../../domain/checklist_providers.dart';
import 'item_card.dart';
import 'progress_indicator.dart';

final Logger logger = Logger();

class ChecklistWatchScreen extends ConsumerStatefulWidget {
  const ChecklistWatchScreen({super.key});

  @override
  ConsumerState<ChecklistWatchScreen> createState() => _ChecklistWatchScreenState();
}

class _ChecklistWatchScreenState extends ConsumerState<ChecklistWatchScreen> {
  @override
  void initState() {
    super.initState();
    logger.i('⌚ ChecklistWatchScreen initialized');
  }

  @override
  Widget build(BuildContext context) {
    final checklistsAsync = ref.watch(checklistNotifierProvider);
    
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

    // For now, show the first checklist
    // TODO: Implement navigation between checklists
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
              ChecklistProgressIndicator(
                completedItems: activeChecklist.items.where((item) => item.status == ItemStatus.completed).length,
                totalItems: activeChecklist.items.length,
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
              return ChecklistItemCard(
                item: item,
                onTap: () => _toggleItem(item),
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
          Text(
            'Loading checklists...',
            style: TextStyle(color: Colors.white),
          ),
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
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48,
          ),
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
          Icon(
            Icons.checklist,
            color: Colors.grey,
            size: 48,
          ),
          SizedBox(height: 16),
          Text(
            'No checklists found',
            style: TextStyle(color: Colors.white),
          ),
          SizedBox(height: 8),
          Text(
            'Create a checklist on your phone first',
            style: TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _toggleItem(ChecklistItem item) {
    logger.i('⌚ Toggling item: ${item.text}');
    // TODO: Implement item toggle functionality
    // This will be implemented when we add the checklist notifier
  }
}
