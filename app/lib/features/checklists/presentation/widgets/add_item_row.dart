import 'package:flutter/material.dart';
import '../../../../core/services/translation_service.dart';

class AddItemRow extends StatefulWidget {
  final VoidCallback onTap;
  final Function(String)? onQuickAdd;

  const AddItemRow({super.key, required this.onTap, this.onQuickAdd});

  @override
  State<AddItemRow> createState() => _AddItemRowState();
}

class _AddItemRowState extends State<AddItemRow> {
  void _showQuickAddSelector() {
    if (widget.onQuickAdd == null) return;

    final quickAddOptions = [
      'Take a photo',
      'Make a call',
      'Send an email',
      'Set a reminder',
      'Buy groceries',
      'Exercise',
      'Read',
      'Write notes',
      'Clean up',
      'Plan meeting',
    ];

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flash_on, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  TranslationService.translate('quick_add'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: quickAddOptions.length,
                itemBuilder: (context, index) {
                  final option = quickAddOptions[index];
                  return InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                      widget.onQuickAdd?.call(option);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          option,
                          style: const TextStyle(fontSize: 14),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onQuickAdd != null ? _showQuickAddSelector : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Placeholder for checkbox area (empty space to align with other items)
              const SizedBox(
                width: 24, // Same width as checkbox
                height: 24,
              ),
              const SizedBox(width: 12),

              // Add item content
              Expanded(
                child: Row(
                  children: [
                    // Add item text
                    Expanded(
                      child: Text(
                        TranslationService.translate('add_item'),
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    // Add icon
                    Icon(
                      Icons.add_circle_outline,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                  ],
                ),
              ),

              // Empty space to align with hamburger menu
              const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }
}
