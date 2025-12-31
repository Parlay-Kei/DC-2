# Security Roadmap - Direct Cuts Mobile

**Last Updated:** 2025-12-31
**Status:** P1 items deferred for MVP, documented for post-launch

## Overview

This document outlines security features planned for future releases. P0 security issues have been addressed in the initial security sprint. P1 features are important but not blocking for MVP/store submission.

---

## P1: Root/Jailbreak Detection

### Decision: Soft Warning for MVP

**Rationale:**
- Hard blocks frustrate power users with legitimate rooted devices
- Many barbers use older/rooted phones
- Competitors don't enforce this strictly
- Focus on server-side validation is more important

### MVP Implementation (Soft Warning)

Show a non-blocking warning dialog on app launch if device is rooted/jailbroken:

```dart
// lib/services/device_security_service.dart
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';

class DeviceSecurityService {
  static Future<bool> checkDeviceIntegrity() async {
    try {
      final isJailbroken = await FlutterJailbreakDetection.jailbroken;
      final isDeveloperMode = await FlutterJailbreakDetection.developerMode;

      if (isJailbroken || isDeveloperMode) {
        // Log for analytics (no PII)
        Logger.warning('Device integrity check: modified device detected');
        return false; // Device is not secure
      }
      return true;
    } catch (e) {
      Logger.error('Device integrity check failed', e);
      return true; // Fail open for MVP
    }
  }

  static void showSecurityWarning(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Security Notice'),
        content: Text(
          'Your device appears to be rooted or jailbroken. '
          'Some security features may be limited. '
          'For the best experience, use an unmodified device.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('I Understand'),
          ),
        ],
      ),
    );
  }
}
```

### Post-MVP: Enhanced Detection

For future releases, implement stricter controls:

1. **SafetyNet Attestation (Android)**
   - Use Google Play Integrity API
   - Verify device hasn't been tampered with
   - Block payment flows on compromised devices

2. **Device Check (iOS)**
   - Use Apple DeviceCheck API
   - Detect simulator, jailbreak, debug attachments
   - Rate limit suspicious devices

3. **Behavioral Analysis**
   - Track unusual patterns (rapid bookings, location spoofing)
   - Flag accounts for manual review
   - Server-side risk scoring

### Package to Use

```yaml
# pubspec.yaml
dependencies:
  flutter_jailbreak_detection: ^1.10.0
```

---

## P1: Certificate Pinning

### Decision: Defer for MVP

**Rationale:**
- Adds significant complexity to certificate rotation
- Can cause app outages if not managed carefully
- Supabase and Stripe handle their own pinning
- HTTPS with proper TLS is sufficient for MVP

### Post-MVP Implementation

When implementing certificate pinning, use the following approach:

1. **Pin to Intermediate CA, not Leaf**
   - Leaf certificates rotate frequently
   - Intermediate CA pins last 2-5 years
   - Reduces maintenance burden

2. **Use Backup Pins**
   - Always include at least 2 pin hashes
   - One current, one backup CA
   - Allows emergency rotation

3. **Implement Pin Refresh**
   - Fetch new pins from a pinned bootstrap endpoint
   - Cache pins with expiration
   - Graceful degradation if refresh fails

### Implementation Pattern

```dart
// lib/services/http_client.dart
import 'package:http_certificate_pinning/http_certificate_pinning.dart';

class SecureHttpClient {
  static const _pins = [
    // Primary: Supabase intermediate CA (SHA-256)
    'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
    // Backup: Let's Encrypt R3 intermediate
    'sha256/jQJTbIh0grw0/1TkHSumWb+Fs0Ggogr621gT3PvPKG0=',
  ];

  static Future<http.Response> get(String url) async {
    final secureClient = HttpClientWithCertificatePinning(
      pins: _pins,
      timeout: Duration(seconds: 30),
    );

    try {
      return await secureClient.get(Uri.parse(url));
    } on CertificatePinningException catch (e) {
      Logger.error('Certificate pinning failed', e);
      throw SecurityException('Connection not trusted');
    }
  }
}
```

### Risks of Certificate Pinning

1. **App Lockout**: If pins expire without app update, users can't connect
2. **Emergency Response**: Can't quickly rotate if CA is compromised
3. **Testing Complexity**: Need different pins for staging/production
4. **CDN Issues**: Third-party CDNs may have rotating certificates

### Mitigation Strategy

1. Set pin expiration reminders (90 days before cert expiry)
2. Implement remote pin update mechanism
3. Include kill switch to disable pinning in emergencies
4. Monitor certificate expiry in CI/CD pipeline

---

## Security Checklist Summary

### P0 - Completed (Required for Store Submission)

| Item | Status | PR |
|------|--------|-----|
| Remove PII from logs | ✅ Done | PR 1 |
| Use production Logger utility | ✅ Done | PR 1 |
| .env not tracked in git | ✅ Done | PR 2 |
| Token rotation documented | ✅ Done | PR 2 |
| CI security gates | ✅ Done | PR 3 |
| Remove hardcoded tokens | ✅ Done | main |
| Disable cleartext traffic | ✅ Done | main |
| iOS privacy descriptions | ✅ Verified | - |

### P1 - Deferred (Post-MVP)

| Item | Priority | Target |
|------|----------|--------|
| Root/jailbreak soft warning | P1 | v2.1 |
| Certificate pinning | P1 | v2.2 |
| SafetyNet/DeviceCheck | P2 | v2.3 |
| Behavioral fraud detection | P2 | v3.0 |

---

## Contact

- **Security Questions**: security@direct-cuts.com
- **Vulnerability Reports**: security@direct-cuts.com (encrypted via PGP)
- **Urgent Issues**: Escalate via Slack #security-incidents
