import 'package:flutter/material.dart';
import '../../domain/checklist_view_type.dart';

/// Widget for selecting checklist view types via a popup menu
class ViewSelectorMenu extends StatelessWidget {
  final ChecklistViewType currentViewType;
  final Function(ChecklistViewType) onViewTypeChanged;
  final List<ChecklistViewType> availableViewTypes;

  const ViewSelectorMenu({
    super.key,
    required this.currentViewType,
    required this.onViewTypeChanged,
    this.availableViewTypes = const [
      ChecklistViewType.list,
      ChecklistViewType.swipe,
      ChecklistViewType.matrix,
    ],
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ChecklistViewType>(
      icon: const Icon(Icons.more_vert),
      tooltip: 'View Options',
      onSelected: onViewTypeChanged,
      itemBuilder: (context) => availableViewTypes.map((viewType) {
        return PopupMenuItem<ChecklistViewType>(
          value: viewType,
          child: Row(
            children: [
              Icon(
                _getIconData(viewType.icon),
                size: 20,
                color: viewType == currentViewType
                    ? Theme.of(context).primaryColor
                    : Colors.grey[600],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      viewType.displayName,
                      style: TextStyle(
                        fontWeight: viewType == currentViewType
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: viewType == currentViewType
                            ? Theme.of(context).primaryColor
                            : null,
                      ),
                    ),
                    Text(
                      viewType.description,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              if (viewType == currentViewType)
                Icon(
                  Icons.check,
                  size: 16,
                  color: Theme.of(context).primaryColor,
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'swipe':
        return Icons.swipe;
      case 'list':
        return Icons.list;
      case 'grid_on':
        return Icons.grid_on;
      default:
        return Icons.view_list;
    }
  }
}
