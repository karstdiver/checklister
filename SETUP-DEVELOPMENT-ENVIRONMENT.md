# Checklister Development Environment Setup

This document contains all the steps needed to recreate the development environment for the Checklister Flutter app on a new computer.

## Current Environment Details

### Flutter Setup
- **Flutter Version**: 3.33.0-1.0.pre.450 (master channel)
- **Dart Version**: 3.9.0 (build 3.9.0-220.0.dev)
- **DevTools Version**: 2.48.0-dev.0
- **Flutter Path**: `/Users/rich/SDKs/flutter/bin/flutter`
- **Framework Revision**: 68f39bac27

### Firebase Tools
- **Firebase CLI Version**: 14.9.0
- **Firebase Path**: `/usr/local/bin/firebase`

### Dart
- **Dart Path**: `/usr/local/bin/dart`

## Step-by-Step Setup Instructions

### 1. Install Flutter SDK

```bash
# Clone Flutter repository
git clone https://github.com/flutter/flutter.git ~/SDKs/flutter

# Add Flutter to PATH (add to ~/.zshrc or ~/.bash_profile)
export PATH="$PATH:$HOME/SDKs/flutter/bin"

# Reload shell configuration
source ~/.zshrc  # or source ~/.bash_profile

# Verify installation
flutter --version
```

### 2. Install Dart SDK

```bash
# Install Dart via Homebrew
brew install dart

# Verify installation
dart --version
```

### 3. Install Firebase CLI

```bash
# Install Firebase CLI via npm
npm install -g firebase-tools

# Verify installation
firebase --version
```

### 4. Install FlutterFire CLI

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Verify installation
flutterfire --version
```

### 5. Install Development Tools

```bash
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 6. Shell Setup and Configuration

#### Verify Shell Installation
```bash
# Check current shell
echo $SHELL
# Should show: /bin/zsh (on macOS Catalina+)

# Check shell version
zsh --version
# Should show: zsh 5.x.x (x86_64-apple-darwin...)

# Alternative: Check bash version (if using bash)
bash --version
```

#### Configure Shell Environment
```bash
# Determine your shell configuration file
if [ "$SHELL" = "/bin/zsh" ]; then
    echo "Using zsh - config file: ~/.zshrc"
    CONFIG_FILE="~/.zshrc"
elif [ "$SHELL" = "/bin/bash" ]; then
    echo "Using bash - config file: ~/.bash_profile"
    CONFIG_FILE="~/.bash_profile"
else
    echo "Unknown shell: $SHELL"
    exit 1
fi
```

#### Install Oh My Zsh (Recommended for zsh)
```bash
# Install Oh My Zsh for enhanced zsh experience
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# This will:
# - Install Oh My Zsh
# - Backup your existing ~/.zshrc to ~/.zshrc.pre-oh-my-zsh
# - Create a new ~/.zshrc with Oh My Zsh configuration
```

#### Configure Oh My Zsh (if installed)
```bash
# Edit your ~/.zshrc file
nano ~/.zshrc

# Recommended Oh My Zsh theme for development
ZSH_THEME="agnoster"

# Useful Oh My Zsh plugins for development
plugins=(
    git
    flutter
    dart
    firebase
    zsh-autosuggestions
    zsh-syntax-highlighting
)

# Install additional plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
```

#### Shell Aliases for Development
Add these useful aliases to your shell configuration file:

```bash
# Flutter aliases
alias f='flutter'
alias fr='flutter run'
alias fg='flutter pub get'
alias fc='flutter clean'
alias fd='flutter doctor'
alias fdev='flutter run --debug'
alias frel='flutter run --release'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'
alias gco='git checkout'
alias gcb='git checkout -b'

# Navigation aliases
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias home='cd ~'

# Development aliases
alias c='cursor'
alias vs='code'
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'

# Firebase aliases
alias fb='firebase'
alias fbl='firebase login'
alias fbp='firebase projects:list'
alias fbd='firebase deploy'

# Utility aliases
alias ports='lsof -i -P -n | grep LISTEN'
alias myip='curl http://ipecho.net/plain; echo'
alias weather='curl wttr.in'
```

