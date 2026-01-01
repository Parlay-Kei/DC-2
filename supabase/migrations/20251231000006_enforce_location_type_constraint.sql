-- Migration: Enforce location_type when coordinates present
-- Created: 2025-12-31
-- Description: Backend invariant - if coords exist, location_type must be set
--
-- WHY THIS MATTERS:
-- - UI prompts users to set location_type, but admins/scripts could bypass
-- - Without this constraint, barbers can become invisible without knowing why
-- - This prevents future "coords but no type" rows from being created
--
-- PREREQUISITE: Run migration 20251231000005 first to backfill existing rows

-- ============================================================
-- PREFLIGHT: Fail loudly if backfill incomplete
-- ============================================================
-- This prevents operator error (running 00006 before 00005)
-- If this fails, run migration 00005 first to backfill legacy rows

DO $preflight$
DECLARE
  legacy_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO legacy_count
  FROM public.barbers
  WHERE latitude IS NOT NULL
    AND longitude IS NOT NULL
    AND location_type IS NULL;

  IF legacy_count > 0 THEN
    RAISE EXCEPTION 'PREFLIGHT FAILED: % barbers have coords but no location_type. Run migration 20251231000005 first to backfill.', legacy_count;
  END IF;
END $preflight$;

-- ============================================================
-- A) ADD CHECK CONSTRAINT
-- ============================================================
-- Invariant: if coordinates exist, location_type must also exist
-- This enforces the rule at the database level

ALTER TABLE public.barbers
DROP CONSTRAINT IF EXISTS barbers_location_type_required_when_coords_present;

ALTER TABLE public.barbers
ADD CONSTRAINT barbers_location_type_required_when_coords_present
CHECK (
  (latitude IS NULL AND longitude IS NULL)
  OR location_type IS NOT NULL
);

-- ============================================================
-- B) DOCUMENTATION
-- ============================================================

COMMENT ON CONSTRAINT barbers_location_type_required_when_coords_present ON public.barbers IS
  'Enforces that barbers with coordinates must have location_type set. Prevents invisible barbers.';

-- Migration rollback:
-- ALTER TABLE public.barbers DROP CONSTRAINT IF EXISTS barbers_location_type_required_when_coords_present;
