import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'checklist.dart';
import 'checklist_view_type.dart';
import '../presentation/views/list_view_widget.dart';
import '../presentation/widgets/add_item_row.dart';
import '../../../core/services/translation_service.dart';
import '../../../core/services/validation_service.dart';
import '../../items/presentation/item_edit_screen.dart';
import '../domain/checklist_providers.dart';

/// Factory class for creating different checklist view widgets
class ChecklistViewFactory {
  /// Builds the appropriate view widget based on the checklist's view type
  static Widget buildView(Checklist checklist) {
    switch (checklist.viewType) {
      case ChecklistViewType.swipe:
        return SwipeViewWidget(checklist: checklist);
      case ChecklistViewType.list:
        return ListViewWidget(
          checklist: checklist,
          onItemTap: (item) {
            // TODO: Implement item tap logic
          },
          onItemEdit: (item) {
            // TODO: Implement item edit logic
          },
          onItemDelete: (item) {
            // TODO: Implement item delete logic
          },
          onItemMove: (item, direction) {
            // TODO: Implement item move logic
          },
        );
      case ChecklistViewType.matrix:
        return MatrixViewWidget(checklist: checklist);
    }
  }

  /// Builds the appropriate view widget with callbacks
  static Widget buildViewWithCallbacks(
    Checklist checklist, {
    required Function(ChecklistItem) onItemTap,
    required Function(ChecklistItem) onItemEdit,
    required Function(ChecklistItem) onItemDelete,
    required Function(ChecklistItem, int) onItemMove,
    Function(ChecklistItem)? onItemAdd,
    Function(ChecklistItem, String)? onTextUpdate,
    Function(String)? onQuickAdd,
    Function()? onQuickTemplate,
  }) {
    switch (checklist.viewType) {
      case ChecklistViewType.swipe:
        return SwipeViewWidget(checklist: checklist);
      case ChecklistViewType.list:
        return ListViewWidget(
          checklist: checklist,
          onItemTap: onItemTap,
          onItemEdit: onItemEdit,
          onItemDelete: onItemDelete,
          onItemMove: onItemMove,
          onItemAdd: onItemAdd,
          onTextUpdate: onTextUpdate,
          onQuickAdd: onQuickAdd,
          onQuickTemplate: onQuickTemplate,
        );
      case ChecklistViewType.matrix:
        return MatrixViewWidget(
          checklist: checklist,
          onItemTap: onItemTap,
          onItemEdit: onItemEdit,
          onItemDelete: onItemDelete,
          onItemMove: onItemMove,
          onItemAdd: onItemAdd,
          onTextUpdate: onTextUpdate,
          onQuickAdd: onQuickAdd,
          onQuickTemplate: onQuickTemplate,
        );
    }
  }

  /// Gets all available view types
  static List<ChecklistViewType> get availableViewTypes =>
      ChecklistViewType.values;

  /// Gets the next view type in the cycle
  static ChecklistViewType getNextViewType(ChecklistViewType current) {
    final types = availableViewTypes;
    final currentIndex = types.indexOf(current);
    final nextIndex = (currentIndex + 1) % types.length;
    return types[nextIndex];
  }
}

/// Placeholder widget for swipe view (existing functionality)
class SwipeViewWidget extends StatelessWidget {
  final Checklist checklist;

  const SwipeViewWidget({super.key, required this.checklist});

