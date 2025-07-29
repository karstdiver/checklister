# Import/Export Capabilities Feature Design

## Overview
This document outlines the design for implementing import/export capabilities in the Checklister app, including file import, paste functionality, and future AI integration for checklist generation.

## Feature Goals
- Allow users to import checklists from external sources (Notes app, files, etc.)
- Provide paste functionality for quick checklist creation
- Enable AI-powered checklist generation (future feature)
- Create a unified import experience across all sources
- Support export functionality for data portability

## User Experience Design

### Unified Import Dialog
```
┌─────────────────────────────────────────┐
│ Import/Create Checklist                 │
├─────────────────────────────────────────┤
│ [📁 File] [📋 Paste] [🤖 AI Create]     │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │ Source: [File/Paste/AI]             │ │
│ │                                     │ │
│ │ Content/Description:                │ │
│ │ [Input area changes based on mode]  │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ [Preview] [Create] [Cancel]             │
└─────────────────────────────────────────┘
```

### Integration Points
- **Checklist Editor**: Add "Import" option to the title bar menu dropdown
- **Home Screen**: Bulk import option for multiple checklists
- **Settings**: Import/export preferences and history

## Import Sources & Formats

### File-Based Imports
- **Notes App Export**: Text files with bullet points or numbered lists
- **CSV Files**: Standard spreadsheet format for structured data
- **JSON Files**: Structured data from other checklist apps
- **Plain Text Files**: Simple .txt files with various formatting patterns

### Paste Functionality (High Priority)
- **Notes App Workflow**: Copy-paste from Notes rather than file export
- **Web Sources**: Copy checklists from websites, emails, other apps
- **Quick Import**: Faster than file selection for simple lists
- **Universal Compatibility**: Works across all platforms and apps

### AI Integration (Future Feature)
- **Natural Language Description**: "Create a camping trip checklist"
- **Task-Based Requests**: "I need to pack for a 3-day business trip"
- **Template Requests**: "Give me a weekly grocery shopping list"
- **Custom Instructions**: "Create a checklist for moving apartments, focus on kitchen items"

## Format Detection & Parsing

### Common Patterns to Support
1. **Bullet Points**: `• Item`, `- Item`, `* Item`
2. **Numbered Lists**: `1. Item`, `1) Item`
3. **Checkboxes**: `☐ Item`, `[ ] Item`, `□ Item`
4. **Mixed Formats**: Handle combinations gracefully
5. **Indentation**: Respect hierarchical structure
6. **Empty Lines**: Skip or treat as separators

### Smart Parsing Logic
- **Auto-detect format** based on first few lines
- **Fallback parsing** if format isn't recognized
- **Preview mode** showing how items will be imported
- **Validation** with user confirmation for unclear items

## Technical Architecture

### Service Layer Design
```
ImportService
├── FileImporter (CSV, JSON, TXT)
├── TextImporter (Paste functionality)
├── AIImporter (AI generation - future)
└── UnifiedPreview (Common preview logic)
```

### Data Flow
1. **User selects source type** (File/Paste/AI)
2. **Input validation** per source type
3. **Content processing** (parse file, analyze text, call AI)
4. **Unified preview** showing processed items
5. **User confirmation/editing**
6. **Create checklist** with processed items

## Implementation Strategy

### Phase 1: Foundation (Current Focus)
1. **Unified import dialog** with mode switching
2. **File and paste functionality** (easier to implement)
3. **Common preview system** for all sources
4. **Service layer architecture** ready for AI

### Phase 2: AI Integration (Future)
1. **AI service integration** (OpenAI, etc.)
2. **Prompt engineering** for checklist generation
3. **Response parsing** and item extraction
4. **Error handling** and fallbacks

### Phase 3: Advanced Features (Future)
1. **AI suggestions** and templates
2. **Personalization** and learning
3. **Advanced parsing** (hierarchical items, categories)
4. **Export symmetry** (AI can also export in various formats)

