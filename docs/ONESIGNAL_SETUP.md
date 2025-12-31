# Direct Cuts - OneSignal Push Notification Setup

**Project:** Direct Cuts Mobile App (DC-2)
**SDK Version:** onesignal_flutter 5.3.5
**Last Updated:** 2025-12-20

---

## Overview

The DC-2 Flutter mobile app uses OneSignal for push notifications. The integration shares the same OneSignal account as DC-1 (web app), allowing unified notification management across platforms.

## Current Status

| Component | Status |
|-----------|--------|
| SDK Installed | onesignal_flutter ^5.3.5 |
| NotificationService | Configured |
| Environment Config | Via --dart-define |
| Android Config | compileSdkVersion=34, minSdkVersion=23 |
| iOS Podfile | Updated with extension instructions |

---

## Quick Start

### 1. Get Your OneSignal App ID

1. Go to https://onesignal.com and sign up (or use existing account)
2. Create/select "Direct Cuts" app
3. Go to Settings > Keys & IDs
4. Copy the **App ID** (UUID format: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`)

### 2. Run the App with OneSignal

```bash
# Android
flutter run --dart-define=ONESIGNAL_APP_ID=your-app-id-here

# iOS (requires physical device)
flutter run --dart-define=ONESIGNAL_APP_ID=your-app-id-here

# Build APK with OneSignal
flutter build apk --dart-define=ONESIGNAL_APP_ID=your-app-id-here

# Build iOS with OneSignal
flutter build ios --dart-define=ONESIGNAL_APP_ID=your-app-id-here
```

### 3. Enable Debug Mode (Optional)

```bash
flutter run --dart-define=ONESIGNAL_APP_ID=your-app-id --dart-define=DEBUG_MODE=true
```

---

## Step-by-Step Setup

### Step 1: Create OneSignal Account

1. Go to https://onesignal.com and sign up
2. Click "New App/Website"
3. Enter app name: **Direct Cuts**
4. Select platforms: **Google Android** and **Apple iOS**

---

### Step 2: Android Setup (FCM)

#### Get Firebase Credentials:
1. Go to https://console.firebase.google.com
2. Create new project or use existing: **Direct Cuts**
3. Add Android app with package name: `com.directcuts.app`
4. Download `google-services.json`
5. Place it in `C:\Dev\DC-2\android\app\google-services.json`

#### Generate Service Account JSON (Required for FCM V1):
1. In Firebase Console > Project Settings > Service accounts
2. Click "Generate new private key"
3. Download the JSON file (keep it secure!)

#### Configure in OneSignal:
1. In OneSignal dashboard > Settings > Platforms > Google Android
2. Click "Firebase Cloud Messaging API (V1)"
3. Upload your Service Account JSON file
4. Verify Sender ID matches Firebase project
5. Save

---

### Step 3: iOS Setup (APNs)

#### Generate APNs Key:
1. Go to https://developer.apple.com
2. Certificates, Identifiers & Profiles > Keys
3. Create new key with **Apple Push Notifications service (APNs)**
4. Download the `.p8` file (one-time download!)
5. Note your **Key ID** (10 characters) and **Team ID**

#### Configure in OneSignal:
1. In OneSignal dashboard > Settings > Platforms > Apple iOS
2. Upload your `.p8` file
3. Enter Key ID and Team ID
4. Enter Bundle ID: `com.directcuts.app`
5. Save

#### Xcode Configuration:
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner target > Signing & Capabilities
3. Add capabilities:
   - **Push Notifications**
   - **Background Modes** > Remote notifications
   - **App Groups** > `group.com.directcuts.app.onesignal`

#### Notification Service Extension (for rich notifications):
1. File > New > Target > Notification Service Extension
2. Name: `OneSignalNotificationServiceExtension`
3. Language: Objective-C
4. DO NOT click "Activate" when prompted
5. Add App Groups capability (same group ID)
6. Update `ios/Podfile` - uncomment extension target
7. Run `cd ios && pod install && cd ..`

---

### Step 4: Get Your OneSignal App ID

1. In OneSignal dashboard > Settings > Keys & IDs
2. Copy your **OneSignal App ID** (UUID format)

---

### Step 5: Test Push Notifications

#### From OneSignal Dashboard:
1. Go to Messages > New Push
2. Select "Send to Subscribed Users" or "Test Users"
3. Enter title and message
4. Click "Send"

#### From App:
1. Run app on device:
   ```bash
   flutter run --dart-define=ONESIGNAL_APP_ID=your-app-id
   ```
2. Allow notification permission when prompted
3. Check console for:
   ```
   NotificationService: OneSignal + Local notifications ready
   OneSignal initialized with App ID: xxxxxxxx...
   ```
4. Check OneSignal dashboard > Audience for registered device

---

## Configuration Files

### lib/config/app_config.dart

Contains environment configuration:
- `oneSignalAppId`: Set via --dart-define
- `isOneSignalConfigured`: Checks if App ID is set
- `debugMode`: Enable verbose logging

### lib/services/notification_service.dart

Handles:
- OneSignal initialization
- Notification handlers (click, foreground)
- Device token registration with Supabase
- Local notifications fallback
- User tags for segmentation

---

## User Segmentation

Tag users for targeted notifications:

```dart
// After user logs in
await NotificationService.instance.setUserTags({
  'user_type': 'customer', // or 'barber'
  'city': 'las_vegas',
});
```

Then target segments in OneSignal dashboard.

---

## Troubleshooting

### Android:
- Verify FCM credentials in OneSignal Dashboard
- Check device has Google Play Services
- Ensure `compileSdkVersion >= 34`
- Run `flutter clean && flutter pub get`

### iOS:
- Push notifications do NOT work on Simulator - use physical device
- Verify APNs key is uploaded correctly
- Check bundle ID matches
- Verify capabilities in Xcode

### General:
- Check OneSignal dashboard for registered devices
- Enable debug mode: `--dart-define=DEBUG_MODE=true`
- Verify internet connectivity
- Check console for initialization errors

---

## Testing Without OneSignal

If you want to test the app without OneSignal configured:

1. The app will still work - notifications just won't be received
2. Local notifications (reminders) will still work
3. Console shows: "Local notifications only (OneSignal not configured)"

---

## Build Commands

### Development
```bash
flutter run --dart-define=ONESIGNAL_APP_ID=your-app-id --dart-define=DEBUG_MODE=true
```

### Production
```bash
# Android APK
flutter build apk --release --dart-define=ONESIGNAL_APP_ID=your-app-id

# Android App Bundle
flutter build appbundle --release --dart-define=ONESIGNAL_APP_ID=your-app-id

# iOS
flutter build ios --release --dart-define=ONESIGNAL_APP_ID=your-app-id
```

---

## Production Checklist

- [ ] OneSignal account created
- [ ] OneSignal app configured (Android + iOS platforms)
- [ ] Firebase Service Account JSON uploaded to OneSignal
- [ ] APNs .p8 key uploaded to OneSignal
- [ ] google-services.json added to android/app/
- [ ] Xcode capabilities added (Push, Background, App Groups)
- [ ] Notification Service Extension created (optional for rich notifications)
- [ ] Test notification sent successfully
- [ ] User segmentation set up (optional)

---

## Related Documentation

- DC-1 Connection Guide: `docs/DC-1_CONNECTION_GUIDE.md`
- Flutter SDK Ops Skill: `C:\Dev\Direct-Cuts\skills\flutter-sdk-ops\SKILL.md`
- [OneSignal Flutter SDK Docs](https://documentation.onesignal.com/docs/flutter-sdk-setup)
- [OneSignal Dashboard](https://dashboard.onesignal.com)
