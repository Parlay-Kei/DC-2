# Release QA Checklist

## Pre-Release Validation (P0-QA-504)

Run these tests on a RELEASE build before any production deployment.

---

### 1. Anonymous User - Nearby Barber Discovery

**Test**: Logged out user can browse barbers

| Step | Expected | Pass |
|------|----------|------|
| Launch app (logged out) | Welcome screen or home screen loads | [ ] |
| Navigate to Nearby/Explore | Map or list view loads | [ ] |
| Barbers appear on map/list | At least 1 barber visible (if seeded) | [ ] |
| Tap on barber | Profile summary shows (safe fields only) | [ ] |
| Attempt to book | Redirects to login | [ ] |

**Evidence required**: Screenshot of Nearby view with barber count

---

### 2. Anonymous User - Cannot Access Private Data

**Test**: Logged out user cannot access protected routes/data

| Step | Expected | Pass |
|------|----------|------|
| Deep link to /profile | Redirects to login | [ ] |
| Deep link to /barber/appointments | Redirects to login | [ ] |
| Check network tab | No private data in responses | [ ] |

---

### 3. Role Selection Flow

**Test**: New user can select role and it persists

| Step | Expected | Pass |
|------|----------|------|
| Create new account | Account created successfully | [ ] |
| Role selection screen appears | Customer/Barber options visible | [ ] |
| Select "Customer" | Role saved, navigates to customer home | [ ] |
| Force quit and relaunch | Still logged in as customer | [ ] |
| Check Build Info screen | Shows role = customer | [ ] |

**Evidence required**: Screenshot of Build Info showing role

---

### 4. Role Update Verification (RLS Check)

**Test**: Role update shows explicit error if blocked

| Step | Expected | Pass |
|------|----------|------|
| Login as existing user | Home screen loads | [ ] |
| Attempt role change (if available) | Either succeeds or shows clear error | [ ] |
| Check database | Role matches what app displays | [ ] |

**Note**: If role update silently fails, this is a P0 bug.

---

### 4b. Cross-Device Role Truth (P0-QA-603)

**Test**: Role is server-authoritative, not local-storage dependent

| Step | Expected | Pass |
|------|----------|------|
| Device A: Create account, choose "Barber" | Routes to barber dashboard | [ ] |
| Device B: Login same user (fresh install) | Routes to barber dashboard immediately | [ ] |
| No role selection prompt on Device B | Role fetched from server, not prompted | [ ] |
| Clear app data on Device A, relaunch | Still routes as Barber after login | [ ] |

**Evidence required**: Screenshot of Device B showing barber dashboard without role prompt

**Why this matters**: If role is stored only in local SharedPreferences, a user who logs in on a new device will be prompted to select role again, potentially creating data inconsistencies.

---

### 5. Barber Location Privacy

**Test**: Barber location settings work correctly

| Step | Expected | Pass |
|------|----------|------|
| Login as barber | Barber dashboard loads | [ ] |
| Navigate to Location Settings | Current location type shown | [ ] |
| Change location type | Warning dialog appears | [ ] |
| Confirm location | location_type saved to database | [ ] |
| Check public view as anon user | Coordinates visible only if location_type set | [ ] |

**Evidence required**: Screenshot of location settings with warning

---

### 5b. Legacy Barber Location Type Migration (P0-QA-604)

**Test**: Barber with coords but no location_type sees yellow warning and can fix

| Step | Expected | Pass |
|------|----------|------|
| Seed barber with coords + null location_type | Barber exists in database | [ ] |
| Login as that barber | Dashboard loads | [ ] |
| Navigate to Location Settings | Yellow "Not Visible" warning appears | [ ] |
| Yellow card shows explanation | "Customers can't see you until..." text visible | [ ] |
| Click "Business" or "Service Area" button | Type saved, card turns green | [ ] |
| Logged out customer Nearby | Barber now appears in results | [ ] |

**Evidence required**: Screenshot of yellow warning → green confirmation transition

---

### 5c. Location Clear and Re-set Flow (P0-QA-605)

**Test**: Clearing location resets type, re-setting requires confirmation

| Step | Expected | Pass |
|------|----------|------|
| Login as barber with location set | Green "Visible" status | [ ] |
| Click "Clear Location" | Confirmation dialog appears | [ ] |
| Confirm clear | Gray "No Location Set" status | [ ] |
| Use GPS to set new location | Type confirmation dialog appears | [ ] |
| Confirm type | Green "Visible" status restored | [ ] |
| Save address when type already set | NO dialog (type preserved) | [ ] |

