enum ChecklistViewType { swipe, list, matrix }

extension ChecklistViewTypeExtension on ChecklistViewType {
  String get displayName {
    switch (this) {
      case ChecklistViewType.swipe:
        return 'Swipe';
      case ChecklistViewType.list:
        return 'List';
      case ChecklistViewType.matrix:
        return 'Matrix';
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
        return 'One item per screen, swipe to advance';
      case ChecklistViewType.list:
        return 'All items in a scrollable list';
      case ChecklistViewType.matrix:
        return 'Grid layout for visual overview';
    }
  }
}
