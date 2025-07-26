import 'package:flutter/material.dart';
import 'checklist.dart';
import 'checklist_view_type.dart';

/// Factory class for creating different checklist view widgets
class ChecklistViewFactory {
  /// Builds the appropriate view widget based on the checklist's view type
  static Widget buildView(Checklist checklist) {
    switch (checklist.viewType) {
      case ChecklistViewType.swipe:
        return SwipeViewWidget(checklist: checklist);
      case ChecklistViewType.list:
        return ListViewWidget(checklist: checklist);
      case ChecklistViewType.matrix:
        return MatrixViewWidget(checklist: checklist);
    }
  }

  /// Gets all available view types
  static List<ChecklistViewType> get availableViewTypes =>
      ChecklistViewType.values;

  /// Gets the next view type in the cycle
  static ChecklistViewType getNextViewType(ChecklistViewType current) {
    final types = availableViewTypes;
    final currentIndex = types.indexOf(current);
    final nextIndex = (currentIndex + 1) % types.length;
    return types[nextIndex];
  }
}

/// Placeholder widget for swipe view (existing functionality)
class SwipeViewWidget extends StatelessWidget {
  final Checklist checklist;

  const SwipeViewWidget({super.key, required this.checklist});

  @override
  Widget build(BuildContext context) {
    // TODO: Implement or refactor existing swipe view
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.swipe, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('Swipe View', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Checklist: ${checklist.title}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'Items: ${checklist.items.length}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// Placeholder widget for list view (to be implemented in Phase 2)
class ListViewWidget extends StatelessWidget {
  final Checklist checklist;

  const ListViewWidget({super.key, required this.checklist});

  @override
  Widget build(BuildContext context) {
    // TODO: Implement list view in Phase 2
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.list, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('List View', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Checklist: ${checklist.title}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'Items: ${checklist.items.length}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Text(
            'Coming in Phase 2',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder widget for matrix view (to be implemented in Phase 3)
class MatrixViewWidget extends StatelessWidget {
  final Checklist checklist;

  const MatrixViewWidget({super.key, required this.checklist});

  @override
  Widget build(BuildContext context) {
    // TODO: Implement matrix view in Phase 3
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.grid_on, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('Matrix View', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Checklist: ${checklist.title}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'Items: ${checklist.items.length}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Text(
            'Coming in Phase 3',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