**Why this matters**: Ensures type is cleared with coords and re-prompted only when needed.

---

### 6. Build Info Screen Validation

**Test**: Configuration is correctly detected

| Step | Expected | Pass |
|------|----------|------|
| Navigate to Profile > Build Info | Screen loads | [ ] |
| Mapbox Token | Shows "Configured" (green) or "Missing" (red) | [ ] |
| Supabase URL | Shows masked hostname | [ ] |
| Supabase Key | Shows "Configured" or "Missing" | [ ] |
| OneSignal App ID | Shows status | [ ] |
| Copy button works | Copies sanitized info to clipboard | [ ] |

**Evidence required**: Screenshot of Build Info screen

---

### 7. Performance Baseline

**Test**: Nearby barber query performs acceptably

| Step | Expected | Pass |
|------|----------|------|
| Open Nearby view | Loads in < 2 seconds | [ ] |
| Check logs/network | RPC call completes < 500ms | [ ] |
| With 50+ barbers | Still loads in < 3 seconds | [ ] |

---

## Post-Release Monitoring

- [ ] Check Supabase dashboard for RPC error rates
- [ ] Monitor for "Invalid latitude/longitude" errors (indicates parameter validation working)
- [ ] Check for slow query alerts on `get_nearby_barbers`

---

## Sign-Off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| QA Lead | | | |
| Dev Lead | | | |
| Product Owner | | | |

---

## Release Evidence Pack (REQUIRED)

**No release is "complete" without this pack. A build without evidence is "built", not "shipped".**

### Required Artifacts

| # | Artifact | Description | Attached |
|---|----------|-------------|----------|
| 1 | Build Info Copy | Paste from Build Info screen "Copy to Clipboard" | [ ] |
| 2 | Screenshot: Nearby (logged out) | Shows barbers visible to anon users | [ ] |
| 3 | Screenshot: Barber Location Settings | Shows Green "Visible" state | [ ] |
| 4 | Screenshot: Cross-Device Login | Device B routes correctly (no role prompt) | [ ] |
| 5 | DB Health Snapshot | Paste SQL query output (see below) | [ ] |

### Build Info Copy Template

```
App: Direct Cuts
Version: X.X.X+N
Build Mode: release
Mapbox Token: ✓ Configured
Supabase URL: xxxxxx.supabase.co
Supabase Key: ✓ Configured
OneSignal: ✓ Configured
User Role: [customer|barber|null]
```

### Log Snippet Template (Role Update)

```
RoleProvider: Updating role to 'barber' for user abc123
RoleProvider: Role update sent, verifying persistence...
RoleProvider: Re-fetch confirmed role = 'barber' ✓
```

### Log Snippet Template (RPC Timing)

```
NearbyBarbersProvider: Starting PUBLIC search at (36.1699, -115.1398)
NearbyBarbersProvider: Found 12 barbers in 287ms
```

### DB Health Snapshot Query

Run in Supabase SQL Editor and paste output:

```sql
SELECT
  count(*) FILTER (WHERE is_active = true) AS active_barbers,
  count(*) FILTER (WHERE is_active = true AND latitude IS NOT NULL AND longitude IS NOT NULL) AS active_with_coords,
  count(*) FILTER (WHERE is_active = true AND latitude IS NOT NULL AND longitude IS NOT NULL AND location_type IS NOT NULL) AS active_visible
FROM public.barbers;
```

**Expected**: `active_with_coords` = `active_visible` (zero invisible barbers)

If `active_with_coords > active_visible`, you have barbers lurking invisibly. Fix before release.

---

## Appendix: Migration Execution Order

```
1. 20251231000000_create_profiles_table.sql
2. 20251231000001_add_profiles_rls_policies.sql
3. 20251231000002_create_public_barbers_view.sql
4. 20251231000003_create_public_barbers_rpc.sql
5. 20251231000004_harden_public_rpcs.sql
6. 20251231000005_add_location_type_constraint.sql
7. 20251231000006_enforce_location_type_constraint.sql
```

All migrations must complete without errors before release.

**Note**: Migration 6 adds a CHECK constraint that enforces `location_type IS NOT NULL` when coordinates exist. Run migration 5 first to backfill existing rows.
