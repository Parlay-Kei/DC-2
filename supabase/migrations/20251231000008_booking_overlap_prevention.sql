-- Migration: Booking Overlap Prevention with Exclusion Constraint
-- Created: 2025-12-31
-- Description: Prevents overlapping appointments using tstzrange exclusion
--
-- WHY THIS MATTERS:
-- - Unique index on start_time prevents exact duplicates but NOT overlaps
-- - Example failure: 10:00 (60 min) + 10:30 (30 min) = both allowed but overlap
-- - Exclusion constraint makes overlapping appointments impossible
--
-- PREREQUISITES:
-- - btree_gist extension (for exclusion on non-range types)
-- - end_time must be NOT NULL for all appointments
--
-- APPROACH:
-- 1. Enable btree_gist extension
-- 2. Backfill end_time for any NULL values (30 min default)
-- 3. Add NOT NULL constraint on end_time
-- 4. Add exclusion constraint using tstzrange

-- ============================================================
-- A) ENABLE btree_gist EXTENSION
-- ============================================================
-- Required for exclusion constraints that mix range and equality operators

CREATE EXTENSION IF NOT EXISTS btree_gist;

-- ============================================================
-- B) BACKFILL end_time FOR EXISTING APPOINTMENTS
-- ============================================================
-- For any appointments with NULL end_time, compute from service duration
-- or default to 30 minutes if service lookup fails

UPDATE public.appointments a
SET end_time = a.start_time + INTERVAL '30 minutes'
WHERE a.end_time IS NULL;

-- Note: Skipping service-based duration lookup since schema varies
-- All appointments get 30 min default; new bookings will use actual duration from RPC

-- ============================================================
-- C) ADD NOT NULL CONSTRAINT ON end_time
-- ============================================================

ALTER TABLE public.appointments
ALTER COLUMN end_time SET NOT NULL;

-- ============================================================
-- D) ADD EXCLUSION CONSTRAINT FOR OVERLAP PREVENTION
-- ============================================================
-- Uses half-open interval [start, end) so adjacent bookings don't conflict
-- Only applies to active bookings (pending/confirmed)

ALTER TABLE public.appointments
ADD CONSTRAINT no_overlapping_appointments
EXCLUDE USING gist (
  barber_id WITH =,
  tstzrange(start_time, end_time, '[)') WITH &&
)
WHERE (status IN ('pending', 'confirmed'));

COMMENT ON CONSTRAINT no_overlapping_appointments ON public.appointments IS
  'Prevents overlapping appointments for the same barber. Uses half-open interval [start, end).';

-- ============================================================
-- E) UPDATE create_booking RPC TO HANDLE OVERLAP ERRORS
-- ============================================================
-- Drop old function signatures first to avoid ambiguity
-- Then create new version with duration and price params

DROP FUNCTION IF EXISTS public.create_booking(UUID, UUID, TIMESTAMPTZ, TEXT, TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS public.create_booking(UUID, UUID, TIMESTAMPTZ, TEXT, TEXT, TEXT, TEXT, INT, NUMERIC);

CREATE OR REPLACE FUNCTION public.create_booking(
  p_barber_id UUID,
  p_service_id UUID,
  p_start_time TIMESTAMPTZ,
  p_payment_method TEXT,
  p_location_type TEXT DEFAULT 'shop',
  p_address TEXT DEFAULT NULL,
  p_notes TEXT DEFAULT NULL,
  p_duration_minutes INT DEFAULT 30,
  p_price NUMERIC DEFAULT NULL
)
RETURNS public.appointments
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_customer_id UUID := auth.uid();
  v_end_time TIMESTAMPTZ;
  v_price NUMERIC;
  v_platform_fee NUMERIC;
  v_appt public.appointments;
BEGIN
  -- ========== VALIDATION ==========

  IF v_customer_id IS NULL THEN
    RAISE EXCEPTION 'AUTH_REQUIRED: Must be logged in to book'
      USING ERRCODE = 'P0001';
  END IF;

  -- Validate payment method
  IF p_payment_method NOT IN ('card', 'cash') THEN
    RAISE EXCEPTION 'INVALID_PAYMENT: Must be card or cash'
      USING ERRCODE = 'P0003';
  END IF;

  -- Validate location type
  IF p_location_type NOT IN ('shop', 'mobile') THEN
    RAISE EXCEPTION 'INVALID_LOCATION: Must be shop or mobile'
      USING ERRCODE = 'P0004';
  END IF;

  -- ========== CALCULATE END TIME ==========
  -- Duration and price passed from client (looked up from service there)

  v_end_time := p_start_time + (p_duration_minutes || ' minutes')::INTERVAL;

  -- ========== PRICE CALCULATION ==========
  -- Price passed from client (looked up from service there)

  v_price := COALESCE(p_price, 0);
  v_platform_fee := v_price * 0.15;

  -- ========== ATOMIC INSERT ==========
  -- Both unique index AND exclusion constraint will reject conflicts

  INSERT INTO public.appointments (
    customer_id,
    barber_id,
    service_id,
    start_time,
    end_time,
    status,
    price,
    platform_fee,
    payment_method,
    payment_status,
    location_type,
    service_address,
    notes
  ) VALUES (
    v_customer_id,
    p_barber_id,
    p_service_id,
    p_start_time,
    v_end_time,
    'pending',
    v_price,
    v_platform_fee,
    p_payment_method,
    'pending',
    p_location_type::location_type,
    p_address,
    p_notes
  )
  RETURNING * INTO v_appt;

  RETURN v_appt;

EXCEPTION
  WHEN unique_violation THEN
    -- Exact start_time conflict (from ux_appointments_barber_slot)
    RAISE EXCEPTION 'SLOT_TAKEN: This time slot was just booked'
      USING ERRCODE = 'P0005';
  WHEN exclusion_violation THEN
    -- Overlapping time range conflict (from no_overlapping_appointments)
    RAISE EXCEPTION 'SLOT_TAKEN: This time overlaps with an existing booking'
      USING ERRCODE = 'P0005';
END;
$$;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION public.create_booking TO authenticated;

COMMENT ON FUNCTION public.create_booking IS
  'Atomically creates a booking. Fails with SLOT_TAKEN if double-booking or overlap attempted.';

-- ============================================================
-- ROLLBACK
-- ============================================================
-- ALTER TABLE public.appointments DROP CONSTRAINT IF EXISTS no_overlapping_appointments;
-- ALTER TABLE public.appointments ALTER COLUMN end_time DROP NOT NULL;
-- DROP EXTENSION IF EXISTS btree_gist;
