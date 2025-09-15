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
  int _currentChecklistIndex = 0;
  final PageController _pageController = PageController();
  List<Checklist> _localChecklists = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    logger.i('⌚ ChecklistWatchScreen initialized');

    try {
      // For Phase 2 testing, we'll work with local data only
      // This avoids all Firestore permission issues
      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null) {
        logger.i('⌚ User authenticated: ${currentUser.uid}');

        // Create sample data directly in local storage
        final repository = ref.read(checklistRepositoryProvider);
        await repository.createSampleChecklists(currentUser.uid);

        // Load checklists from local storage only
        final localChecklists = await repository.loadChecklistsFromLocal(
          userId: currentUser.uid,
        );

        // Update the state directly with local data
        if (mounted) {
          setState(() {
            _localChecklists = localChecklists;
            _isInitialized = true;
          });
        }

        logger.i(
          '⌚ Sample data created and loaded successfully from local storage',
        );
      } else {
        logger.w('⌚ No authenticated user found');
        // For testing, create anonymous sample data
        await _createAnonymousSampleData();
      }
    } catch (e) {
      logger.e('⌚ Error initializing data: $e');
      // Fallback to anonymous sample data
      await _createAnonymousSampleData();
    }
  }

  Future<void> _createAnonymousSampleData() async {
    try {
      final repository = ref.read(checklistRepositoryProvider);
      await repository.createSampleChecklists('anonymous_test_user');

      final localChecklists = await repository.loadChecklistsFromLocal(
        userId: 'anonymous_test_user',
      );

      if (mounted) {
        setState(() {
          _localChecklists = localChecklists;
          _isInitialized = true;
        });
      }

      logger.i('⌚ Anonymous sample data created successfully');
    } catch (e) {
      logger.e('⌚ Error creating anonymous sample data: $e');
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
      body: SafeArea(child: _buildHybridUI(_localChecklists)),
    );
  }

  Widget _buildHybridUI(List<Checklist> checklists) {
    if (checklists.isEmpty) {
      return _buildEmptyState();
    }

    // Show only the first 3 checklists for the hybrid approach
    final displayChecklists = checklists.take(3).toList();
    final hasMoreChecklists = checklists.length > 3;

    return Column(
      children: [
        // Header with checklist title and progress
        Container(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Checklist title
              Text(
                displayChecklists[_currentChecklistIndex].title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Progress indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${displayChecklists[_currentChecklistIndex].completedItems} / ${displayChecklists[_currentChecklistIndex].totalItems}',
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                  if (hasMoreChecklists) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.more_horiz, color: Colors.grey, size: 12),
                  ],
                ],
              ),

              // Page indicator dots with navigation hints
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Left arrow indicator (if not on first page)
                  if (_currentChecklistIndex > 0)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: const Icon(
                        Icons.chevron_left,
                        color: Colors.grey,
                        size: 12,
                      ),
                    ),

                  // Page dots
                  ...List.generate(
                    displayChecklists.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index == _currentChecklistIndex
                            ? Colors.white
                            : Colors.grey.withOpacity(0.3),
                      ),
                    ),
                  ),

                  // Right arrow indicator (if not on last page)
                  if (_currentChecklistIndex < displayChecklists.length - 1)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      child: const Icon(
                        Icons.chevron_right,
                        color: Colors.grey,
                        size: 12,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        // Swipeable checklist content with improved gesture handling
        Expanded(
          child: RawGestureDetector(
            gestures: <Type, GestureRecognizerFactory>{
              HorizontalDragGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<
                    HorizontalDragGestureRecognizer
                  >(() => HorizontalDragGestureRecognizer(), (
                    HorizontalDragGestureRecognizer instance,
                  ) {
                    instance
                      ..onStart = (details) {
                        logger.d(
                          '⌚ Raw horizontal drag started: ${details.globalPosition}',
                        );
                      }
                      ..onUpdate = (details) {
                        logger.d(
                          '⌚ Raw horizontal drag update: ${details.delta.dx}',
                        );
                      }
                      ..onEnd = (details) {
                        logger.d(
                          '⌚ Raw horizontal drag ended: velocity=${details.primaryVelocity}',
                        );

                        if (details.primaryVelocity != null) {
                          if (details.primaryVelocity! > 150 &&
                              _currentChecklistIndex > 0) {
                            // Swipe right - go to previous checklist
                            logger.i('⌚ Raw swipe right to previous checklist');
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } else if (details.primaryVelocity! < -150 &&
                              _currentChecklistIndex <
                                  displayChecklists.length - 1) {
                            // Swipe left - go to next checklist
                            logger.i('⌚ Raw swipe left to next checklist');
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        }
                      };
                  }),
            },
            child: PageView.builder(
              controller: _pageController,
              physics:
                  const NeverScrollableScrollPhysics(), // Disable PageView's own scrolling
              onPageChanged: (index) {
                setState(() {
                  _currentChecklistIndex = index;
                });
              },
              itemCount: displayChecklists.length,
              itemBuilder: (context, index) {
                final checklist = displayChecklists[index];
                return _buildChecklistItems(checklist);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChecklistItems(Checklist checklist) {
    return ListView.builder(
      itemCount: checklist.items.length,
      itemBuilder: (context, index) {
        final item = checklist.items[index];
        return GestureDetector(
          onTap: () => _toggleItemStatus(checklist, item),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: item.status == ItemStatus.completed
                  ? Colors.green.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
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
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.text,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
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
          ),
        );
      },
    );
  }

  void _toggleItemStatus(Checklist checklist, ChecklistItem item) {
    try {
      // For Phase 2 testing, we'll update the item locally only
      // This completely avoids Firestore permission issues

      // Find the checklist and item in our local data
      final checklistIndex = _localChecklists.indexWhere(
        (c) => c.id == checklist.id,
      );
      if (checklistIndex == -1) {
        logger.w('⌚ Checklist not found in local data');
        return;
      }

      final itemIndex = _localChecklists[checklistIndex].items.indexWhere(
        (i) => i.id == item.id,
      );
      if (itemIndex == -1) {
        logger.w('⌚ Item not found in local data');
        return;
      }

      // Toggle the item status locally
      final updatedItem = _localChecklists[checklistIndex].items[itemIndex]
          .copyWith(
            status: item.status == ItemStatus.completed
                ? ItemStatus.pending
                : ItemStatus.completed,
          );

      // Update the local data
      final updatedItems = List<ChecklistItem>.from(
        _localChecklists[checklistIndex].items,
      );
      updatedItems[itemIndex] = updatedItem;

      final updatedChecklist = _localChecklists[checklistIndex].copyWith(
        items: updatedItems,
        completedItems: updatedItems
            .where((i) => i.status == ItemStatus.completed)
            .length,
      );

      // Update the local state
      setState(() {
        _localChecklists[checklistIndex] = updatedChecklist;
      });

      logger.i(
        '⌚ Toggled item status locally: ${item.text} -> ${updatedItem.status.name}',
      );
    } catch (e) {
      logger.e('⌚ Error toggling item status: $e');
      // Don't crash the app, just log the error
    }
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
