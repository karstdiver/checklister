import 'package:flutter/material.dart';
import 'package:checklister/features/checklists/domain/checklist.dart';
import '../../../../core/services/translation_service.dart';

class ChecklistItemRow extends StatefulWidget {
  final ChecklistItem item;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final Function(String)? onTextUpdate;

  const ChecklistItemRow({
    super.key,
    required this.item,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.onMoveUp,
    this.onMoveDown,
    this.onTextUpdate,
  });

  @override
  State<ChecklistItemRow> createState() => _ChecklistItemRowState();
}

class _ChecklistItemRowState extends State<ChecklistItemRow> {
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
  void didUpdateWidget(ChecklistItemRow oldWidget) {
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

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: _startEditing,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Checkbox
              Checkbox(
                value: isCompleted,
                onChanged: (value) => widget.onTap(),
                activeColor: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 12),

              // Item content (text and optional thumbnail)
              Expanded(
                child: Row(
                  children: [
                    // Item text or text field when editing
                    Expanded(
                      child: _isEditing
                          ? TextField(
                              controller: _textController,
                              focusNode: _focusNode,
                              style: TextStyle(
                                fontSize: 16,
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: isCompleted ? Colors.grey[600] : null,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                suffixIcon: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.check, size: 20),
                                      onPressed: _saveEdit,
                                      color: Colors.green,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 20),
                                      onPressed: _cancelEdit,
                                      color: Colors.red,
                                    ),
                                  ],
                                ),
                              ),
                              onSubmitted: (_) => _saveEdit(),
                            )
                          : Text(
                              widget.item.text,
                              style: TextStyle(
                                fontSize: 16,
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: isCompleted ? Colors.grey[600] : null,
                              ),
                            ),
                    ),

                    // Thumbnail (if item has an image)
                    if (widget.item.imageUrl != null &&
                        widget.item.imageUrl!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            widget.item.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: Colors.grey[200],
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 20,
                                    color: Colors.grey[400],
                                  ),
                                ),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey[200],
                                child: Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                              null
                                          ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                          : null,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Hamburger menu
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      widget.onEdit();
                      break;
                    case 'delete':
                      _showDeleteDialog(context);
                      break;
                    case 'move_up':
                      widget.onMoveUp?.call();
                      break;
                    case 'move_down':
                      widget.onMoveDown?.call();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit, size: 20),
                        const SizedBox(width: 8),
                        Text(TranslationService.translate('edit')),
                      ],
                    ),
                  ),
                  if (widget.onMoveUp != null)
                    PopupMenuItem(
                      value: 'move_up',
                      child: Row(
                        children: [
                          const Icon(Icons.keyboard_arrow_up, size: 20),
                          const SizedBox(width: 8),
                          Text(TranslationService.translate('move_up')),
                        ],
                      ),
                    ),
                  if (widget.onMoveDown != null)
                    PopupMenuItem(
                      value: 'move_down',
                      child: Row(
                        children: [
                          const Icon(Icons.keyboard_arrow_down, size: 20),
                          const SizedBox(width: 8),
                          Text(TranslationService.translate('move_down')),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete, size: 20, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          TranslationService.translate('delete'),
                          style: const TextStyle(color: Colors.red),
                        ),
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
        title: Text(TranslationService.translate('delete_item')),
        content: Text(
          TranslationService.translate('delete_item_confirmation', [
            widget.item.text,
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(TranslationService.translate('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDelete();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(TranslationService.translate('delete')),
          ),
        ],
      ),
    );
  }
}