#### Reload Shell Configuration
```bash
# Reload your shell configuration
source ~/.zshrc  # for zsh
# or
source ~/.bash_profile  # for bash

# Verify environment variables are loaded
echo $PATH
flutter --version
```

#### Shell Customization Tips
```bash
# Enable command history search
# Add to your shell config file:
bindkey '^R' history-incremental-search-backward

# Increase history size
HISTSIZE=10000
SAVEHIST=10000

# Enable command correction
setopt correct

# Enable extended globbing
setopt extendedglob

# Share history between sessions
setopt share_history
```

### 7. Install Xcode and iOS Development Tools

#### Install Xcode
```bash
# Install Xcode from Mac App Store
# Search for "Xcode" in the App Store and install the latest version
# Or download from: https://developer.apple.com/xcode/

# Verify Xcode installation
xcode-select --print-path
# Should show: /Applications/Xcode.app/Contents/Developer

# Install Xcode Command Line Tools (if not already installed)
xcode-select --install
```

#### Xcode Setup Steps
1. **Launch Xcode** for the first time
2. **Complete Initial Setup**:
   - Accept license agreement
   - Install additional components when prompted
   - Wait for all components to download and install

3. **Install iOS Simulator**:
   - Open Xcode
   - Go to `Xcode` → `Preferences` → `Components`
   - Download and install iOS Simulator for your target iOS version
   - Recommended: Install latest iOS version (iOS 17.x)

4. **Configure iOS Development**:
   - Go to `Xcode` → `Preferences` → `Accounts`
   - Add your Apple ID (required for iOS development)
   - Click "Manage Certificates" and create a development certificate

#### Install iOS Simulator Devices
1. **Open Xcode**
2. **Go to Window** → `Devices and Simulators`
3. **Click the "+" button** to add a new simulator
4. **Select Device Type**:
   - Choose "iPhone" category
   - Select "iPhone 15 Pro" (recommended for testing)
   - Click "Next"

5. **Select iOS Version**:
   - Choose the latest iOS version (iOS 17.x)
   - If not downloaded, click "Download" next to it
   - Wait for download to complete
   - Click "Create"

#### Alternative: Install Simulators via Command Line
```bash
# List available simulators
xcrun simctl list devices

# List available runtimes (iOS versions)
xcrun simctl list runtimes

# Create a new simulator
xcrun simctl create "iPhone 15 Pro" "iPhone 15 Pro" "iOS17.0"

# Boot the simulator
xcrun simctl boot "iPhone 15 Pro"

# Open Simulator app
open -a Simulator
```

### 8. Install Android Studio and Android SDK

#### Download and Install Android Studio
```bash
# Download Android Studio from official website
# https://developer.android.com/studio

# Or install via Homebrew (alternative method)
brew install --cask android-studio
```

#### Android Studio Setup Steps
1. **Launch Android Studio** for the first time
2. **Complete Setup Wizard**:
   - Choose "Standard" installation
   - Let it download and install Android SDK
   - Accept all licenses when prompted

3. **Install Flutter and Dart Plugins**:
   - Go to `Android Studio` → `Preferences` → `Plugins`
   - Search for "Flutter" and install it
   - Search for "Dart" and install it
   - Restart Android Studio

4. **Configure Android SDK**:
   - Go to `Android Studio` → `Preferences` → `Appearance & Behavior` → `System Settings` → `Android SDK`
   - Note the Android SDK Location (usually `/Users/username/Library/Android/sdk`)

#### Set Up Android Environment Variables
Add these to your shell configuration file (`~/.zshrc` or `~/.bash_profile`):

```bash
# Android SDK
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$PATH:$ANDROID_HOME/emulator"
export PATH="$PATH:$ANDROID_HOME/tools"
export PATH="$PATH:$ANDROID_HOME/tools/bin"
export PATH="$PATH:$ANDROID_HOME/platform-tools"
```

### 9. Set Up Android Emulators

