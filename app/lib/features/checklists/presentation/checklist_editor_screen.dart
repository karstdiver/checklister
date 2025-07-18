import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/checklist.dart';
import '../domain/checklist_providers.dart';

import '../../../core/services/analytics_service.dart';
import '../../../core/services/translation_service.dart';
import '../../../shared/widgets/app_card.dart';

class ChecklistEditorScreen extends ConsumerStatefulWidget {
  final Checklist? checklist; // null for creating new, non-null for editing

  const ChecklistEditorScreen({super.key, this.checklist});

  @override
  ConsumerState<ChecklistEditorScreen> createState() =>
      _ChecklistEditorScreenState();
}

class _ChecklistEditorScreenState extends ConsumerState<ChecklistEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagController = TextEditingController();

  List<ChecklistItem> _items = [];
  List<String> _tags = [];
  bool _isPublic = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.checklist != null) {
      // Editing existing checklist
      _titleController.text = widget.checklist!.title;
      _descriptionController.text = widget.checklist!.description ?? '';
      _tags = List.from(widget.checklist!.tags);
      _items = List.from(widget.checklist!.items);
      _isPublic = widget.checklist!.isPublic;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.checklist != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? tr(ref, 'edit_checklist') : tr(ref, 'create_checklist'),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(onPressed: _saveChecklist, child: Text(tr(ref, 'save'))),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Basic Information
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(ref, 'basic_information'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: tr(ref, 'title'),
                      hintText: tr(ref, 'enter_checklist_title'),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return tr(ref, 'title_required');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: tr(ref, 'description'),
                      hintText: tr(ref, 'enter_checklist_description'),
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  // Public toggle
                  SwitchListTile(
                    title: Text(tr(ref, 'make_public')),
                    subtitle: Text(tr(ref, 'public_checklist_description')),
                    value: _isPublic,
                    onChanged: (value) {
                      setState(() {
                        _isPublic = value;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Tags
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(ref, 'tags'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Add tag
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _tagController,
                          decoration: InputDecoration(
                            labelText: tr(ref, 'add_tag'),
                            hintText: tr(ref, 'enter_tag'),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _addTag,
                        child: Text(tr(ref, 'add')),
                      ),
                    ],
                  ),

                  // Tags list
                  if (_tags.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _tags
                          .map(
                            (tag) => Chip(
                              label: Text(tag),
                              onDeleted: () => _removeTag(tag),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Items
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tr(ref, 'items'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _addItem,
                        icon: const Icon(Icons.add),
                        label: Text(tr(ref, 'add_item')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_items.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.checklist_outlined,
                            size: 64,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            tr(ref, 'no_items_yet'),
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            tr(ref, 'add_items_description'),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _items.length,
                      onReorder: _reorderItems,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return Card(
                          key: ValueKey(item.id),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.drag_handle),
                            title: Text(item.text),
                            subtitle: item.notes != null
                                ? Text(item.notes!)
                                : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () => _editItem(index),
                                  icon: const Icon(Icons.edit),
                                ),
                                IconButton(
                                  onPressed: () => _removeItem(index),
                                  icon: const Icon(Icons.delete),
                                  color: Colors.red,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _addItem() {
    _showItemDialog();
  }

  void _editItem(int index) {
    _showItemDialog(item: _items[index], index: index);
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _reorderItems(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);

      // Update order
      for (int i = 0; i < _items.length; i++) {
        _items[i] = _items[i].copyWith(order: i);
      }
    });
  }

  void _showItemDialog({ChecklistItem? item, int? index}) {
    final textController = TextEditingController(text: item?.text ?? '');
    final notesController = TextEditingController(text: item?.notes ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item != null ? tr(ref, 'edit_item') : tr(ref, 'add_item')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              decoration: InputDecoration(
                labelText: tr(ref, 'item_text'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: tr(ref, 'notes'),
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(tr(ref, 'cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              final text = textController.text.trim();
              if (text.isNotEmpty) {
                final newItem = ChecklistItem.create(
                  text: text,
                  notes: notesController.text.trim().isEmpty
                      ? null
                      : notesController.text.trim(),
                );

                setState(() {
                  if (index != null) {
                    _items[index] = newItem.copyWith(
                      id: item!.id,
                      order: item.order,
                    );
                  } else {
                    _items.add(
                      newItem.copyWith(
                        id: 'item_${DateTime.now().millisecondsSinceEpoch}',
                        order: _items.length,
                      ),
                    );
                  }
                });
              }
              Navigator.of(context).pop();
            },
            child: Text(tr(ref, 'save')),
          ),
        ],
      ),
    );
  }

  Future<void> _saveChecklist() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final notifier = ref.read(checklistNotifierProvider.notifier);
      final analytics = AnalyticsService();

      if (widget.checklist != null) {
        // Update existing checklist
        final updatedChecklist = widget.checklist!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          items: _items,
          tags: _tags,
          isPublic: _isPublic,
          totalItems: _items.length,
        );

        final success = await notifier.updateChecklist(updatedChecklist);
        if (success) {
          await analytics.logCustomEvent(
            name: 'checklist_updated',
            parameters: {'checklist_id': widget.checklist!.id},
          );
          if (mounted) {
            Navigator.of(context).pop(updatedChecklist);
          }
        }
      } else {
        // Create new checklist
        final newChecklist = await notifier.createChecklist(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          userId: user.uid,
          items: _items,
          tags: _tags,
          isPublic: _isPublic,
        );

        if (newChecklist != null && mounted) {
          Navigator.of(context).pop(newChecklist);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(ref, 'error_saving_checklist')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
