import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/checklist_repository.dart';
import 'checklist.dart';
import '../../../core/services/analytics_service.dart';
import '../../achievements/domain/achievement_notifier.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ChecklistNotifier extends StateNotifier<AsyncValue<List<Checklist>>> {
  final ChecklistRepository _repository;
  final AnalyticsService _analytics;
  final AchievementNotifier? _achievementNotifier;

  ChecklistNotifier(
    this._repository, {
    AchievementNotifier? achievementNotifier,
  }) : _analytics = AnalyticsService(),
       _achievementNotifier = achievementNotifier,
       super(const AsyncValue.loading());

  // Load user's checklists
  Future<void> loadUserChecklists(
    String userId, {
    ConnectivityResult? connectivity,
  }) async {
    print(
      '[DEBUG] ChecklistNotifier: loadUserChecklists called for userId=$userId, connectivity=$connectivity',
    );
    print(
      '[DEBUG] ChecklistNotifier: Current state before loading: ${state.toString()}',
    );
    print('[DEBUG] ChecklistNotifier: Starting loadUserChecklists...');
    try {
      state = const AsyncValue.loading();

      final conn = connectivity;
      print('[DEBUG] ChecklistNotifier: Connectivity value = $conn');

      // Simplified approach: always try local first, then online if available
      try {
        // Always try to load from local first
        final checklists = await _repository.loadChecklistsFromLocal(
          userId: userId,
        );
        print(
          '[DEBUG] ChecklistNotifier: loaded ${checklists.length} checklists from Hive for userId=$userId',
        );

        // If local storage is empty and we're online, try Firestore
        if (checklists.isEmpty && conn != ConnectivityResult.none) {
          print(
            '[DEBUG] ChecklistNotifier: Local storage empty, trying Firestore...',
          );
          try {
            final firestoreChecklists = await _repository.getUserChecklists(
              userId,
            );
            print(
              '[DEBUG] ChecklistNotifier: loaded ${firestoreChecklists.length} checklists from Firestore for userId=$userId',
            );
            state = AsyncValue.data(firestoreChecklists);
            print('[DEBUG] ChecklistNotifier: set state to data (Firestore)');
            await _repository.saveChecklistsToLocal(
              firestoreChecklists,
              userId: userId,
            );
            print(
              '[DEBUG] ChecklistNotifier: saved checklists to Hive for userId=$userId',
            );
          } catch (firestoreError) {
            print(
              '[DEBUG] ChecklistNotifier: Firestore load failed: $firestoreError',
            );
            // If Firestore fails, use empty local data
            state = AsyncValue.data(checklists);
            print(
              '[DEBUG] ChecklistNotifier: set state to data (Hive - empty)',
            );
          }
        } else {
          // Local storage has data or we're offline, use local data
          state = AsyncValue.data(checklists);
          print('[DEBUG] ChecklistNotifier: set state to data (Hive)');
        }
      } catch (e) {
        print('[DEBUG] ChecklistNotifier: Local load failed: $e');

        // If local fails and we're online, try Firestore
        if (conn != ConnectivityResult.none) {
          try {
            print('[DEBUG] ChecklistNotifier: Trying Firestore...');
            final checklists = await _repository.getUserChecklists(userId);
            print(
              '[DEBUG] ChecklistNotifier: loaded ${checklists.length} checklists from Firestore for userId=$userId',
            );
            state = AsyncValue.data(checklists);
            print('[DEBUG] ChecklistNotifier: set state to data (Firestore)');
            await _repository.saveChecklistsToLocal(checklists, userId: userId);
            print(
              '[DEBUG] ChecklistNotifier: saved checklists to Hive for userId=$userId',
            );
          } catch (firestoreError) {
            print(
              '[DEBUG] ChecklistNotifier: Firestore load failed: $firestoreError',
            );
            // If both fail, return empty list
            state = AsyncValue.data([]);
            print('[DEBUG] ChecklistNotifier: set state to empty data');
          }
        } else {
          // Offline and local failed, return empty list
          print(
            '[DEBUG] ChecklistNotifier: Offline and local failed, returning empty list',
          );
          state = AsyncValue.data([]);
        }
      }
    } catch (error, stackTrace) {
      print('[DEBUG] ChecklistNotifier: error=$error');
      print(stackTrace);
      // Instead of setting error state, set empty data to prevent spinning
      print('[DEBUG] ChecklistNotifier: Setting empty data due to error');
      state = AsyncValue.data([]);
    }
    print('[DEBUG] ChecklistNotifier: loadUserChecklists completed');
  }

  // Create a new checklist
  Future<Checklist?> createChecklist({
    required String title,
    String? description,
    required String userId,
    List<ChecklistItem> items = const [],
    String? coverImageUrl,
    bool isPublic = false,
    List<String> tags = const [],
  }) async {
    try {
      final checklist = Checklist.create(
        title: title,
        description: description,
        userId: userId,
        items: items,
        coverImageUrl: coverImageUrl,
        isPublic: isPublic,
        tags: tags,
      );

      final createdChecklist = await _repository.createChecklist(checklist);

      // Update state
      state.whenData((checklists) {
        state = AsyncValue.data([createdChecklist, ...checklists]);
      });

      // Log analytics
      await _analytics.logChecklistCreated(checklistId: createdChecklist.id);

      // Check achievements for checklist creation
      if (_achievementNotifier != null) {
        try {
          await _achievementNotifier!.checkChecklistCreationAchievements();
          print(
            '🎯 Achievement checking completed for checklist creation: ${createdChecklist.id}',
          );
        } catch (e) {
          print('Error checking achievements for checklist creation: $e');
          // Don't let achievement errors break checklist creation
        }
      } else {
        print('Achievement notifier is null, skipping achievement checking');
      }

      return createdChecklist;
    } catch (error, stackTrace) {
      print('❌ Error creating checklist: $error');
      print(stackTrace);
      state = AsyncValue.error(error, stackTrace);
      return null;
    }
  }

  // Update a checklist
  Future<bool> updateChecklist(Checklist checklist) async {
    try {
      print(
        '[DEBUG] updateChecklist CALLED: id=${checklist.id}, completedItems=${checklist.completedItems}, totalItems=${checklist.totalItems}, isComplete=${checklist.isComplete}',
      );
      await _repository.updateChecklist(checklist);

      // Update state
      state.whenData((checklists) {
        final updatedChecklists = checklists.map((c) {
          if (c.id == checklist.id) {
            return checklist;
          }
          return c;
        }).toList();
        state = AsyncValue.data(updatedChecklists);
        print('[DEBUG] All checklists after update:');
        for (final c in updatedChecklists) {
          print(
            '  id=${c.id}, completedItems=${c.completedItems}, totalItems=${c.totalItems}, isComplete=${c.isComplete}',
          );
        }
      });

      return true;
    } catch (error, stackTrace) {
      print('❌ Error updating checklist: $error');
      print(stackTrace);
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  // Delete a checklist
  Future<bool> deleteChecklist(String checklistId) async {
    try {
      await _repository.deleteChecklist(checklistId);

      // Update state
      state.whenData((checklists) {
        final updatedChecklists = checklists
            .where((c) => c.id != checklistId)
            .toList();
        state = AsyncValue.data(updatedChecklists);
      });

      return true;
    } catch (error, stackTrace) {
      print('❌ Error deleting checklist: $error');
      print(stackTrace);
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  // Add an item to a checklist
  Future<bool> addItem(String checklistId, ChecklistItem item) async {
    try {
      await _repository.addItem(checklistId, item);

      // Refresh the specific checklist
      await _refreshChecklist(checklistId);

      return true;
    } catch (error, stackTrace) {
      print('❌ Error adding item: $error');
      print(stackTrace);
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  // Update an item in a checklist
  Future<bool> updateItem(String checklistId, ChecklistItem item) async {
    try {
      await _repository.updateItem(checklistId, item);

      // Refresh the specific checklist
      await _refreshChecklist(checklistId);

      return true;
    } catch (error, stackTrace) {
      print('❌ Error updating item: $error');
      print(stackTrace);
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  // Remove an item from a checklist
  Future<bool> removeItem(String checklistId, String itemId) async {
    try {
      await _repository.removeItem(checklistId, itemId);

      // Refresh the specific checklist
      await _refreshChecklist(checklistId);

      return true;
    } catch (error, stackTrace) {
      print('❌ Error removing item: $error');
      print(stackTrace);
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  // Reorder items in a checklist
  Future<bool> reorderItems(String checklistId, List<String> itemIds) async {
    try {
      await _repository.reorderItems(checklistId, itemIds);

      // Refresh the specific checklist
      await _refreshChecklist(checklistId);

      return true;
    } catch (error, stackTrace) {
      print('❌ Error reordering items: $error');
      print(stackTrace);
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  // Duplicate a checklist
  Future<Checklist?> duplicateChecklist(
    String checklistId,
    String newUserId,
  ) async {
    try {
      final duplicatedChecklist = await _repository.duplicateChecklist(
        checklistId,
        newUserId,
      );

      // Update state
      state.whenData((checklists) {
        state = AsyncValue.data([duplicatedChecklist, ...checklists]);
      });

      return duplicatedChecklist;
    } catch (error, stackTrace) {
      print('❌ Error duplicating checklist: $error');
      print(stackTrace);
      state = AsyncValue.error(error, stackTrace);
      return null;
    }
  }

  // Search checklists
  Future<List<Checklist>> searchChecklists(String userId, String query) async {
    try {
      return await _repository.searchChecklists(userId, query);
    } catch (error) {
      print('❌ Error searching checklists: $error');
      rethrow;
    }
  }

  // Get a specific checklist by ID
  Checklist? getChecklistById(String checklistId) {
    return state.whenData((checklists) {
      try {
        return checklists.firstWhere((c) => c.id == checklistId);
      } catch (e) {
        return null;
      }
    }).value;
  }

  // Mark checklist as used
  Future<bool> markChecklistAsUsed(String checklistId) async {
    try {
      await _repository.markChecklistAsUsed(checklistId);

      // Update the checklist in state
      state.whenData((checklists) {
        final updatedChecklists = checklists.map((c) {
          if (c.id == checklistId) {
            return c.copyWith(lastUsedAt: DateTime.now());
          }
          return c;
        }).toList();
        state = AsyncValue.data(updatedChecklists);
      });

      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  // Refresh a specific checklist
  Future<void> _refreshChecklist(String checklistId) async {
    try {
      final updatedChecklist = await _repository.getChecklist(checklistId);
      if (updatedChecklist != null) {
        state.whenData((checklists) {
          final updatedChecklists = checklists.map((c) {
            if (c.id == checklistId) {
              return updatedChecklist;
            }
            return c;
          }).toList();
          state = AsyncValue.data(updatedChecklists);
        });
      }
    } catch (error) {
      // If refresh fails, we don't want to break the entire state
      print('Failed to refresh checklist $checklistId: $error');
    }
  }

  // Clear state
  void clear() {
    print('[DEBUG] ChecklistNotifier: clear() called');
    print('[DEBUG] ChecklistNotifier: Previous state: ${state.toString()}');
    state = const AsyncValue.loading();
    print('[DEBUG] ChecklistNotifier: New state: ${state.toString()}');
  }

  // Refresh checklists from Firestore (clears local cache first)
  Future<void> refreshFromFirestore(String userId) async {
    print(
      '[DEBUG] ChecklistNotifier: refreshFromFirestore called for userId=$userId',
    );

    // Clear local storage first to ensure fresh data
    await _repository.clearLocalChecklists(userId: userId);
    print('[DEBUG] ChecklistNotifier: Cleared local storage for refresh');

    // Then load with current connectivity
    await loadUserChecklists(userId);
  }
}
