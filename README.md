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

### 🔄 In Progress
- 

### 📋 Pending
- **Checklist JSON Import/Export**: Design and implement checklist JSON import/export, including defining the file format and UI
- **Public Checklist Sharing**: Implement public checklist sharing, including backend and UI for sharing and browsing
- **Upgrade Flow**: Design and implement the upgrade flow and capabilities (e.g., premium features, privilege gating)
- **Documentation**: Write and update help, developer, and user documentation
- **Release Candidate**: Produce a deployable release candidate after all features are tested and documented
- **Multi-Session Guarded**: Plan and implement multiple concurrent checklist sessions as a privilege-guarded feature
- **Firebase Costs & Cleanup**: Estimate and monitor Firebase costs for new features (multi-session, audit logs, etc.), and implement cleanup strategies (TTL, Cloud Functions)
- **Anonymous TTL Cascade**: Add TTL to anonymous user documents and related data, and set up cascading deletion (Cloud Function or TTL on related collections)

---

## 📇 License

[MIT License](LICENSE)

---

## 👤 Authors

- Karst Diver & Checklister Dev Team
