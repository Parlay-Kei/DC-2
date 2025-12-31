# Mapbox Token Types Explained

## Public vs Secret Tokens

### Public Tokens (`pk.*`)
- **Use Case:** Web applications with URL restrictions
- **Scopes:** `styles:read`, `fonts:read` (public scopes)
- **Limitation:** Cannot include `tiles:read` (that's a secret scope)
- **Security:** Safe to expose in client-side web code
- **URL Restrictions:** Can be restricted to specific domains

### Secret Tokens (`sk.*`)
- **Use Case:** Mobile apps OR server-side applications
- **Scopes:** Can include `tiles:read` (secret scope) + public scopes
- **Required For:** Reading map tiles (mobile apps need this!)
- **Security:** Safe when embedded in mobile app binary, NOT safe for web client code
- **URL Restrictions:** Should be empty for mobile apps

## Why Mobile Apps Need Secret Tokens

When you add the `tiles:read` scope (required for loading map tiles), Mapbox automatically makes the token a secret token (`sk.*`). This is **normal and expected** for mobile apps.

### Is This Safe?

**Yes, for mobile apps:**
- ✅ Token is compiled into the app binary
- ✅ Not exposed via network to third parties
- ✅ Only has read-only permissions
- ✅ Can be revoked anytime in Mapbox Dashboard

**No, for web apps:**
- ❌ Secret tokens should NOT be used in web client code
- ❌ Web apps should use public tokens with URL restrictions
- ❌ Web apps can use `styles:read` and `fonts:read` without `tiles:read`

## Token Configuration by Platform

### Web App (React/TypeScript)
```
Type: Public (pk.*)
Scopes: styles:read, fonts:read
URL Restrictions: https://yourdomain.com, http://localhost:*
NOT: tiles:read (not available for public tokens)
```

### Mobile App (Flutter)
```
Type: Secret (sk.*) - automatically when tiles:read is added
Scopes: styles:read, fonts:read, tiles:read
URL Restrictions: NONE (empty)
Safe: Yes, when embedded in app binary
```

### Server/Edge Functions
```
Type: Secret (sk.*)
Scopes: geocoding:read (or other server scopes)
URL Restrictions: NONE
Storage: Environment variables, secrets (never in client code)
```

## Summary

- **Web:** Use public token (`pk.*`) with URL restrictions, no `tiles:read`
- **Mobile:** Use secret token (`sk.*`) with `tiles:read`, no URL restrictions
- **Server:** Use secret token (`sk.*`) with appropriate server scopes

The fact that mobile tokens are secret is a Mapbox design decision, not a security issue for mobile apps.

