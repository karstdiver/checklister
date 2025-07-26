import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:checklister/features/checklists/domain/checklist.dart';
import 'package:checklister/features/checklists/presentation/widgets/checklist_item_row.dart';

class ListViewWidget extends ConsumerStatefulWidget {
  final Checklist checklist;
  final Function(ChecklistItem) onItemTap;
  final Function(ChecklistItem) onItemEdit;
  final Function(ChecklistItem) onItemDelete;
  final Function(ChecklistItem, int) onItemMove;

  const ListViewWidget({
    super.key,
    required this.checklist,
    required this.onItemTap,
    required this.onItemEdit,
    required this.onItemDelete,
    required this.onItemMove,
  });

  @override
  ConsumerState<ListViewWidget> createState() => _ListViewWidgetState();
}

class _ListViewWidgetState extends ConsumerState<ListViewWidget> {
  @override
  Widget build(BuildContext context) {
    final items = widget.checklist.items;

    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.checklist_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No items in this checklist',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Add some items to get started',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isFirst = index == 0;
        final isLast = index == items.length - 1;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ChecklistItemRow(
            item: item,
            onTap: () => widget.onItemTap(item),
            onEdit: () => widget.onItemEdit(item),
            onDelete: () => widget.onItemDelete(item),
            onMoveUp: isFirst ? null : () => widget.onItemMove(item, -1),
            onMoveDown: isLast ? null : () => widget.onItemMove(item, 1),
          ),
        );
      },
    );
  }
}
