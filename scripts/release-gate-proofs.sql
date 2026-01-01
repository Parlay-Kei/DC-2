-- ============================================================
-- RELEASE GATE PROOFS - Execute against Supabase SQL Editor
-- ============================================================
-- Run each section, capture output, attach to release notes
-- Date: 2025-12-31
-- ============================================================

-- ============================================================
-- 1. DB HEALTH SNAPSHOT
-- ============================================================

-- 1a. Active barbers (total)
SELECT 'active_barbers' AS metric, COUNT(*) AS count
FROM public.barbers
WHERE is_active = true;

-- 1b. Active with coords
SELECT 'active_with_coords' AS metric, COUNT(*) AS count
FROM public.barbers
WHERE is_active = true
  AND latitude IS NOT NULL
  AND longitude IS NOT NULL;

-- 1c. Active visible ready (matches public_barbers view)
SELECT 'active_visible_ready' AS metric, COUNT(*) AS count
FROM public.barbers
WHERE is_active = true
  AND latitude IS NOT NULL
  AND longitude IS NOT NULL
  AND location_type IS NOT NULL;

-- 1d. Cross-check: public_barbers view count should match 1c
SELECT 'public_barbers_view' AS metric, COUNT(*) AS count
FROM public.public_barbers;

-- ============================================================
-- 2. BOOKING OVERLAP PROOF (DETERMINISTIC)
-- ============================================================
-- Proves: 10:00 (60m) blocks 10:30 (30m) for same barber
-- Self-contained: finds real IDs, creates bookings, asserts failure, cleans up

DO $$
DECLARE
  v_barber_id UUID;
  v_customer_id UUID;
  v_service_id UUID;
  v_first_booking_id UUID;
  v_test_start TIMESTAMPTZ;
  v_overlap_failed BOOLEAN := FALSE;
BEGIN
  -- Find a valid barber with an active service
  SELECT b.id, s.id INTO v_barber_id, v_service_id
  FROM public.barbers b
  JOIN public.services s ON s.barber_id = b.id AND s.is_active = true
  WHERE b.is_active = true
  LIMIT 1;

  IF v_barber_id IS NULL THEN
    RAISE EXCEPTION 'PROOF FAILED: No active barber with active service found';
  END IF;

  -- Find a valid customer (any profile, or use barber as self-booking for test)
  SELECT id INTO v_customer_id
  FROM public.profiles
  LIMIT 1;

  -- If no profiles exist, use the barber ID (self-booking is valid for constraint testing)
  IF v_customer_id IS NULL THEN
    v_customer_id := v_barber_id;
    RAISE NOTICE 'No profiles found, using barber as customer for constraint test';
  END IF;

  -- Use a test slot far in the future to avoid real data conflicts
  v_test_start := DATE_TRUNC('day', NOW()) + INTERVAL '30 days' + INTERVAL '10 hours';

  RAISE NOTICE 'Testing with barber=%, customer=%, service=%', v_barber_id, v_customer_id, v_service_id;

  -- Step 1: Create first booking 10:00-11:00 (confirmed)
  -- Include all NOT NULL financial fields
  INSERT INTO public.appointments (
    id, barber_id, customer_id, service_id,
    start_time, end_time, status, created_at,
    price, platform_fee, subtotal_cents, tip_amount_cents, total_cents, platform_fee_cents
  )
  VALUES (
    gen_random_uuid(),
    v_barber_id,
    v_customer_id,
    v_service_id,
    v_test_start,
    v_test_start + INTERVAL '1 hour',
    'confirmed',
    NOW(),
    25.00, 3.75, 2500, 0, 2500, 375  -- Test values for required financial fields
  )
  RETURNING id INTO v_first_booking_id;

  RAISE NOTICE 'Created first booking: % (10:00-11:00)', v_first_booking_id;

  -- Step 2: Attempt overlapping booking 10:30-11:00 (should fail)
  BEGIN
    INSERT INTO public.appointments (
      id, barber_id, customer_id, service_id,
      start_time, end_time, status, created_at,
      price, platform_fee, subtotal_cents, tip_amount_cents, total_cents, platform_fee_cents
    )
    VALUES (
      gen_random_uuid(),
      v_barber_id,
      v_customer_id,
      v_service_id,
      v_test_start + INTERVAL '30 minutes',
      v_test_start + INTERVAL '1 hour',
      'pending',
      NOW(),
      25.00, 3.75, 2500, 0, 2500, 375
    );
    -- If we get here, the constraint didn't fire
    RAISE EXCEPTION 'PROOF FAILED: Overlapping booking was ALLOWED (constraint broken)';
  EXCEPTION
    WHEN exclusion_violation THEN
      v_overlap_failed := TRUE;
      RAISE NOTICE 'PROOF PASSED: Overlapping booking correctly rejected';
  END;

  -- Cleanup
  DELETE FROM public.appointments WHERE id = v_first_booking_id;
  RAISE NOTICE 'Cleaned up test booking';

  IF NOT v_overlap_failed THEN
    RAISE EXCEPTION 'PROOF FAILED: Expected exclusion_violation but got different error';
  END IF;

  RAISE NOTICE '✓ OVERLAP PROOF COMPLETE: 10:00 (60m) correctly blocks 10:30 (30m)';
