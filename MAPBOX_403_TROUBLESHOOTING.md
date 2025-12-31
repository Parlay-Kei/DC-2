# Mapbox 403 Forbidden Error - Troubleshooting Guide

## Current Status
- ✅ Token is recognized (length: 96)
- ✅ Token is initialized in code
- ✅ Map style loads successfully
- ❌ Tile loading returns 403 Forbidden

## Root Cause
The token in your Mapbox Dashboard likely still has **URL restrictions** configured, which blocks mobile app requests.

## Step-by-Step Fix

### 1. Verify Token in Mapbox Dashboard

1. Go to [Mapbox Account → Access Tokens](https://account.mapbox.com/access-tokens/)
2. Find your token: `sk.eyJ1IjoicG93ZXJvZnN0ZXZlIiwiYSI6ImNtamxlaXFzbjI5N2ozZ3EyeWR3dG04NXkifQ.60ljdk1cvjsM7S2CtIqzYQ`
3. Click on the token to edit it

### 2. Check URL Restrictions

**CRITICAL:** The "URL restrictions" field must be **COMPLETELY EMPTY** for mobile apps.

- ❌ **WRONG:** Any URL listed (even `*` or `localhost`)
- ✅ **CORRECT:** Field is completely empty/blank

### 3. Verify Token Scopes

Ensure the token has these scopes:
- ✅ `styles:read`
- ✅ `fonts:read`
- ✅ `tiles:read`

### 4. Save Changes

After removing URL restrictions, click "Save" or "Update token"

### 5. Rebuild App

After updating the token in Mapbox Dashboard:

```powershell
cd C:\Dev\DC-2
flutter clean
flutter run
```

## Alternative: Create a Fresh Token

If editing doesn't work, create a completely new token:

1. Go to [Mapbox Account → Access Tokens](https://account.mapbox.com/access-tokens/)
2. Click "Create a token"
3. **Token Name:** `Direct Cuts Mobile (Flutter) - No Restrictions`
4. **Token Type:** Will become Secret (`sk.*`) when you add `tiles:read`
5. **Scopes:**
   - ✅ `styles:read`
   - ✅ `fonts:read`
   - ✅ `tiles:read`
6. **URL Restrictions:** **LEAVE COMPLETELY EMPTY** ⚠️
7. Click "Create token"
8. Copy the new token
9. Update `strings.xml` and `app_config.dart` with the new token
10. Rebuild app

## Verification Checklist

After fixing, verify:
- [ ] Token has NO URL restrictions in Mapbox Dashboard
- [ ] Token has `tiles:read` scope
- [ ] Token is updated in `strings.xml`
- [ ] Token is updated in `app_config.dart` (fallback)
- [ ] App is rebuilt (not just hot reload)
- [ ] No 403 errors in logs

## Why This Happens

Mobile apps don't have URLs - they make direct API calls. When Mapbox sees a request from a mobile app with a token that has URL restrictions, it rejects the request because there's no matching URL.

## Still Not Working?

If you've verified all the above and still get 403 errors:

1. **Check token usage in Mapbox Dashboard:**
   - Go to token details
   - Check if there are any usage errors or warnings

2. **Test token directly:**
   ```bash
   curl "https://api.mapbox.com/styles/v1/mapbox/streets-v12?access_token=YOUR_TOKEN"
   ```
   Should return 200, not 403

3. **Verify token isn't expired:**
   - Check token creation date
   - Tokens don't expire, but check for any account issues

4. **Check Mapbox account status:**
   - Ensure account is active
   - Check for any billing or usage limit issues













