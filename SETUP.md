# Direct Cuts Mobile App - Quick Setup Guide

## Prerequisites
- Flutter SDK 3.0+
- Android Studio with Android SDK
- Xcode (for iOS, Mac only)
- OneSignal account (for push notifications)

## Setup Steps

### 1. Clone and Install Dependencies
```bash
cd C:\Dev\DC-2
flutter pub get
```

### 2. Add Icon Assets
Download the generated icons and place in `assets/images/`:
- `app_icon.png` (1024x1024)
- `app_icon_foreground.png` (1024x1024)
- `splash_logo.png` (512x512)

### 3. Configure OneSignal
1. Create account at https://onesignal.com
2. Create new app for iOS/Android
3. Copy your App ID
4. Edit `lib/services/notification_service.dart`
5. Replace `YOUR_ONESIGNAL_APP_ID` with your actual ID

### 4. Configure Supabase
Edit `lib/config/supabase_config.dart`:
```dart
static const String url = 'YOUR_SUPABASE_URL';
static const String anonKey = 'YOUR_SUPABASE_ANON_KEY';
```

### 5. Configure Stripe (Optional)
For payment processing, configure Stripe keys in your environment.

### 6. Generate Assets
```bash
# Generate app icons
dart run flutter_launcher_icons

# Generate splash screen
dart run flutter_native_splash:create
```

### 7. Run the App
```bash
# Debug mode
flutter run

# Release mode
flutter run --release
```

### 8. Build for Release

**Android APK:**
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

**Android App Bundle (for Play Store):**
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

**iOS (Mac only):**
```bash
flutter build ios --release
# Then archive in Xcode
```

## Project Structure
```
lib/
├── config/          # Theme, router, Supabase config
├── models/          # Data models
├── services/        # API services
├── providers/       # Riverpod providers
├── screens/         # UI screens
├── widgets/         # Reusable widgets
├── utils/           # Utilities
└── main.dart        # Entry point
```

## Environment Variables
Create `.env` file (optional):
```
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_ANON_KEY=xxx
ONESIGNAL_APP_ID=xxx
STRIPE_PUBLISHABLE_KEY=xxx
```

## Troubleshooting

### Build Errors
```bash
flutter clean
flutter pub get
```

### Android Gradle Issues
```bash
cd android
./gradlew clean
cd ..
flutter build apk
```

### iOS Pod Issues
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter build ios
```

## Support
- Email: support@directcuts.com
- Docs: https://directcuts.com/docs
