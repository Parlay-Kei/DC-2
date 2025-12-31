# Token Rotation Guide

**Last Updated:** 2025-12-31
**Status:** Required before production launch

## Overview

This document provides instructions for rotating exposed API tokens and ensuring secure secret management for Direct Cuts mobile and web applications.

## P0 Security Action: Rotate Exposed Tokens

### Why Rotation is Required

During development, the following tokens may have been exposed in git history or logs:
- Mapbox access tokens (sk.* secret tokens)
- OneSignal App IDs
- Supabase service role keys

**All exposed tokens MUST be rotated before production deployment.**

### Token Rotation Checklist

#### 1. Mapbox Tokens

**Revoke Exposed Tokens:**
1. Log into [Mapbox Dashboard](https://account.mapbox.com/access-tokens/)
2. Find any tokens with `sk.*` prefix that were committed
3. Click the token name → Delete
4. Confirm deletion

**Create New Tokens:**
1. Click "Create a token"
2. For mobile apps:
   - Name: `direct-cuts-mobile-prod`
   - Scopes: Select only required scopes (DOWNLOADS:READ for map tiles)
   - URL restrictions: None for mobile
3. For web apps:
   - Name: `direct-cuts-web-prod`
   - Scopes: Styles, Tilesets, Geocoding as needed
   - URL restrictions: Add production domain(s)
4. Copy the new `pk.*` token (public) - this is safe for client apps

**Update Configuration:**
```bash
# Mobile: Set in CI/CD secrets and local .env
MAPBOX_ACCESS_TOKEN=pk.your-new-token-here

# Web: Update in environment variables
NEXT_PUBLIC_MAPBOX_TOKEN=pk.your-new-token-here
```

#### 2. OneSignal App ID

The OneSignal App ID is not a secret token, but if your REST API Key was exposed:

1. Log into [OneSignal Dashboard](https://app.onesignal.com/)
2. Settings → Keys & IDs
3. Click "Regenerate" next to REST API Key
4. Update CI/CD secrets with new key

#### 3. Supabase Keys

If Supabase service role key was exposed:

1. Log into [Supabase Dashboard](https://supabase.com/dashboard)
2. Project Settings → API
3. Click "Regenerate" for service_role key
4. Update all backend services with new key

**NEVER commit service_role key to git!**

## Build-Time Configuration

### Mobile (Flutter)

Secrets are injected at build time using `--dart-define`:

```bash
# Build with secrets (local development)
flutter run --dart-define=ONESIGNAL_APP_ID=$ONESIGNAL_APP_ID \
            --dart-define=MAPBOX_ACCESS_TOKEN=$MAPBOX_ACCESS_TOKEN

# Production build (CI/CD)
flutter build appbundle --release \
    --dart-define=ONESIGNAL_APP_ID=${{ secrets.ONESIGNAL_APP_ID }} \
    --dart-define=MAPBOX_ACCESS_TOKEN=${{ secrets.MAPBOX_ACCESS_TOKEN }}
```

### Web (Next.js)

Secrets are set via environment variables:

```bash
# .env.local (never committed)
NEXT_PUBLIC_MAPBOX_TOKEN=pk.xxx
NEXT_PUBLIC_ONESIGNAL_APP_ID=xxx-xxx-xxx
SUPABASE_SERVICE_ROLE_KEY=xxx  # Server-side only!
```

## CI/CD Secret Setup

### GitHub Actions

Add these secrets in your repository settings:

| Secret Name | Description | Required For |
|-------------|-------------|--------------|
| `ONESIGNAL_APP_ID` | OneSignal App ID | Push notifications |
| `MAPBOX_ACCESS_TOKEN` | Mapbox public token | Map display |
| `ANDROID_KEYSTORE_BASE64` | Keystore file (base64) | Android signing |
| `ANDROID_KEYSTORE_PASSWORD` | Keystore password | Android signing |
| `ANDROID_KEY_ALIAS` | Key alias | Android signing |
| `ANDROID_KEY_PASSWORD` | Key password | Android signing |
| `MATCH_PASSWORD` | iOS cert encryption | iOS signing |

### Setting Secrets

1. Go to Repository → Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Enter name and value
4. Save

## Verification

After rotation, verify the build works:

```bash
# 1. Check .env is ignored
git check-ignore .env  # Should output ".env"

# 2. Check no secrets in tracked files
git ls-files | xargs grep -l "sk\." || echo "No secret tokens in tracked files"

# 3. Test build with new tokens
export ONESIGNAL_APP_ID=xxx
export MAPBOX_ACCESS_TOKEN=pk.xxx
./scripts/mobile/build_android.sh

# 4. Verify app functionality
adb install artifacts/mobile/*/android/*.apk
# Test maps load, push notifications register
```

## Emergency Token Rotation

If tokens are compromised in production:

1. **Immediately** revoke the compromised token in the provider dashboard
2. Generate new token
3. Update CI/CD secrets
4. Trigger new deployment
5. Monitor for unauthorized usage
6. Review access logs in provider dashboards

## Git History Cleanup (Optional)

To remove secrets from git history entirely:

```bash
# WARNING: This rewrites history - coordinate with team
# Back up the repository first!

# Install git-filter-repo
pip install git-filter-repo

# Remove .env files from history
git filter-repo --path .env --invert-paths

# Force push (requires coordination)
git push origin --force --all
```

**Note:** This requires all team members to re-clone the repository.

## Contact

For security incidents:
- Email: security@direct-cuts.com
- Slack: #security-incidents
