# Secret Management Guide

**Project:** Direct Cuts (DC-2)
**Last Updated:** 2025-12-31

This document outlines best practices for managing secrets and API keys in the Direct Cuts mobile application.

---

## Critical Security Requirements

### 1. NEVER Commit Secrets to Git

**Files that must NEVER be committed:**
- `.env` and `.env.*` files
- `android/key.properties`
- `*.keystore` files
- Any file containing API keys, passwords, or tokens

**Verification:**
```bash
# Check if sensitive files are tracked:
git ls-files | grep -E "(\.env|key\.properties|\.keystore)"
# Expected: No results

# Check gitignore:
git check-ignore .env
# Expected: .env (file is ignored)
```

---

## Current API Keys and Secrets

### Supabase Anonymous Key
**File:** `lib/config/supabase_config.dart`
**Status:** ✅ SAFE TO COMMIT
**Reason:** Anon keys are designed to be public. Security is enforced by Row-Level Security (RLS) policies on Supabase.

```dart
static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

**Security Measures:**
- ✅ Never use `service_role` key in client code
- ✅ Enable RLS on all Supabase tables
- ✅ Configure API rate limiting in Supabase dashboard

---

### Mapbox Access Token
**Current Location:** `.env` file (MUST BE ROTATED - exposed in git history)
**Status:** ❌ EXPOSED - Requires immediate rotation
**Type:** Secret token (sk.*) with tiles:read scope

**Immediate Actions Required:**

1. **Rotate the exposed token:**
   ```bash
   # 1. Go to https://account.mapbox.com/access-tokens/
   # 2. Delete token: sk.eyJ1IjoicG93ZXJvZnN0ZXZlIiwiYSI6ImNtamxlaXFzbjI5N2ozZ3EyeWR3dG04NXkifQ.60ljdk1cvjsM7S2CtIqzYQ
   # 3. Create new secret token with tiles:read scope
   # 4. Update .env with new token (but DO NOT commit)
   ```

2. **Remove .env from git history:**
   ```bash
   # WARNING: This rewrites git history - coordinate with team
   git filter-branch --force --index-filter \
     "git rm --cached --ignore-unmatch .env" \
     --prune-empty --tag-name-filter cat -- --all

   # Force push (CAUTION):
   git push origin --force --all
   ```

3. **Configure for builds:**
   ```bash
   # For local development, set environment variable:
   export MAPBOX_ACCESS_TOKEN="your-new-secret-token"

   # For production builds, use --dart-define:
   flutter build apk --release --dart-define=MAPBOX_ACCESS_TOKEN=your-new-secret-token
   flutter build ios --release --dart-define=MAPBOX_ACCESS_TOKEN=your-new-secret-token
   ```

4. **Add URL restrictions in Mapbox dashboard:**
   - Go to https://account.mapbox.com/access-tokens/
   - Click on your token
   - Add URL restrictions (if applicable)
   - Enable rate limits

**Why This Is Safe for Mobile:**
Mapbox requires secret tokens (sk.*) for mobile apps when using tiles:read scope. This is acceptable because:
- Token is compiled into app binary (not easily extractable)
- URL restrictions prevent web abuse
- Rate limits prevent excessive usage
- Alternative (session tokens) adds complexity for minimal security gain

---

### OneSignal App ID
**Location:** Environment variable or --dart-define
**Status:** ✅ PROPERLY CONFIGURED
**Type:** Public identifier (safe to expose)

**Configuration:**
```bash
# Development:
export ONESIGNAL_APP_ID="your-onesignal-app-id"

# Production build:
flutter build apk --release --dart-define=ONESIGNAL_APP_ID=your-app-id
```

**Security:** OneSignal App IDs are public and safe to embed in apps.

---

### Stripe Publishable Key
**Location:** Passed to Stripe SDK at runtime
**Status:** ✅ SAFE TO COMMIT
**Type:** Publishable key (pk_live_* or pk_test_*)

**Security Measures:**
- ✅ Never use secret key (sk_*) in client code
- ✅ All payment processing on server (Supabase Edge Functions)
- ✅ Stripe SDK handles PCI compliance

---

## Build Configuration

### Development Builds

**Option 1: Environment Variables (Recommended for Local Dev)**
```bash
# Set in terminal or .bashrc/.zshrc
export MAPBOX_ACCESS_TOKEN="sk.your-secret-token"
export ONESIGNAL_APP_ID="your-app-id"

# Run app:
flutter run
```

**Option 2: .env File (Local Only - NEVER Commit)**
```bash
# Create .env in project root:
MAPBOX_ACCESS_TOKEN=sk.your-secret-token
ONESIGNAL_APP_ID=your-app-id

# Verify it's in .gitignore:
git check-ignore .env
# Expected: .env
```

---

### Production Builds

**Always use --dart-define for production:**

```bash
# Android Release:
flutter build apk --release \
  --dart-define=MAPBOX_ACCESS_TOKEN=sk.your-production-token \
  --dart-define=ONESIGNAL_APP_ID=your-production-app-id

