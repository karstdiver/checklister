import '../../../core/services/translation_service.dart';

class ValidationService {
  // Validation constants
  static const int maxTitleLength = 100;
  static const int maxDescriptionLength = 500;
  static const int maxTagLength = 20;
  static const int maxTagsCount = 10;
  static const int minTitleLength = 1;
  static const int minTagLength = 1;

  /// Validates checklist title
  static String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return TranslationService.translate('title_required');
    }
    
    final trimmedValue = value.trim();
    if (trimmedValue.length < minTitleLength) {
      return TranslationService.translate('title_too_short');
    }
    
    if (trimmedValue.length > maxTitleLength) {
      return TranslationService.translate('title_too_long', [maxTitleLength.toString()]);
    }
    
    return null; // Valid
  }

  /// Validates checklist description
  static String? validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Description is optional
    }
    
    final trimmedValue = value.trim();
    if (trimmedValue.length > maxDescriptionLength) {
      return TranslationService.translate('description_too_long', [maxDescriptionLength.toString()]);
    }
    
    return null; // Valid
  }

  /// Validates individual tag
  static String? validateTag(String? value) {
    if (value == null || value.trim().isEmpty) {
      return TranslationService.translate('tag_required');
    }
    
    final trimmedValue = value.trim();
    if (trimmedValue.length < minTagLength) {
      return TranslationService.translate('tag_too_short');
    }
    
    if (trimmedValue.length > maxTagLength) {
      return TranslationService.translate('tag_too_long', [maxTagLength.toString()]);
    }
    
    // Only allow alphanumeric characters, hyphens, and underscores
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(trimmedValue)) {
      return TranslationService.translate('tag_invalid_format');
    }
    
    return null; // Valid
  }

  /// Validates tag list (for duplicates, count limits)
  static String? validateTagList(List<String> tags, String? newTag) {
    if (newTag != null) {
      // Check if tag already exists
      if (tags.any((tag) => tag.toLowerCase() == newTag.trim().toLowerCase())) {
        return TranslationService.translate('tag_already_exists');
      }
      
      // Check if adding this tag would exceed limit
      if (tags.length >= maxTagsCount) {
        return TranslationService.translate('too_many_tags', [maxTagsCount.toString()]);
      }
    }
    
    return null; // Valid
  }

  /// Validates item text
  static String? validateItemText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return TranslationService.translate('item_text_required');
    }
    
    final trimmedValue = value.trim();
    if (trimmedValue.length > 200) { // Max item text length
      return TranslationService.translate('item_text_too_long', ['200']);
    }
    
    return null; // Valid
  }

  /// Validates item notes
  static String? validateItemNotes(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Notes are optional
    }
    
    final trimmedValue = value.trim();
    if (trimmedValue.length > 1000) { // Max notes length
      return TranslationService.translate('notes_too_long', ['1000']);
    }
    
    return null; // Valid
  }

  /// Sanitizes text input (removes dangerous characters)
  static String sanitizeText(String text) {
    // Remove any potential HTML/script tags
    return text
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(RegExp(r'javascript:', caseSensitive: false), '') // Remove javascript: protocol
        .trim();
  }

  /// Truncates text to specified length
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}...';
  }
}
