import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:checklister/features/checklists/domain/checklist.dart';

void main() {
  group('Checklist Domain Tests', () {
    test(
      'Checklist.create should create a new checklist with default values',
      () {
        final checklist = Checklist.create(
          title: 'Test Checklist',
          description: 'Test Description',
          userId: 'test_user_id',
          items: [],
          tags: ['test', 'sample'],
        );

        expect(checklist.title, 'Test Checklist');
        expect(checklist.description, 'Test Description');
        expect(checklist.userId, 'test_user_id');
        expect(checklist.items, isEmpty);
        expect(checklist.tags, ['test', 'sample']);
        expect(checklist.isPublic, false);
        expect(checklist.totalItems, 0);
        expect(checklist.completedItems, 0);
        expect(checklist.id, isEmpty); // Will be set by Firestore
      },
    );

    test(
      'ChecklistItem.create should create a new item with default values',
      () {
        final item = ChecklistItem.create(
          text: 'Test Item',
          notes: 'Test Notes',
          order: 1,
        );

        expect(item.text, 'Test Item');
        expect(item.notes, 'Test Notes');
        expect(item.order, 1);
        expect(item.status, ItemStatus.pending);
        expect(item.id, isEmpty); // Will be set by Firestore
      },
    );

    test('Checklist completion percentage should be calculated correctly', () {
      final items = [
        ChecklistItem.create(text: 'Item 1', order: 0),
        ChecklistItem.create(text: 'Item 2', order: 1),
        ChecklistItem.create(text: 'Item 3', order: 2),
      ];

      final checklist = Checklist.create(
        title: 'Test Checklist',
        userId: 'test_user_id',
        items: items,
      );

      expect(checklist.completionPercentage, 0.0);

      // Mark first item as completed
      final updatedItems = [
        items[0].copyWith(status: ItemStatus.completed),
        items[1],
        items[2],
      ];

      final updatedChecklist = checklist.copyWith(
        items: updatedItems,
        completedItems: 1,
      );

      expect(updatedChecklist.completionPercentage, 1.0 / 3.0);
    });

    test('Checklist should be complete when all items are completed', () {
      final items = [
        ChecklistItem.create(text: 'Item 1', order: 0),
        ChecklistItem.create(text: 'Item 2', order: 1),
      ];

      final checklist = Checklist.create(
        title: 'Test Checklist',
        userId: 'test_user_id',
        items: items,
      );

      expect(checklist.isComplete, false);

      final completedItems = [
        items[0].copyWith(status: ItemStatus.completed),
        items[1].copyWith(status: ItemStatus.completed),
      ];

      final completedChecklist = checklist.copyWith(
        items: completedItems,
        completedItems: 2,
      );

      expect(completedChecklist.isComplete, true);
    });

    test('Checklist should be empty when no items', () {
      final checklist = Checklist.create(
        title: 'Test Checklist',
        userId: 'test_user_id',
        items: [],
      );

      expect(checklist.isEmpty, true);
      expect(checklist.totalItems, 0);
    });

    test(
      'Checklist copyWith should create a new instance with updated values',
      () {
        final original = Checklist.create(
          title: 'Original Title',
          userId: 'test_user_id',
          items: [],
        );

        final updated = original.copyWith(
          title: 'Updated Title',
          description: 'Updated Description',
          isPublic: true,
        );

        expect(updated.title, 'Updated Title');
        expect(updated.description, 'Updated Description');
        expect(updated.isPublic, true);
        expect(updated.userId, original.userId); // Should remain unchanged
        expect(updated.items, original.items); // Should remain unchanged
      },
    );

    test(
      'ChecklistItem copyWith should create a new instance with updated values',
      () {
        final original = ChecklistItem.create(text: 'Original Text', order: 0);

        final updated = original.copyWith(
          text: 'Updated Text',
          status: ItemStatus.completed,
          notes: 'Updated Notes',
        );

        expect(updated.text, 'Updated Text');
        expect(updated.status, ItemStatus.completed);
        expect(updated.notes, 'Updated Notes');
        expect(updated.order, original.order); // Should remain unchanged
      },
    );
  });
}