#### Create Android Virtual Device (AVD)
1. **Open Android Studio**
2. **Go to Tools** → `AVD Manager` (or click the AVD Manager icon)
3. **Click "Create Virtual Device"**
4. **Select Device**:
   - Choose "Phone" category
   - Select "Pixel 7" (recommended for testing)
   - Click "Next"

5. **Select System Image**:
   - Choose "API Level 34" (Android 14.0)
   - If not downloaded, click "Download" next to it
   - Wait for download to complete
   - Click "Next"

6. **Configure AVD**:
   - Name: "Pixel_7_API_34" (or your preferred name)
   - Leave other settings as default
   - Click "Finish"

#### Alternative: Create AVD via Command Line
```bash
# List available Android Virtual Devices
emulator -list-avds

# Create a new AVD (if you prefer command line)
# First, list available system images
sdkmanager --list | grep "system-images"

# Create AVD with specific configuration
avdmanager create avd -n "Pixel_7_API_34" -k "system-images;android-34;google_apis;x86_64"

# Start the emulator
emulator -avd "Pixel_7_API_34"
```

#### Performance Optimization for Emulators
```bash
# Enable hardware acceleration (if available)
# For Intel Macs with Hypervisor.framework
export ANDROID_EMU_ENABLE_CRASH_REPORTING=1

# For better performance, add to your shell config:
export ANDROID_EMU_ENABLE_CRASH_REPORTING=1
export ANDROID_EMU_ENABLE_CRASH_REPORTING=1
```

### 10. Flutter Configuration

```bash
# Accept Flutter licenses
flutter doctor --android-licenses

# Run Flutter doctor to verify setup
flutter doctor

# Enable web support
flutter config --enable-web

# Enable desktop support (optional)
flutter config --enable-macos-desktop
flutter config --enable-windows-desktop
flutter config --enable-linux-desktop
```

### 11. Firebase Project Setup

```bash
# Login to Firebase
firebase login

# Configure Firebase for the project
cd /path/to/checklister/app
flutterfire configure

# This will:
# - Select your Firebase project
# - Configure platforms (iOS, Android, Web)
# - Generate firebase_options.dart
```

### 12. Project Dependencies

```bash
# Navigate to Flutter app directory
cd app

# Install dependencies
flutter pub get

# Verify everything works
flutter run
```

### 13. IDE Setup

#### Install Cursor IDE
```bash
# Download Cursor from official website
# https://cursor.sh/

# Or install via Homebrew (alternative method)
brew install --cask cursor

# Verify installation
cursor --version
```

#### Cursor Setup Steps
1. **Launch Cursor** for the first time
2. **Complete Initial Setup**:
   - Sign in with your account (GitHub, Google, etc.)
   - Choose your preferred theme and settings
   - Install recommended extensions

3. **Install Essential Extensions**:
   - **Flutter** - Flutter support and debugging
   - **Dart** - Dart language support
   - **Firebase Explorer** - Firebase project management
   - **GitLens** - Enhanced Git capabilities
   - **Error Lens** - Inline error display
   - **Auto Rename Tag** - HTML/XML tag renaming
   - **Bracket Pair Colorizer** - Color-coded brackets
   - **Material Icon Theme** - Material Design icons
   - **One Dark Pro** - Popular dark theme (optional)

4. **Configure Cursor for Flutter Development**:
   - Go to `Cursor` → `Preferences` → `Settings`
   - Search for "Flutter" and enable Flutter support
   - Set up your preferred keybindings
   - Configure terminal to use your shell (zsh/bash)

5. **Open the Project**:
   ```bash
   # Navigate to your project
   cd /path/to/checklister
   
   # Open in Cursor
   cursor .
   ```

#### Cursor Configuration for Flutter
```json
// Add to your Cursor settings.json
{
  "editor.formatOnSave": true,
  "editor.formatOnType": true,
  "editor.codeActionsOnSave": {
    "source.fixAll": true,
    "source.organizeImports": true
  },
  "dart.flutterSdkPath": "/Users/rich/SDKs/flutter",
  "dart.lineLength": 80,
  "dart.enableSdkFormatter": true,
  "files.associations": {
    "*.dart": "dart"
  },
  "terminal.integrated.defaultProfile.osx": "zsh"
}
```

