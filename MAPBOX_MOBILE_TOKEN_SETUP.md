# Mapbox Mobile Token Setup

## Issue: HTTP 403 Forbidden Errors

If you're seeing `HTTP status code 403. Forbidden` errors when loading map tiles in the Flutter app, it's because the token has URL restrictions that don't apply to mobile apps.

## Solution: Create a Mobile-Specific Token

Mobile apps need a token with **NO URL restrictions** because mobile apps don't have URLs - they make direct API calls.

### Steps to Fix

1. **Go to Mapbox Dashboard**
   - Navigate to [Account → Access Tokens](https://account.mapbox.com/access-tokens/)

2. **Create a New Token for Mobile**
   - Click "Create a token"
   - **Token Type:** Will become Secret (`sk.`) when you add `tiles:read` - this is normal and expected!
   - **Token Name:** `Direct Cuts Mobile (Flutter)`
   - **Token Scopes:**
     - ✅ `styles:read` - Read map styles
     - ✅ `fonts:read` - Read fonts  
     - ✅ `tiles:read` - Read map tiles (NOTE: This makes the token secret `sk.` - that's OK!)
   - **URL Restrictions:** **LEAVE EMPTY** (this is critical for mobile!)
   - Click "Create token"
   - **Note:** The token will be a secret token (`sk.`) because `tiles:read` is a secret scope. This is safe for mobile apps as long as it's embedded in the app binary and not exposed via network.

3. **Update AppConfig**
   - Replace the fallback token in `lib/config/app_config.dart` with your new mobile token
   - Or use `--dart-define=MAPBOX_ACCESS_TOKEN=your-mobile-token` when running

### Why This Matters

- **Web tokens** can have URL restrictions (e.g., `https://direct-cuts.vercel.app`)
- **Mobile tokens** must have NO URL restrictions (mobile apps don't have URLs)
- Using a web-restricted token in a mobile app causes 403 Forbidden errors

### Token Security

Even though the mobile token has no URL restrictions and may be a secret token (`sk.*`), it's still safe for mobile apps because:
- It's embedded in the app binary (compiled into the app)
- It's not exposed via network requests to third parties
- It only has read-only scopes (styles, fonts, tiles)
- Mapbox tracks usage per token
- You can revoke it anytime if needed
- **Important:** Never expose secret tokens in web client code or API responses

### Current Token Status

The current token (`pk.eyJ1IjoicG93ZXJvZnN0ZXZlIiwiYSI6ImNtamN6cjl0czAxNTkzZXBycWlqYjd1a2MifQ.PjRxOw6ChXZ-aNsXIJIIgA`) appears to have URL restrictions configured for web use, which is why mobile requests are being rejected.

### Understanding Token Types

- **Public Tokens (`pk.*`):** For web apps with URL restrictions. Scopes: `styles:read`, `fonts:read` (but NOT `tiles:read`)
- **Secret Tokens (`sk.*`):** Required for `tiles:read` scope. Safe for mobile apps when embedded in app binary.
- **For Mobile:** Use a secret token (`sk.*`) with `tiles:read` scope and NO URL restrictions.

### Quick Fix

1. Create a new unrestricted token in Mapbox Dashboard
2. Update the fallback token in `lib/config/app_config.dart` line 58
3. Or set it via: `flutter run --dart-define=MAPBOX_ACCESS_TOKEN=your-new-token`

