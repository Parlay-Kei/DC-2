# Mobile Security Pre-Release Checklist

**Project:** Direct Cuts (DC-2)
**Purpose:** Security validation before production deployment
**Last Updated:** 2025-12-31

This checklist must be completed and reviewed before each production release.

---

## Pre-Release Security Gate

**BLOCKER CRITERIA:** All P0 items must be ✅ PASS before release approval.

**Approval Required From:**
- [ ] Technical Lead
- [ ] Security Reviewer
- [ ] Product Owner (for risk acceptance decisions)

---

## P0 - CRITICAL SECURITY CHECKS (BLOCKERS)

### Code Security

- [ ] **No PII in production logs**
  ```bash
  # Verification command:
  grep -r "print.*user\.id\|print.*user\.email\|print.*\.token\|print.*password" lib/ --include="*.dart"
  # Expected: No results
  ```
  - **Status:** ⬜ NOT VERIFIED
  - **Verification Date:** ___________
  - **Verified By:** ___________

- [ ] **No hardcoded secrets in codebase**
  ```bash
  # Verification command:
  grep -ri "password\s*=\s*['\"].*['\"]" lib/ --include="*.dart"
  grep -ri "api_key\s*=\s*['\"].*['\"]" lib/ --include="*.dart"
  grep -ri "secret\s*=\s*['\"].*['\"]" lib/ --include="*.dart"
  # Expected: No results except test fixtures
  ```
  - **Status:** ⬜ NOT VERIFIED
  - **Exceptions (if any):** ___________

- [ ] **No .env files committed to repository**
  ```bash
  # Verification command:
  git ls-files | grep "\.env"
  # Expected: No results

  git log --all --full-history -- "*.env*"
  # Expected: No history (or removed via git filter-branch)
  ```
  - **Status:** ⬜ NOT VERIFIED
  - **Action Taken:** ___________

- [ ] **All API keys rotated if previously exposed**
  - [ ] Mapbox access token rotated
  - [ ] Old tokens revoked in provider dashboards
  - [ ] New tokens configured via --dart-define
  - **Status:** ⬜ NOT VERIFIED

- [ ] **Debug logging disabled in release builds**
  ```bash
  # Verification: All debug statements wrapped in kDebugMode
  grep -r "debugPrint\|print(" lib/ --include="*.dart" | grep -v "if (kDebugMode)" | grep -v "// "
  # Expected: Only production-safe logging (or zero results)
  ```
  - **Status:** ⬜ NOT VERIFIED

### Build Security

- [ ] **Android R8/ProGuard enabled**
  ```bash
  # Verification: Check build.gradle.kts
  grep "isMinifyEnabled = true" android/app/build.gradle.kts
  grep "isShrinkResources = true" android/app/build.gradle.kts
  # Expected: Both present in release buildType
  ```
  - **Status:** ⬜ NOT VERIFIED

- [ ] **Production keystore configured (Android)**
  ```bash
  # Verification: key.properties exists and is NOT in git
  ls android/key.properties
  git check-ignore android/key.properties
  # Expected: File exists, is ignored by git
  ```
  - **Status:** ⬜ NOT VERIFIED
  - **Keystore Created:** ⬜ YES ⬜ NO
  - **Keystore Backed Up Securely:** ⬜ YES ⬜ NO

- [ ] **iOS Release configuration uses production provisioning**
  - **Provisioning Profile Type:** ⬜ Development ⬜ Ad-Hoc ⬜ App Store (REQUIRED)
  - **Certificate Type:** ⬜ Development ⬜ Distribution (REQUIRED)
  - **Status:** ⬜ NOT VERIFIED

### Infrastructure Security

- [ ] **Supabase Row-Level Security (RLS) enabled on all tables**
  ```sql
  -- Verification: Run in Supabase SQL editor
  SELECT tablename, rowsecurity
  FROM pg_tables
  WHERE schemaname = 'public'
  AND rowsecurity = false;
  -- Expected: No results (all tables should have rowsecurity = true)
  ```
  - **Status:** ⬜ NOT VERIFIED
  - **Tables Without RLS (if any):** ___________

- [ ] **Supabase service_role key never exposed to client**
  ```bash
  # Verification:
  grep -ri "service.*role\|service_role" lib/ android/ ios/ --include="*.dart" --include="*.kt" --include="*.swift"
  # Expected: No results
  ```
  - **Status:** ⬜ NOT VERIFIED

