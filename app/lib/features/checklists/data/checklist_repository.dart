import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/checklist.dart';
import '../../../core/services/translation_service.dart';

class ChecklistRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new checklist
  Future<Checklist> createChecklist(Checklist checklist) async {
    try {
      final docRef = await _firestore
          .collection('checklists')
          .add(checklist.toFirestore());

      // Return the checklist with the generated ID
      return checklist.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Failed to create checklist: $e');
    }
  }

  // Get a checklist by ID
  Future<Checklist?> getChecklist(String checklistId) async {
    try {
      final doc = await _firestore
          .collection('checklists')
          .doc(checklistId)
          .get();

      if (doc.exists) {
        return Checklist.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get checklist: $e');
    }
  }

  // Get all checklists for a user
  Future<List<Checklist>> getUserChecklists(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('checklists')
          .where('userId', isEqualTo: userId)
          .orderBy('updatedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Checklist.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user checklists: $e');
    }
  }

  // Get public checklists (for sharing/templates)
  Future<List<Checklist>> getPublicChecklists() async {
    try {
      final querySnapshot = await _firestore
          .collection('checklists')
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(50) // Limit to prevent performance issues
          .get();

      return querySnapshot.docs
          .map((doc) => Checklist.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get public checklists: $e');
    }
  }

  // Update a checklist
  Future<void> updateChecklist(Checklist checklist) async {
    try {
      final updatedData = checklist
          .copyWith(updatedAt: DateTime.now())
          .toFirestore();

      await _firestore
          .collection('checklists')
          .doc(checklist.id)
          .update(updatedData);
    } catch (e) {
      throw Exception('Failed to update checklist: $e');
    }
  }

  // Delete a checklist
  Future<void> deleteChecklist(String checklistId) async {
    try {
      await _firestore.collection('checklists').doc(checklistId).delete();
    } catch (e) {
      throw Exception('Failed to delete checklist: $e');
    }
  }

  // Add an item to a checklist
  Future<void> addItem(String checklistId, ChecklistItem item) async {
    try {
      final checklist = await getChecklist(checklistId);
      if (checklist == null) {
        throw Exception('Checklist not found');
      }

      final newItem = item.copyWith(
        id: 'item_${DateTime.now().millisecondsSinceEpoch}',
        order: checklist.items.length,
      );

      final updatedItems = [...checklist.items, newItem];
      final updatedChecklist = checklist.copyWith(
        items: updatedItems,
        totalItems: updatedItems.length,
        updatedAt: DateTime.now(),
      );

      await updateChecklist(updatedChecklist);
    } catch (e) {
      throw Exception('Failed to add item: $e');
    }
  }

  // Update an item in a checklist
  Future<void> updateItem(String checklistId, ChecklistItem item) async {
    try {
      final checklist = await getChecklist(checklistId);
      if (checklist == null) {
        throw Exception('Checklist not found');
      }

      final updatedItems = checklist.items.map((existingItem) {
        if (existingItem.id == item.id) {
          return item;
        }
        return existingItem;
      }).toList();

      final updatedChecklist = checklist.copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );

      await updateChecklist(updatedChecklist);
    } catch (e) {
      throw Exception('Failed to update item: $e');
    }
  }

  // Remove an item from a checklist
  Future<void> removeItem(String checklistId, String itemId) async {
    try {
      final checklist = await getChecklist(checklistId);
      if (checklist == null) {
        throw Exception('Checklist not found');
      }

      final updatedItems = checklist.items
          .where((item) => item.id != itemId)
          .toList();

      // Reorder remaining items
      for (int i = 0; i < updatedItems.length; i++) {
        updatedItems[i] = updatedItems[i].copyWith(order: i);
      }

      final updatedChecklist = checklist.copyWith(
        items: updatedItems,
        totalItems: updatedItems.length,
        updatedAt: DateTime.now(),
      );

      await updateChecklist(updatedChecklist);
    } catch (e) {
      throw Exception('Failed to remove item: $e');
    }
  }

  // Reorder items in a checklist
  Future<void> reorderItems(String checklistId, List<String> itemIds) async {
    try {
      final checklist = await getChecklist(checklistId);
      if (checklist == null) {
        throw Exception('Checklist not found');
      }

      final updatedItems = <ChecklistItem>[];
      for (int i = 0; i < itemIds.length; i++) {
        final item = checklist.items.firstWhere(
          (item) => item.id == itemIds[i],
        );
        updatedItems.add(item.copyWith(order: i));
      }

      final updatedChecklist = checklist.copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );

      await updateChecklist(updatedChecklist);
    } catch (e) {
      throw Exception('Failed to reorder items: $e');
    }
  }

  // Mark checklist as used (update lastUsedAt)
  Future<void> markChecklistAsUsed(String checklistId) async {
    try {
      await _firestore.collection('checklists').doc(checklistId).update({
        'lastUsedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to mark checklist as used: $e');
    }
  }

  // Search checklists by title or tags
  Future<List<Checklist>> searchChecklists(String userId, String query) async {
    try {
      // Get user's checklists
      final userChecklists = await getUserChecklists(userId);

      // Filter by title or tags
      return userChecklists.where((checklist) {
        final titleMatch = checklist.title.toLowerCase().contains(
          query.toLowerCase(),
        );
        final tagMatch = checklist.tags.any(
          (tag) => tag.toLowerCase().contains(query.toLowerCase()),
        );
        return titleMatch || tagMatch;
      }).toList();
    } catch (e) {
      throw Exception('Failed to search checklists: $e');
    }
  }

  // Duplicate a checklist
  Future<Checklist> duplicateChecklist(
    String checklistId,
    String newUserId,
  ) async {
    try {
      final originalChecklist = await getChecklist(checklistId);
      if (originalChecklist == null) {
        throw Exception('Checklist not found');
      }

      final duplicatedChecklist = Checklist.create(
        title:
            '${originalChecklist.title}${TranslationService.translate('checklist_copy_suffix')}',
        description: originalChecklist.description,
        userId: newUserId,
        items: originalChecklist.items
            .map(
              (item) => item.copyWith(
                id: 'item_${DateTime.now().millisecondsSinceEpoch}_${item.order}',
                status: ItemStatus.pending,
                completedAt: null,
                skippedAt: null,
              ),
            )
            .toList(),
        coverImageUrl: originalChecklist.coverImageUrl,
        isPublic: false, // Duplicates are private by default
        tags: originalChecklist.tags,
      );

      return await createChecklist(duplicatedChecklist);
    } catch (e) {
      throw Exception('Failed to duplicate checklist: $e');
    }
  }
}
