# ✅ Checklister App
# Checklister App  
*Essential truth spoken concisely is true eloquence.*

**Checklister** is a cross-platform Flutter app designed to guide users through checklist-driven tasks. Inspired by aviation-grade checklists, the app provides swipe-based, image-enhanced, and voice-activated interactions to ensure step-by-step execution for any repeatable procedure.

---

## 📱 Features

- 🔐 Secure login using Firebase Authentication
- 📋 Create, edit, and manage multiple checklists
- 🖼️ Add and view images for each checklist item
- 👆 Swipe gestures to navigate checklist items
  - Left: Mark complete
  - Right: Go back
  - Up: Mark intentionally skipped
- ✅ End-of-checklist summary screen
- 🧠 Planned: Voice-activated hands-free checklist control
- 🌐 Localization with `easy_localization`

---

## 💎 Paid Tier (Planned)

The paid-for tier of Checklister will unlock advanced features for professional and compliance-driven users:

- 🗂️ **Session Persistence & Audit Trail:**
  - Retain completed sessions for history, analytics, and regulatory compliance (e.g., FAA audit).
  - Export and review past session data.
- 📊 **Advanced Analytics:**
  - Access detailed usage statistics and performance reports.
- 🛡️ **Priority Support & SLA:**
  - Get faster support and guaranteed uptime for mission-critical use.
- 🏷️ **More to come:**
  - Suggest features you need for your workflow!

*Note: The free tier deletes finished sessions to save storage and improve performance. Paid users will have the option to retain session data as needed.*

---

## 📦 Tech Stack

- **Flutter** with Level 3/4 Clean Architecture
- **State Management**: Riverpod
- **Firebase**: Auth, Firestore, Storage
- **Localization**: `easy_localization`, `flutter_gen`
- **Testing**: `flutter_test`, `mocktail`, `integration_test`, `golden_toolkit`
- **Logging**: `logger`

---

## 📁 Directory Structure (Simplified)

```
lib/
├── core/                # App-wide utilities, constants, and error handling
├── features/
│   ├── auth/            # Login, splash screen, authentication logic
│   ├── checklists/      # Checklist list screen
│   └── items/           # Checklist item view, editor, end-of-checklist screen
├── shared/              # Reusable widgets, themes, localization
└── main.dart            # Entry point
```

---

## 🚀 Getting Started

```bash
flutter pub get
flutter run
```

To run with localization and Firebase:
- Set up `assets/translations/`
- Configure `firebase_options.dart` (use `flutterfire configure`)

---

## 🧪 Testing

```bash
flutter test
flutter test --update-goldens
flutter drive --driver=test_driver/integration_test.dart
```

---

## 🛠️ Development Roadmap & TODOs

### ✅ Completed
- **Sourcetree Installation**: Installed and configured Sourcetree for Git visualization
- **Git Branching Structure**: Set up git-flow with main/develop branches, feature/release/hotfix prefixes, and version tag prefix 'v'
- **Profile Offline Caching**: Create feature branch and plan implementation to avoid checklist-style complexity
- **Anonymous User Upgrade Flow**: Implemented upgrade flow for anonymous user sign-in to email/password (data continuity, UI, and privilege persistence for upgrade only)
- **Camera & Photo Permissions**: Added iOS and Android camera/photo library permissions for item photos
- **Item Thumbnails**: Implemented thumbnail display in session screen list view items
- **Help Screen Content**: Added multiple views FAQ and tips with proper localization
- **Zero Items Dialog**: Added dialog for saving checklists with zero items (Continue/Cancel/Add Item options)
- **Privilege Bar Clickability**: Made privilege level bar clickable with navigation to upgrade encouragement screen
- **Add Item Row**: Added "Add Item" row at bottom of session screen list view
- **Inline Text Editing**: Implemented long press on item rows for inline text editing
- **Quick Add/Template Selector**: Enhanced long press on "Add Item" row with dual-option selector (Quick Add text input vs Quick Template grid)
- **Checklist Import**: Implemented paste import and file picker import functionality with full-screen modal UI, user tier limit enforcement, and proper navigation flow
- **TTL & Cleanup System**: Implemented hybrid TTL cleanup system with app-based cleanup service and Firebase admin scripts for anonymous user cleanup and session management

### 🔄 In Progress
- **Upgrade Flow**: Full privilege level upgrade flow (e.g., free → premium/pro) and related UI/UX polish

### 📋 Pending
- **Checklist Export**: Design and implement checklist JSON export functionality
- **Public Checklist Sharing**: Implement public checklist sharing, including backend and UI for sharing and browsing
- **Documentation**: Write and update help, developer, and user documentation
- **Release Candidate**: Produce a deployable release candidate after all features are tested and documented
- **Multi-Session Guarded**: Plan and implement multiple concurrent checklist sessions as a privilege-guarded feature
- **Firebase Costs & Cleanup**: Monitor Firebase costs for new features (multi-session, audit logs, etc.)
- **Anonymous TTL Cascade**: Monitor and optimize TTL cascade performance for anonymous user cleanup

---

## 🗄️ Data Retention & TTL Policy

To control Firebase costs and comply with privacy best practices, Checklister enforces the following data retention and automatic cleanup (TTL) policies:

| Data Type   | Anonymous Users | Registered (Free) | Paid/Pro Users |
|-------------|----------------|-------------------|---------------|
| **Sessions**    | 7 days after last activity | 30 days | Indefinite |
| **Checklists**  | 7 days after last edit | 90 days | Indefinite |
| **Media (orphaned)** | 7 days | 7 days | 7 days |
| **Logs/Audit Trails** | 90 days | 90 days | 90 days (or as needed) |
| **User Account** | 7 days after inactivity | Until deleted | Until deleted |

**Details:**
- All documents include `createdAt` and `lastActiveAt` timestamps.
- An `expiresAt` field is set for collections using Firestore TTL.
- Orphaned media (not referenced by any checklist/session) are deleted after 7 days.
- When a user is deleted (especially anonymous), all related data is also deleted (cascading delete).
- Paid users retain all data unless they delete it themselves.
- Logs and audit trails are kept for 90 days for all users unless compliance requires otherwise.

These policies help keep storage costs predictable and ensure user data is managed responsibly.

---

## 📇 License

[MIT License](LICENSE)

---

## 👤 Authors

- Karst Diver & Checklister Dev Team
