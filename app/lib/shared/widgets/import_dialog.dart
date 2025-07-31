import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/import_service.dart';
import '../../core/services/translation_service.dart';
import '../../features/checklists/domain/checklist.dart';
import '../../core/providers/providers.dart';
import 'import_preview.dart';

enum ImportMode { file, paste, ai }

class ImportDialog extends ConsumerStatefulWidget {
  final Function(
    List<ChecklistItem>, {
    String? title,
    String? description,
    List<String>? tags,
  })
  onImport;

  const ImportDialog({super.key, required this.onImport});

  @override
  ConsumerState<ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends ConsumerState<ImportDialog> {
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
    // Listen for user changes to clear dialog state
    ref.listen<User?>(currentUserProvider, (previous, next) {
      if (previous?.uid != next?.uid && mounted) {
        _clearDialogState();
      }
    });
  }

  @override
  void dispose() {
    _clearDialogState();
    _contentController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _clearDialogState() {
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

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ImportService().getSupportedExtensions(),
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final content = file.bytes != null
            ? String.fromCharCodes(file.bytes!)
            : await File(file.path!).readAsString();

        setState(() {
          _selectedFileName = file.name;
          _contentController.text = content;
          _titleController.text = _titleController.text.isEmpty
              ? ImportService().extractTitleFromFileName(file.name)
              : _titleController.text;
        });

        _processContent();
      }
    } catch (e) {
      _showError('Error reading file: ${e.toString()}');
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

  void _createChecklist() {
    if (_importResult == null || _importResult!.items.isEmpty) {
      _showError('No items to import');
      return;
    }

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showError('Please enter a title for the checklist');
      return;
    }

    widget.onImport(
      _importResult!.items,
      title: title,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      tags: _tags.isEmpty ? null : _tags,
    );

    _clearDialogState();
    Navigator.of(context).pop();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async {
        _clearDialogState();
        return true;
      },
      child: Dialog(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          margin: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.file_upload, color: theme.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      TranslationService.translate('import_create_checklist'),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Mode Selection
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildModeButton(
                        mode: ImportMode.file,
                        icon: Icons.folder,
                        label: TranslationService.translate('file'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildModeButton(
                        mode: ImportMode.paste,
                        icon: Icons.content_paste,
                        label: TranslationService.translate('paste'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildModeButton(
                        mode: ImportMode.ai,
                        icon: Icons.smart_toy,
                        label: TranslationService.translate('ai_create'),
                        disabled: true, // TODO: Enable when AI is implemented
                      ),
                    ),
                  ],
                ),
              ),

              // Content Area
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Source indicator
                      Text(
                        TranslationService.translate('source'),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(_getSourceText()),
                      ),
                      const SizedBox(height: 16),

                      // Content input
                      if (_currentMode == ImportMode.paste ||
                          _currentMode == ImportMode.ai) ...[
                        Text(
                          TranslationService.translate('content_description'),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: TextField(
                            controller: _contentController,
                            maxLines: null,
                            decoration: InputDecoration(
                              hintText: _getContentHint(),
                              border: const OutlineInputBorder(),
                              alignLabelWithHint: true,
                            ),
                            onChanged: (_) => _processContent(),
                          ),
                        ),
                      ] else ...[
                        // File selection
                        ElevatedButton.icon(
                          onPressed: _pickFile,
                          icon: const Icon(Icons.folder_open),
                          label: Text(
                            _selectedFileName ??
                                TranslationService.translate('select_file'),
                          ),
                        ),
                        if (_selectedFileName != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Selected: $_selectedFileName',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],

                      const SizedBox(height: 16),

                      // Basic Information
                      Text(
                        TranslationService.translate('basic_information'),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Title
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: TranslationService.translate('title'),
                          hintText: TranslationService.translate(
                            'enter_checklist_title',
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Description
                      TextField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: TranslationService.translate(
                            'description',
                          ),
                          hintText: TranslationService.translate(
                            'enter_checklist_description',
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 8),

                      // Tags
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
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
                              onSubmitted: (_) => _addTag(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _addTag,
                            child: Text(TranslationService.translate('add')),
                          ),
                        ],
                      ),
                      if (_tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
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
              ),

              // Preview or Loading
              if (_isLoading)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: const Center(child: CircularProgressIndicator()),
                )
              else if (_importResult != null)
                ImportPreview(
                  result: _importResult!,
                  onEdit: () {
                    // TODO: Implement edit functionality
                  },
                ),

              // Action Buttons
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        _clearDialogState();
                        Navigator.of(context).pop();
                      },
                      child: Text(TranslationService.translate('cancel')),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _importResult?.hasPartialSuccess == true
                          ? _createChecklist
                          : null,
                      child: Text(TranslationService.translate('create')),
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

  Widget _buildModeButton({
    required ImportMode mode,
    required IconData icon,
    required String label,
    bool disabled = false,
  }) {
    final isSelected = _currentMode == mode;
    final theme = Theme.of(context);

    return InkWell(
      onTap: disabled
          ? null
          : () {
              setState(() {
                _currentMode = mode;
                _selectedFileName = null;
                if (mode == ImportMode.paste) {
                  _loadClipboardContent();
                }
              });
            },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primaryColor.withOpacity(0.1)
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? theme.primaryColor : theme.dividerColor,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: disabled
                  ? theme.disabledColor
                  : isSelected
                  ? theme.primaryColor
                  : theme.iconTheme.color,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: disabled
                    ? theme.disabledColor
                    : isSelected
                    ? theme.primaryColor
                    : null,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getSourceText() {
    switch (_currentMode) {
      case ImportMode.file:
        return _selectedFileName ?? TranslationService.translate('file');
      case ImportMode.paste:
        return TranslationService.translate('paste');
      case ImportMode.ai:
        return TranslationService.translate('ai_create');
    }
  }

  String _getContentHint() {
    switch (_currentMode) {
      case ImportMode.file:
        return TranslationService.translate('select_file_to_import');
      case ImportMode.paste:
        return TranslationService.translate('paste_checklist_content');
      case ImportMode.ai:
        return TranslationService.translate('describe_checklist_to_create');
    }
  }
}
