import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import '../../domain/checklist.dart';

final Logger logger = Logger();

class ChecklistItemCard extends StatelessWidget {
  final ChecklistItem item;
  final VoidCallback onTap;

  const ChecklistItemCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: item.status == ItemStatus.completed ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: item.status == ItemStatus.completed ? Colors.green : Colors.grey.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Checkbox icon
                Icon(
                  item.status == ItemStatus.completed ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: item.status == ItemStatus.completed ? Colors.green : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 12),
                
                // Item text
                Expanded(
                  child: Text(
                    item.text,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      decoration: item.status == ItemStatus.completed ? TextDecoration.lineThrough : null,
                      decorationColor: Colors.grey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                // Status indicator
                if (item.status == ItemStatus.completed)
                  const Icon(
                    Icons.done,
                    color: Colors.green,
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
