# Direct Cuts - Mobile Release Build Guide

This guide covers building production-ready Android and iOS releases for the Direct Cuts mobile application.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Environment Setup](#environment-setup)
3. [Android Build](#android-build)
4. [iOS Build](#ios-build)
5. [Version Management](#version-management)
6. [CI/CD Integration](#cicd-integration)
7. [Troubleshooting](#troubleshooting)
8. [Security Best Practices](#security-best-practices)

---

## Prerequisites

### General Requirements

- Flutter SDK 3.0.0 or later
- Git (for version tracking)
- Access to required API credentials

### Android Requirements

- Java JDK 17 or later
- Android SDK with build-tools
- Android Studio (recommended for SDK management)

### iOS Requirements (macOS only)

- macOS 12.0 or later
- Xcode 15.0 or later
- CocoaPods
- Valid Apple Developer account
- Apple Team ID

### Required Environment Variables

The following environment variables **MUST** be set before building:

| Variable | Description | Required |
|----------|-------------|----------|
| `ONESIGNAL_APP_ID` | OneSignal App ID for push notifications | **Yes** |
| `MAPBOX_ACCESS_TOKEN` | Mapbox access token for maps | **Yes** |

Optional variables for CI/CD:

| Variable | Description | Default |
|----------|-------------|---------|
| `ANDROID_KEYSTORE_PATH` | Path to Android keystore | `android/app/release.keystore` |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password | From `key.properties` |
| `ANDROID_KEY_ALIAS` | Key alias | From `key.properties` |
| `ANDROID_KEY_PASSWORD` | Key password | From `key.properties` |
| `APPLE_TEAM_ID` | Apple Developer Team ID | Automatic |

---

## Environment Setup

### 1. Set Required Environment Variables

#### Linux/macOS (bash/zsh)

Add to your `~/.bashrc`, `~/.zshrc`, or `~/.profile`:

```bash
# Direct Cuts Build Environment
export ONESIGNAL_APP_ID="your-onesignal-app-id"
export MAPBOX_ACCESS_TOKEN="sk.your-mapbox-token"
```

Then reload:
```bash
source ~/.bashrc  # or ~/.zshrc
```

#### Windows (PowerShell)

```powershell
# Set for current session
$env:ONESIGNAL_APP_ID = "your-onesignal-app-id"
$env:MAPBOX_ACCESS_TOKEN = "sk.your-mapbox-token"

# Or set permanently (run as Administrator)
[Environment]::SetEnvironmentVariable("ONESIGNAL_APP_ID", "your-app-id", "User")
[Environment]::SetEnvironmentVariable("MAPBOX_ACCESS_TOKEN", "your-token", "User")
```

#### Windows (Command Prompt)

```cmd
set ONESIGNAL_APP_ID=your-onesignal-app-id
set MAPBOX_ACCESS_TOKEN=sk.your-mapbox-token
```

### 2. Verify Flutter Installation

```bash
flutter doctor -v
```

Ensure all checkmarks are green for your target platform(s).

### 3. Get Dependencies

```bash
cd /path/to/DC-2
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## Android Build

### First-Time Setup: Create Production Keystore

**IMPORTANT**: You only need to do this once. The keystore is your app's identity on Google Play.

```bash
./scripts/mobile/create_keystore.sh
```

This script will:
1. Generate a new production keystore
2. Create `android/key.properties` with signing configuration
3. Update `.gitignore` to exclude sensitive files

**CRITICAL**:
- Back up your keystore file and passwords immediately
- Store in multiple secure locations (password manager, encrypted backup)
- If you lose the keystore, you cannot update your app on Google Play

### Build Android Release

```bash
./scripts/mobile/build_android.sh
```

#### Build Options

| Option | Description |
|--------|-------------|
| `--apk-only` | Build only APK (skip AAB) |
| `--aab-only` | Build only AAB (skip APK) |
| `--skip-clean` | Skip `flutter clean` step |
| `--skip-tests` | Skip running tests |
| `--verbose` | Enable verbose output |

#### Examples

```bash
# Full build (APK + AAB)
./scripts/mobile/build_android.sh

# Quick APK for testing
./scripts/mobile/build_android.sh --apk-only --skip-tests

# AAB only for Play Store
./scripts/mobile/build_android.sh --aab-only
```

### Build Artifacts

After a successful build, artifacts are located at:

```
artifacts/mobile/<version>/android/
├── direct-cuts-<version>.aab    # App Bundle for Play Store
├── direct-cuts-<version>.apk    # APK for direct installation
├── checksums.sha256             # SHA-256 checksums
└── build-manifest.json          # Build metadata
```

### Install APK for Testing

```bash
adb install artifacts/mobile/2.0.0/android/direct-cuts-2.0.0.apk
```

---

## iOS Build

### Prerequisites

iOS builds require macOS with Xcode 15+.

### First-Time Setup

1. **Configure Apple Developer Account**
   - Sign in to Xcode with your Apple ID
   - Ensure you have an active Apple Developer Program membership

2. **Update Team ID**

   Edit `ios/ExportOptions.plist` and replace `TEAM_ID_PLACEHOLDER` with your Team ID:
   ```xml
   <key>teamID</key>
   <string>YOUR_TEAM_ID</string>
   ```

   To find your Team ID:
   - Go to https://developer.apple.com/account
   - Click "Membership"
   - Copy your Team ID

3. **Update Bundle Identifier**

   The bundle ID should be `com.directcuts.app`. Verify in:
   - `ios/Runner.xcodeproj/project.pbxproj`
   - Xcode project settings

### Build iOS Release

```bash
./scripts/mobile/build_ios.sh
```

#### Build Options

| Option | Description |
|--------|-------------|
| `--no-codesign` | Build without code signing (for CI) |
| `--export-method METHOD` | Export method: app-store, ad-hoc, development |
| `--skip-clean` | Skip flutter clean step |
| `--skip-tests` | Skip running tests |
| `--verbose` | Enable verbose output |

#### Examples

```bash
# Full signed build for App Store
./scripts/mobile/build_ios.sh

# Build without signing (for CI validation)
./scripts/mobile/build_ios.sh --no-codesign

# Ad-hoc build for internal testing
./scripts/mobile/build_ios.sh --export-method ad-hoc
```

### Build Artifacts

```
artifacts/mobile/<version>/ios/
├── DirectCuts-<version>.ipa     # IPA for distribution
├── checksums.sha256             # SHA-256 checksums
└── build-manifest.json          # Build metadata
```

### Upload to App Store Connect

#### Using Transporter (GUI)

1. Download [Transporter](https://apps.apple.com/app/transporter/id1450874784) from Mac App Store
2. Sign in with your Apple ID
3. Drag and drop the IPA file
4. Click "Deliver"

#### Using Command Line

```bash
xcrun altool --upload-app \
  --type ios \
  --file artifacts/mobile/2.0.0/ios/DirectCuts-2.0.0.ipa \
  --username "your-apple-id@email.com" \
  --password "@keychain:AC_PASSWORD"
```

---

## Version Management

### Semantic Versioning

The app uses semantic versioning: `MAJOR.MINOR.PATCH+BUILD`

- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes (backward compatible)
- **BUILD**: Auto-generated from git commit count

### Bump Version

```bash
# Patch release (2.0.0 -> 2.0.1)
./scripts/mobile/bump_version.sh patch

# Minor release (2.0.1 -> 2.1.0)
./scripts/mobile/bump_version.sh minor

# Major release (2.1.0 -> 3.0.0)
./scripts/mobile/bump_version.sh major

# Set specific version
./scripts/mobile/bump_version.sh --set 2.5.0

# Bump and create git tag
./scripts/mobile/bump_version.sh patch --tag
```

### Version Locations

Version is updated in:
- `pubspec.yaml` - Main version source
- `lib/config/app_config.dart` - Runtime version constant

---

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Mobile Release Build

on:
  push:
    tags:
      - 'v*.*.*'

jobs:
  build-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          distribution: 'zulu'
          java-version: '17'

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.27.0'
          channel: 'stable'

      - name: Decode Keystore
        run: echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 -d > android/app/release.keystore

      - name: Create key.properties
        run: |
          cat > android/key.properties << EOF
          storePassword=${{ secrets.ANDROID_KEYSTORE_PASSWORD }}
          keyPassword=${{ secrets.ANDROID_KEY_PASSWORD }}
          keyAlias=${{ secrets.ANDROID_KEY_ALIAS }}
          storeFile=release.keystore
          EOF

      - name: Build Android
        env:
          ONESIGNAL_APP_ID: ${{ secrets.ONESIGNAL_APP_ID }}
          MAPBOX_ACCESS_TOKEN: ${{ secrets.MAPBOX_ACCESS_TOKEN }}
        run: ./scripts/mobile/build_android.sh --skip-tests

      - name: Upload Artifacts
        uses: actions/upload-artifact@v4
        with:
          name: android-release
          path: artifacts/mobile/*/android/*

  build-ios:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.27.0'
          channel: 'stable'

      - name: Build iOS (unsigned)
        env:
          ONESIGNAL_APP_ID: ${{ secrets.ONESIGNAL_APP_ID }}
          MAPBOX_ACCESS_TOKEN: ${{ secrets.MAPBOX_ACCESS_TOKEN }}
        run: ./scripts/mobile/build_ios.sh --no-codesign --skip-tests
```

### Required GitHub Secrets

| Secret | Description |
|--------|-------------|
| `ONESIGNAL_APP_ID` | OneSignal App ID |
| `MAPBOX_ACCESS_TOKEN` | Mapbox access token |
| `ANDROID_KEYSTORE_BASE64` | Base64-encoded keystore file |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password |
| `ANDROID_KEY_ALIAS` | Key alias |
| `ANDROID_KEY_PASSWORD` | Key password |

### Encode Keystore for CI

```bash
base64 -i android/app/release.keystore -o keystore.base64.txt
# Copy contents of keystore.base64.txt to GitHub secret
```

---

## Troubleshooting

### Common Issues

#### "ONESIGNAL_APP_ID is NOT SET"

The build script requires the `ONESIGNAL_APP_ID` environment variable.

```bash
export ONESIGNAL_APP_ID="your-app-id-from-onesignal-dashboard"
```

#### "Keystore file not found"

Run the keystore creation script:
```bash
./scripts/mobile/create_keystore.sh
```

#### Gradle Build Failed

1. Clean and rebuild:
   ```bash
   cd android && ./gradlew clean && cd ..
   flutter clean
   flutter pub get
   ```

2. Check Java version:
   ```bash
   java -version  # Should be 17+
   ```

#### iOS Code Signing Issues

1. Verify Xcode is signed in:
   ```
   Xcode > Settings > Accounts
   ```

2. Clean derived data:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```

3. Reset provisioning:
   ```bash
   cd ios && rm -rf Pods Podfile.lock && pod install
   ```

#### CocoaPods Issues

```bash
cd ios
rm -rf Pods Podfile.lock
pod repo update
pod install --repo-update
```

### Build Logs

Build logs are saved in:
- `artifacts/mobile/<version>/android/build-manifest.json`
- `artifacts/mobile/<version>/ios/build-manifest.json`

---

## Security Best Practices

### DO

- Store keystore and passwords in a secure password manager
- Use GitHub Secrets or similar for CI/CD credentials
- Verify checksums before distributing builds
- Keep keystore backups in multiple secure locations
- Rotate API keys periodically

### DON'T

- Commit keystore files to git
- Commit `key.properties` to git
- Share passwords via email or chat
- Store credentials in plain text files
- Use debug signing for production releases

### Files to Never Commit

Ensure these are in `.gitignore`:

```gitignore
# Android signing
*.keystore
*.jks
android/key.properties

# iOS signing (if manual)
*.mobileprovision
*.p12

# Environment files
.env
.env.local
.env.production
```

---

## Quick Reference

### Full Release Workflow

```bash
# 1. Set environment variables
export ONESIGNAL_APP_ID="your-app-id"
export MAPBOX_ACCESS_TOKEN="your-token"

# 2. Bump version
./scripts/mobile/bump_version.sh patch --tag

# 3. Build Android
./scripts/mobile/build_android.sh

# 4. Build iOS (on Mac)
./scripts/mobile/build_ios.sh

# 5. Verify artifacts
ls -la artifacts/mobile/*/

# 6. Verify checksums
cat artifacts/mobile/*/android/checksums.sha256
cat artifacts/mobile/*/ios/checksums.sha256
```

### Script Locations

| Script | Purpose |
|--------|---------|
| `scripts/mobile/build_android.sh` | Build Android APK/AAB |
| `scripts/mobile/build_ios.sh` | Build iOS IPA |
| `scripts/mobile/create_keystore.sh` | Generate Android keystore |
| `scripts/mobile/bump_version.sh` | Manage version numbers |

### Artifact Locations

```
artifacts/mobile/
└── <version>/
    ├── android/
    │   ├── direct-cuts-<version>.aab
    │   ├── direct-cuts-<version>.apk
    │   ├── checksums.sha256
    │   └── build-manifest.json
    └── ios/
        ├── DirectCuts-<version>.ipa
        ├── checksums.sha256
        └── build-manifest.json
```

---

## Support

For build issues:
1. Check this troubleshooting guide
2. Review build logs in `artifacts/` directory
3. Check Flutter doctor: `flutter doctor -v`
4. Contact the development team

---

*Last updated: December 2025*
*Direct Cuts v2.0.0*
