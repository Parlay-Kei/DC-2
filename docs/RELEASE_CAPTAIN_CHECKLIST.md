# Release Captain Checklist

> **Current RC:** `mobile-rc-20251231-7`  
> **Status:** Clean RC with green CI - awaiting human verification

---

## Gate 0: What We Have vs What We Need

| Item | Current State | Store Ready? |
|------|---------------|--------------|
| Android artifact | APK (from ci.yml) | ❌ Need AAB |
| iOS artifact | Unsigned (--no-codesign) | ❌ Need signed IPA |
| CI status | ✅ Green | - |
| Version in pubspec | 2.0.0+1 | ✅ |

**To get store-ready builds**, trigger `mobile_release.yml`:
```bash
# 1. Bump version if needed
cd /c/Dev/DC-2
# Edit pubspec.yaml: version: 2.0.1+2

# 2. Create version tag
git tag v2.0.1
git push origin v2.0.1

# This triggers mobile_release.yml which builds signed AAB + IPA
```

---

## Gate 1: Artifact Verification

### Android
- [ ] Download AAB from workflow artifacts (or build locally)
- [ ] Verify AAB is signed: `jarsigner -verify -certs app-release.aab`
- [ ] Verify bundle ID: `bundletool dump manifest --bundle=app-release.aab`
- [ ] Check version matches: `2.0.0` / build `1`

### iOS
- [ ] Download IPA from workflow artifacts (or build via Xcode)
- [ ] Verify bundle ID in Xcode Organizer
- [ ] Confirm provisioning profile is valid (not expired)
- [ ] Check build number is unique in App Store Connect

---

## Gate 2: Device Smoke Test

### Test Device Requirements
- [ ] Android: Physical device running Android 10+
- [ ] iOS: Physical device running iOS 15+

### Smoke Test Flows (Both Platforms)

#### A. First Launch + Permissions
- [ ] App launches without crash
- [ ] Location permission prompt appears
- [ ] Notification permission prompt appears (iOS)
- [ ] Permissions grant successfully

#### B. Authentication
- [ ] Can create new account (email/password)
- [ ] Can log out
- [ ] Can log back in
- [ ] Session persists after app restart

#### C. Core Booking Flow
- [ ] Can search for barbers
- [ ] Can view barber profile
- [ ] Can select service
- [ ] Can select time slot
- [ ] Can complete booking (no actual charge in test)

#### D. Location Behavior
- [ ] Map renders correctly (Mapbox)
- [ ] "Nearby" barbers list populates
- [ ] Location updates when moving (if testable)

#### E. Push Notification Registration
- [ ] Device registers with OneSignal
- [ ] Can send test push from OneSignal dashboard
- [ ] Push is received on device
- [ ] Tapping push opens correct screen

---

## Gate 3: External Service Verification

### Mapbox Token
- [ ] **CRITICAL:** Rotate token in Mapbox dashboard
- [ ] Old `sk.eyJ1...` token is REVOKED
- [ ] New token set in GitHub Secrets: `MAPBOX_ACCESS_TOKEN`
- [ ] Map loads in app with new token

### OneSignal
- [ ] Using production OneSignal App ID (not sandbox)
- [ ] `ONESIGNAL_APP_ID` set in GitHub Secrets
- [ ] Test push delivered successfully

### Stripe (if applicable)
- [ ] Using production Stripe keys
- [ ] Test payment flow works
- [ ] Webhook endpoint responding

---

## Gate 4: Store Submission

### Fastlane Environment
Required secrets (GitHub Secrets or local `.env`):

**iOS:**
```
APP_STORE_CONNECT_API_KEY_ID
APP_STORE_CONNECT_API_ISSUER_ID  
APP_STORE_CONNECT_API_KEY_CONTENT (base64 .p8)
APPLE_TEAM_ID
MATCH_GIT_URL
MATCH_PASSWORD
```

**Android:**
```
GOOGLE_PLAY_JSON_KEY (path to service account JSON)
ANDROID_KEYSTORE_PATH
ANDROID_KEYSTORE_PASSWORD
ANDROID_KEY_ALIAS
ANDROID_KEY_PASSWORD
```

### TestFlight (iOS)
```bash
cd /c/Dev/DC-2
bundle exec fastlane ios beta
```
- [ ] Upload completes without error
- [ ] Build appears in App Store Connect
- [ ] TestFlight review passes (usually auto-approved)
- [ ] Internal testers can install

### Play Internal Testing (Android)
```bash
cd /c/Dev/DC-2
bundle exec fastlane android beta
```
- [ ] Upload completes without error
- [ ] Build appears in Play Console
- [ ] Internal testing track shows new version
- [ ] Testers can install from Play Store

---

## Gate 5: Production Promotion

> **Only after internal testing is validated**

### iOS: App Store Review
```bash
bundle exec fastlane ios release --submit_for_review
```
- [ ] App submitted to Apple Review
- [ ] Review approved
- [ ] Staged rollout configured (optional)

### Android: Production Track
```bash
bundle exec fastlane android release --rollout 0.1
```
- [ ] App uploaded to production track
- [ ] Staged rollout at 10%
- [ ] Monitor crash reports for 24h
- [ ] Increase rollout to 50% → 100%

---

## Post-Release

- [ ] Create GitHub Release (non-prerelease) with final build
- [ ] Update `CHANGELOG.md`
- [ ] Announce to team/stakeholders
- [ ] Monitor:
  - Crash rates (Firebase Crashlytics)
  - User reviews
  - Support tickets
  - OneSignal delivery stats

---

## Quick Reference: What's NOT a Release

| Situation | Status |
|-----------|--------|
| CI green | Gate passed, not released |
| Tag pushed | Automation started, not released |
| Build uploaded to TestFlight/Play | Internal testing, not released |
| Users on real devices verified flows | Ready to promote |
| Live in App Store/Play Store | **Released** |

---

*Last updated: 2025-12-31*
