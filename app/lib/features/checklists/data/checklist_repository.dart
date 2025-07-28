import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/checklist.dart';
import '../../../core/services/translation_service.dart';
import '../../../core/constants/ttl_config.dart';
import '../../../core/domain/user_tier.dart';
import 'package:hive/hive.dart';

class ChecklistRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new checklist
  Future<Checklist> createChecklist(
    Checklist checklist, {
    UserTier? userTier,
  }) async {
    try {
      // Prepare checklist data
      final checklistData = checklist.toFirestore();

      // Add Firestore native TTL if user tier is provided and TTL should be enabled
      if (userTier != null && TTLConfig.shouldEnableNativeTTL(userTier)) {
        final ttl = TTLConfig.calculateFirestoreTTL(userTier);
        if (ttl != null) {
          checklistData['ttl'] = ttl;
          print('🕒 Set Firestore native TTL for checklist: ${ttl.toDate()}');
        }
      }

      final docRef = await _firestore
          .collection('checklists')
          .add(checklistData);

      // Return the checklist with the generated ID
      return checklist.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Failed to create checklist: $e');
    }
  }

  // Update checklist TTL based on user tier
  Future<void> updateChecklistTTL(String checklistId, UserTier userTier) async {
    try {
      if (TTLConfig.shouldEnableNativeTTL(userTier)) {
        final ttl = TTLConfig.calculateFirestoreTTL(userTier);
        if (ttl != null) {
          await _firestore.collection('checklists').doc(checklistId).update({
            'ttl': ttl,
          });
          print(
            '🕒 Updated Firestore native TTL for checklist $checklistId: ${ttl.toDate()}',
          );
        }
      } else {
        // Remove TTL for unlimited tiers
        await _firestore.collection('checklists').doc(checklistId).update({
          'ttl': FieldValue.delete(),
        });
        print(
          '🕒 Removed Firestore native TTL for checklist $checklistId (unlimited tier)',
        );
      }
    } catch (e) {
      print('❌ Error updating checklist TTL: $e');
      throw Exception('Failed to update checklist TTL: $e');
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
      print(
        '[DEBUG] ChecklistRepository: Starting getUserChecklists for userId=$userId',
      );
      print(
        '[DEBUG] ChecklistRepository: Executing Firestore query for userId=$userId',
      );
      final querySnapshot = await _firestore
          .collection('checklists')
          .where('userId', isEqualTo: userId)
          .orderBy('updatedAt', descending: true)
          .get();

      print(
        '[DEBUG] ChecklistRepository: Firestore query returned ${querySnapshot.docs.length} documents',
      );

      final checklists = <Checklist>[];
      for (final doc in querySnapshot.docs) {
        try {
          print('[DEBUG] ChecklistRepository: Processing document ${doc.id}');
          final checklist = Checklist.fromFirestore(doc);
          checklists.add(checklist);
          print(
            '[DEBUG] ChecklistRepository: Successfully parsed document ${doc.id}',
          );
        } catch (e) {
          print(
            '[DEBUG] ChecklistRepository: Error parsing document ${doc.id}: $e',
          );
          // Continue with other documents
        }
      }
      print(
        '[DEBUG] ChecklistRepository: Loaded ${checklists.length} checklists from Firestore for userId=$userId',
      );
      return checklists;
    } catch (e) {
      print('[DEBUG] ChecklistRepository: Error in getUserChecklists: $e');
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
  Future<void> updateChecklist(
    Checklist checklist, {
    UserTier? userTier,
  }) async {
    try {
      final updatedData = checklist
          .copyWith(updatedAt: DateTime.now())
          .toFirestore();

      // Update TTL if user tier is provided
      if (userTier != null && TTLConfig.shouldEnableNativeTTL(userTier)) {
        final ttl = TTLConfig.calculateFirestoreTTL(userTier);
        if (ttl != null) {
          updatedData['ttl'] = ttl;
        }
      }

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
    String newUserId, {
    UserTier? userTier,
  }) async {
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

      return await createChecklist(duplicatedChecklist, userTier: userTier);
    } catch (e) {
      throw Exception('Failed to duplicate checklist: $e');
    }
  }

  Future<void> saveChecklistsToLocal(
    List<Checklist> checklists, {
    String? userId,
  }) async {
    final box = await Hive.openBox('checklists');
    final key = userId ?? 'anonymous';
    print(
      '[DEBUG] ChecklistRepository: Saving ${checklists.length} checklists to Hive with key="$key"',
    );
    await box.put(key, checklists.map((c) => c.toJson()).toList());
    print(
      '[DEBUG] ChecklistRepository: Successfully saved checklists to Hive with key="$key"',
    );
  }

  Future<List<Checklist>> loadChecklistsFromLocal({String? userId}) async {
    try {
      print(
        '[DEBUG] ChecklistRepository: Starting loadChecklistsFromLocal for userId=$userId',
      );
      final box = await Hive.openBox('checklists');
      final key = userId ?? 'anonymous';
      print(
        '[DEBUG] ChecklistRepository: Loading checklists from Hive with key="$key"',
      );
      final list = box.get(key, defaultValue: []) as List<dynamic>;
      print('[DEBUG] ChecklistRepository: Raw data from Hive: $list');
      final checklists = list
          .map((json) => Checklist.fromJson(Map<String, dynamic>.from(json)))
          .toList();
      print(
        '[DEBUG] ChecklistRepository: Loaded ${checklists.length} checklists from Hive with key="$key"',
      );
      return checklists;
    } catch (e) {
      print(
        '[DEBUG] ChecklistRepository: Error in loadChecklistsFromLocal: $e',
      );
      rethrow;
    }
  }

  Future<void> clearLocalChecklists({String? userId}) async {
    final box = await Hive.openBox('checklists');
    final key = userId ?? 'anonymous';
    print(
      '[DEBUG] ChecklistRepository: Clearing checklists from Hive with key="$key"',
    );
    await box.delete(key);
    print(
      '[DEBUG] ChecklistRepository: Successfully cleared checklists from Hive with key="$key"',
    );
  }

  Future<void> clearAllLocalChecklists() async {
    final box = await Hive.openBox('checklists');
    print('[DEBUG] ChecklistRepository: Clearing ALL checklists from Hive');
    await box.clear();
    print(
      '[DEBUG] ChecklistRepository: Successfully cleared ALL checklists from Hive',
    );
  }
}