- [ ] **API rate limiting configured**
  - **Supabase rate limits:** ⬜ Configured ⬜ Default
  - **Mapbox rate limits:** ⬜ Configured ⬜ Default
  - **Custom API rate limits:** ⬜ N/A ⬜ Configured
  - **Status:** ⬜ NOT VERIFIED

---

## P1 - HIGH PRIORITY SECURITY CHECKS

### Platform Hardening

- [ ] **Root/Jailbreak detection implemented OR risk accepted**
  - **Implementation Status:** ⬜ Implemented ⬜ Deferred
  - **If Deferred - Risk Acceptance:**
    - [ ] Risk documented in security audit
    - [ ] Approved by: ___________
    - [ ] Planned implementation date: ___________
  - **Status:** ⬜ NOT VERIFIED

- [ ] **Certificate pinning implemented OR risk accepted**
  - **Implementation Status:** ⬜ Implemented ⬜ Deferred
  - **If Deferred - Risk Acceptance:**
    - [ ] Justification documented (e.g., Supabase is trusted provider)
    - [ ] Approved by: ___________
    - [ ] Planned implementation date: ___________
  - **Status:** ⬜ NOT VERIFIED

- [ ] **Enhanced ProGuard rules for sensitive classes**
  ```bash
  # Verification: Check proguard-rules.pro contains app-specific rules
  grep -E "(Direct Cuts|com.directcuts)" android/app/proguard-rules.pro
  # Expected: Custom rules for app classes
  ```
  - **Status:** ⬜ NOT VERIFIED

### Network Security

- [ ] **TLS 1.2+ enforced on all endpoints**
  - **iOS ATS Configuration:**
    ```bash
    # Verification: Check Info.plist
    grep -A 5 "NSAppTransportSecurity" ios/Runner/Info.plist
    # Expected: NSAllowsArbitraryLoads = false
    ```
  - **Status:** ⬜ NOT VERIFIED

- [ ] **Android Network Security Config created**
  ```bash
  # Verification:
  ls android/app/src/main/res/xml/network_security_config.xml
  # Expected: File exists with cleartext blocked
  ```
  - **Status:** ⬜ NOT VERIFIED ⬜ OPTIONAL (deferred)

### Permissions Audit

- [ ] **Android permissions minimized and justified**
  ```bash
  # Verification: Review AndroidManifest.xml
  grep "<uses-permission" android/app/src/main/AndroidManifest.xml
  ```
  - **Permissions Requested:**
    - [ ] INTERNET - Justified: ___________
    - [ ] ACCESS_FINE_LOCATION - Justified: ___________
    - [ ] CAMERA - Justified: ___________
    - [ ] READ_EXTERNAL_STORAGE - Justified: ___________
    - [ ] POST_NOTIFICATIONS - Justified: ___________
    - [ ] Other: ___________
  - **Status:** ⬜ NOT VERIFIED

- [ ] **iOS permission descriptions clear and accurate**
  ```bash
  # Verification: Check Info.plist
  grep "UsageDescription" ios/Runner/Info.plist
  # Expected: All permission descriptions explain why they're needed
  ```
  - **Status:** ⬜ NOT VERIFIED

---

## P2 - MEDIUM PRIORITY SECURITY CHECKS

### Data Protection

- [ ] **User data deletion functionality tested**
  - **Manual Test:**
    1. Create test account
    2. Add data (profile, bookings, messages)
    3. Delete account via app
    4. Verify data removed from Supabase dashboard
  - **Test Date:** ___________
  - **Tested By:** ___________
  - **Status:** ⬜ PASS ⬜ FAIL

- [ ] **Session timeout tested**
  - **Test Scenario:** Leave app idle for 30 minutes
  - **Expected Behavior:** ___________
  - **Actual Behavior:** ___________
  - **Status:** ⬜ PASS ⬜ FAIL

- [ ] **Token refresh mechanism tested**
  - **Test Scenario:** Use app continuously for 2+ hours
  - **Expected Behavior:** Seamless token refresh, no logout
  - **Status:** ⬜ PASS ⬜ FAIL

### Dependency Security

- [ ] **Dependencies up to date with security patches**
  ```bash
  # Verification:
  flutter pub outdated
  # Review for security-related updates
  ```
  - **Last Update Date:** ___________
  - **Critical Updates Applied:** ⬜ N/A ⬜ YES
  - **Status:** ⬜ NOT VERIFIED