END $$;

-- ============================================================
-- 3. PENDING EXPIRY PROOF (DETERMINISTIC)
-- ============================================================
-- Proves: pending booking older than 15 min becomes 'expired'
-- Self-contained: creates stale booking, runs expiry, verifies, cleans up
-- NOTE: Requires service_role to execute expire function

DO $$
DECLARE
  v_barber_id UUID;
  v_customer_id UUID;
  v_service_id UUID;
  v_stale_booking_id UUID;
  v_test_start TIMESTAMPTZ;
  v_status_before TEXT;
  v_status_after TEXT;
  v_expiry_result JSON;
  v_slot_blocked_before INT;
  v_slot_blocked_after INT;
BEGIN
  -- Find a valid barber with an active service
  SELECT b.id, s.id INTO v_barber_id, v_service_id
  FROM public.barbers b
  JOIN public.services s ON s.barber_id = b.id AND s.is_active = true
  WHERE b.is_active = true
  LIMIT 1;

  IF v_barber_id IS NULL THEN
    RAISE EXCEPTION 'PROOF FAILED: No active barber with active service found';
  END IF;

  -- Find a valid customer (any profile, or use barber as self-booking for test)
  SELECT id INTO v_customer_id
  FROM public.profiles
  LIMIT 1;

  -- If no profiles exist, use the barber ID (self-booking is valid for expiry testing)
  IF v_customer_id IS NULL THEN
    v_customer_id := v_barber_id;
    RAISE NOTICE 'No profiles found, using barber as customer for expiry test';
  END IF;

  -- Use a test slot far in the future
  v_test_start := DATE_TRUNC('day', NOW()) + INTERVAL '31 days' + INTERVAL '14 hours';

  RAISE NOTICE 'Testing with barber=%, customer=%, service=%', v_barber_id, v_customer_id, v_service_id;

  -- Step 1: Create stale pending booking (backdated 16 minutes)
  -- Include all NOT NULL financial fields
  INSERT INTO public.appointments (
    id, barber_id, customer_id, service_id,
    start_time, end_time, status, created_at,
    price, platform_fee, subtotal_cents, tip_amount_cents, total_cents, platform_fee_cents
  )
  VALUES (
    gen_random_uuid(),
    v_barber_id,
    v_customer_id,
    v_service_id,
    v_test_start,
    v_test_start + INTERVAL '1 hour',
    'pending',
    NOW() - INTERVAL '16 minutes',
    25.00, 3.75, 2500, 0, 2500, 375  -- Test values for required financial fields
  )
  RETURNING id INTO v_stale_booking_id;

  RAISE NOTICE 'Created stale pending booking: % (created 16 min ago)', v_stale_booking_id;

  -- Step 2: Verify slot is blocked BEFORE expiry
  SELECT COUNT(*) INTO v_slot_blocked_before
  FROM public.appointments
  WHERE barber_id = v_barber_id
    AND status IN ('pending', 'confirmed')
    AND start_time = v_test_start;

  IF v_slot_blocked_before != 1 THEN
    RAISE EXCEPTION 'PROOF FAILED: Slot not blocked before expiry (count=%)', v_slot_blocked_before;
  END IF;
  RAISE NOTICE 'Slot correctly blocked before expiry (count=%)', v_slot_blocked_before;

  -- Step 3: Run expiry function
  SELECT public.expire_stale_pending_bookings() INTO v_expiry_result;
  RAISE NOTICE 'Expiry result: %', v_expiry_result;

  -- Step 4: Verify booking is now expired
  SELECT status INTO v_status_after
  FROM public.appointments
  WHERE id = v_stale_booking_id;

  IF v_status_after != 'expired' THEN
    RAISE EXCEPTION 'PROOF FAILED: Booking status is % (expected expired)', v_status_after;
  END IF;
  RAISE NOTICE 'Booking correctly expired: status=%', v_status_after;

  -- Step 5: Verify slot is now available
  SELECT COUNT(*) INTO v_slot_blocked_after
  FROM public.appointments
  WHERE barber_id = v_barber_id
    AND status IN ('pending', 'confirmed')
    AND start_time = v_test_start;

  IF v_slot_blocked_after != 0 THEN
    RAISE EXCEPTION 'PROOF FAILED: Slot still blocked after expiry (count=%)', v_slot_blocked_after;
  END IF;
  RAISE NOTICE 'Slot correctly freed after expiry (count=%)', v_slot_blocked_after;

  -- Cleanup
  DELETE FROM public.appointments WHERE id = v_stale_booking_id;
  RAISE NOTICE 'Cleaned up test booking';

  RAISE NOTICE '✓ EXPIRY PROOF COMPLETE: 16-min-old pending -> expired, slot freed';
