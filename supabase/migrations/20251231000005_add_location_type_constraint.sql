-- Migration: Add location_type constraint for coordinate safety
-- Created: 2025-12-31
-- Description: Ensures coordinates have explicit type (shop/service_area) to prevent home address exposure
--
-- PRIVACY PROTECTION:
-- - location_type must be explicitly set before coordinates are accepted
-- - Prevents "oops I entered my home address" from becoming a privacy incident
-- - UI should warn barbers and require acknowledgment when setting location
--
-- VALID TYPES:
-- - 'shop': Fixed business location (shop, salon, studio)
-- - 'service_area': General service area center (for mobile barbers)
-- - NULL: Coordinates not yet validated (will be hidden from public view)

BEGIN;

-- ============================================================
-- A) ADD location_type COLUMN
-- ============================================================

-- Add column if not exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'barbers'
    AND column_name = 'location_type'
  ) THEN
    ALTER TABLE public.barbers ADD COLUMN location_type TEXT;
  END IF;
END $$;

-- Add check constraint for valid values
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.constraint_column_usage
    WHERE table_schema = 'public'
    AND table_name = 'barbers'
    AND constraint_name = 'barbers_location_type_check'
  ) THEN
    ALTER TABLE public.barbers
    ADD CONSTRAINT barbers_location_type_check
    CHECK (location_type IS NULL OR location_type IN ('shop', 'service_area'));
  END IF;
END $$;

-- Add timestamp for when location was last confirmed
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'barbers'
    AND column_name = 'location_confirmed_at'
  ) THEN
    ALTER TABLE public.barbers ADD COLUMN location_confirmed_at TIMESTAMPTZ;
  END IF;
END $$;

-- ============================================================
-- B) UPDATE public_barbers VIEW to require location_type
-- ============================================================

-- Only show barbers who have explicitly confirmed their location type
DROP VIEW IF EXISTS public.public_barbers;

CREATE VIEW public.public_barbers AS
SELECT
  b.id,
  COALESCE(p.full_name, b.shop_name, 'Barber') AS display_name,
  p.avatar_url,
  b.shop_name,
  b.location AS city_area,
  b.latitude,
  b.longitude,
  COALESCE(r.avg_rating, 0) AS rating,
  COALESCE(r.review_count, 0) AS review_count,
  COALESCE(b.is_mobile, false) AS is_mobile,
  COALESCE(b.service_radius_miles, 10) AS service_radius_miles,
  COALESCE(b.is_verified, false) AS is_verified,
  b.updated_at
FROM public.barbers b
LEFT JOIN public.profiles p ON b.id = p.id
LEFT JOIN (
  SELECT
    barber_id,
    AVG(rating)::DOUBLE PRECISION AS avg_rating,
    COUNT(*)::INTEGER AS review_count
  FROM public.reviews
  GROUP BY barber_id
) r ON b.id = r.barber_id
WHERE COALESCE(b.is_active, true) = true
  AND b.latitude IS NOT NULL
  AND b.longitude IS NOT NULL
  -- CRITICAL: Only show barbers who have explicitly set location_type
  AND b.location_type IS NOT NULL;

COMMENT ON VIEW public.public_barbers IS
  'Safe public directory of active barbers. Only includes barbers with confirmed location_type (shop or service_area).';

-- ============================================================
-- C) BACKFILL existing barbers (assume shop if they have coordinates)
-- ============================================================
-- This is a one-time backfill for existing data
-- New barbers must explicitly set location_type through the UI

UPDATE public.barbers
SET
  location_type = 'shop',
  location_confirmed_at = NOW()
WHERE latitude IS NOT NULL
  AND longitude IS NOT NULL
  AND location_type IS NULL;

-- ============================================================
-- D) DOCUMENTATION
-- ============================================================

COMMENT ON COLUMN public.barbers.location_type IS
  'Type of location coordinates represent: shop (fixed business) or service_area (mobile barber center). NULL means unconfirmed.';

COMMENT ON COLUMN public.barbers.location_confirmed_at IS
  'Timestamp when barber last confirmed their location. Used for periodic re-confirmation prompts.';

COMMIT;

-- Migration rollback:
-- DROP VIEW IF EXISTS public.public_barbers;
-- ALTER TABLE public.barbers DROP CONSTRAINT IF EXISTS barbers_location_type_check;
-- ALTER TABLE public.barbers DROP COLUMN IF EXISTS location_type;
-- ALTER TABLE public.barbers DROP COLUMN IF EXISTS location_confirmed_at;
-- (then re-run 20251231000002 to restore original view)
