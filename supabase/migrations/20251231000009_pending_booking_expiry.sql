-- Migration: Pending Booking Expiry (Auto-Cancel Abandoned Flows)
-- Created: 2025-12-31
-- Description: Auto-cancels pending bookings older than 15 minutes
--
-- WHY THIS MATTERS:
-- - Users may abandon booking flow mid-way, leaving slots "locked"
-- - Pending bookings block the slot due to exclusion constraint
-- - 15 minute window gives user time to complete payment but releases abandoned slots
--
-- APPROACH:
-- 1. Create function to expire stale pending bookings
-- 2. Create pg_cron job to run every 5 minutes
-- 3. Expired bookings get status='expired' (distinct from 'cancelled')

-- ============================================================
-- A) ADD EXPIRED STATUS IF NOT EXISTS
-- ============================================================
-- Check if 'expired' is already a valid status value
-- Some DBs use enum, some use check constraint

-- If using check constraint, we need to alter it
-- If just a string column, no change needed - Postgres accepts any string
-- We'll add a comment to document the new status

COMMENT ON COLUMN public.appointments.status IS
  'Booking status: pending, confirmed, completed, cancelled, no_show, expired.
   expired = auto-cancelled due to 15 minute timeout on pending bookings.';

-- ============================================================
-- B) CREATE EXPIRY FUNCTION
-- ============================================================
-- Marks pending bookings older than 15 minutes as expired
-- Uses NOW() (timestamptz) compared to created_at (timestamptz) - no timezone issues
-- Idempotent: safe to run every 5 minutes forever

CREATE OR REPLACE FUNCTION public.expire_stale_pending_bookings()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_expired_count INTEGER;
  v_oldest_pending_age INTERVAL;
  v_pending_count INTEGER;
BEGIN
  -- Get observability data BEFORE update
  SELECT
    COUNT(*),
    MAX(NOW() - created_at)
  INTO v_pending_count, v_oldest_pending_age
  FROM public.appointments
  WHERE status = 'pending';

  -- Expire pending bookings older than 15 minutes
  -- Only touches status='pending', never confirmed/cancelled/completed
  UPDATE public.appointments
  SET
    status = 'expired',
    updated_at = NOW()
  WHERE status = 'pending'
    AND created_at < NOW() - INTERVAL '15 minutes';

  GET DIAGNOSTICS v_expired_count = ROW_COUNT;

  -- Return observability data
  RETURN json_build_object(
    'expired_count', v_expired_count,
    'pending_remaining', v_pending_count - v_expired_count,
    'oldest_pending_age_seconds', COALESCE(EXTRACT(EPOCH FROM v_oldest_pending_age), 0)::INTEGER,
    'run_at', NOW()
  );
END;
$$;

COMMENT ON FUNCTION public.expire_stale_pending_bookings IS
  'Auto-cancels pending bookings older than 15 minutes. Run via cron every 5 minutes.
   Returns: {expired_count, pending_remaining, oldest_pending_age_seconds, run_at}';

-- ============================================================
-- C) CREATE CRON JOB (requires pg_cron extension)
-- ============================================================
-- pg_cron must be enabled in Supabase dashboard: Database > Extensions

-- NOTE: Uncomment the following after enabling pg_cron extension:
--
-- SELECT cron.schedule(
--   'expire-stale-pending-bookings',  -- job name
--   '*/5 * * * *',                    -- every 5 minutes
--   $$SELECT public.expire_stale_pending_bookings()$$
-- );

-- ============================================================
-- D) ALTERNATIVE: Edge Function Trigger
-- ============================================================
-- If pg_cron is not available, call this from a Supabase Edge Function
-- scheduled via external cron service (Vercel Cron, Railway Cron, etc.)
--
-- CREATE OR REPLACE FUNCTION public.expire_pending_bookings_api()
-- RETURNS JSON
-- LANGUAGE plpgsql
-- SECURITY DEFINER
-- AS $$
-- DECLARE
--   v_count INTEGER;
-- BEGIN
--   SELECT public.expire_stale_pending_bookings() INTO v_count;
--   RETURN json_build_object('expired_count', v_count, 'timestamp', NOW());
-- END;
-- $$;
--
-- GRANT EXECUTE ON FUNCTION public.expire_pending_bookings_api TO service_role;

-- ============================================================
-- E) INDEX FOR PERFORMANCE
-- ============================================================
-- Speed up the expiry query

CREATE INDEX IF NOT EXISTS idx_appointments_pending_created
ON public.appointments (created_at)
WHERE status = 'pending';

COMMENT ON INDEX idx_appointments_pending_created IS
  'Supports efficient lookup for pending booking expiry cron job.';

-- ============================================================
-- F) MANUAL TRIGGER FUNCTION (for Edge Function / testing)
-- ============================================================
-- SECURITY: Only service_role can call this. Revoke from public/anon/authenticated.

CREATE OR REPLACE FUNCTION public.trigger_pending_expiry()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Delegate to the core expiry function (which now returns JSON)
  RETURN public.expire_stale_pending_bookings();
END;
$$;

-- SECURITY: Restrict to service_role only
REVOKE ALL ON FUNCTION public.trigger_pending_expiry FROM PUBLIC;
REVOKE ALL ON FUNCTION public.trigger_pending_expiry FROM anon;
REVOKE ALL ON FUNCTION public.trigger_pending_expiry FROM authenticated;
GRANT EXECUTE ON FUNCTION public.trigger_pending_expiry TO service_role;

-- Also restrict the core function
REVOKE ALL ON FUNCTION public.expire_stale_pending_bookings FROM PUBLIC;
REVOKE ALL ON FUNCTION public.expire_stale_pending_bookings FROM anon;
REVOKE ALL ON FUNCTION public.expire_stale_pending_bookings FROM authenticated;
GRANT EXECUTE ON FUNCTION public.expire_stale_pending_bookings TO service_role;

COMMENT ON FUNCTION public.trigger_pending_expiry IS
  'Trigger pending booking expiry. SERVICE_ROLE ONLY. Call from Edge Function with service key.';

-- ============================================================
-- ROLLBACK
-- ============================================================
-- DROP INDEX IF EXISTS idx_appointments_pending_created;
-- DROP FUNCTION IF EXISTS public.trigger_pending_expiry;
-- DROP FUNCTION IF EXISTS public.expire_stale_pending_bookings;
-- SELECT cron.unschedule('expire-stale-pending-bookings');