#### VS Code Extensions (Alternative to Cursor)
- Flutter
- Dart
- Firebase Explorer
- GitLens
- Error Lens

#### Android Studio Plugins
- Flutter
- Dart

### 14. Environment Variables

Add these to your shell configuration file (`~/.zshrc` or `~/.bash_profile`):

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

### 15. Git Configuration

```bash
# Configure Git (if not already done)
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Clone the repository
git clone https://github.com/karstdiver/checklister.git
cd checklister
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
- [ ] Flutter and Dart plugins are installed in Android Studio
- [ ] Android emulator starts and runs
- [ ] `flutter run` works on iOS Simulator
- [ ] `flutter run` works on Android emulator
- [ ] `flutter run` works on at least one platform
- [ ] Firebase project is configured
- [ ] Git repository is cloned and working

## Testing iOS Setup

```bash
# Check if iOS setup is working
flutter doctor

# Should show:
# ✓ Xcode - develop for iOS and macOS
# ✓ iOS toolchain - develop for iOS devices
# ✓ iOS Simulator - develop for iOS devices

# List available devices
flutter devices

# Should show your iOS Simulator in the list

# Run on iOS Simulator
flutter run -d ios

# Or run on specific simulator
flutter run -d "iPhone 15 Pro"

# Open iOS Simulator manually
open -a Simulator
```

## Testing Android Setup

```bash
# Check if Android setup is working
flutter doctor

# Should show:
# ✓ Android toolchain - develop for Android devices
# ✓ Android Studio (version 2023.1.1)
# ✓ VS Code (version 1.85.1)

# List available devices
flutter devices

# Should show your Android emulator in the list

# Run on Android emulator
flutter run -d android

# Or run on specific emulator
flutter run -d "Pixel_7_API_34"
```

## Troubleshooting

### Common Issues

1. **Flutter not found**: Check PATH configuration
2. **Firebase not found**: Reinstall via npm
3. **iOS build issues**: Install Xcode and accept licenses
4. **Android build issues**: Install Android Studio and SDK
5. **Emulator not starting**: Check hardware acceleration settings
6. **Slow emulator**: Enable hardware acceleration or use physical device

### iOS-Specific Issues

#### iOS Simulator Won't Start
```bash
# Check available simulators
xcrun simctl list devices

# Boot a specific simulator
xcrun simctl boot "iPhone 15 Pro"

# Open Simulator app
open -a Simulator

# Reset all simulators (if having issues)
xcrun simctl erase all
```

#### iOS Build Issues
```bash
# Accept Xcode licenses
sudo xcodebuild -license accept

# Check Xcode installation
xcode-select --print-path

# Reset Xcode command line tools
sudo xcode-select --reset

# Clean iOS build
cd app/ios
rm -rf build/
rm -rf Pods/
pod install
cd ..
flutter clean
flutter pub get
```

#### iOS Certificate Issues
```bash
# Open Xcode and go to Preferences → Accounts
# Add your Apple ID and create a development certificate
# Or use automatic signing in Xcode

# Check certificates
security find-identity -v -p codesigning
```

### Android-Specific Issues

#### Emulator Won't Start
```bash
# Check available AVDs
emulator -list-avds

# Start with verbose logging
emulator -avd "Pixel_7_API_34" -verbose

# Check system requirements
# Ensure you have enough RAM (8GB+ recommended)
# Ensure virtualization is enabled in BIOS
```

#### Slow Emulator Performance
```bash
# Enable hardware acceleration
# For Intel Macs: Use Hypervisor.framework
# For Apple Silicon: Use ARM system images

# Use physical device for better performance
# Enable USB debugging on your Android phone
# Connect via USB and run: flutter run -d android
```

#### SDK License Issues
```bash
# Accept all Android licenses
flutter doctor --android-licenses

# Or manually accept via sdkmanager
sdkmanager --licenses
```

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

# Check iOS devices
flutter devices

# Check Android devices
flutter devices

# Run on specific device
flutter run -d <device-id>

# Open iOS Simulator
open -a Simulator

# List iOS simulators
xcrun simctl list devices

# List Android emulators
emulator -list-avds
```

