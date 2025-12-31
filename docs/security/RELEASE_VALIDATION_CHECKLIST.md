# Release Validation Checklist

**Release Candidate:** `mobile-rc-20251231-1`
**Date:** 2025-12-31
**Status:** Pending Validation

---

## Pre-Release Requirements

### 1. Token Rotation (BLOCKING)

- [ ] **Mapbox Token Rotated**
  - Go to [Mapbox Console](https://console.mapbox.com/account/access-tokens/)
  - Revoke token: `sk.eyJ1IjoicG93ZXJvZnN0ZXZlIiwiYSI6ImNtamxlaXFzbjI5N2ozZ3EyeWR3dG04NXkifQ.60ljdk1cvjsM7S2CtIqzYQ`
  - Create new token with minimal scopes
  - See: `docs/security/MAPBOX_TOKEN_ROTATION_ACTION.md`

- [ ] **GitHub Secret Set**
  ```bash
  gh secret set MAPBOX_ACCESS_TOKEN --body "pk.your-new-token"
  ```

- [ ] **Local .env Configured**
  ```bash
  # .env (not committed)
  MAPBOX_ACCESS_TOKEN=pk.your-new-token
  ```

---

## CI Validation

### 2. CI Green on Tag

- [ ] Push tag to remote:
  ```bash
  git push origin mobile-rc-20251231-1
  ```

- [ ] Verify workflows pass:
  - [ ] `security.yml` - Code hygiene gates
  - [ ] `mobile_pr.yml` - Lint, test, build
  - [ ] `mobile_main.yml` - Full validation

### 3. Production Build

- [ ] Build completes with `--dart-define`:
  ```bash
  flutter build appbundle --release \
    --dart-define=MAPBOX_ACCESS_TOKEN=$MAPBOX_ACCESS_TOKEN \
    --dart-define=ONESIGNAL_APP_ID=$ONESIGNAL_APP_ID
  ```

- [ ] APK/AAB generated in `build/app/outputs/`

---

## Device Smoke Test

### 4. Auth Flow

- [ ] New user registration works
- [ ] Existing user login works
- [ ] Password reset email sends
- [ ] Session persists after app restart
- [ ] Logout clears session

### 5. Booking Flow

- [ ] Map loads with barber markers
- [ ] Barber profile displays correctly
- [ ] Service selection works
- [ ] Time slot selection works
- [ ] Booking confirmation shows

### 6. Location Permissions

- [ ] Permission prompt appears on first launch
- [ ] "Allow While Using" works
- [ ] "Allow Always" works (if applicable)
- [ ] Deny gracefully handled

### 7. Push Notification Registration

- [ ] OneSignal SDK initializes without crash
- [ ] Device registers (check OneSignal dashboard)
- [ ] Test push received in production config

---

## Log Verification

### 8. Release Logs Clean

Run app in release mode and verify:

- [ ] No user IDs in logs
- [ ] No email addresses in logs
- [ ] No device tokens in logs
- [ ] No API keys/tokens in logs
- [ ] No request/response payload dumps

Verification command:
```bash
adb logcat -d | grep -i "direct.cuts" | grep -iE "user.*id|email|token|password|payload"
# Should return empty
```

---

## Sign-Off

| Role | Name | Date | Status |
|------|------|------|--------|
| QA Tester | | | |
| Security Reviewer | | | |
| Release Manager | | | |

---

## Post-Release Monitoring

After store submission:

- [ ] Monitor Mapbox usage dashboard for unauthorized calls
- [ ] Check crash reporting (Firebase Crashlytics)
- [ ] Review OneSignal delivery metrics
- [ ] Monitor app store reviews for issues
