import 'package:flutter/material.dart';
import 'package:checklister/features/checklists/domain/checklist.dart';

class ChecklistItemRow extends StatelessWidget {
  final ChecklistItem item;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  const ChecklistItemRow({
    super.key,
    required this.item,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.onMoveUp,
    this.onMoveDown,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = item.status == ItemStatus.completed;

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Checkbox
              Checkbox(
                value: isCompleted,
                onChanged: (value) => onTap(),
                activeColor: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 12),

              // Item text
              Expanded(
                child: Text(
                  item.text,
                  style: TextStyle(
                    fontSize: 16,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted ? Colors.grey[600] : null,
                  ),
                ),
              ),

              // Hamburger menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                      break;
                    case 'delete':
                      _showDeleteDialog(context);
                      break;
                    case 'move_up':
                      onMoveUp?.call();
                      break;
                    case 'move_down':
                      onMoveDown?.call();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  if (onMoveUp != null)
                    const PopupMenuItem(
                      value: 'move_up',
                      child: Row(
                        children: [
                          Icon(Icons.keyboard_arrow_up, size: 20),
                          SizedBox(width: 8),
                          Text('Move Up'),
                        ],
                      ),
                    ),
                  if (onMoveDown != null)
                    const PopupMenuItem(
                      value: 'move_down',
                      child: Row(
                        children: [
                          Icon(Icons.keyboard_arrow_down, size: 20),
                          SizedBox(width: 8),
                          Text('Move Down'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.text}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
