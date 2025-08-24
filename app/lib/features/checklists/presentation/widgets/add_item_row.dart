import 'package:flutter/material.dart';
import '../../../../core/services/translation_service.dart';
import '../../../../core/services/validation_service.dart';

class AddItemRow extends StatefulWidget {
  final VoidCallback onTap;
  final Function(String)? onQuickAdd;
  final Function()? onQuickTemplate;

  const AddItemRow({
    super.key,
    required this.onTap,
    this.onQuickAdd,
    this.onQuickTemplate,
  });

  @override
  State<AddItemRow> createState() => _AddItemRowState();
}

class _AddItemRowState extends State<AddItemRow> {
  // Validation state for quick add
  String? _quickAddError;
  
  void _showQuickOptionsSelector() {
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
                Icon(
                  Icons.add_circle_outline,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  TranslationService.translate('add_item'),
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
            Row(
              children: [
                // Quick Add Option
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                      _showQuickAddDialog();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.edit_note,
                            size: 32,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            TranslationService.translate('quick_add'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            TranslationService.translate(
                              'quick_add_description',
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Quick Template Option
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                      _showQuickTemplateSelector();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.format_list_bulleted,
                            size: 32,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            TranslationService.translate('quick_template'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            TranslationService.translate(
                              'quick_template_description',
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Validation methods for quick add
  void _validateQuickAdd(String value) {
    setState(() {
      _quickAddError = ValidationService.validateItemText(value);
    });
  }

  bool _isQuickAddValid() {
    return _quickAddError == null && 
           _quickAddTextController.text.trim().isNotEmpty;
  }

  // Controller for quick add text field
  late TextEditingController _quickAddTextController;

  void _showQuickAddDialog() {
    _quickAddTextController = TextEditingController();
    _quickAddError = null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(TranslationService.translate('quick_add')),
        content: TextField(
          controller: _quickAddTextController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: TranslationService.translate('enter_item_text'),
            border: const OutlineInputBorder(),
            errorText: _quickAddError,
            suffixText: '${_quickAddTextController.text.length}/200',
          ),
          onChanged: _validateQuickAdd,
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(TranslationService.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: _isQuickAddValid() ? () {
              final text = _quickAddTextController.text.trim();
              if (text.isNotEmpty) {
                Navigator.of(context).pop();
                widget.onQuickAdd?.call(text);
              }
            } : null,
            child: Text(TranslationService.translate('add')),
          ),
        ],
      ),
    );
  }

  void _showQuickTemplateSelector() {
    if (widget.onQuickTemplate == null) return;

    final quickTemplateOptions = [
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
                Icon(
                  Icons.format_list_bulleted,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  TranslationService.translate('quick_template'),
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
                itemCount: quickTemplateOptions.length,
                itemBuilder: (context, index) {
                  final option = quickTemplateOptions[index];
                  return InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                      // Validate template option before calling quick add
                      final validationError = ValidationService.validateItemText(option);
                      if (validationError != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(validationError),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
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
        onLongPress: _showQuickOptionsSelector,
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