- [ ] **Known vulnerabilities checked**
  ```bash
  # Manual check or use automated tool:
  # 1. Check pub.dev for security advisories
  # 2. Review GitHub Security tab for flutter_secure_storage, supabase_flutter, flutter_stripe
  ```
  - **Last Check Date:** ___________
  - **Vulnerabilities Found:** ⬜ None ⬜ Yes (list below)
  - **Status:** ⬜ NOT VERIFIED

---

## P3 - COMPLIANCE & DOCUMENTATION

### Legal & Compliance

- [ ] **Privacy Policy reviewed and accessible**
  - **Policy Updated Date:** ___________
  - **Includes GDPR disclosures:** ⬜ YES ⬜ N/A
  - **Includes CCPA disclosures:** ⬜ YES ⬜ N/A
  - **Status:** ⬜ VERIFIED

- [ ] **Terms of Service reviewed and accessible**
  - **ToS Updated Date:** ___________
  - **Status:** ⬜ VERIFIED

- [ ] **Data retention policies documented**
  - **User data retained for:** ___________
  - **Deletion policy:** ___________
  - **Status:** ⬜ DOCUMENTED

### Incident Response

- [ ] **Security contact published**
  - **Contact Email:** support@directcuts.app (verify)
  - **Contact Page:** ⬜ In App ⬜ Website ⬜ SECURITY.md
  - **Status:** ⬜ VERIFIED

- [ ] **SECURITY.md created in repository**
  ```bash
  # Verification:
  ls SECURITY.md
  # Expected: File exists with vulnerability disclosure policy
  ```
  - **Status:** ⬜ NOT VERIFIED

- [ ] **Incident response plan documented**
  - **Plan Location:** ___________
  - **Response SLA:** ___________
  - **Status:** ⬜ DOCUMENTED

---

## Security Testing Results

### Static Analysis

- [ ] **Flutter analyze completed with no errors**
  ```bash
  flutter analyze --no-pub
  # Expected: No issues found
  ```
  - **Run Date:** ___________
  - **Errors Found:** ___________
  - **Status:** ⬜ PASS ⬜ FAIL

- [ ] **Dart formatting verified**
  ```bash
  dart format --set-exit-if-changed .
  # Expected: No changes needed
  ```
  - **Status:** ⬜ PASS ⬜ FAIL

### Dynamic Analysis

- [ ] **Release build tested on physical device**
  - **Android Test Device:** ___________
  - **iOS Test Device:** ___________
  - **Test Date:** ___________
  - **Status:** ⬜ PASS ⬜ FAIL

- [ ] **Network traffic intercepted and validated**
  - **Tool Used:** ⬜ Burp Suite ⬜ Charles Proxy ⬜ Other: ___________
  - **TLS Validation:** ⬜ PASS (rejects invalid certs) ⬜ FAIL
  - **API Calls Encrypted:** ⬜ PASS (HTTPS only) ⬜ FAIL
  - **No Sensitive Data in URLs:** ⬜ PASS ⬜ FAIL
  - **Test Date:** ___________

- [ ] **Rooted/Jailbroken device testing (if detection implemented)**
  - **Android Rooted Device:** ___________
  - **iOS Jailbroken Device:** ___________
  - **Detection Working:** ⬜ PASS ⬜ FAIL ⬜ N/A
  - **Test Date:** ___________

### Penetration Testing

- [ ] **Local data extraction attempted**
  - **Method:** ADB backup / iTunes backup
  - **Tokens Extracted:** ⬜ NO (secure) ⬜ YES (insecure)
  - **Card Data Extracted:** ⬜ NO (expected) ⬜ YES (critical issue)
  - **Test Date:** ___________
  - **Status:** ⬜ PASS ⬜ FAIL

- [ ] **APK/IPA decompiled and obfuscation verified**
  ```bash
  # Android:
  apktool d app-release.apk -o decompiled/
  grep -r "AuthService\|PaymentService" decompiled/
  # Expected: Obfuscated class names

  # iOS:
  # Use Hopper Disassembler or similar tool
  ```
  - **Class Names Obfuscated:** ⬜ YES (Android) ⬜ NO ⬜ N/A
  - **Sensitive Strings Removed:** ⬜ YES ⬜ NO
  - **Test Date:** ___________
  - **Status:** ⬜ PASS ⬜ FAIL

### Automated Security Scanning

- [ ] **MobSF (Mobile Security Framework) scan completed**
  ```bash
  # Upload APK/IPA to MobSF and review findings
  ```
  - **Scan Date:** ___________
  - **High/Critical Findings:** ___________
  - **All Findings Addressed:** ⬜ YES ⬜ NO (document exceptions)
  - **Status:** ⬜ PASS ⬜ FAIL

