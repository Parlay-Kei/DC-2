# DC-2
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

# Generate models
dart run build_runner build --delete-conflicting-outputs

# Run on device
flutter run
```

## Project Structure
```
lib/
├── config/       # App configuration
├── models/       # Data classes (Freezed)
├── providers/    # Riverpod providers
├── services/     # API/backend services
├── screens/      # Full-page views
├── widgets/      # Reusable components
└── utils/        # Helpers, constants
```

## Related

- [DC-1 (React PWA)](https://github.com/YOUR_USERNAME/Direct-Cuts) — Production web app
- [Notion Project](https://notion.so/2c213b428aa78136b676eddb36cd7d54) — Development tracker
