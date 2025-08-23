# Release Process Guide

This document outlines the release process for the Checklister app, including how to create releases and what information to include.

## 🏷️ Release Types

- **Release Candidate (RC)**: `v0.9.0-rc1` - Testing releases before production
- **Beta**: `v0.9.0-beta.3` - Early testing releases
- **Production**: `v0.9.0` - Final releases for app stores

## 📝 Release Information Template

### Release Header
```
# Release 0.9.0-rc1

**Release Date:** [Date]  
**Release Type:** [RC/Beta/Production]  
**Target Platforms:** [Android/iOS/Both]  
```

### Release Summary
```
## 🎯 Release Summary
[One paragraph describing what this release accomplishes]
```

### New Features
```
## 🚀 New Features
- [ ] [Feature description]
- [ ] [Feature description]
```

### Technical Improvements
```
## 🔧 Technical Improvements
- [ ] [Improvement description]
- [ ] [Improvement description]
```

### Bug Fixes
```
## 🐛 Bug Fixes
- [ ] [Bug fix description]
- [ ] [Bug fix description]
```

### Platform Status
```
## 📱 Platform Status
- **Android:** Version [x.y.z+build] ([Status])
- **iOS:** Version [x.y.z+build] ([Status])
- **Web:** [Status]
```

### Testing Checklist
```
## 🧪 Testing
- [ ] Android AAB builds successfully
- [ ] iOS IPA builds successfully
- [ ] Both platforms aligned at version [x.y.z+build]
- [ ] Build scripts validate environment correctly
```

### Deployment Checklist
```
## 📋 Deployment Checklist
- [ ] Version updated in pubspec.yaml
- [ ] Both platforms built successfully
- [ ] Builds uploaded to respective stores
- [ ] Documentation updated
- [ ] Git tag created and pushed
```

### Next Steps
```
## 🔄 Next Steps
1. [Next action]
2. [Next action]
3. [Next action]
```

### Metrics (Optional)
```
## 📊 Metrics
- **Build Time:** [Time]
- **AAB Size:** [Size]
- **IPA Size:** [Size]
- **Lines of Code:** [Count]
```

## 🚀 Git Release Process

### Step 1: Prepare Release Information
1. Copy the template above
2. Fill in the specific information for your release
3. Save this as your release notes

### Step 2: Create Git Tag with Release Notes
```bash
git tag -a v0.9.0-rc1 -m "Release Candidate 1: [Brief Description]

## 🚀 What's New
- [Key feature 1]
- [Key feature 2]
- [Key feature 3]

## 📱 Platform Status
- Android: Version [x.y.z+build] ([Status])
- iOS: Version [x.y.z+build] ([Status])

## 🔧 Technical Changes
- [Technical change 1]
- [Technical change 2]

## 📋 Next Steps
1. [Next step 1]
2. [Next step 2]"
```

### Step 3: Push Tag
```bash
git push origin v0.9.0-rc1
```

### Step 4: Enhance GitHub Release (Optional)
1. Go to GitHub → Releases
2. Edit the auto-generated release
3. Add rich formatting, screenshots, or downloads
4. Link to this RELEASE.md file for process documentation

## 📋 Example Release

### Release 0.9.0-rc1

**Release Date:** August 21, 2025  
**Release Type:** Release Candidate  
**Target Platforms:** Android, iOS  

#### 🎯 Release Summary
Complete deployment infrastructure with automated build processes and comprehensive documentation for both Google Play Store and Apple App Store.

#### 🚀 New Features
- [x] iOS build automation script (`scripts/ios-build-script.sh`)
- [x] Unified build script with interactive menu (`scripts/build-release.sh`)
- [x] Comprehensive deployment documentation
- [x] Security improvements for signing files

#### 🔧 Technical Improvements
- [x] Environment validation in build scripts
- [x] Build exploration features (list existing builds)
- [x] Error handling and graceful failures
- [x] Colored output for better UX

#### 📱 Platform Status
- **Android:** Version 0.9.0+4 (Internal Testing)
- **iOS:** Version 0.9.0+4 (Ready for TestFlight)
- **Web:** Active at https://checklister-firebase-dev.web.app

#### 🧪 Testing
- [x] Android AAB builds successfully
- [x] iOS IPA builds successfully
- [x] Both platforms aligned at version 0.9.0+4
- [x] Build scripts validate environment correctly

#### 📋 Deployment Checklist
- [x] Version updated in pubspec.yaml
- [x] Both platforms built successfully
- [x] Builds uploaded to respective stores
- [x] Documentation updated
- [x] Git tag created and pushed

#### 🔄 Next Steps
1. Upload iOS build to App Store Connect
2. Submit for TestFlight review
3. Expand Google Play testing
4. Prepare for production release

#### 📊 Metrics
- **Build Time:** ~30 minutes for both platforms
- **AAB Size:** 53MB
- **IPA Size:** 55MB
- **Lines of Code:** +500 (documentation and scripts)

## 🔄 Version Management

### Version Format
- **Format:** `x.y.z+build_number` (e.g., `0.9.0+4`)
- **x.y.z:** Semantic version (major.minor.patch)
- **build_number:** Incremental build number for store submission

### Version Alignment Process
1. Update `pubspec.yaml` version
2. Use unified build script: `./scripts/build-release.sh`
3. Verify alignment with detailed build listing
4. Upload to stores

### Version History
- **0.9.0+2:** Initial deployment infrastructure
- **0.9.0+3:** iOS encryption compliance
- **0.9.0+4:** Version alignment and unified build script

## 📚 Related Documentation

- **README.md:** Main project documentation
- **CHANGELOG.md:** Technical change log (optional)
- **scripts/build-release.sh:** Unified build automation
- **scripts/ios-build-script.sh:** iOS-specific build automation


