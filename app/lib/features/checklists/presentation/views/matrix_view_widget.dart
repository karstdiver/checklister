import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:checklister/features/checklists/domain/checklist.dart';
import 'package:checklister/features/checklists/presentation/widgets/checklist_item_card.dart';
import 'package:checklister/features/checklists/presentation/widgets/add_item_card.dart';
import '../../../../core/services/translation_service.dart';
import '../../../items/presentation/item_edit_screen.dart';
import '../../domain/checklist_providers.dart';

class MatrixViewWidget extends ConsumerStatefulWidget {
  final Checklist checklist;
  final Function(ChecklistItem) onItemTap;
  final Function(ChecklistItem) onItemEdit;
  final Function(ChecklistItem) onItemDelete;
  final Function(ChecklistItem, int) onItemMove;
  final Function(ChecklistItem)? onItemAdd;
  final Function(ChecklistItem, String)? onTextUpdate;
  final Function(String)? onQuickAdd;
  final Function()? onQuickTemplate;

  const MatrixViewWidget({
    super.key,
    required this.checklist,
    required this.onItemTap,
    required this.onItemEdit,
    required this.onItemDelete,
    required this.onItemMove,
    this.onItemAdd,
    this.onTextUpdate,
    this.onQuickAdd,
    this.onQuickTemplate,
  });

  @override
  ConsumerState<MatrixViewWidget> createState() => _MatrixViewWidgetState();
}

class _MatrixViewWidgetState extends ConsumerState<MatrixViewWidget> {
  @override
  Widget build(BuildContext context) {
    final items = widget.checklist.items;

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.grid_view, size: 64, color: Colors.grey),
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

    // Calculate grid layout based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = _calculateCrossAxisCount(screenWidth);
    final childAspectRatio = _calculateChildAspectRatio(screenWidth);

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length + (widget.onItemAdd != null ? 1 : 0),
      itemBuilder: (context, index) {
        // Check if this is the "add item" card
        if (widget.onItemAdd != null && index == items.length) {
          return AddItemCard(
            onTap: () => _handleAddItem(),
            onQuickAdd: widget.onQuickAdd,
            onQuickTemplate: widget.onQuickTemplate,
          );
        }

        final item = items[index];

        return ChecklistItemCard(
          item: item,
          onTap: () => widget.onItemTap(item),
          onEdit: () => _handleEditItem(item),
          onDelete: () => widget.onItemDelete(item),
          onTextUpdate: widget.onTextUpdate != null
              ? (newText) => widget.onTextUpdate!(item, newText)
              : null,
        );
      },
    );
  }

  int _calculateCrossAxisCount(double screenWidth) {
    if (screenWidth < 600) {
      return 2; // Mobile: 2 columns
    } else if (screenWidth < 900) {
      return 3; // Tablet: 3 columns
    } else {
      return 4; // Desktop: 4 columns
    }
  }

  double _calculateChildAspectRatio(double screenWidth) {
    if (screenWidth < 600) {
      return 1.2; // Mobile: slightly wider than tall
    } else if (screenWidth < 900) {
      return 1.0; // Tablet: square
    } else {
      return 0.9; // Desktop: slightly taller than wide
    }
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

            // The navigation will pop back to the matrix view automatically
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

            // The navigation will pop back to the matrix view automatically
          },
        ),
      ),
    );
  }
}
