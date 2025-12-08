# Direct Cuts v2 (Flutter)

Native mobile application for the Direct Cuts barber booking platform.

## Tech Stack

- **Framework:** Flutter 3.x / Dart
- **State Management:** Riverpod
- **Navigation:** go_router
- **Backend:** Supabase (shared with DC-1)
- **Payments:** Stripe Connect
- **Maps:** Google Maps Flutter

## Getting Started

```bash
# Install dependencies
flutter pub get

# Generate models (if using Freezed)
dart run build_runner build --delete-conflicting-outputs

# Run on device
flutter run
```

## Project Structure

```
lib/
├── main.dart           # App entry point
├── config/             # App configuration
│   ├── router.dart     # go_router setup
│   ├── theme.dart      # DC design system
│   └── supabase_config.dart
├── models/             # Data classes
│   ├── profile.dart
│   ├── barber.dart
│   ├── booking.dart
│   └── service.dart
├── providers/          # Riverpod providers
│   └── auth_provider.dart
├── services/           # API/backend services
├── screens/            # Full-page views
│   ├── auth/
│   ├── customer/
│   └── barber/
├── widgets/            # Reusable components
│   ├── common/
│   ├── forms/
│   └── cards/
└── utils/              # Helpers, constants
```

## Configuration

Before running, update `lib/config/supabase_config.dart` with your Supabase credentials:

```dart
static const String url = 'YOUR_SUPABASE_URL';
static const String anonKey = 'YOUR_ANON_KEY';
```

## Build Commands

```bash
# Android APK
flutter build apk

# Android App Bundle (Play Store)
flutter build appbundle

# iOS
flutter build ios
```

## Related

- [DC-1 (React PWA)](https://github.com/Parlay-Kei/Direct-Cuts) — Production web app
- [Notion Project](https://notion.so/2c213b428aa78136b676eddb36cd7d54) — Development tracker
