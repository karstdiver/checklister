import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/checklist.dart';
import '../domain/checklist_providers.dart';
import '../../items/data/item_photo_service.dart';
import '../../items/presentation/item_edit_screen.dart';
import '../../../core/providers/privilege_provider.dart';
import '../../../core/widgets/feature_guard.dart';
import '../../../core/widgets/signup_encouragement.dart';

import '../../../core/services/analytics_service.dart';
import '../../../core/services/translation_service.dart';
import '../../../shared/widgets/app_card.dart';
import '../../settings/presentation/upgrade_screen.dart';

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

  bool _isDirty() {
    if (widget.checklist == null) {
      // New checklist: check if any field is non-empty or items/tags changed
      return _titleController.text.trim().isNotEmpty ||
          _descriptionController.text.trim().isNotEmpty ||
          _items.isNotEmpty ||
          _tags.isNotEmpty ||
          _isPublic;
    } else {
      // Editing: check if any field changed
      return _titleController.text.trim() != widget.checklist!.title.trim() ||
          (_descriptionController.text.trim() !=
              (widget.checklist!.description ?? '').trim()) ||
          _isPublic != widget.checklist!.isPublic ||
          !_listEquals(_items, widget.checklist!.items) ||
          !_listEquals(_tags, widget.checklist!.tags);
    }
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<bool> _confirmDiscardChanges(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(TranslationService.translate('discard_changes_title')),
            content: Text(
              TranslationService.translate('discard_changes_message'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(TranslationService.translate('cancel')),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(TranslationService.translate('discard')),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop(false); // Close dialog
                  await _saveChecklist(); // Save and navigate back
                },
                child: Text(TranslationService.translate('save')),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.checklist != null;

    return WillPopScope(
      onWillPop: () async {
        if (_isDirty()) {
          final discard = await _confirmDiscardChanges(context);
          return discard;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isEditing
                ? TranslationService.translate('edit_checklist')
                : TranslationService.translate('create_checklist'),
          ),
          leading: IconButton(
            onPressed: () async {
              if (_isDirty()) {
                final discard = await _confirmDiscardChanges(context);
                if (!discard) return;
              }
              Navigator.of(context).pop();
            },
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
              TextButton(
                onPressed: _saveChecklist,
                child: Text(TranslationService.translate('save')),
              ),
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
                      TranslationService.translate('basic_information'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: TranslationService.translate('title'),
                        hintText: TranslationService.translate(
                          'enter_checklist_title',
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return TranslationService.translate('title_required');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: TranslationService.translate('description'),
                        hintText: TranslationService.translate(
                          'enter_checklist_description',
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    // Public toggle with privilege guard (curious user method)
                    SwitchListTile(
                      title: Text(TranslationService.translate('make_public')),
                      subtitle: Text(
                        TranslationService.translate(
                          'public_checklist_description',
                        ),
                      ),
                      value: _isPublic,
                      onChanged: (value) {
                        // Check privilege before allowing public toggle
                        final privileges = ref.read(privilegeProvider);
                        final hasPublicChecklists =
                            privileges?.features['publicChecklists'] == true;

                        if (hasPublicChecklists) {
                          setState(() {
                            _isPublic = value;
                          });
                        } else {
                          // Show encouragement dialog for curious users
                          _showPublicChecklistsEncouragement();
                        }
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
                      TranslationService.translate('tags'),
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
                              labelText: TranslationService.translate(
                                'add_tag',
                              ),
                              hintText: TranslationService.translate(
                                'enter_tag',
                              ),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _addTag,
                          child: Text(TranslationService.translate('add')),
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
                          TranslationService.translate('items'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _addItem,
                          icon: const Icon(Icons.add),
                          label: Text(TranslationService.translate('add_item')),
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
                              TranslationService.translate('no_items_yet'),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              TranslationService.translate(
                                'add_items_description',
                              ),
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
                              leading:
                                  item.imageUrl != null &&
                                      item.imageUrl!.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Image.network(
                                        item.imageUrl!,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(Icons.broken_image),
                                      ),
                                    )
                                  : const Icon(Icons.drag_handle),
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ItemEditScreen(
          onSave: (item) {
            setState(() {
              _items.add(item.copyWith(order: _items.length));
            });
          },
        ),
      ),
    );
  }

  void _editItem(int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ItemEditScreen(
          item: _items[index],
          onSave: (item) {
            setState(() {
              _items[index] = item.copyWith(order: _items[index].order);
            });
          },
        ),
      ),
    );
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

  void _showPublicChecklistsEncouragement() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(TranslationService.translate('public_checklists_title')),
        content: Text(
          TranslationService.translate('public_checklists_description'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(TranslationService.translate('maybe_later')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const UpgradeScreen()),
              );
            },
            child: Text(TranslationService.translate('upgrade')),
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
            content: Text(
              TranslationService.translate('error_saving_checklist'),
            ),
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
