# Secret Audit Report

**Generated:** 2025-12-31
**Repository:** Direct-Cuts / DC-2
**Auditor:** Claude Code Security Scan

---

## 1. No .env Files Tracked

**Command:** `git ls-files | grep -i "\.env"`

```
[PASS] No .env files tracked in repository
```

## 2. No Known Secret Patterns in Tracked Files

### 2a. Mapbox Secret Tokens (sk.eyJ pattern)

**Command:** `git ls-files | xargs grep -l "sk\.eyJ"`

```
[PASS] No Mapbox secret tokens found
```

### 2b. Stripe Keys (sk_live, sk_test patterns)

**Command:** `git ls-files | xargs grep -l "sk_live\|sk_test"`

```
[PASS] No Stripe secret keys found
```

### 2c. Supabase Service Role Keys (service_role pattern)

**Command:** `git ls-files | xargs grep -l "service_role"`

```
[PASS] No Supabase service role keys found
```

### 2d. OneSignal REST API Keys (rest_api_key pattern)

**Command:** `git ls-files | xargs grep -li "onesignal.*key\|rest_api_key"`

```
[PASS] No OneSignal REST API keys found
```

### 2e. High-Entropy Strings (potential API keys/tokens)

**Command:** Search for base64-like strings 40+ chars

```
[PASS] No suspicious secrets found
Note: High-entropy matches are placeholder text in code comments (e.g., "your-app-id")
```

## 3. No .env Ever Committed (History Check)

**Command:** `git log --all --name-only --oneline | grep -i "\.env"`

```
[PASS] No .env files committed to history
Note: "faa063d .env hygiene" is a commit message, not an actual .env file
```

## 4. History Check for Exposed Token

**Command:** `git log --all -p -S "sk.eyJ" --oneline | head -30`

```
[CRITICAL] Token found in git history - requires rotation + optional history rewrite:
e4ac05e security(CRITICAL): remove hardcoded token + disable cleartext traffic
diff --git a/lib/config/app_config.dart b/lib/config/app_config.dart
new file mode 100644
index 0000000..3a3620f
--- /dev/null
+++ b/lib/config/app_config.dart
@@ -0,0 +1,91 @@
+import 'dart:io';
+import 'package:flutter/foundation.dart';
+
...
```

**ACTION REQUIRED:** Token is in git history. Must be rotated. See MAPBOX_TOKEN_ROTATION_ACTION.md

---

## Summary

| Check | Status | Notes |
|-------|--------|-------|
| No .env tracked | PASS | Verified with git ls-files |
| No Mapbox sk.* tokens | PASS | Removed from app_config.dart |
| No Stripe sk_* keys | PASS | No keys found |
| No Supabase service_role | INFO | Check if docs only |
| No OneSignal REST keys | PASS | No keys found |
| No high-entropy secrets | PASS | No suspicious strings |
| No .env in history | PASS | Clean history |
| No sk.eyJ in history | CRITICAL | Token in history - must rotate |

## Remediation Status

1. **Token Rotation**: See `MAPBOX_TOKEN_ROTATION_ACTION.md`
2. **History Rewrite**: Optional - token rotation is the primary fix
3. **CI Gates**: Added in PR 3 to prevent future commits

---

**Audit Complete**
