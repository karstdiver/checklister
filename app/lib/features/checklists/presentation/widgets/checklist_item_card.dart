import 'package:flutter/material.dart';
import 'package:checklister/features/checklists/domain/checklist.dart';
import '../../../../core/services/translation_service.dart';

class ChecklistItemCard extends StatefulWidget {
  final ChecklistItem item;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(String)? onTextUpdate;

  const ChecklistItemCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.onTextUpdate,
  });

  @override
  State<ChecklistItemCard> createState() => _ChecklistItemCardState();
}

class _ChecklistItemCardState extends State<ChecklistItemCard> {
  late TextEditingController _textController;
  bool _isEditing = false;
  FocusNode? _focusNode;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.item.text);
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ChecklistItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.text != widget.item.text) {
      _textController.text = widget.item.text;
    }
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
    // Focus the text field after a short delay to ensure the widget is built
    Future.delayed(const Duration(milliseconds: 100), () {
      _focusNode?.requestFocus();
    });
  }

  void _saveEdit() {
    final newText = _textController.text.trim();
    if (newText.isNotEmpty && newText != widget.item.text) {
      widget.onTextUpdate?.call(newText);
    }
    setState(() {
      _isEditing = false;
    });
    _focusNode?.unfocus();
  }

  void _cancelEdit() {
    _textController.text = widget.item.text;
    setState(() {
      _isEditing = false;
    });
    _focusNode?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.item.status == ItemStatus.completed;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Card(
        elevation: isCompleted ? 1 : 2,
        margin: EdgeInsets.zero,
        color: isCompleted ? Colors.grey[50] : null,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            onLongPress: _showOptionsMenu,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Checkbox with animation
                  AnimatedScale(
                    scale: isCompleted ? 0.9 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: Checkbox(
                      value: isCompleted,
                      onChanged: (value) {
                        widget.onTap();
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Text content
                  Expanded(
                    child: _isEditing
                        ? TextField(
                            controller: _textController,
                            focusNode: _focusNode,
                            textAlign: TextAlign.center,
                            maxLines: null,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onSubmitted: (_) => _saveEdit(),
                            onEditingComplete: _saveEdit,
                          )
                        : AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isCompleted ? Colors.grey : Colors.black87,
                            ),
                            child: Text(
                              widget.item.text,
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showOptionsMenu() {
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
                  Icons.edit,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  TranslationService.translate('item_options'),
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
            // Edit option
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(TranslationService.translate('edit_item')),
              onTap: () {
                Navigator.of(context).pop();
                _startEditing();
              },
            ),
            // Delete option
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(
                TranslationService.translate('delete_item'),
                style: const TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _showDeleteConfirmation();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(TranslationService.translate('delete_item')),
        content: Text(
          TranslationService.translate('delete_item_confirmation', [widget.item.text]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(TranslationService.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDelete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(TranslationService.translate('delete')),
          ),
        ],
      ),
    );
  }
}
