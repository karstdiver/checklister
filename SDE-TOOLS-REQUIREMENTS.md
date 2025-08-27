# Checklister SDE Tools Requirements

This document contains the **necessary and sufficient** 3rd party tools required to develop the Checklister Flutter app on a new macOS host computer. This covers the current state of the project (pre-watch companion app).

## Quick Setup Summary

```bash
# 1. Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install core tools
brew install git dart node
brew install --cask cursor android-studio

# 3. Install Flutter SDK
git clone https://github.com/flutter/flutter.git ~/SDKs/flutter
echo 'export PATH="$PATH:$HOME/SDKs/flutter/bin"' >> ~/.zshrc
source ~/.zshrc

# 4. Install Firebase tools
npm install -g firebase-tools
dart pub global activate flutterfire_cli

# 5. Install Xcode from Mac App Store
# 6. Configure Android Studio and SDK
# 7. Run flutter doctor and accept licenses
flutter doctor --android-licenses
```

## Required Tools by Category

### 1. Core Development Tools

#### Git (Version Control)
- **Installation**: `brew install git`
- **Version**: Latest stable
- **Purpose**: Source code version control
- **Verification**: `git --version`

#### Homebrew (Package Manager)
- **Installation**: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
- **Version**: Latest stable
- **Purpose**: macOS package management
- **Verification**: `brew --version`

### 2. Flutter Development Stack

#### Flutter SDK
- **Installation**: 
  ```bash
  git clone https://github.com/flutter/flutter.git ~/SDKs/flutter
  echo 'export PATH="$PATH:$HOME/SDKs/flutter/bin"' >> ~/.zshrc
  source ~/.zshrc
  ```
- **Version**: 3.33.0-1.0.pre.450 (master channel)
- **Purpose**: Cross-platform app development framework
- **Verification**: `flutter --version`

#### Dart SDK
- **Installation**: `brew install dart`
- **Version**: 3.9.0 (build 3.9.0-220.0.dev)
- **Purpose**: Programming language for Flutter
- **Verification**: `dart --version`

#### FlutterFire CLI
- **Installation**: `dart pub global activate flutterfire_cli`
- **Version**: Latest stable
- **Purpose**: Firebase configuration for Flutter
- **Verification**: `flutterfire --version`

### 3. Firebase Development Tools

#### Firebase CLI
- **Installation**: `npm install -g firebase-tools`
- **Version**: 14.9.0
- **Purpose**: Firebase project management and deployment
- **Verification**: `firebase --version`

#### Node.js (for Firebase CLI)
- **Installation**: `brew install node`
- **Version**: Latest LTS
- **Purpose**: Required for Firebase CLI
- **Verification**: `node --version` and `npm --version`

### 4. iOS Development Tools