# iOS Release:
flutter build ios --release \
  --dart-define=MAPBOX_ACCESS_TOKEN=sk.your-production-token \
  --dart-define=ONESIGNAL_APP_ID=your-production-app-id
```

**CI/CD Integration (GitHub Actions, GitLab CI, etc.):**
```yaml
# Example GitHub Actions workflow:
- name: Build Android Release
  env:
    MAPBOX_TOKEN: ${{ secrets.MAPBOX_ACCESS_TOKEN }}
    ONESIGNAL_ID: ${{ secrets.ONESIGNAL_APP_ID }}
  run: |
    flutter build apk --release \
      --dart-define=MAPBOX_ACCESS_TOKEN=$MAPBOX_TOKEN \
      --dart-define=ONESIGNAL_APP_ID=$ONESIGNAL_ID
```

---

## Android Keystore Management

### Create Production Keystore

```bash
# Run the provided script:
cd scripts/mobile
./create_keystore.sh

# Or manually:
keytool -genkey -v -keystore android/app/directcuts-release.keystore \
  -alias directcuts -keyalg RSA -keysize 2048 -validity 10000
```

### Configure key.properties

**File:** `android/key.properties` (MUST be in .gitignore)

```properties
storePassword=your-store-password
keyPassword=your-key-password
keyAlias=directcuts
storeFile=directcuts-release.keystore
```

**Security Checklist:**
- [ ] key.properties is in .gitignore
- [ ] Keystore file is backed up securely (NOT in git)
- [ ] Passwords stored in password manager
- [ ] Production keystore never used for debug builds

---

## iOS Code Signing

### Provisioning Profiles

**Development:**
- Use Xcode automatic signing for development
- Development certificates expire yearly

**Production:**
- Use App Store Distribution profile
- Store in secure location (NOT in git)
- Renew annually

**Security Checklist:**
- [ ] Production provisioning profile never committed to git
- [ ] Distribution certificate stored securely
- [ ] Certificate password in password manager

---

## Secret Rotation Schedule

### Immediate (Within 24 Hours)
- ❌ Mapbox access token (EXPOSED - see above)

### Monthly
- [ ] Review API key usage in provider dashboards
- [ ] Check for unauthorized access patterns
- [ ] Rotate keys if breach suspected

### Annually
- [ ] Rotate all API keys as best practice
- [ ] Update Mapbox token
- [ ] Regenerate OneSignal app ID (if needed)
- [ ] Renew iOS certificates and profiles

---

## Incident Response

### If a Secret is Exposed

1. **Immediately Rotate the Secret:**
   - Revoke exposed key in provider dashboard
   - Generate new key
   - Update all environments

2. **Assess Impact:**
   - Check provider dashboards for unauthorized usage
   - Review access logs
   - Estimate potential exposure window

3. **Remove from Git History:**
   ```bash
   # Use git-filter-repo (recommended) or filter-branch
   git filter-repo --path path/to/secret/file --invert-paths
   ```

4. **Notify Stakeholders:**
   - Technical lead
   - Security team (if applicable)
   - Provider support (if abuse detected)

5. **Document Incident:**
   - What was exposed
   - How it was exposed
   - Remediation steps taken
   - Preventive measures implemented

---

## Best Practices Checklist

**Before Every Commit:**
- [ ] Run `git status` and verify no .env files staged
- [ ] Check diff for hardcoded secrets: `git diff --cached`
- [ ] Verify .gitignore is comprehensive

**Before Every Build:**
- [ ] Verify secrets loaded via environment variables or --dart-define
- [ ] Never hardcode secrets in source code
- [ ] Test with production keys only in release builds

**Monthly Security Review:**
- [ ] Audit all API keys in codebase
- [ ] Review git history for accidental commits
- [ ] Verify .gitignore effectiveness
- [ ] Check provider dashboards for unusual activity

---

## Contact for Security Issues

**Internal:**
- Technical Lead: [Contact Info]
- Security Team: [Contact Info]

**External (Providers):**
- Supabase Support: support@supabase.io
- Mapbox Support: help@mapbox.com
- Stripe Support: https://support.stripe.com
- OneSignal Support: support@onesignal.com

---

## Additional Resources

**Supabase Security:**
- https://supabase.com/docs/guides/platform/security

**Mapbox Token Management:**
- https://docs.mapbox.com/help/troubleshooting/how-to-use-mapbox-securely/

**Flutter Secure Storage:**
- https://pub.dev/packages/flutter_secure_storage

**OWASP Mobile Security:**
- https://owasp.org/www-project-mobile-security/

---

**Document Version:** 1.0
**Last Updated:** 2025-12-31
**Next Review:** Upon next key rotation or security incident