  @override
  Widget build(BuildContext context) {
    // TODO: Implement or refactor existing swipe view
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.swipe, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            TranslationService.translate('swipe_view_title'),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            TranslationService.translate('checklist_label', [checklist.title]),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text(
            TranslationService.translate('items_label', [
              checklist.items.length.toString(),
            ]),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Matrix view widget with grid layout and inline editing
class MatrixViewWidget extends ConsumerStatefulWidget {
  final Checklist checklist;
  final Function(ChecklistItem)? onItemTap;
  final Function(ChecklistItem)? onItemEdit;
  final Function(ChecklistItem)? onItemDelete;
  final Function(ChecklistItem, int)? onItemMove;
  final Function(ChecklistItem)? onItemAdd;
  final Function(ChecklistItem, String)? onTextUpdate;
  final Function(String)? onQuickAdd;
  final Function()? onQuickTemplate;

  const MatrixViewWidget({
    super.key,
    required this.checklist,
    this.onItemTap,
    this.onItemEdit,
    this.onItemDelete,
    this.onItemMove,
    this.onItemAdd,
    this.onTextUpdate,
    this.onQuickAdd,
    this.onQuickTemplate,
  });

  @override
  ConsumerState<MatrixViewWidget> createState() => _MatrixViewWidgetState();
}

class _MatrixViewWidgetState extends ConsumerState<MatrixViewWidget> {
  int _getCrossAxisCount(double screenWidth) {
    if (screenWidth < 600) return 2;
    if (screenWidth < 900) return 3;
    return 4;
  }

  void _handleEditItem(ChecklistItem item) {
    // Navigate to ItemEditScreen for editing
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ItemEditScreen(
          item: item,
          onSave: (updatedItem) async {
            try {
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
                widget.onItemEdit?.call(updatedItem);
              } else {
                throw Exception('Failed to update item');
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      TranslationService.translate('error_saving_item'),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              rethrow;
            }
          },
        ),
      ),
    );
  }

  void _handleDeleteItem(ChecklistItem item) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(TranslationService.translate('delete_item')),
        content: Text(
          TranslationService.translate('delete_item_confirmation', [item.text]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(TranslationService.translate('cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                // Call the onItemDelete callback to notify parent (session screen) to delete
                await widget.onItemDelete?.call(item);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        TranslationService.translate('error_deleting_item'),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(TranslationService.translate('delete')),
          ),
        ],
      ),
    );
  }

