import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/import_service.dart';
import '../../../core/services/translation_service.dart';
import '../../../core/services/analytics_service.dart';
import '../domain/checklist.dart';
import '../domain/checklist_providers.dart';
import '../../../core/providers/providers.dart';
import '../../../core/providers/privilege_provider.dart';
import '../../../core/domain/user_tier.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/import_preview.dart';
import '../../settings/presentation/upgrade_screen.dart';
import '../../auth/presentation/login_screen.dart';

enum ImportMode { file, paste, ai }

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  ImportMode _currentMode = ImportMode.paste;
  final _contentController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagController = TextEditingController();

  List<String> _tags = [];
  bool _isLoading = false;
  ImportResult? _importResult;
  String? _selectedFileName;

  @override
  void initState() {
    super.initState();
    _loadClipboardContent();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _contentController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _clearScreenState() {
    if (mounted) {
      setState(() {
        _contentController.clear();
        _titleController.clear();
        _descriptionController.clear();
        _tagController.clear();
        _tags.clear();
        _isLoading = false;
        _importResult = null;
        _selectedFileName = null;
        _currentMode = ImportMode.paste;
      });
    }
  }

  Future<void> _loadClipboardContent() async {
    if (_currentMode == ImportMode.paste) {
      final clipboardContent = await ImportService().getClipboardContent();
      if (clipboardContent != null &&
          ImportService().isValidContent(clipboardContent)) {
        setState(() {
          _contentController.text = clipboardContent;
        });
        _processContent();
      }
    }
  }

  /// Show upgrade dialog when limits are reached
  void _showUpgradeDialog() {
    final privileges = ref.read(privilegeProvider);
    final userTier = privileges?.tier ?? UserTier.anonymous;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(TranslationService.translate('limit_reached')),
        content: Text(TranslationService.translate('upgrade_to_create_more')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(TranslationService.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (userTier == UserTier.anonymous) {
                // For anonymous users, navigate directly to signup
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(initialSignUpMode: true),
                  ),
                );
              } else {
                // Navigate to upgrade screen for other users
                _navigateToUpgrade();
              }
            },
            child: Text(
              userTier == UserTier.anonymous
                  ? TranslationService.translate('signup')
                  : TranslationService.translate('upgrade_now'),
            ),
          ),
        ],
      ),
    );
  }

  /// Navigate to upgrade screen
  void _navigateToUpgrade() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const UpgradeScreen()));
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'csv', 'json'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        final content = await file.readAsString();

        setState(() {
          _contentController.text = content;
          _selectedFileName = result.files.first.name;
          _currentMode = ImportMode.file;
        });

        _processContent();
      }
    } catch (e) {
      _showError('Error picking file: ${e.toString()}');
    }
  }

  Future<void> _processContent() async {
    if (!ImportService().isValidContent(_contentController.text)) {
      return;
    }

    setState(() {
      _isLoading = true;
      _importResult = null;
    });

    try {
      ImportResult result;

      switch (_currentMode) {
        case ImportMode.file:
          if (_selectedFileName != null) {
            result = await ImportService().importFromFile(
              _contentController.text,
              _selectedFileName!,
            );
          } else {
            result = await ImportService().importFromText(
              _contentController.text,
            );
          }
          break;
        case ImportMode.paste:
          result = await ImportService().importFromText(
            _contentController.text,
          );
          break;
        case ImportMode.ai:
          // TODO: Implement AI import
          result = const ImportResult(
            items: [],
            totalItems: 0,
            successfulItems: 0,
            failedItems: 1,
            errors: ['AI import not yet implemented'],
          );
          break;
      }

      setState(() {
        _importResult = result;
        _isLoading = false;
      });

      // Auto-fill title if not set
      if (_titleController.text.isEmpty && result.title != null) {
        _titleController.text = result.title!;
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Error processing content: ${e.toString()}');
    }
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

  Future<void> _createChecklist() async {
    if (_importResult == null || _importResult!.items.isEmpty) {
      _showError('No items to import');
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      _showError('Title is required');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    print('[DEBUG] ImportScreen: Starting checklist creation');
    print('[DEBUG] ImportScreen: Items count: ${_importResult!.items.length}');
    print('[DEBUG] ImportScreen: Title: ${_titleController.text.trim()}');

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showError('User not authenticated');
        return;
      }

      // Get user tier for limit checking
      final privileges = ref.read(privilegeProvider);
      final userTier = privileges?.tier;
      print('[DEBUG] ImportScreen: User tier: $userTier');
      print('[DEBUG] ImportScreen: Privileges: $privileges');

      final createdChecklist = await ref
          .read(checklistNotifierProvider.notifier)
          .createChecklist(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            userId: currentUser.uid,
            items: _importResult!.items,
            tags: _tags,
            isPublic: false,
            userTier: userTier, // Pass user tier for limit checking
          );

      if (createdChecklist == null) {
        print('[DEBUG] ImportScreen: Checklist creation returned null');

        // Check if there's an error in the state
        final checklistState = ref.read(checklistNotifierProvider);
        if (checklistState.hasError) {
          final errorMessage = checklistState.error.toString();
          print('[DEBUG] ImportScreen: State has error: $errorMessage');

          // Check if this is a limit exceeded error
          if (errorMessage.contains('limit reached') ||
              errorMessage.contains('limit_reached') ||
              errorMessage.contains('Item limit reached')) {
            print('[DEBUG] ImportScreen: Showing upgrade dialog');
            _showUpgradeDialog();
          } else {
            print('[DEBUG] ImportScreen: Showing generic error');
            _showError('Error creating checklist: $errorMessage');
          }
        } else {
          _showError('Failed to create checklist. Please try again.');
        }
        return;
      }

      print(
        '[DEBUG] ImportScreen: Checklist created successfully with ID: ${createdChecklist.id}',
      );

      // Track analytics
      await AnalyticsService().logChecklistCreated(
        checklistId: createdChecklist.id,
      );

      print('[DEBUG] ImportScreen: About to pop with result=true');
      if (mounted) {
        Navigator.of(context).pop(true); // Return success
      }
    } catch (e) {
      final errorMessage = e.toString();
      print('[DEBUG] ImportScreen: Error creating checklist: $errorMessage');
      print('[DEBUG] ImportScreen: Error type: ${e.runtimeType}');
      print(
        '[DEBUG] ImportScreen: Error contains "limit reached": ${errorMessage.contains('limit reached')}',
      );
      print(
        '[DEBUG] ImportScreen: Error contains "limit_reached": ${errorMessage.contains('limit_reached')}',
      );
      print(
        '[DEBUG] ImportScreen: Error contains "Item limit reached": ${errorMessage.contains('Item limit reached')}',
      );

      // Check if this is a limit exceeded error
      if (errorMessage.contains('limit reached') ||
          errorMessage.contains('limit_reached') ||
          errorMessage.contains('Item limit reached')) {
        print('[DEBUG] ImportScreen: Showing upgrade dialog');
        _showUpgradeDialog();
      } else {
        print('[DEBUG] ImportScreen: Showing generic error');
        _showError('Error creating checklist: $errorMessage');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  bool _isDirty() {
    return _contentController.text.trim().isNotEmpty ||
        _titleController.text.trim().isNotEmpty ||
        _descriptionController.text.trim().isNotEmpty ||
        _tags.isNotEmpty ||
        _importResult != null;
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
                  await _createChecklist(); // Save and navigate back
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

    // Listen for user changes to clear screen state
    ref.listen<User?>(currentUserProvider, (previous, next) {
      if (previous?.uid != next?.uid && mounted) {
        _clearScreenState();
      }
    });

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
          title: Text(TranslationService.translate('import_save_checklist')),
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
                onPressed: _createChecklist,
                child: Text(TranslationService.translate('create')),
              ),
          ],
        ),
        body: Form(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Import Mode Selection
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      TranslationService.translate('import_method'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Mode selection buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _currentMode = ImportMode.paste;
                              });
                              _loadClipboardContent();
                            },
                            icon: const Icon(Icons.content_paste),
                            label: Text(TranslationService.translate('paste')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _currentMode == ImportMode.paste
                                  ? theme.primaryColor
                                  : null,
                              foregroundColor: _currentMode == ImportMode.paste
                                  ? Colors.white
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickFile,
                            icon: const Icon(Icons.file_upload),
                            label: Text(TranslationService.translate('file')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _currentMode == ImportMode.file
                                  ? theme.primaryColor
                                  : null,
                              foregroundColor: _currentMode == ImportMode.file
                                  ? Colors.white
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _currentMode = ImportMode.ai;
                              });
                            },
                            icon: const Icon(Icons.auto_awesome),
                            label: Text(TranslationService.translate('ai')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _currentMode == ImportMode.ai
                                  ? theme.primaryColor
                                  : null,
                              foregroundColor: _currentMode == ImportMode.ai
                                  ? Colors.white
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Content Input
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      TranslationService.translate('content'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // File name display
                    if (_selectedFileName != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.file_present,
                              color: theme.primaryColor,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedFileName!,
                                style: TextStyle(
                                  color: theme.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Content text field
                    TextFormField(
                      controller: _contentController,
                      decoration: InputDecoration(
                        labelText: TranslationService.translate(
                          'paste_content',
                        ),
                        hintText: TranslationService.translate(
                          'paste_content_hint',
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 8,
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          _processContent();
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Import Preview
              if (_importResult != null) ...[
                ImportPreview(result: _importResult!, onEdit: _processContent),
                const SizedBox(height: 16),
              ],

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
            ],
          ),
        ),
      ),
    );
  }
}
