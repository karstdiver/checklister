import '../../../core/services/translation_service.dart';

enum ChecklistViewType { swipe, list, matrix }

extension ChecklistViewTypeExtension on ChecklistViewType {
  String get displayName {
    switch (this) {
      case ChecklistViewType.swipe:
        return TranslationService.translate('swipe_view');
      case ChecklistViewType.list:
        return TranslationService.translate('list_view');
      case ChecklistViewType.matrix:
        return TranslationService.translate('matrix_view');
    }
  }

  String get icon {
    switch (this) {
      case ChecklistViewType.swipe:
        return 'swipe';
      case ChecklistViewType.list:
        return 'list';
      case ChecklistViewType.matrix:
        return 'grid_on';
    }
  }

  String get description {
    switch (this) {
      case ChecklistViewType.swipe:
        return TranslationService.translate('swipe_view_description');
      case ChecklistViewType.list:
        return TranslationService.translate('list_view_description');
      case ChecklistViewType.matrix:
        return TranslationService.translate('matrix_view_description');
    }
  }
}
