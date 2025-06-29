
# Checklister App – Project Plan

## Project Overview

Checklister is a mobile checklist application developed using **Flutter (Level 3 Clean Architecture)**. The app allows users to build, manage, and interactively execute visual checklists, supporting swipe gestures, attached photos, and Firebase-backed cloud synchronization. Future enhancements include voice activation, AI-powered checklist assistance, and deployment to iOS and Android platforms.

---

## 1. Objectives

- ✅ Enable users to create, view, and manage personalized checklists.
- ✅ Allow users to attach images or photos to individual checklist items.
- ✅ Support intuitive gesture-based navigation using swipe controls.
- ✅ Store and sync checklist data securely via Firebase Firestore and Firebase Storage.
- ✅ Authenticate users using Firebase Auth (Google/email).
- 🚀 Future: Voice-activated checklist navigation and item interaction.
- 🚀 Future: AI integration to suggest checklist templates or actions. Use AI APIs to recommend checklist items and pre-fill templates based on user history and context.
- 🚀 Future: Deployment to the Apple App Store and Google Play Store.
- 🚀 Future: Gain FAA certification for experiement and certified aircraft.

---

## 2. Technology Stack

| Layer            | Technology                         |
|------------------|-------------------------------------|
| UI Framework     | Flutter (Level 3 Clean Architecture)|
| Backend Services | Firebase Firestore, Storage, Auth   |
| Voice Input      | speech_to_text, flutter_tts         |
| CI/CD (Future)   | fastlane, GitHub Actions            |
| AI (Future)      | OpenAI API, Gemini, or local ML models |

---

## 3. Flutter App Directory Structure

### 3.1 Source Directory Model (Level 4)

```
lib/
├── core/            # Cross-cutting concerns (errors, utils, constants)
├── features/        # Self-contained feature modules
│   └── checklist/
│       ├── data/
│       ├── domain/
│       └── presentation/
├── shared/          # Reusable widgets, theming, localization
└── main.dart        # App entry point
```

### 3.2 Assets and Configuration

```
assets/
├── images/
├── icons/
└── fonts/

config/
├── firebase/
└── environments/
```

---

## 4. Key UI Screens and Interaction

- **Login Screen**: Background branding, login controls, forgot password, and an "About" overlay.
- **Home Screen**: List of user checklists with a “New Checklist” button.
- **Checklist Item Screen**: Displays item image and allows directional swiping:
  - Left: Check and continue
  - Right: Review previous item
  - Up: Skip item
  - Down: Manage item (edit/delete)

---

## 5. Testing Plan

| Type              | Tools & Packages                  |
|-------------------|-----------------------------------|
| Unit & Widget     | `flutter_test`                    |
| Mocking           | `mocktail`                        |
| Integration Tests | `integration_test`, Firebase Emulators |
| Golden Tests      | `golden_toolkit`                  |

---

## 6. Logging and Monitoring

- `logger` and `print()` used during development.
- Errors reported via global Flutter error handlers.
- Future integration: Cloud-based logging for production telemetry.

---

## 7. Localization Strategy

- Uses `flutter_localizations`, `flutter_gen`, `easy_localization`.
- Language assets stored in `lib/shared/localization/`.
- Supports `.arb` files, default language: English.

---

## 8. App Icon Vision

- A bold **“C”** superimposed with a checkmark or encircling a checkmark.
- Designed to reinforce identity and checklist utility visually.

---

## 9. Voice and AI Integration (Planned)

- Voice commands for checklist traversal (via `speech_to_text` and `flutter_tts`).
- AI service for pre-building checklist templates and predicting next actions.
- API candidates: OpenAI, Gemini, HuggingFace hosted models.

---

## 10. CI/CD Plan (Planned)

- Use **GitHub Actions** to run tests and builds on push/PR.
- Use **fastlane** for code signing and Play Store/App Store deployment.
- Optional: Firebase App Distribution for beta testing.

---

## 11. Deployment Targets

- ✅ Android (via Play Store)
- ✅ iOS (via Apple App Store)
- 🔄 Web (experimental)
- ✅ Local dev via emulators

---

## 12. Security & Privacy

- Firebase Auth enforces identity verification.
- Cloud Storage secured per user.
- Image uploads validated and sanitized.
- Future: Consent-based telemetry and privacy policy integration.

---

## 13. Non-Functional Requirements

- Fast startup time (≤2s on modern devices)
- Swipe actions must complete under 200ms
- Persistent offline caching of last-used checklist
- Accessibility: large fonts, voice feedback (planned)
- Dark mode support
- Consideration for energy usage of the app and related frontend and backend to eliminate excessive energy usage. Make the app environmentally 'green.'

---

## 14. SNOBOL-Inspired Concepts in Checklist Editing

The Checklister app draws inspiration from the SNOBOL programming language, specifically in how it models checklist editing and session management. Just as SNOBOL treats strings as symbolic, dynamic data structures, Checklister treats checklists as navigable token streams. Items are "matched" and "transformed" via gestures and session state, allowing fluid control, review, and backtracking during checklist execution. This abstraction supports both linear and non-linear checklist flows and aligns with the app's vision for symbolic and contextual interaction.

---


## 15. Checklister App Widget Tree

This document outlines the high-level widget structure for the Checklister Flutter app following Level 3/4 Clean Architecture.

### 15.1  Widget Hierarchy

```
ChecklisterApp (MaterialApp)
├── EasyLocalization
│   └── MaterialApp
│       ├── Theme / Routes / Localization
│       └── Initial Route: SplashScreen
│
├── SplashScreen
│   └── FutureBuilder (checks auth status)
│       ├── Logged in → HomeScreen
│       └── Not logged in → LoginScreen
│
├── LoginScreen
│   ├── Logo (Checklister Icon)
│   ├── TextFields (Email/Password)
│   ├── Login Button
│   ├── Forgot Password
│   └── About Button → AboutDialog
│
├── HomeScreen
│   ├── AppBar
│   ├── ListView (User's Checklists)
│   │   └── ChecklistCard (title, preview image)
│   └── FloatingActionButton (New Checklist)
│
├── ChecklistScreen (Checklist Playback Mode)
│   ├── Image (per item or default)
│   ├── Overlay: Hamburger Menu
│   │   ├── Check / Uncheck
│   │   ├── Edit / Delete
│   │   └── Add Image
│   ├── Swipe Detectors
│   │   ├── Left → Mark as Seen
│   │   ├── Right → Review Seen Items
│   │   └── Up → Mark as Ignored
│   └── Navigation Indicator (Progress dots or count)
│
├── ChecklistEditorScreen (New/Edit)
│   ├── Form Fields (Item Text, Image)
│   └── Save / Cancel Buttons
│
└── EndOfChecklistScreen
    ├── Summary View
    ├── Save or Share Results
    └── Return to Home
```

### 15.2 Optional Advanced Widgets (Future)

- **VoiceActivationOverlay** – listens for “next”, “back”, “skip” commands
- **ChecklistSessionRecorder** – tracks time, skips, errors
- **ChecklistStatsPanel** – per-session performance visualization

### 15.3 Riverpod Integration

State and providers managed via Riverpod:

```dart
class HomeScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checklists = ref.watch(userChecklistsProvider);
    // ...
  }
}
```
---

## Appendix

- [Flutter Clean Architecture Guide](https://medium.com/flutter-community/flutter-clean-architecture-2eeb5aa651d5)
- [Firebase Flutter Docs](https://firebase.flutter.dev/)
- [Voice Plugin: speech_to_text](https://pub.dev/packages/speech_to_text)
