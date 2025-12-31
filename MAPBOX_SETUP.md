# Mapbox Configuration for Flutter App

## Quick Start

The Flutter app requires a Mapbox access token to display maps. There are three ways to provide it:

### Option 1: Use the Launch Script (Recommended for Development)

```powershell
.\run.ps1
```

This script will:
- Read the token from `.env` file (if it exists)
- Fall back to system environment variable
- Use the default token if neither is found
- Launch Flutter with the token configured

### Option 2: Set Environment Variable

```powershell
$env:MAPBOX_ACCESS_TOKEN = "pk.eyJ1IjoicG93ZXJvZnN0ZXZlIiwiYSI6ImNtamN6cjl0czAxNTkzZXBycWlqYjd1a2MifQ.PjRxOw6ChXZ-aNsXIJIIgA"
flutter run
```

### Option 3: Use --dart-define (For Builds)

```powershell
flutter run --dart-define=MAPBOX_ACCESS_TOKEN=pk.eyJ1IjoicG93ZXJvZnN0ZXZlIiwiYSI6ImNtamN6cjl0czAxNTkzZXBycWlqYjd1a2MifQ.PjRxOw6ChXZ-aNsXIJIIgA
```

## Configuration Priority

The `AppConfig` class checks for the token in this order:
1. `--dart-define=MAPBOX_ACCESS_TOKEN` (highest priority, for builds)
2. System environment variable `MAPBOX_ACCESS_TOKEN` (for development)
3. Empty string (disables Mapbox features)

## Current Token

The default public token is:
```
pk.eyJ1IjoicG93ZXJvZnN0ZXZlIiwiYSI6ImNtamN6cjl0czAxNTkzZXBycWlqYjd1a2MifQ.PjRxOw6ChXZ-aNsXIJIIgA
```

This token is configured for:
- Styles, fonts, and tiles scopes
- URL restrictions for Direct Cuts domains

## Verification

After launching the app, check the logs for:
```
[NearbyMapScreen] Mapbox token length: 96
[NearbyMapScreen] isMapboxConfigured: true
```

If you see `token length: 0` or `isMapboxConfigured: false`, the token is not being read correctly.

## Troubleshooting

**Token length is 0:**
- Check that `.env` file exists and contains `MAPBOX_ACCESS_TOKEN=...`
- Or set the environment variable: `$env:MAPBOX_ACCESS_TOKEN = "your-token"`
- Or use `--dart-define` when running Flutter

**Map still shows "Mapbox Not Configured":**
- Restart the Flutter app after setting the token
- Check that the token is valid in Mapbox Dashboard
- Verify the token has the correct scopes (Styles, Fonts, Tiles)

