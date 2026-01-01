# Release Gate Proofs - P0 Hardening Sprint

Pre-ship verification tests for the pending booking expiry, duration source of truth, and barber supply growth features.

## 1. Pending Booking Expiry Proof

**Goal**: Verify abandoned pending bookings auto-expire after 15 minutes and release the slot.

### Test Procedure

```sql
-- Step 1: Create a test pending booking (backdated to 16 minutes ago)
INSERT INTO public.appointments (
  id, barber_id, customer_id, service_id,
  start_time, end_time, status, created_at
)
VALUES (
  gen_random_uuid(),
  '<test_barber_id>',
  '<test_customer_id>',
  '<test_service_id>',
  NOW() + INTERVAL '1 day',
  NOW() + INTERVAL '1 day' + INTERVAL '30 minutes',
  'pending',
  NOW() - INTERVAL '16 minutes'  -- Created 16 min ago
);

-- Step 2: Verify slot is blocked
SELECT COUNT(*) FROM public.appointments
WHERE barber_id = '<test_barber_id>'
  AND status IN ('pending', 'confirmed')
  AND start_time = NOW() + INTERVAL '1 day';
-- Expected: 1

-- Step 3: Run the expiry function
SELECT public.expire_stale_pending_bookings();
-- Expected: {"expired_count": 1, "pending_remaining": 0, ...}

-- Step 4: Verify booking is now expired
SELECT status FROM public.appointments WHERE id = '<booking_id>';
-- Expected: 'expired'

-- Step 5: Verify slot is now available (can create new booking)
INSERT INTO public.appointments (...)
  VALUES (...same_slot...);
-- Expected: SUCCESS (no constraint violation)
```

### Expected Results
- [x] Pending booking created 16+ minutes ago gets status='expired'
- [x] Exclusion constraint no longer blocks the slot
- [x] Function returns observability JSON with expired_count

### Edge Cases to Verify
- Pending booking < 15 min old: NOT expired
- Confirmed booking > 15 min old: NOT touched
- Cancelled/completed bookings: NOT touched

---

## 2. Duration/Price Tamper Proof

**Goal**: Verify create_booking RPC ignores client-provided duration/price and uses DB values.

### Test Procedure

```sql
-- Step 1: Check existing service values
SELECT id, duration_minutes, price FROM public.services
WHERE barber_id = '<test_barber_id>' LIMIT 1;
-- Note the real values: e.g., duration=30, price=25.00

-- Step 2: Call RPC with FAKE values
SELECT public.create_booking(
  p_barber_id := '<test_barber_id>',
  p_customer_id := '<test_customer_id>',
  p_service_id := '<service_id>',
  p_start_time := NOW() + INTERVAL '2 days',
  p_duration_minutes := 999,  -- FAKE: should be ignored
  p_price := 0.01            -- FAKE: should be ignored
);

-- Step 3: Verify booking uses DB values, not client values
SELECT
  end_time - start_time AS actual_duration,
  price
FROM public.appointments
WHERE id = '<returned_booking_id>';
-- Expected: 30 minutes, $25.00 (from services table)
```

### Expected Results
- [x] RPC accepts call even with fake duration/price
- [x] Booking end_time calculated from services.duration_minutes
- [x] Booking price set from services.price
- [x] Client values completely ignored

### Security Edge Cases
- Service belongs to different barber: REJECT with 'INVALID_SERVICE'
- Service is inactive: REJECT with 'INVALID_SERVICE'
- Service doesn't exist: REJECT with 'INVALID_SERVICE'

---

## 3. Referral Link Deep Link Proof

**Goal**: Verify barber referral links work for logged-out users.

### Test Procedure

1. **Generate Link**: From barber dashboard, tap Share > Copy Link
   - Expected format: `https://directcuts.app/b/{barberId}`

2. **Test Logged Out**:
   - Open incognito/private browser
   - Navigate to referral link
   - Expected: Barber profile visible (name, services, ratings, location)
   - Expected: Book button visible (redirects to login)

3. **Verify RPC Works for Anon**:
```sql
-- As anon role
SELECT * FROM public.get_public_barbers()
WHERE id = '<barber_id>';
-- Expected: Row returned with display_name, rating, etc.
```

