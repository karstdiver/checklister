# Multi-Checklist Views Implementation Plan

## Overview
Add the capability for users to select different views for each checklist: Swipe View (existing), List View (new), and Matrix View (future). Each checklist will remember its preferred view type.

## Requirements Summary

### UI/UX Requirements
- **Menu Placement:** App bar hamburger menu (⋮)
- **Menu Type:** PopupMenuButton with view options
- **Default View:** Swipe view for new checklists
- **Immediate Switch:** Instant view change when selected

### View Types
1. **Swipe View** (existing): One item per screen, swipe to advance
2. **List View** (new): Scrollable list with checkboxes, similar to Apple Notes
3. **Matrix View** (future): X×Y grid of squares, tap to toggle

### List View Features
- Scrollable list of checklist items
- Each row: Checkbox + item text + hamburger menu (⋮)
- Row hamburger menu: "Edit", "Delete", "Move Up", "Move Down"
- Edit navigation: Navigate to existing item edit screen, then pop back
- Reordering: Move up/down buttons (drag-and-drop for future enhancement)

### Matrix View Features (Future)
- Adaptive grid: 2-4 columns based on screen width
- Each square: Shows item photo or first 2-3 words of text
- Tap to toggle: Check/uncheck with visual overlay
- Responsive: Adapts to screen size and item count

### Persistence Strategy
- **Hive-first:** Save to local storage immediately
- **Firestore sync:** Sync to cloud when online
- **Backward compatibility:** Existing checklists default to swipe view

## Technical Architecture

### Data Model Changes
```dart
enum ChecklistViewType {
  swipe,
  list,
  matrix,
}

class Checklist {
  // ... existing fields
  ChecklistViewType viewType;
  
  // Constructor with default
  Checklist({
    // ... existing parameters
    this.viewType = ChecklistViewType.swipe,
  });
}
```

### View Factory Pattern
```dart
Widget buildChecklistView(Checklist checklist) {
  switch (checklist.viewType) {
    case ChecklistViewType.swipe:
      return SwipeViewWidget(checklist: checklist);
    case ChecklistViewType.list:
      return ListViewWidget(checklist: checklist);
    case ChecklistViewType.matrix:
      return MatrixViewWidget(checklist: checklist);
  }
}
```

### State Management
- Update `viewType` immediately in UI
- Save to Hive first, sync to Firestore when online
- Maintain backward compatibility

## Implementation Phases

### Phase 1: Foundation (Week 1)
1. **Add viewType to Checklist model**
   - Create `ChecklistViewType` enum
   - Update Checklist class with viewType field
   - Update database schema (Hive and Firestore)

2. **Create view factory**
   - Implement view factory pattern
   - Add view selector widget
   - Update checklist screen to use factory

3. **Add hamburger menu to app bar**
   - Add PopupMenuButton to checklist screen app bar
   - Implement view switching logic
   - Add immediate UI feedback

### Phase 2: List View Implementation (Week 2)
4. **Implement list view widget**
   - Create ListViewWidget class
   - Implement scrollable list layout
   - Add checkbox functionality

5. **Add row-level hamburger menus**
   - Add hamburger menu to each list item row
   - Implement "Edit", "Delete", "Move Up", "Move Down" options
   - Connect to existing item edit screen

6. **Implement reordering logic**
   - Add move up/down functionality
   - Update item order in database
   - Handle edge cases (first/last item)

### Phase 3: Matrix View (Future - Week 3)
7. **Implement adaptive grid layout**
   - Create MatrixViewWidget class
   - Implement responsive grid (2-4 columns)
   - Handle different screen sizes

8. **Add tap-to-toggle functionality**
   - Implement tap to check/uncheck
   - Add visual overlay for completion status
   - Handle photo/text display in squares

9. **Optimize matrix view performance**
   - Implement efficient grid rendering
   - Handle large numbers of items
   - Add smooth animations

### Phase 4: Polish and Enhancement (Week 4)
10. **Add drag-and-drop reordering**
    - Implement ReorderableListView for list view
    - Add drag-and-drop animations
    - Update order persistence

11. **Add view transition animations**
    - Smooth transitions between views
    - Loading states and animations
    - Error handling and fallbacks

