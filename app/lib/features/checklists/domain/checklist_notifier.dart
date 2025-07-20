import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/checklist_repository.dart';
import 'checklist.dart';
import '../../../core/services/analytics_service.dart';
import '../../achievements/domain/achievement_notifier.dart';

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
  Future<void> loadUserChecklists(String userId) async {
    try {
      state = const AsyncValue.loading();
      final checklists = await _repository.getUserChecklists(userId);
      state = AsyncValue.data(checklists);
    } catch (error, stackTrace) {
      print('❌ Error loading checklists: $error');
      print(stackTrace);
      state = AsyncValue.error(error, stackTrace);
    }
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
    state = const AsyncValue.data([]);
  }
}
