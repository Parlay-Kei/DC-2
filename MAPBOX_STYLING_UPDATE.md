# Mapbox Styling Update - Match DC-1

## Issue
The mobile app map was not rendering like DC-1 (web app) and had a 403 error.

## Root Cause
1. **403 Error**: App was run with the old restricted token instead of the new Default public token
2. **Styling Mismatch**: Map markers and labels didn't match DC-1's visual design

## Changes Made

### 1. Updated Map Marker Styling (`nearby_map_screen.dart`)
- Increased `iconSize` from 1.0 to 1.2 to match DC-1 pin size
- Improved label styling to match DC-1's white badge effect:
  - `textSize`: 11.0 (increased from 10.0)
  - `textHaloWidth`: 4.0 (increased from 3.0 for better badge effect)
  - `textMaxWidth`: 12.0 (increased from 10.0 for longer names)
  - `textOffset`: [0, 2.5] (adjusted spacing to match DC-1)
- Added `textAnchor: TextAnchor.TOP` for proper text positioning

### 2. Map Style
- Already using `mapbox://styles/mapbox/streets-v12` (matches DC-1)
- This provides the light theme with streets that DC-1 uses

## How to Run with Correct Token

**IMPORTANT**: You must use the Default public token (no URL restrictions):

```bash
cd C:\Dev\DC-2
flutter run --dart-define=ONESIGNAL_APP_ID=6e92aa37-54cf-4eb8-9725-3a37bcf46b8f --dart-define=MAPBOX_ACCESS_TOKEN=pk.eyJ1IjoicG93ZXJvZnN0ZXZlIiwiYSI6ImNtamN6M2NmMzAweWkzZW93d29hOXU3ZTQifQ.INwgu_lwjph7zV4pnBRKVw
```

**Note**: The token in the command above is the Default public token with no URL restrictions. This is different from the restricted token that was causing 403 errors.

## Files Updated
- `lib/screens/customer/nearby_map_screen.dart` - Updated marker styling to match DC-1

## Expected Result
- Map should load without 403 errors
- Map style matches DC-1 (light theme with streets)
- Pin markers have better visual styling matching DC-1
- Labels have improved white badge effect matching DC-1

## Next Steps (Optional Improvements)
1. Add custom teardrop pin images (like DC-1) instead of default markers
2. Add user location marker (red dot with white border)
3. Add navigation controls matching DC-1 positioning