12. **Performance optimization**
    - Optimize list rendering for large checklists
    - Implement lazy loading if needed
    - Add caching strategies

## Database Schema Changes

### Firestore Document Structure
```json
{
  "id": "checklist_id",
  "title": "Checklist Title",
  "description": "Description",
  "userId": "user_id",
  "items": [...],
  "viewType": "swipe", // New field: "swipe", "list", "matrix"
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  // ... other existing fields
}
```

### Hive Box Structure
```dart
// Update existing Hive box to include viewType
// No migration needed - new checklists will have viewType, old ones default to "swipe"
```

## File Structure Changes

### New Files to Create
```
lib/features/checklists/
├── domain/
│   ├── checklist_view_type.dart          // Enum definition
│   └── checklist_view_factory.dart       // View factory
├── presentation/
│   ├── views/
│   │   ├── swipe_view_widget.dart        // Existing, may need refactoring
│   │   ├── list_view_widget.dart         // New
│   │   └── matrix_view_widget.dart       // New (future)
│   └── widgets/
│       ├── checklist_item_row.dart       // New - reusable list item
│       └── view_selector_menu.dart       // New - hamburger menu
```

### Files to Modify
```
lib/features/checklists/
├── domain/
│   ├── checklist.dart                    // Add viewType field
│   └── checklist_notifier.dart          // Add view switching logic
├── data/
│   └── checklist_repository.dart        // Update save/load methods
└── presentation/
    └── checklist_screen.dart            // Add hamburger menu
```

## Testing Strategy

### Unit Tests
- Checklist model with viewType
- View factory logic
- State management for view switching

### Widget Tests
- List view widget rendering
- Hamburger menu functionality
- View switching behavior

### Integration Tests
- End-to-end view switching
- Persistence across app restarts
- Offline/online sync behavior

## Migration Strategy

### Backward Compatibility
- Existing checklists without viewType default to "swipe"
- No data migration required
- Graceful handling of missing viewType field

### Deployment
- Deploy in phases to minimize risk
- Phase 1: Foundation (no user-facing changes)
- Phase 2: List view (new functionality)
- Phase 3: Matrix view (future enhancement)

## Success Criteria

### Functional Requirements
- [ ] Users can switch between views using hamburger menu
- [ ] Each checklist remembers its preferred view
- [ ] List view shows all items with checkboxes
- [ ] Row-level editing works correctly
- [ ] Reordering works with move up/down buttons
- [ ] View preferences persist across app restarts
- [ ] Offline functionality works correctly

### Performance Requirements
- [ ] View switching is instant (< 100ms)
- [ ] List view handles 100+ items smoothly
- [ ] No memory leaks during view switching
- [ ] Efficient database operations

### UX Requirements
- [ ] Intuitive hamburger menu placement
- [ ] Clear visual feedback for view changes
- [ ] Consistent behavior across platforms
- [ ] Smooth animations and transitions

## Risk Mitigation

### Technical Risks
- **Complex state management:** Use existing Riverpod patterns
- **Performance with large lists:** Implement pagination if needed
- **Database migration:** Use backward-compatible approach

### UX Risks
- **User confusion:** Clear visual indicators and help text
- **Feature discovery:** Consider onboarding for new views
- **Accessibility:** Ensure all views are accessible

## Future Enhancements

### Phase 5: Advanced Features
- Drag-and-drop reordering
- Custom view preferences per user
- View-specific settings (e.g., list view density)
- Export/import with view preferences

### Phase 6: Matrix View Enhancements
- Custom grid layouts
- Item grouping in matrix
- Advanced filtering and sorting

## Notes and Considerations

### Platform Differences
- iOS: Use CupertinoSegmentedControl for future segmented control option
- Android: Use Material Design patterns for consistency
- Cross-platform: Ensure consistent behavior

### Accessibility
- Screen reader support for all views
- Keyboard navigation support
- High contrast mode compatibility

### Performance Considerations
- Lazy loading for large checklists
- Efficient image caching for matrix view
- Memory management for view switching

---

**Last Updated:** [Current Date]
**Version:** 1.0
**Status:** Planning Phase
**Next Review:** After Phase 1 completion 