#### Xcode
- **Installation**: Mac App Store or [developer.apple.com](https://developer.apple.com/xcode/)
- **Version**: Latest stable (15.0+)
- **Purpose**: iOS development, simulators, and app signing
- **Verification**: `xcode-select --print-path`

#### Xcode Command Line Tools
- **Installation**: `xcode-select --install`
- **Purpose**: Command line development tools
- **Verification**: `xcodebuild --version`

#### iOS Simulator
- **Installation**: Via Xcode → Preferences → Components
- **Version**: Latest iOS (17.x)
- **Purpose**: iOS app testing and debugging
- **Verification**: `xcrun simctl list devices`

### 5. Android Development Tools

#### Android Studio
- **Installation**: `brew install --cask android-studio` or [developer.android.com](https://developer.android.com/studio)
- **Version**: Latest stable (2023.1.1+)
- **Purpose**: Android development and emulator management
- **Verification**: Launch Android Studio

#### Android SDK
- **Installation**: Via Android Studio Setup Wizard
- **Version**: API Level 34 (Android 14.0)
- **Purpose**: Android development libraries and tools
- **Path**: `$HOME/Library/Android/sdk`

#### Android Emulator
- **Installation**: Via Android Studio → AVD Manager
- **Version**: API Level 34
- **Purpose**: Android app testing and debugging
- **Verification**: `emulator -list-avds`

### 6. IDE and Code Editor

#### Cursor IDE (Primary)
- **Installation**: `brew install --cask cursor` or [cursor.sh](https://cursor.sh)
- **Version**: Latest stable
- **Purpose**: Primary development environment
- **Verification**: `cursor --version`

#### VS Code (Alternative)
- **Installation**: `brew install --cask visual-studio-code`
- **Version**: Latest stable
- **Purpose**: Alternative development environment
- **Verification**: `code --version`

### 7. Shell and Terminal Tools

#### Zsh (Default macOS Shell)
- **Installation**: Pre-installed on macOS Catalina+
- **Version**: 5.x+
- **Purpose**: Command line interface
- **Verification**: `zsh --version`

#### Oh My Zsh (Optional Enhancement)
- **Installation**: `sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"`
- **Purpose**: Enhanced shell experience
- **Verification**: Check `~/.zshrc` for Oh My Zsh configuration

## Detailed Setup Instructions

### Step 1: System Preparation

```bash
# Update macOS
softwareupdate --all --install --force

# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Add Homebrew to PATH (if not already done)
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
source ~/.zshrc
```

### Step 2: Core Development Tools

```bash
# Install Git
brew install git

# Configure Git
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Install Node.js (for Firebase CLI)
brew install node

# Install Dart
brew install dart
```

### Step 3: Flutter SDK Setup

```bash
# Clone Flutter repository
git clone https://github.com/flutter/flutter.git ~/SDKs/flutter

# Add Flutter to PATH
echo 'export PATH="$PATH:$HOME/SDKs/flutter/bin"' >> ~/.zshrc
source ~/.zshrc

# Verify Flutter installation
flutter --version

# Accept Flutter licenses
flutter doctor --android-licenses

# Enable Flutter platforms
flutter config --enable-web
flutter config --enable-macos-desktop
```

### Step 4: Firebase Tools Setup

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Login to Firebase
firebase login

# Verify installations
firebase --version
flutterfire --version
```

### Step 5: iOS Development Setup

```bash
# Install Xcode from Mac App Store
# Then install command line tools
xcode-select --install

# Accept Xcode licenses
sudo xcodebuild -license accept

# Verify Xcode installation
xcode-select --print-path

# Install iOS Simulator (via Xcode GUI)
# Xcode → Preferences → Components → Download iOS Simulator
```

### Step 6: Android Development Setup

```bash
# Install Android Studio
brew install --cask android-studio

# Launch Android Studio and complete setup wizard
# This will install Android SDK automatically

# Set up Android environment variables
echo 'export ANDROID_HOME="$HOME/Library/Android/sdk"' >> ~/.zshrc
echo 'export PATH="$PATH:$ANDROID_HOME/emulator"' >> ~/.zshrc
echo 'export PATH="$PATH:$ANDROID_HOME/tools"' >> ~/.zshrc
echo 'export PATH="$PATH:$ANDROID_HOME/tools/bin"' >> ~/.zshrc
echo 'export PATH="$PATH:$ANDROID_HOME/platform-tools"' >> ~/.zshrc
source ~/.zshrc

# Create Android Virtual Device (AVD)
# Android Studio → Tools → AVD Manager → Create Virtual Device
# Recommended: Pixel 7 with API Level 34
```

### Step 7: IDE Setup

```bash
# Install Cursor IDE
brew install --cask cursor

# Launch Cursor and install Flutter/Dart extensions
# Extensions to install:
# - Flutter
# - Dart
# - Firebase Explorer
# - GitLens
# - Error Lens
```

### Step 8: Project Setup

```bash
# Clone the repository
git clone https://github.com/karstdiver/checklister.git
cd checklister

# Navigate to Flutter app
cd app

# Install dependencies
flutter pub get

# Configure Firebase
flutterfire configure

# Verify setup
flutter doctor
```

## Environment Variables

Add these to your `~/.zshrc`:

```bash
# Flutter
export PATH="$PATH:$HOME/SDKs/flutter/bin"

# Dart
export PATH="$PATH:/usr/local/bin"

# Android SDK
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$PATH:$ANDROID_HOME/emulator"
export PATH="$PATH:$ANDROID_HOME/tools"
export PATH="$PATH:$ANDROID_HOME/tools/bin"
export PATH="$PATH:$ANDROID_HOME/platform-tools"

# Android Emulator Performance
export ANDROID_EMU_ENABLE_CRASH_REPORTING=1

# iOS Development
export PATH="$PATH:/Applications/Xcode.app/Contents/Developer/usr/bin"
```

## Verification Checklist

After setup, verify everything works:

- [ ] `flutter --version` shows correct version
- [ ] `dart --version` shows correct version
- [ ] `firebase --version` shows correct version
- [ ] `flutter doctor` shows no issues
- [ ] Xcode opens without errors
- [ ] iOS Simulator starts and runs
- [ ] Android Studio opens without errors
- [ ] Android emulator starts and runs
- [ ] `flutter run` works on iOS Simulator
- [ ] `flutter run` works on Android emulator
- [ ] Firebase project is configured
- [ ] Git repository is cloned and working

## Testing Commands

```bash
# Test Flutter setup
flutter doctor -v

# Test iOS setup
flutter run -d ios

# Test Android setup
flutter run -d android

# Test Firebase setup
firebase projects:list

# Test project build
cd app
flutter build ios --no-codesign
flutter build apk
```

## Troubleshooting

### Common Issues

1. **Flutter not found**: Check PATH configuration in `~/.zshrc`
2. **Firebase not found**: Reinstall via `npm install -g firebase-tools`
3. **iOS build issues**: Install Xcode and accept licenses
4. **Android build issues**: Install Android Studio and SDK
5. **Emulator not starting**: Check hardware acceleration settings

### Useful Commands

```bash
# Check Flutter installation
flutter doctor -v

# Clean and rebuild
flutter clean
flutter pub get

# Check Firebase project
firebase projects:list

# Update Flutter
flutter upgrade

# List available devices
flutter devices

# Open iOS Simulator
open -a Simulator

# List iOS simulators
xcrun simctl list devices

# List Android emulators
emulator -list-avds
```

## Project Dependencies

The project uses these key dependencies (from `pubspec.yaml`):

- **Flutter SDK**: ^3.9.0-220.0.dev
- **Firebase**: Core, Auth, Firestore, Storage, Analytics, App Check
- **State Management**: flutter_riverpod ^2.5.1
- **Localization**: easy_localization ^3.0.7+1
- **Image Processing**: image_picker, firebase_storage, flutter_image_compress
- **UI Components**: webview_flutter, animated_text_kit, flutter_markdown
- **Storage**: shared_preferences, hive, file_picker
- **Connectivity**: connectivity_plus
- **Logging**: logger ^2.0.2

## Notes

- This setup was created on macOS
- Flutter is using the master channel (pre-release)
- Firebase project: checklister (configured in Firebase Console)
- Repository: https://github.com/karstdiver/checklister.git
- Xcode version: Latest stable (15.0+)
- iOS Simulator: Latest iOS version (17.x)
- Android Studio version: Latest stable (2023.1.1+)
- Android SDK API Level: 34 (Android 14.0)

## Last Updated

Created: $(date)
Environment: macOS
Flutter Version: 3.33.0-1.0.pre.450
Firebase CLI: 14.9.0
Xcode: Latest stable
Android Studio: Latest stable