## Notes

- This setup was created on macOS
- Flutter is using the master channel (pre-release)
- Firebase project: checklister (configured in Firebase Console)
- Repository: https://github.com/karstdiver/checklister.git
- Xcode version: Latest stable (15.0+)
- iOS Simulator: Latest iOS version (17.x)
- Android Studio version: Latest stable (2023.1.1+)
- Android SDK API Level: 34 (Android 14.0)

## TODO: Deployment Tools Setup

### Future Deployment Tools to Research and Configure

#### App Store Deployment
- [ ] **iOS App Store Connect Setup**
  - [ ] Apple Developer Account configuration
  - [ ] App Store Connect app creation
  - [ ] App signing certificates and provisioning profiles
  - [ ] App Store submission process
  - [ ] TestFlight distribution

- [ ] **Google Play Console Setup**
  - [ ] Google Play Developer Account
  - [ ] Play Console app creation
  - [ ] App signing and release management
  - [ ] Google Play submission process
  - [ ] Internal testing and beta distribution

#### Web Deployment
- [ ] **Firebase Hosting**
  - [ ] Firebase Hosting configuration
  - [ ] Custom domain setup
  - [ ] SSL certificate management
  - [ ] CI/CD pipeline for web deployment

- [ ] **Alternative Web Hosting**
  - [ ] Netlify deployment
  - [ ] Vercel deployment
  - [ ] GitHub Pages deployment

#### Desktop Deployment
- [ ] **macOS App Distribution**
  - [ ] macOS app signing
  - [ ] App Store for Mac submission
  - [ ] Direct distribution (DMG files)

- [ ] **Windows App Distribution**
  - [ ] Windows app signing
  - [ ] Microsoft Store submission
  - [ ] Direct distribution (MSI/EXE files)

- [ ] **Linux App Distribution**
  - [ ] Snap package creation
  - [ ] Flatpak package creation
  - [ ] AppImage creation

#### CI/CD Pipeline
- [ ] **GitHub Actions**
  - [ ] Automated testing
  - [ ] Automated building
  - [ ] Automated deployment
  - [ ] Release management

- [ ] **Firebase App Distribution**
  - [ ] Test device management
  - [ ] Beta testing setup
  - [ ] Crash reporting integration

- [ ] **CodePush (for React Native)**
  - [ ] Over-the-air updates
  - [ ] Staging and production environments

#### Monitoring and Analytics
- [ ] **Firebase Analytics**
  - [ ] User behavior tracking
  - [ ] Crash reporting
  - [ ] Performance monitoring

- [ ] **Alternative Analytics**
  - [ ] Google Analytics
  - [ ] Mixpanel
  - [ ] Amplitude

#### Security and Compliance
- [ ] **App Security**
  - [ ] Code obfuscation
  - [ ] API key management
  - [ ] Secure storage implementation

- [ ] **Privacy Compliance**
  - [ ] GDPR compliance
  - [ ] CCPA compliance
  - [ ] Privacy policy implementation

#### Documentation
- [ ] **Deployment Guides**
  - [ ] Step-by-step deployment instructions
  - [ ] Troubleshooting guides
  - [ ] Rollback procedures

- [ ] **User Documentation**
  - [ ] User manual
  - [ ] API documentation
  - [ ] Developer documentation

### Deployment Research Resources
- [Flutter Deployment Documentation](https://docs.flutter.dev/deployment)
- [Firebase Hosting Documentation](https://firebase.google.com/docs/hosting)
- [Apple Developer Documentation](https://developer.apple.com/documentation)
- [Google Play Console Help](https://support.google.com/googleplay/android-developer)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

### Notes for Future Implementation
- Research current best practices for each deployment method
- Consider cost implications of different deployment strategies
- Plan for scalability and maintenance
- Document all deployment processes for team reference
- Set up monitoring and alerting for production deployments

## Last Updated

Created: $(date)
Environment: macOS
Flutter Version: 3.33.0-1.0.pre.450
Firebase CLI: 14.9.0
Xcode: Latest stable
Android Studio: Latest stable 