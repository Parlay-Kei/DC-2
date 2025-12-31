# Direct Cuts - CI/CD Secrets Setup Guide

This guide provides step-by-step instructions for configuring all secrets required for the mobile CI/CD pipelines.

## Table of Contents

1. [Secrets Overview](#secrets-overview)
2. [Android Secrets](#android-secrets)
3. [iOS Secrets](#ios-secrets)
4. [App Configuration Secrets](#app-configuration-secrets)
5. [Adding Secrets to GitHub](#adding-secrets-to-github)
6. [Security Best Practices](#security-best-practices)
7. [Verification Checklist](#verification-checklist)

---

## Secrets Overview

### Required vs Optional

| Secret | Required For | Priority |
|--------|--------------|----------|
| `ANDROID_KEYSTORE_BASE64` | Signed Android builds | P0 |
| `ANDROID_KEYSTORE_PASSWORD` | Signed Android builds | P0 |
| `ANDROID_KEY_ALIAS` | Signed Android builds | P0 |
| `ANDROID_KEY_PASSWORD` | Signed Android builds | P0 |
| `ONESIGNAL_APP_ID` | Push notifications | P1 |
| `MAPBOX_ACCESS_TOKEN` | Map functionality | P1 |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | Play Store deployment | P1 |
| `APP_STORE_CONNECT_API_KEY_ID` | TestFlight deployment | P2 |
| `APP_STORE_CONNECT_API_ISSUER_ID` | TestFlight deployment | P2 |
| `APP_STORE_CONNECT_API_KEY_CONTENT` | TestFlight deployment | P2 |
| `MATCH_GIT_URL` | iOS code signing | P2 |
| `MATCH_PASSWORD` | iOS code signing | P2 |
| `APPLE_TEAM_ID` | iOS builds | P2 |

### What Goes Where

| Storage | Secrets |
|---------|---------|
| **GitHub Secrets** | All production credentials |
| **Local .env** | Development tokens only |
| **Never commit** | Keystores, .p8 keys, service account JSON |

---

## Android Secrets

### 1. ANDROID_KEYSTORE_BASE64

The release keystore encoded in base64 format.

#### Creating a New Keystore

If you don't have a keystore yet:

```bash
# Run the keystore creation script
./scripts/mobile/create_keystore.sh
```

Or manually:

```bash
keytool -genkey -v \
  -keystore release.keystore \
  -alias direct-cuts-key \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -storepass YOUR_STORE_PASSWORD \
  -keypass YOUR_KEY_PASSWORD \
  -dname "CN=Direct Cuts, OU=Mobile, O=Direct Cuts Inc, L=City, ST=State, C=US"
```

#### Encoding the Keystore

**macOS/Linux:**
```bash
base64 -i android/app/release.keystore | tr -d '\n' > keystore_base64.txt
cat keystore_base64.txt
# Copy this output to GitHub Secrets
```

**Windows (PowerShell):**
```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("android\app\release.keystore")) | Out-File -NoNewline keystore_base64.txt
Get-Content keystore_base64.txt
# Copy this output to GitHub Secrets
```

**Windows (Git Bash):**
```bash
base64 android/app/release.keystore | tr -d '\n' > keystore_base64.txt
cat keystore_base64.txt
```

#### Verifying the Encoding

```bash
# Decode and verify (should show keystore info)
echo "YOUR_BASE64_STRING" | base64 --decode > test.keystore
keytool -list -keystore test.keystore -storepass YOUR_PASSWORD
rm test.keystore
```

### 2. ANDROID_KEYSTORE_PASSWORD

The password used when creating the keystore (`-storepass` value).

### 3. ANDROID_KEY_ALIAS

The alias for the signing key (`-alias` value).

Default: `direct-cuts-key`

### 4. ANDROID_KEY_PASSWORD

The password for the key (`-keypass` value).

Often the same as the keystore password.

---

## iOS Secrets

### 1. APP_STORE_CONNECT_API_KEY_ID

The Key ID from your App Store Connect API key.

#### Creating an API Key

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to **Users and Access** > **Keys** tab
3. Click **+** to create a new key
4. Set:
   - Name: `Direct Cuts CI`
   - Access: `App Manager` or `Developer`
5. Download the `.p8` file (only available once!)
6. Note the **Key ID** (e.g., `ABC123DEF4`)

### 2. APP_STORE_CONNECT_API_ISSUER_ID

The Issuer ID is shared across all keys in your account.

Find it at the top of the **Keys** page in App Store Connect.

Example: `12345678-1234-1234-1234-123456789012`

### 3. APP_STORE_CONNECT_API_KEY_CONTENT

The `.p8` key file content, base64 encoded.

#### Encoding the .p8 Key

```bash
# Encode the key
base64 -i AuthKey_ABC123DEF4.p8 | tr -d '\n' > api_key_base64.txt
cat api_key_base64.txt
# Copy this output to GitHub Secrets
```

### 4. APPLE_TEAM_ID

Your 10-character Apple Developer Team ID.

#### Finding Your Team ID

1. Go to [Apple Developer Account](https://developer.apple.com/account)
2. Click **Membership** in the sidebar
3. Find **Team ID** (e.g., `ABCDE12345`)

### 5. MATCH_GIT_URL

Git repository URL for Fastlane Match certificate storage.

#### Setting Up Match

1. Create a **private** Git repository for certificates
2. Use the SSH URL: `git@github.com:your-org/certificates.git`
3. Ensure CI has read access (deploy key or SSH key)

### 6. MATCH_PASSWORD

Encryption password for Match certificates.

Create a strong, random password:
```bash
openssl rand -base64 24
```

---

## App Configuration Secrets

### 1. ONESIGNAL_APP_ID

Your OneSignal application identifier.

#### Getting Your App ID

1. Go to [OneSignal Dashboard](https://dashboard.onesignal.com)
2. Select your app (or create one)
3. Go to **Settings** > **Keys & IDs**
4. Copy the **OneSignal App ID**

Format: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` (UUID)

### 2. MAPBOX_ACCESS_TOKEN

Your Mapbox public access token.

#### Getting Your Token

1. Go to [Mapbox Account](https://account.mapbox.com)
2. Navigate to **Access Tokens**
3. Use the default public token or create a new one
4. For production, create a token with restricted scopes

Format: `pk.eyJ1Ijoi...` (starts with `pk.`)

### 3. GOOGLE_PLAY_SERVICE_ACCOUNT_JSON

Service account credentials for Google Play API access.

#### Creating a Service Account

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create or select a project
3. Enable the **Google Play Developer API**
4. Go to **IAM & Admin** > **Service Accounts**
5. Click **Create Service Account**:
   - Name: `direct-cuts-ci`
   - Role: None (we'll set it in Play Console)
6. Create a JSON key and download it

#### Granting Access in Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Navigate to **Setup** > **API access**
3. Link to your Google Cloud project
4. Find your service account and click **Manage permissions**
5. Grant permissions:
   - **App access**: Your app only
   - **Permissions**: "Release to internal testing" (minimum)
   - For full release: "Release apps to production"

#### Encoding the JSON

The entire JSON file content goes into the secret (not base64 encoded):

```bash
cat google-play-key.json
# Copy the entire JSON content
```

**Important**: Store the JSON content directly, not base64 encoded.

---

## Adding Secrets to GitHub

### Via GitHub UI

1. Go to your repository on GitHub
2. Click **Settings** > **Secrets and variables** > **Actions**
3. Click **New repository secret**
4. Enter the secret name and value
5. Click **Add secret**

### Via GitHub CLI

```bash
# Set a secret
gh secret set ANDROID_KEYSTORE_BASE64 < keystore_base64.txt

# Set from clipboard (macOS)
pbpaste | gh secret set ONESIGNAL_APP_ID

# Set interactively
gh secret set MAPBOX_ACCESS_TOKEN
```

### Bulk Setup Script

```bash
#!/bin/bash
# save as setup_secrets.sh

echo "Setting up GitHub Secrets for Direct Cuts CI/CD"
echo "================================================"
echo ""

# Android
echo "Enter ANDROID_KEYSTORE_BASE64 (or press Enter to skip):"
read -s KEYSTORE_BASE64
if [ -n "$KEYSTORE_BASE64" ]; then
  echo "$KEYSTORE_BASE64" | gh secret set ANDROID_KEYSTORE_BASE64
  echo "Set ANDROID_KEYSTORE_BASE64"
fi

echo "Enter ANDROID_KEYSTORE_PASSWORD:"
read -s KEYSTORE_PASS
if [ -n "$KEYSTORE_PASS" ]; then
  echo "$KEYSTORE_PASS" | gh secret set ANDROID_KEYSTORE_PASSWORD
  echo "Set ANDROID_KEYSTORE_PASSWORD"
fi

echo "Enter ANDROID_KEY_ALIAS (default: direct-cuts-key):"
read KEY_ALIAS
KEY_ALIAS=${KEY_ALIAS:-direct-cuts-key}
echo "$KEY_ALIAS" | gh secret set ANDROID_KEY_ALIAS
echo "Set ANDROID_KEY_ALIAS"

echo "Enter ANDROID_KEY_PASSWORD:"
read -s KEY_PASS
if [ -n "$KEY_PASS" ]; then
  echo "$KEY_PASS" | gh secret set ANDROID_KEY_PASSWORD
  echo "Set ANDROID_KEY_PASSWORD"
fi

# App Config
echo "Enter ONESIGNAL_APP_ID:"
read ONESIGNAL_ID
if [ -n "$ONESIGNAL_ID" ]; then
  echo "$ONESIGNAL_ID" | gh secret set ONESIGNAL_APP_ID
  echo "Set ONESIGNAL_APP_ID"
fi

echo "Enter MAPBOX_ACCESS_TOKEN:"
read MAPBOX_TOKEN
if [ -n "$MAPBOX_TOKEN" ]; then
  echo "$MAPBOX_TOKEN" | gh secret set MAPBOX_ACCESS_TOKEN
  echo "Set MAPBOX_ACCESS_TOKEN"
fi

echo ""
echo "Basic secrets configured!"
echo "For store deployment, also configure:"
echo "  - GOOGLE_PLAY_SERVICE_ACCOUNT_JSON"
echo "  - APP_STORE_CONNECT_* secrets"
```

---

## Security Best Practices

### Do

1. **Use strong passwords**: Generate with `openssl rand -base64 24`
2. **Limit secret access**: Only add secrets to repos that need them
3. **Rotate regularly**: Change passwords/tokens annually
4. **Audit access**: Review who can access secrets
5. **Use environment secrets**: For staging vs production
6. **Backup securely**: Store keystore backup in secure vault

### Don't

1. **Never commit secrets**: Add to `.gitignore`:
   ```
   *.keystore
   *.jks
   *.p8
   **/key.properties
   google-play-key.json
   *_base64.txt
   ```

2. **Never log secrets**: Even in CI logs
3. **Never share via chat**: Use secure channels
4. **Never use personal tokens**: Create service-specific credentials

### Secret Rotation Checklist

When rotating secrets:

1. Generate new credential
2. Update in GitHub Secrets
3. Test with a manual workflow run
4. Revoke old credential
5. Update any local copies

---

## Verification Checklist

Use this checklist to verify your setup:

### Android Build

- [ ] `ANDROID_KEYSTORE_BASE64` - Keystore decodes correctly
- [ ] `ANDROID_KEYSTORE_PASSWORD` - Password unlocks keystore
- [ ] `ANDROID_KEY_ALIAS` - Alias exists in keystore
- [ ] `ANDROID_KEY_PASSWORD` - Password unlocks key

Test: Run `mobile_release.yml` workflow

### Google Play Deployment

- [ ] `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` - Valid JSON
- [ ] Service account linked in Play Console
- [ ] Correct permissions granted
- [ ] App exists in Play Console

Test: Run `fastlane android beta` locally

### iOS Build (Optional)

- [ ] `APP_STORE_CONNECT_API_KEY_ID` - 10 character key ID
- [ ] `APP_STORE_CONNECT_API_ISSUER_ID` - UUID format
- [ ] `APP_STORE_CONNECT_API_KEY_CONTENT` - Valid base64 .p8
- [ ] `APPLE_TEAM_ID` - 10 character team ID
- [ ] `MATCH_GIT_URL` - Accessible repository
- [ ] `MATCH_PASSWORD` - Correct encryption password

Test: Run `fastlane ios beta` locally

### App Configuration

- [ ] `ONESIGNAL_APP_ID` - UUID format, matches dashboard
- [ ] `MAPBOX_ACCESS_TOKEN` - Starts with `pk.`

Test: Build app and verify push/maps work

---

## Quick Reference

### Secret Formats

| Secret | Format | Example |
|--------|--------|---------|
| `ANDROID_KEYSTORE_BASE64` | Base64 string | `MIIKfAIBAzCCCj...` |
| `ANDROID_KEYSTORE_PASSWORD` | String | `securePassword123` |
| `ANDROID_KEY_ALIAS` | String | `direct-cuts-key` |
| `ANDROID_KEY_PASSWORD` | String | `securePassword123` |
| `ONESIGNAL_APP_ID` | UUID | `a1b2c3d4-e5f6-...` |
| `MAPBOX_ACCESS_TOKEN` | Token | `pk.eyJ1Ijoi...` |
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | JSON | `{"type":"service_account",...}` |
| `APP_STORE_CONNECT_API_KEY_ID` | 10 chars | `ABC123DEF4` |
| `APP_STORE_CONNECT_API_ISSUER_ID` | UUID | `12345678-1234-...` |
| `APP_STORE_CONNECT_API_KEY_CONTENT` | Base64 | `LS0tLS1CRUdJTi...` |
| `APPLE_TEAM_ID` | 10 chars | `ABCDE12345` |
| `MATCH_GIT_URL` | SSH URL | `git@github.com:org/certs.git` |
| `MATCH_PASSWORD` | String | `randomSecurePass` |

### Useful Commands

```bash
# List all secrets (names only)
gh secret list

# Verify a secret exists
gh secret list | grep ANDROID_KEYSTORE_BASE64

# Delete a secret
gh secret delete OLD_SECRET_NAME

# Set secret from file
gh secret set SECRET_NAME < file.txt
```

---

## Support

If you encounter issues with secrets:

1. Verify format matches expected pattern
2. Check for trailing whitespace/newlines
3. Ensure base64 encoding is correct (no line breaks)
4. Test locally first with Fastlane
5. Check workflow logs for specific error messages