  void _handleAddItem() {
    // Navigate to ItemEditScreen for adding new item
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ItemEditScreen(
          onSave: (newItem) async {
            try {
              // Call the onItemAdd callback to notify parent (session screen) to add the item
              widget.onItemAdd?.call(newItem);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      TranslationService.translate('error_saving_item'),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              rethrow;
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.checklist.items;
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = _getCrossAxisCount(screenWidth);

    return Column(
      children: [
        // Grid of items with add item at the end
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 1.2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount:
                items.length +
                (widget.onItemAdd != null
                    ? 1
                    : 0), // Add 1 for the "add item" card
            itemBuilder: (context, index) {
              // Check if this is the "add item" card
              if (widget.onItemAdd != null && index == items.length) {
                return AddItemRow(
                  onTap: _handleAddItem,
                  onQuickAdd: widget.onQuickAdd,
                  onQuickTemplate: widget.onQuickTemplate,
                );
              }

              final item = items[index];
              final isFirst = index == 0;
              final isLast = index == items.length - 1;

              return MatrixItemCard(
                item: item,
                onTap: () => widget.onItemTap?.call(item),
                onEdit: () => _handleEditItem(item),
                onDelete: () => _handleDeleteItem(item),
                onMoveUp: isFirst
                    ? null
                    : () => widget.onItemMove?.call(item, -1),
                onMoveDown: isLast
                    ? null
                    : () => widget.onItemMove?.call(item, 1),
                onTextUpdate: widget.onTextUpdate != null
                    ? (newText) => widget.onTextUpdate!(item, newText)
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Individual matrix item card with inline editing
class MatrixItemCard extends StatefulWidget {
  final ChecklistItem item;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final Function(String)? onTextUpdate;

  const MatrixItemCard({
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
  State<MatrixItemCard> createState() => _MatrixItemCardState();
}

class _MatrixItemCardState extends State<MatrixItemCard> {
  late TextEditingController _textController;
  bool _isEditing = false;
  FocusNode? _focusNode;
  
  // Validation state
  String? _inlineEditError;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.item.text);
    _focusNode = FocusNode();
    _focusNode?.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode?.removeListener(_onFocusChange);
    _focusNode?.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode!.hasFocus && _isEditing) {
      _cancelEdit();
    }
  }

  // Validation methods
  void _validateInlineEdit(String value) {
    setState(() {
      _inlineEditError = ValidationService.validateItemText(value);
    });
  }

  bool _isInlineEditValid() {
    return _inlineEditError == null && 
           _textController.text.trim().isNotEmpty;
  }

  @override
  void didUpdateWidget(MatrixItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.text != widget.item.text) {
      _textController.text = widget.item.text;
    }
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      _focusNode?.requestFocus();
    });
  }

  void _saveEdit() {
    final newText = _textController.text.trim();
    
    // Validate before saving
    if (!_isInlineEditValid()) {
      // Show error message if validation fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TranslationService.translate('please_fix_errors')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
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
      child: GestureDetector(
        onTap: _isEditing ? _cancelEdit : widget.onTap,
        onLongPress: _startEditing,
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              // Checkbox at the top
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Checkbox(
                    value: isCompleted,
                    onChanged: (value) {
                      if (_isEditing) {
                        _cancelEdit();
                      }
                      widget.onTap();
                    },
                    activeColor: Theme.of(context).primaryColor,
                  ),
                  // Hamburger menu
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 16),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          widget.onEdit();
                          break;
                        case 'delete':
                          widget.onDelete();
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
                            const Icon(Icons.edit, size: 16),
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
                              const Icon(Icons.keyboard_arrow_up, size: 16),
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
                              const Icon(Icons.keyboard_arrow_down, size: 16),
                              const SizedBox(width: 8),
                              Text(TranslationService.translate('move_down')),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(
                              Icons.delete,
                              size: 16,
                              color: Colors.red,
                            ),
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

              // Item content
              Expanded(
                child: _isEditing
                    ? GestureDetector(
                        onTap: () {
                          // Prevent tap from bubbling up when editing
                        },
                        child: Column(
                          children: [
                            // Text field with more space
                            Expanded(
                              child: TextField(
                                controller: _textController,
                                focusNode: _focusNode,
                                style: TextStyle(
                                  fontSize: 12,
                                  decoration: isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: isCompleted ? Colors.grey[600] : null,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  hintText: 'Enter item text...',
                                  errorText: _inlineEditError,
                                  suffixText: '${_textController.text.length}/200',
                                ),
                                onChanged: _validateInlineEdit,
                                maxLines: null,
                                expands: true,
                                textAlignVertical: TextAlignVertical.top,
                                onSubmitted: (_) => _saveEdit(),
                              ),
                            ),
                            // Save/Cancel buttons at the bottom
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check, size: 16),
                                  onPressed: _isInlineEditValid() ? _saveEdit : null,
                                  color: _isInlineEditValid() ? Colors.green : Colors.grey,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 16),
                                  onPressed: _cancelEdit,
                                  color: Colors.red,
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          // Item image (if available)
                          if (widget.item.imageUrl != null &&
                              widget.item.imageUrl!.isNotEmpty) ...[
                            Expanded(
                              flex: 2,
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 1,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    widget.item.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              color: Colors.grey[200],
                                              child: Icon(
                                                Icons.broken_image,
                                                size: 24,
                                                color: Colors.grey[400],
                                              ),
                                            ),
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        color: Colors.grey[200],
                                        child: Center(
                                          child: SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              value:
                                                  loadingProgress
                                                          .expectedTotalBytes !=
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
                            ),
                            const SizedBox(height: 4),
                          ],
                          // Item text
                          Expanded(
                            flex:
                                widget.item.imageUrl != null &&
                                    widget.item.imageUrl!.isNotEmpty
                                ? 1
                                : 3,
                            child: Text(
                              widget.item.text,
                              style: TextStyle(
                                fontSize: 12,
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: isCompleted ? Colors.grey[600] : null,
                              ),
                              textAlign: TextAlign.center,
                              maxLines:
                                  widget.item.imageUrl != null &&
                                      widget.item.imageUrl!.isNotEmpty
                                  ? 2
                                  : 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
