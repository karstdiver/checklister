import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../checklists/domain/checklist.dart';
import '../data/item_photo_service.dart';
import '../../../core/providers/privilege_provider.dart';
import '../../../core/widgets/feature_guard.dart';
import '../../../core/widgets/signup_encouragement.dart';
import '../../../core/services/translation_service.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../features/auth/presentation/login_screen.dart';

class ItemEditScreen extends ConsumerStatefulWidget {
  final ChecklistItem? item; // null for creating new, non-null for editing
  final Function(ChecklistItem) onSave;
  final VoidCallback? onCancel;

  const ItemEditScreen({
    super.key,
    this.item,
    required this.onSave,
    this.onCancel,
  });

  @override
  ConsumerState<ItemEditScreen> createState() => _ItemEditScreenState();
}

class _ItemEditScreenState extends ConsumerState<ItemEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  final _notesController = TextEditingController();
  String? _currentImageUrl;
  bool _isLoading = false;
  final _itemPhotoService = ItemPhotoService();

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.item != null) {
      _textController.text = widget.item!.text;
      _notesController.text = widget.item!.notes ?? '';
      _currentImageUrl = widget.item!.imageUrl;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool _isDirty() {
    if (widget.item == null) {
      // New item: check if any field is non-empty
      return _textController.text.trim().isNotEmpty ||
          _notesController.text.trim().isNotEmpty ||
          (_currentImageUrl != null && _currentImageUrl!.isNotEmpty);
    } else {
      // Editing: check if any field changed
      return _textController.text.trim() != widget.item!.text.trim() ||
          (_notesController.text.trim() != (widget.item!.notes ?? '').trim()) ||
          ((_currentImageUrl ?? '') != (widget.item!.imageUrl ?? ''));
    }
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
                onPressed: () {
                  Navigator.of(context).pop(false); // Close dialog
                  _saveItem(); // Save and navigate back
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
    final isEditing = widget.item != null;

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
                ? TranslationService.translate('edit_item')
                : TranslationService.translate('add_item'),
          ),
          leading: IconButton(
            onPressed: () async {
              if (_isDirty()) {
                final discard = await _confirmDiscardChanges(context);
                if (!discard) return;
              }
              widget.onCancel?.call();
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
                onPressed: _saveItem,
                child: Text(TranslationService.translate('save')),
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Item Text
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      TranslationService.translate('item_text'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _textController,
                      decoration: InputDecoration(
                        labelText: TranslationService.translate('item_text'),
                        hintText: TranslationService.translate(
                          'enter_item_text',
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return TranslationService.translate(
                            'item_text_required',
                          );
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Notes
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      TranslationService.translate('notes'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: TranslationService.translate('notes'),
                        hintText: TranslationService.translate('enter_notes'),
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Item Photo Section
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      TranslationService.translate('item_photo'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Photo display/upload area - always show, but guard the interaction
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child:
                          _currentImageUrl != null &&
                              _currentImageUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                children: [
                                  Image.network(
                                    _currentImageUrl!,
                                    width: double.infinity,
                                    height: 200,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Center(
                                              child: Icon(
                                                Icons.broken_image,
                                                size: 64,
                                                color: Colors.grey,
                                              ),
                                            ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: FeatureGuard(
                                      feature: 'itemPhotos',
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _currentImageUrl = null;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                      fallback: const SizedBox.shrink(),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : FeatureGuard(
                              feature: 'itemPhotos',
                              child: GestureDetector(
                                onTap: () async {
                                  final pickedFile = await _itemPhotoService
                                      .showImageSourceDialog(context);
                                  if (pickedFile != null) {
                                    setState(() {
                                      _isLoading = true;
                                    });

                                    try {
                                      final itemId =
                                          widget.item?.id ??
                                          'temp_${DateTime.now().millisecondsSinceEpoch}';
                                      final url = await _itemPhotoService
                                          .uploadItemPhoto(pickedFile, itemId);
                                      setState(() {
                                        _currentImageUrl = url;
                                        _isLoading = false;
                                      });
                                    } catch (e) {
                                      setState(() {
                                        _isLoading = false;
                                      });
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Failed to upload photo: $e',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No photo',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Tap to add photo',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              fallback: GestureDetector(
                                onTap: () {
                                  // Show encouragement when low privilege user taps
                                  showDialog(
                                    context: context,
                                    barrierDismissible: true,
                                    builder: (context) => AlertDialog(
                                      title: Row(
                                        children: [
                                          Icon(
                                            Icons.star,
                                            color: Colors.orange[600],
                                            size: 24,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              TranslationService.translate(
                                                'item_photos_title',
                                              ),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            TranslationService.translate(
                                              'item_photos_description',
                                            ),
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium,
                                          ),
                                          const SizedBox(height: 12),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue[100],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '✨ itemPhotos',
                                              style: TextStyle(
                                                color: Colors.blue[800],
                                                fontWeight: FontWeight.w500,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                          child: Text(
                                            TranslationService.translate(
                                              'maybe_later',
                                            ),
                                          ),
                                        ),
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    LoginScreen(
                                                      initialSignUpMode: true,
                                                    ),
                                              ),
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.person_add,
                                            size: 18,
                                          ),
                                          label: Text(
                                            TranslationService.translate(
                                              'sign_up_free',
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue[600],
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No photo',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Tap to add photo',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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

  void _saveItem() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final newItem = ChecklistItem.create(
      text: _textController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      imageUrl: _currentImageUrl,
    );

    final savedItem = widget.item != null
        ? newItem.copyWith(id: widget.item!.id, order: widget.item!.order)
        : newItem.copyWith(
            id: 'item_${DateTime.now().millisecondsSinceEpoch}',
            order: 0, // Will be set by parent
          );

    widget.onSave(savedItem);
    Navigator.of(context).pop();
  }
}
