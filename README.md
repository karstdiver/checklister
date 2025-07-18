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

## 📇 License

[MIT License](LICENSE)

---

## 👤 Authors

- Karst Diver & Checklister Dev Team
