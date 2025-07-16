import 'package:flutter_test/flutter_test.dart';
import 'package:checklister/core/services/translation_service.dart';

void main() {
  group('Translation Integration Tests', () {
    setUp(() {
      TranslationService.clearCache();
    });

    tearDown(() {
      TranslationService.clearCache();
    });

    test('should handle missing keys gracefully without loading files', () {
      // Test that missing keys return the key itself without loading files
      expect(TranslationService.translate('missing_key'), 'missing_key');
      expect(TranslationService.translate('nonexistent'), 'nonexistent');
    });

    test('should return keys as-is when no translations are loaded', () {
      // When no translations are loaded, the service returns keys as-is
      expect(TranslationService.translate('welcome {}'), 'welcome {}');
      expect(
        TranslationService.translate('progress {} of {}'),
        'progress {} of {}',
      );
      expect(TranslationService.translate('simple_text'), 'simple_text');
    });

    test('should handle empty args list', () {
      // Test with no placeholders
      expect(TranslationService.translate('simple_text'), 'simple_text');

      // Test with placeholders but no args - should return key as-is
      expect(TranslationService.translate('text {} more'), 'text {} more');
    });

    test('should handle args when no translations are loaded', () {
      // When no translations are loaded, args are ignored and key is returned as-is
      final result = TranslationService.translate('hello {}', ['John', 'Doe']);
      expect(result, 'hello {}');
    });

    test(
      'should handle multiple placeholders when no translations are loaded',
      () {
        // When no translations are loaded, placeholders remain unchanged
        final result = TranslationService.translate('hello {} {}', ['John']);
        expect(result, 'hello {} {}');
      },
    );

    test('should handle special characters in keys', () {
      // Special characters in keys should be preserved
      final result = TranslationService.translate('price: {}', ['99.99']);
      expect(result, 'price: {}');
    });
  });
}
