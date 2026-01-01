-- Migration: Duration Source of Truth (DB computes from service_id)
-- Created: 2025-12-31
-- Description: Modifies create_booking RPC to lookup duration from services table
--
-- WHY THIS MATTERS:
-- - Currently client passes duration (p_duration_minutes) - can be tampered
-- - Service table is the canonical source for duration and price
-- - DB should compute end_time and price from service_id lookup
-- - Removes trust dependency on client-side values
--
-- APPROACH:
-- 1. Update create_booking RPC to lookup service by ID
-- 2. Extract duration_minutes and price from service record
-- 3. Reject booking if service not found or inactive
-- 4. Remove need for client to pass duration/price (backwards compatible - ignores if passed)

-- ============================================================
-- A) UPDATE create_booking RPC
-- ============================================================
-- Drops old signatures and creates new secure version

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
  p_duration_minutes INT DEFAULT NULL,  -- IGNORED: kept for backwards compat
  p_price NUMERIC DEFAULT NULL          -- IGNORED: kept for backwards compat
)
RETURNS public.appointments
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_customer_id UUID := auth.uid();
  v_service RECORD;
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

  -- ========== SERVICE LOOKUP (SOURCE OF TRUTH) ==========
  -- Get duration and price from services table - NOT from client

  SELECT
    id,
    duration_minutes,
    price,
    is_active
  INTO v_service
  FROM public.services
  WHERE id = p_service_id
    AND barber_id = p_barber_id;

  IF v_service IS NULL THEN
    RAISE EXCEPTION 'INVALID_SERVICE: Service not found for this barber'
      USING ERRCODE = 'P0002';
  END IF;

  IF NOT v_service.is_active THEN
    RAISE EXCEPTION 'INVALID_SERVICE: Service is no longer available'
      USING ERRCODE = 'P0002';
  END IF;

  -- ========== CALCULATE END TIME FROM SERVICE DURATION ==========
  -- Duration comes from DB, not client

  v_end_time := p_start_time + (v_service.duration_minutes || ' minutes')::INTERVAL;

  -- ========== PRICE FROM SERVICE (NOT CLIENT) ==========
  -- Price comes from DB, not client

  v_price := v_service.price;
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
  'Atomically creates a booking. Duration and price are looked up from services table (source of truth).
   p_duration_minutes and p_price params are IGNORED (kept for backwards compatibility).
   Fails with SLOT_TAKEN if double-booking or overlap attempted.
   Fails with INVALID_SERVICE if service not found or inactive.';

-- ============================================================
-- B) ADD INDEX ON SERVICES FOR LOOKUP
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_services_barber_active
ON public.services (barber_id)
WHERE is_active = true;

COMMENT ON INDEX idx_services_barber_active IS
  'Supports efficient service lookup in create_booking RPC.';

-- ============================================================
-- ROLLBACK
-- ============================================================
-- To rollback, restore the previous version of create_booking from migration 008
-- DROP INDEX IF EXISTS idx_services_barber_active;
