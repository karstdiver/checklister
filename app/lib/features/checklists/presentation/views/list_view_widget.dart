import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:checklister/features/checklists/domain/checklist.dart';
import 'package:checklister/features/checklists/presentation/widgets/checklist_item_row.dart';
import 'package:checklister/features/checklists/presentation/widgets/add_item_row.dart';
import '../../../../core/services/translation_service.dart';
import '../../../items/presentation/item_edit_screen.dart';
import '../../domain/checklist_providers.dart';

class ListViewWidget extends ConsumerStatefulWidget {
  final Checklist checklist;
  final Function(ChecklistItem) onItemTap;
  final Function(ChecklistItem) onItemEdit;
  final Function(ChecklistItem) onItemDelete;
  final Function(ChecklistItem, int) onItemMove;
  final Function(ChecklistItem)? onItemAdd;
  final Function(ChecklistItem, String)? onTextUpdate;

  const ListViewWidget({
    super.key,
    required this.checklist,
    required this.onItemTap,
    required this.onItemEdit,
    required this.onItemDelete,
    required this.onItemMove,
    this.onItemAdd,
    this.onTextUpdate,
  });

  @override
  ConsumerState<ListViewWidget> createState() => _ListViewWidgetState();
}

class _ListViewWidgetState extends ConsumerState<ListViewWidget> {
  @override
  Widget build(BuildContext context) {
    final items = widget.checklist.items;

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.checklist_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              TranslationService.translate('no_items_in_checklist'),
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              TranslationService.translate('add_items_to_get_started'),
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount:
          items.length +
          (widget.onItemAdd != null ? 1 : 0), // Add 1 for the "add item" row
      itemBuilder: (context, index) {
        // Check if this is the "add item" row
        if (widget.onItemAdd != null && index == items.length) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AddItemRow(onTap: () => _handleAddItem()),
          );
        }

        final item = items[index];
        final isFirst = index == 0;
        final isLast = index == items.length - 1;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ChecklistItemRow(
            item: item,
            onTap: () => widget.onItemTap(item),
            onEdit: () => _handleEditItem(item),
            onDelete: () => widget.onItemDelete(item),
            onMoveUp: isFirst ? null : () => widget.onItemMove(item, -1),
            onMoveDown: isLast ? null : () => widget.onItemMove(item, 1),
            onTextUpdate: widget.onTextUpdate != null
                ? (newText) => widget.onTextUpdate!(item, newText)
                : null,
          ),
        );
      },
    );
  }

  void _handleEditItem(ChecklistItem item) {
    // Navigate to ItemEditScreen for editing
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ItemEditScreen(
          item: item,
          onSave: (updatedItem) async {
            // Update the item in the checklist using the notifier
            final checklistNotifier = ref.read(
              checklistNotifierProvider.notifier,
            );

            // Wait for the checklist update to complete
            final success = await checklistNotifier.updateItem(
              widget.checklist.id,
              updatedItem,
            );

            if (success) {
              // Call the onItemEdit callback to notify parent (session screen) to refresh
              widget.onItemEdit(updatedItem);
            }

            // The navigation will pop back to the list view automatically
          },
        ),
      ),
    );
  }

  void _handleAddItem() {
    // Navigate to ItemEditScreen for adding new item
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ItemEditScreen(
          onSave: (newItem) async {
            // Call the onItemAdd callback to notify parent (session screen) to add the item
            widget.onItemAdd?.call(newItem);

            // The navigation will pop back to the list view automatically
          },
        ),
      ),
    );
  }
}