## Error Handling & User Experience

### Error Handling
- **Graceful degradation** for unrecognized formats
- **Partial imports** when some items can't be parsed
- **Clear feedback** about what was imported vs. skipped
- **Manual editing** option after import

### Preview Feature
- **Real-time preview** as user types/pastes
- **Format indicators** showing detected patterns
- **Item count** and structure preview
- **Edit before import** capability

## Technical Considerations

### File Picker Integration
- **Cross-platform support** (iOS, Android, Web)
- **Multiple file types** (.txt, .csv, .json)
- **File size limits** for performance
- **Encoding detection** (UTF-8, etc.)

### Paste Handling
- **Clipboard access** with proper permissions
- **Rich text stripping** to get plain text
- **Format preservation** where possible
- **Large text handling** with progress indicators

### AI-Specific Considerations (Future)
- **Character limits** for AI prompts
- **Content filtering** for inappropriate requests
- **Rate limiting** to prevent abuse
- **Fallback handling** when AI is unavailable
- **Privacy considerations** for user data sent to AI services
- **Cost management** for AI API usage

## Integration with Existing Features

### User Limits Integration
- **Creation limits** should apply to imported checklists
- **Item limits** should be enforced during import
- **User tier restrictions** for AI generation (future)

### Localization
- **Import dialog** should be fully localized
- **Error messages** in user's language
- **Format detection** should work with international characters

### Analytics
- **Track usage patterns** for different import methods
- **Monitor success rates** for different formats
- **AI usage analytics** (future)

## Questions for Discussion

### Implementation Priority
1. Should we start with paste functionality (easier) or file import (more comprehensive)?
2. Which formats are most important for your user base? Notes app compatibility seems key.
3. Should users always see a preview, or have a "quick import" option?

### Technical Decisions
4. How strict should the parser be? Should it try to import partial data or fail completely?
5. Should this be part of the checklist editor, or a separate import screen accessible from multiple places?

### AI Integration (Future)
6. Which AI service should we integrate with? (OpenAI, Claude, local models?)
7. Should we use structured prompts (JSON) or natural language with parsing?
8. How should we handle AI API costs? (user limits, admin controls?)
9. Should AI generation be limited by user tier (like the creation limits we just implemented)?

## Files to Create/Modify

### New Files
- `app/lib/core/services/import_service.dart`
- `app/lib/core/services/file_importer.dart`
- `app/lib/core/services/text_importer.dart`
- `app/lib/core/services/ai_importer.dart` (future)
- `app/lib/shared/widgets/import_dialog.dart`
- `app/lib/shared/widgets/import_preview.dart`

### Files to Modify
- `app/lib/features/checklists/presentation/checklist_editor_screen.dart` (add import menu option)
- `app/lib/features/checklists/presentation/home_screen.dart` (add bulk import option)
- `app/assets/translations/en_US.json` (add import-related translations)
- `app/assets/translations/es_ES.json` (add import-related translations)

## Dependencies to Add
- `file_picker` for file selection
- `path_provider` for file handling
- `csv` for CSV parsing
- `http` for AI API calls (future)

## Success Metrics
- **User Adoption**: Percentage of users who use import features
- **Success Rate**: Percentage of successful imports vs. failed attempts
- **Format Support**: Number of different formats successfully imported
- **User Satisfaction**: Feedback on import ease of use
- **AI Usage**: Number of AI-generated checklists (future)

## Notes
- This feature should be designed with the existing creation limits system in mind
- The unified dialog approach will make it easier to add AI functionality later
- Paste functionality is likely to be the most used feature initially
- Consider adding export functionality to complement import capabilities
- The feature should respect user privacy and data handling preferences

## Current Status
- **Branch**: `feature/import-export-capabilities`
- **Phase**: Planning and design
- **Next Steps**: Begin implementation of Phase 1 (Foundation)
- **Dependencies**: Creation limits system already implemented and merged to develop 