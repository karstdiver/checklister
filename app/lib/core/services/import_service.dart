import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import '../../features/checklists/domain/checklist.dart';

/// Import result containing parsed items and metadata
class ImportResult {
  final List<ChecklistItem> items;
  final String? title;
  final String? description;
  final List<String> tags;
  final int totalItems;
  final int successfulItems;
  final int failedItems;
  final List<String> errors;

  const ImportResult({
    required this.items,
    this.title,
    this.description,
    this.tags = const [],
    required this.totalItems,
    required this.successfulItems,
    required this.failedItems,
    this.errors = const [],
  });

  bool get isSuccessful => successfulItems > 0 && errors.isEmpty;
  bool get hasPartialSuccess => successfulItems > 0;
}

/// Service for handling checklist imports from various sources
class ImportService {
  static const ImportService _instance = ImportService._internal();
  factory ImportService() => _instance;
  const ImportService._internal();

  static int _itemIdCounter = 0;

  /// Generate a unique item ID
  String _generateItemId() {
    _itemIdCounter++;
    return 'item_${DateTime.now().millisecondsSinceEpoch}_$_itemIdCounter';
  }

  /// Import from text content (paste functionality)
  Future<ImportResult> importFromText(String content, {String? title}) async {
    try {
      final lines = content.split('\n');
      final items = <ChecklistItem>[];
      final errors = <String>[];
      int successfulItems = 0;
      int failedItems = 0;

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        try {
          final item = _parseLine(line);
          if (item != null) {
            items.add(item.copyWith(order: items.length));
            successfulItems++;
          } else {
            failedItems++;
            errors.add('Line ${i + 1}: Could not parse item');
          }
        } catch (e) {
          failedItems++;
          errors.add('Line ${i + 1}: ${e.toString()}');
        }
      }

      return ImportResult(
        items: items,
        title: title,
        totalItems: lines.length,
        successfulItems: successfulItems,
        failedItems: failedItems,
        errors: errors,
      );
    } catch (e) {
      return ImportResult(
        items: [],
        title: title,
        totalItems: 0,
        successfulItems: 0,
        failedItems: 1,
        errors: [e.toString()],
      );
    }
  }

  /// Import from file content
  Future<ImportResult> importFromFile(String content, String fileName) async {
    try {
      final extension = fileName.split('.').last.toLowerCase();

      switch (extension) {
        case 'csv':
          return _importFromCsv(content, fileName);
        case 'json':
          return _importFromJson(content, fileName);
        case 'txt':
        default:
          return importFromText(
            content,
            title: extractTitleFromFileName(fileName),
          );
      }
    } catch (e) {
      return ImportResult(
        items: [],
        title: extractTitleFromFileName(fileName),
        totalItems: 0,
        successfulItems: 0,
        failedItems: 1,
        errors: [e.toString()],
      );
    }
  }

  /// Import from CSV content (simplified without csv package for now)
  Future<ImportResult> _importFromCsv(String content, String fileName) async {
    try {
      final lines = content.split('\n');
      final items = <ChecklistItem>[];
      final errors = <String>[];
      int successfulItems = 0;
      int failedItems = 0;

      // Skip header row if it exists
      final dataLines = lines.length > 1 ? lines.skip(1) : lines;

      for (int i = 0; i < dataLines.length; i++) {
        final line = dataLines.elementAt(i).trim();
        if (line.isEmpty) continue;

        try {
          // Simple CSV parsing - split by comma and take first column
          final columns = line.split(',');
          final itemText = columns.first.trim().replaceAll('"', '');

          if (itemText.isNotEmpty) {
            final item = ChecklistItem.create(
              text: itemText,
              order: items.length,
            );
            final itemWithId = item.copyWith(id: _generateItemId());
            items.add(itemWithId);
            successfulItems++;
          } else {
            failedItems++;
            errors.add('Row ${i + 2}: Empty item text');
          }
        } catch (e) {
          failedItems++;
          errors.add('Row ${i + 2}: ${e.toString()}');
        }
      }

      return ImportResult(
        items: items,
        title: extractTitleFromFileName(fileName),
        totalItems: dataLines.length,
        successfulItems: successfulItems,
        failedItems: failedItems,
        errors: errors,
      );
    } catch (e) {
      return ImportResult(
        items: [],
        title: extractTitleFromFileName(fileName),
        totalItems: 0,
        successfulItems: 0,
        failedItems: 1,
        errors: [e.toString()],
      );
    }
  }

  /// Import from JSON content
  Future<ImportResult> _importFromJson(String content, String fileName) async {
    try {
      final jsonData = json.decode(content);
      final items = <ChecklistItem>[];
      final errors = <String>[];

      if (jsonData is Map<String, dynamic>) {
        // Try to parse as a full checklist
        try {
          final checklist = Checklist.fromJson(jsonData);
          return ImportResult(
            items: checklist.items,
            title: checklist.title,
            description: checklist.description,
            tags: checklist.tags,
            totalItems: checklist.items.length,
            successfulItems: checklist.items.length,
            failedItems: 0,
          );
        } catch (e) {
          // If not a full checklist, try to parse as items array
          if (jsonData.containsKey('items') && jsonData['items'] is List) {
            final itemsList = jsonData['items'] as List;
            int successfulItems = 0;
            int failedItems = 0;

            for (int i = 0; i < itemsList.length; i++) {
              try {
                final item = ChecklistItem.fromJson(
                  Map<String, dynamic>.from(itemsList[i]),
                );
                items.add(item.copyWith(order: items.length));
                successfulItems++;
              } catch (e) {
                failedItems++;
                errors.add('Item ${i + 1}: ${e.toString()}');
              }
            }

            return ImportResult(
              items: items,
              title: jsonData['title'] ?? extractTitleFromFileName(fileName),
              description: jsonData['description'],
              tags: List<String>.from(jsonData['tags'] ?? []),
              totalItems: itemsList.length,
              successfulItems: successfulItems,
              failedItems: failedItems,
              errors: errors,
            );
          }
        }
      } else if (jsonData is List) {
        // Try to parse as array of items
        int successfulItems = 0;
        int failedItems = 0;

        for (int i = 0; i < jsonData.length; i++) {
          try {
            final item = ChecklistItem.fromJson(
              Map<String, dynamic>.from(jsonData[i]),
            );
            items.add(item.copyWith(order: items.length));
            successfulItems++;
          } catch (e) {
            failedItems++;
            errors.add('Item ${i + 1}: ${e.toString()}');
          }
        }

        return ImportResult(
          items: items,
          title: extractTitleFromFileName(fileName),
          totalItems: jsonData.length,
          successfulItems: successfulItems,
          failedItems: failedItems,
          errors: errors,
        );
      }

      return ImportResult(
        items: [],
        title: extractTitleFromFileName(fileName),
        totalItems: 0,
        successfulItems: 0,
        failedItems: 1,
        errors: ['Invalid JSON format'],
      );
    } catch (e) {
      return ImportResult(
        items: [],
        title: extractTitleFromFileName(fileName),
        totalItems: 0,
        successfulItems: 0,
        failedItems: 1,
        errors: [e.toString()],
      );
    }
  }

  /// Parse a single line into a checklist item
  ChecklistItem? _parseLine(String line) {
    // Remove common bullet points and numbering
    final cleanedLine = line
        .replaceAll(RegExp(r'^[\s]*[•\-\*\+]\s*'), '') // Remove bullet points
        .replaceAll(RegExp(r'^[\s]*\d+[\.\)]\s*'), '') // Remove numbering
        .replaceAll(RegExp(r'^[\s]*\[[\sxX]\][\s]*'), '') // Remove checkboxes
        .replaceAll(RegExp(r'^[\s]*☐[\s]*'), '') // Remove unicode checkboxes
        .trim();

    if (cleanedLine.isEmpty) return null;

    final item = ChecklistItem.create(
      text: cleanedLine,
      order: 0, // Will be set by caller
    );
    return item.copyWith(id: _generateItemId());
  }

  /// Extract title from filename
  String extractTitleFromFileName(String fileName) {
    final name = fileName.split('/').last.split('.').first;
    return name.replaceAll(RegExp(r'[_-]'), ' ').trim();
  }

  /// Get clipboard content
  Future<String?> getClipboardContent() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      return data?.text;
    } catch (e) {
      return null;
    }
  }

  /// Validate import content
  bool isValidContent(String content) {
    if (content.trim().isEmpty) return false;

    final lines = content.split('\n');
    final nonEmptyLines = lines.where((line) => line.trim().isNotEmpty).length;

    return nonEmptyLines > 0;
  }

  /// Get supported file extensions
  List<String> getSupportedExtensions() {
    return ['txt', 'csv', 'json'];
  }

  /// Get file type description
  String getFileTypeDescription(String extension) {
    switch (extension.toLowerCase()) {
      case 'txt':
        return 'Plain Text Files';
      case 'csv':
        return 'CSV Spreadsheet Files';
      case 'json':
        return 'JSON Data Files';
      default:
        return 'Unknown File Type';
    }
  }
}