---

## Third-Party Service Security

### Supabase

- [ ] **Project URL uses HTTPS:** `https://dskpfnjbgocieoqyiznf.supabase.co`
- [ ] **Anonymous key is public-safe (not service_role)**
- [ ] **RLS policies tested for data isolation**
  - **Test Scenario:** User A cannot access User B's data
  - **Test Date:** ___________
  - **Status:** ⬜ PASS ⬜ FAIL

- [ ] **Edge Functions use proper authentication**
  - **create-payment-intent:** ⬜ Auth verified
  - **create-refund:** ⬜ Auth verified
  - **Other functions:** ___________
  - **Status:** ⬜ VERIFIED

### Stripe

- [ ] **Publishable key used (not secret key)**
  - **Verification:** Key starts with `pk_live_` or `pk_test_`
  - **Status:** ⬜ VERIFIED

- [ ] **Webhook signature verification enabled**
  - **Endpoint:** ___________
  - **Signature Verification:** ⬜ Enabled
  - **Status:** ⬜ VERIFIED

- [ ] **Test mode disabled in production**
  - **Status:** ⬜ VERIFIED

### Mapbox

- [ ] **Token restrictions configured**
  - **URL Restrictions:** ⬜ Configured ⬜ None
  - **Rate Limits:** ⬜ Configured ⬜ Default
  - **Referrer Restrictions:** ⬜ N/A (mobile app)
  - **Status:** ⬜ VERIFIED

### OneSignal

- [ ] **App ID configured via environment variable (not hardcoded)**
  ```bash
  # Verification:
  grep "ONESIGNAL_APP_ID" lib/config/app_config.dart
  # Expected: Uses String.fromEnvironment or Platform.environment
  ```
  - **Status:** ⬜ VERIFIED

- [ ] **User consent for push notifications implemented**
  - **iOS:** ⬜ Permission prompt shown
  - **Android:** ⬜ Permission prompt shown (Android 13+)
  - **Status:** ⬜ VERIFIED

---

## Pre-Release Sign-Off

### Checklist Summary

**P0 Critical Items:**
- Total: _____ / _____
- Pass Rate: _____%
- **Blocker Status:** ⬜ ALL PASS (may release) ⬜ BLOCKED (fix required)

**P1 High Priority Items:**
- Total: _____ / _____
- Pass Rate: _____%
- **Risk Accepted For:** ___________

**P2 Medium Priority Items:**
- Total: _____ / _____
- Pass Rate: _____%

### Approvals

**Technical Lead:**
- Name: ___________
- Date: ___________
- Signature: ___________
- Comments: ___________

**Security Reviewer:**
- Name: ___________
- Date: ___________
- Signature: ___________
- Comments: ___________

**Product Owner (Risk Acceptance):**
- Name: ___________
- Date: ___________
- Signature: ___________
- Accepted Risks: ___________

### Release Decision

- ⬜ **APPROVED FOR RELEASE**
  - Release Version: ___________
  - Release Date: ___________
  - Platform: ⬜ Android ⬜ iOS ⬜ Both

- ⬜ **REJECTED - FIXES REQUIRED**
  - Blocking Issues: ___________
  - Estimated Fix Time: ___________
  - Re-review Date: ___________

---

## Post-Release Security Monitoring

### First 48 Hours

- [ ] Monitor crash reporting for security-related crashes
- [ ] Review API error rates for anomalies
- [ ] Check Supabase logs for suspicious activity
- [ ] Monitor Stripe dashboard for payment anomalies

### First 30 Days

- [ ] Review user-reported security concerns
- [ ] Analyze authentication failure patterns
- [ ] Check for unauthorized API access attempts
- [ ] Conduct post-launch security review

### Quarterly Reviews

- [ ] Re-run security checklist for major updates
- [ ] Review and update dependencies
- [ ] Conduct penetration testing
- [ ] Update security documentation

---

## Emergency Contacts

**Security Incident Hotline:**
- Email: support@directcuts.app
- Phone: ___________
- On-Call Engineer: ___________

**Escalation Path:**
1. Engineering Lead
2. CTO
3. CEO (for major incidents)

**Third-Party Contacts:**
- Supabase Support: support@supabase.io
- Stripe Support: https://support.stripe.com
- Mapbox Support: help@mapbox.com

---

**Checklist Version:** 1.0
**Last Updated:** 2025-12-31
**Next Review:** Upon next major release
