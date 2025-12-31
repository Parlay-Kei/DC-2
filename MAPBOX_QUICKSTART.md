# Mapbox Quick Start Guide - DC-2

## Get Mapbox Access Token

1. Go to https://account.mapbox.com/access-tokens/
2. Sign in or create account
3. Copy your default public token (starts with `pk.`)

## Run the App

```bash
# Navigate to DC-2 directory
cd C:\Dev\DC-2

# Install dependencies (if not done already)
flutter pub get

# Run with Mapbox token
flutter run --dart-define=MAPBOX_ACCESS_TOKEN=pk.your.actual.token.here
```

## Test the Map

1. Launch app on emulator/device
2. Log in as a customer
3. Navigate to "Nearby Map" screen
4. You should see:
   - Dark Mapbox map
   - Las Vegas centered by default
   - Nearby barbers loaded from Edge Functions
   - Bottom carousel with barber cards
   - Search and location controls

## Troubleshooting

### "Mapbox Not Configured" message
- You forgot to pass the `--dart-define` flag
- Run: `flutter run --dart-define=MAPBOX_ACCESS_TOKEN=pk.your.token`

### No barbers showing
- Check network connection
- Verify Edge Functions are accessible: https://dskpfnjbgocieoqyiznf.supabase.co/functions/v1/map-shops-bbox?bbox=-116,35,-114,37&limit=10
- Check Flutter console for error messages

### Map doesn't load
- Verify Mapbox token is valid (starts with `pk.`)
- Check if token has been revoked or expired
- Ensure you're using public token, not secret token

### Compilation errors
- Run `flutter clean && flutter pub get`
- Verify Flutter version: `flutter --version` (should be 3.0.0+)
- Run `flutter analyze` to check for issues

## VS Code Launch Configuration

Add to `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "DC-2 with Mapbox",
      "request": "launch",
      "type": "dart",
      "program": "lib/main.dart",
      "args": [
        "--dart-define=MAPBOX_ACCESS_TOKEN=pk.eyJ1IjoieW91ci11c2VybmFtZSIsImEiOiJ5b3VyLXRva2VuIn0.your-signature"
      ]
    }
  ]
}
```

Replace the token with your actual Mapbox public token.

## Features to Test

- ✅ Map loads with dark theme
- ✅ Barbers appear as pins
- ✅ Shop pins (red border) vs Mobile pins (green border)
- ✅ Bottom carousel shows barber cards
- ✅ Tap card to view barber profile
- ✅ Search location (geocoding autocomplete)
- ✅ Use current location button
- ✅ Radius filter pills (10/25/50/100 mi)
- ✅ Zoom controls (+/-)
- ✅ Auto-fit bounds to show all barbers
- ✅ Barber count badge

## Next Steps

1. Add custom pin icon assets
2. Wire up category filtering
3. Add pin tap handling
4. Test with production barber data
5. Performance testing with 100+ barbers
6. Add offline map caching (optional)
