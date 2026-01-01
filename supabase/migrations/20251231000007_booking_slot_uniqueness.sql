-- Migration: Booking Slot Uniqueness + Atomic Booking RPC
-- Created: 2025-12-31
-- Description: Prevents double-booking at the database level
--
-- WHY THIS MATTERS:
-- - Current booking flow has a race condition between availability check and insert
-- - Two customers can book the same slot simultaneously
-- - This migration makes double-booking impossible
--
-- ACTUAL SCHEMA:
-- - appointments.start_time (timestamptz) - when the appointment starts
-- - appointments.end_time (timestamptz) - when it ends
-- - appointments.status (text) - pending, confirmed, completed, cancelled, no_show

-- ============================================================
-- A) UNIQUE INDEX ON ACTIVE BOOKINGS
-- ============================================================
-- A barber can only have ONE active booking per start_time
-- Only applies to pending/confirmed bookings (cancelled/completed don't block)

CREATE UNIQUE INDEX IF NOT EXISTS ux_appointments_barber_slot
ON public.appointments (barber_id, start_time)
WHERE status IN ('pending', 'confirmed');

COMMENT ON INDEX ux_appointments_barber_slot IS
  'Prevents double-booking: one active appointment per barber per start time';

-- ============================================================
-- B) CREATE ATOMIC BOOKING RPC
-- ============================================================

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
  -- Unique index will reject if slot already taken

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
    RAISE EXCEPTION 'SLOT_TAKEN: This time slot was just booked'
      USING ERRCODE = 'P0005';
END;
$$;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION public.create_booking TO authenticated;

-- ============================================================
-- C) DOCUMENTATION
-- ============================================================

COMMENT ON FUNCTION public.create_booking IS
  'Atomically creates a booking. Fails with SLOT_TAKEN if double-booking attempted.';

-- ============================================================
-- ROLLBACK
-- ============================================================
-- DROP FUNCTION IF EXISTS public.create_booking;
-- DROP INDEX IF EXISTS ux_appointments_barber_slot;