### Expected Results
- [x] Link format is correct
- [x] Anon users can view barber profile
- [x] Booking CTA redirects to login (not error)
- [x] No PII exposed (no phone, email, exact address)

---

## 4. Onboarding Checklist Alignment Proof

**Goal**: Verify Go Live checklist matches public_barbers visibility rules.

### Visibility Rules (DB)
From `public_barbers` view:
```sql
WHERE is_active = true
  AND latitude IS NOT NULL
  AND longitude IS NOT NULL
  AND location_type IS NOT NULL
```

### Checklist Rules (Flutter)
From `onboarding_progress.dart`:
```dart
// Location step
hasValidLocation = barber.hasLocation && barber.locationType != null

// Visibility step
isComplete: hasValidLocation && barber.isActive
```

### Test Cases

| State | public_barbers | Checklist "Go Live" | Match? |
|-------|---------------|---------------------|--------|
| is_active=false, coords=null | Hidden | Incomplete | YES |
| is_active=true, coords=set, type=null | Hidden | Incomplete | YES |
| is_active=true, coords=set, type=set | Visible | Complete | YES |
| is_active=false, coords=set, type=set | Hidden | Incomplete | YES |

### Expected Results
- [x] All 4 test cases pass
- [x] No state where barber thinks they're live but aren't visible
- [x] No state where barber is visible but checklist shows incomplete

---

## Summary Checklist

Before shipping:

- [ ] Pending expiry: Create booking 16 min ago, run expiry, verify slot freed
- [ ] Duration tamper: Call RPC with fake values, verify DB values used
- [ ] Referral link: Open in incognito, verify barber visible
- [ ] Checklist alignment: Verify all 4 state combinations match

## Post-Ship Monitoring

### Pending Expiry Observability
Monitor the Edge Function logs for the JSON output:
```json
{
  "expired_count": 2,
  "pending_remaining": 5,
  "oldest_pending_age_seconds": 845,
  "run_at": "2025-12-31T12:00:00Z"
}
```

Alert if:
- `oldest_pending_age_seconds` > 1800 (30 min) - cron may be failing
- `expired_count` > 10 in single run - possible abuse or UX issue

### Duration Source of Truth
No runtime monitoring needed - the RPC enforces this at DB level.

### Barber Supply Growth
Track in analytics:
- Share button tap rate (referral_card.dart)
- Onboarding completion rate by step
- Time from signup to "Go Live"

---

## Migration Re-Run Warning

**CRITICAL**: The `public_barbers` view was updated to require `location_type IS NOT NULL`.

Views don't auto-update across deployments. For any environment already created:

```bash
# Re-apply the view migration
supabase db push

# Or run directly in SQL Editor - paste full CREATE VIEW from:
# supabase/migrations/20251231000002_create_public_barbers_view.sql
```

**Verify after re-run:**
```sql
-- Should match: SELECT COUNT(*) FROM barbers
--   WHERE is_active AND lat/lng NOT NULL AND location_type NOT NULL
SELECT COUNT(*) FROM public.public_barbers;
```

---

## Post-Ship Feedback Loop (Minimum Viable)

### 1. "Report an Issue" Link (In-App)

Add to Settings screen - copies to clipboard:
```
Build: 2.0.3+4
Device: iPhone 14 Pro / iOS 17.2
Last Action: booking_confirm
Timestamp: 2025-12-31T14:30:00Z
```

### 2. Lightweight Event Log

Track these events (Supabase or logging service):

| Event | When to Log |
|-------|-------------|
| `SLOT_TAKEN` | Booking fails due to exclusion constraint |
| `RPC_ERROR` | Any create_booking RPC failure |
| `EXPIRED_COUNT` | From expire_stale_pending_bookings() result |
| `SERVICE_INVALID` | Service ownership/active check fails |

**Not analytics theater. Just enough to see where reality disagrees with assumptions.**

---

## Release Verdict

> Your system used to feel like a vending machine that sometimes dispensed coins instead of snacks.
> Now it dispenses what's selected, refunds when it can't, and tells you when the power is out.

**Ship when all proofs pass.**
