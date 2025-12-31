# URGENT: Mapbox Token Rotation Required

**Date:** 2025-12-31
**Status:** ACTION REQUIRED
**Exposed Token:** `sk.eyJ1IjoicG93ZXJvZnN0ZXZlIiwiYSI6ImNtamxlaXFzbjI5N2ozZ3EyeWR3dG04NXkifQ.60ljdk1cvjsM7S2CtIqzYQ`

## Immediate Actions Required

### 1. Revoke the Exposed Token

1. Go to [Mapbox Console](https://console.mapbox.com/account/access-tokens/)
2. Find the token named similar to "direct-cuts-mobile" or with user "powerofsteve"
3. Click on the token → **Delete** or **Revoke**
4. Confirm deletion

### 2. Create New Token with Least Privilege

1. Click **"Create a token"**
2. Configure:
   - **Name:** `direct-cuts-mobile-prod`
   - **Scopes:** Select ONLY what's needed:
     - `styles:tiles` - Read map tiles
     - `styles:read` - Read map styles
     - `fonts:read` - Read fonts (if needed)
   - **URL Restrictions:** Leave empty for mobile (can't restrict mobile apps)
3. Copy the new token (will start with `pk.` for public or `sk.` for secret with tiles)

### 3. Set in GitHub Secrets

```bash
# Using GitHub CLI
gh secret set MAPBOX_ACCESS_TOKEN --body "pk.your-new-token-here"

# Or via GitHub UI:
# Repository → Settings → Secrets and variables → Actions → New repository secret
# Name: MAPBOX_ACCESS_TOKEN
# Value: pk.your-new-token-here
```

### 4. Set for Local Development

Create `.env` file (already in .gitignore):
```bash
# .env (NEVER commit this file)
MAPBOX_ACCESS_TOKEN=pk.your-new-token-here
```

Or set environment variable:
```bash
# PowerShell
$env:MAPBOX_ACCESS_TOKEN = "pk.your-new-token-here"

# Bash
export MAPBOX_ACCESS_TOKEN="pk.your-new-token-here"
```

### 5. Verify Build Uses --dart-define Only

Production builds inject token at build time:
```bash
flutter build apk --release \
  --dart-define=MAPBOX_ACCESS_TOKEN=$MAPBOX_ACCESS_TOKEN
```

The token is NOT read from any committed file. Verified in `lib/config/app_config.dart`:
- Checks `--dart-define` first
- Falls back to environment variable
- Returns empty string if neither set (no hardcoded fallback)

## Verification Checklist

- [ ] Old token revoked in Mapbox dashboard
- [ ] New token created with minimal scopes
- [ ] Token set in GitHub Secrets as `MAPBOX_ACCESS_TOKEN`
- [ ] Local `.env` created with new token (not committed)
- [ ] Build succeeds with `--dart-define`
- [ ] Maps load in app with new token

## Post-Rotation Monitoring

Check Mapbox usage dashboard for:
- Any unauthorized API calls after rotation
- Unexpected geographic patterns
- Unusual request volumes

If suspicious activity detected, rotate again and investigate.
