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

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: _startEditing,
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Checkbox
              Checkbox(
                value: isCompleted,
                onChanged: (value) {
                  widget.onTap();
                },
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
                    : Text(
                        widget.item.text,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: isCompleted ? Colors.grey : Colors.black87,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