END $$;

-- ============================================================
-- 4. REFERRAL LINK PROOF
-- ============================================================
-- Proves: logged-out users can view barber via RPC

-- 4a. Get a public barber ID
SELECT id, display_name FROM public.public_barbers LIMIT 1;

-- 4b. Verify get_public_barbers RPC works (as anon)
-- This RPC is GRANT'd to anon role
SELECT * FROM public.get_public_barbers() LIMIT 5;

-- 4c. Verify get_nearby_barbers RPC works (as anon)
-- Using NYC coords as example
SELECT * FROM public.get_nearby_barbers(40.7128, -74.0060, 50) LIMIT 5;

-- 4d. Manual test: Open in incognito browser
-- URL: https://directcuts.app/b/<barber_id>
-- EXPECTED: Barber profile visible, Book button redirects to login

-- ============================================================
-- 5. DURATION SOURCE OF TRUTH PROOF
-- ============================================================
-- Proves: create_booking RPC uses DB values, ignores client values

-- 5a. Check service values
/*
SELECT id, name, duration_minutes, price
FROM public.services
WHERE barber_id = '<barber_id>' AND is_active = true
LIMIT 1;
-- Note: duration=30, price=25.00 (example)
*/

-- 5b. Call create_booking with FAKE values
/*
SELECT public.create_booking(
  p_barber_id := '<barber_id>',
  p_customer_id := '<customer_id>',
  p_service_id := '<service_id>',
  p_start_time := (DATE_TRUNC('day', NOW()) + INTERVAL '3 days' + INTERVAL '10 hours'),
  p_duration_minutes := 999,  -- FAKE
  p_price := 0.01             -- FAKE
);
*/

-- 5c. Verify DB values used
/*
SELECT
  id,
  EXTRACT(EPOCH FROM (end_time - start_time))/60 AS actual_duration_minutes,
  price
FROM public.appointments
WHERE id = '<returned_booking_id>';
-- EXPECTED: 30 minutes (from services), $25.00 (from services)
*/

-- ============================================================
-- SUMMARY CHECKLIST
-- ============================================================
-- Run this script in Supabase SQL Editor (with service_role for expiry proof)
-- All DO blocks are self-contained and will RAISE EXCEPTION on failure
--
-- [ ] DB Health: Run queries 1a-1d, verify 1c == 1d
-- [ ] Overlap: DO block auto-asserts (look for "✓ OVERLAP PROOF COMPLETE")
-- [ ] Expiry: DO block auto-asserts (look for "✓ EXPIRY PROOF COMPLETE")
-- [ ] Referral: Queries 4a-4c return rows, manual test 4d in incognito
-- [ ] Duration: Manual test - call create_booking with fake values, verify DB wins
--
-- EXPECTED OUTPUT ON SUCCESS:
--   NOTICE: ✓ OVERLAP PROOF COMPLETE: 10:00 (60m) correctly blocks 10:30 (30m)
--   NOTICE: ✓ EXPIRY PROOF COMPLETE: 16-min-old pending -> expired, slot freed
--
-- Save this output in the release evidence pack.
