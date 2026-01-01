-- Migration: Harden public RPC functions
-- Created: 2025-12-31
-- Description: Security hardening for public barber discovery RPCs
--
-- HARDENING APPLIED:
-- 1. Stable return type (prevents accidental column exposure if view changes)
-- 2. Parameter validation (lat/lng bounds, radius clamp, hard limit)
-- 3. Coordinate precision reduction (4 decimal places ~11m accuracy for privacy)
-- 4. Performance indexes for reviews aggregation
--
-- SECURITY NOTES:
-- - SECURITY DEFINER bypasses RLS - return type locks the contract
-- - Parameters are validated BEFORE any query execution
-- - Coordinates rounded to prevent exact-location fingerprinting

BEGIN;

-- ============================================================
-- A) STABLE RETURN TYPE - locks public payload contract
-- ============================================================
-- Adding new columns to public_barbers view will NOT expose them
-- unless this type is explicitly updated

DROP TYPE IF EXISTS public.public_barber_directory_row CASCADE;

CREATE TYPE public.public_barber_directory_row AS (
  id UUID,
  display_name TEXT,
  avatar_url TEXT,
  shop_name TEXT,
  city_area TEXT,
  latitude DOUBLE PRECISION,  -- Rounded to 4 decimals in function
  longitude DOUBLE PRECISION, -- Rounded to 4 decimals in function
  rating DOUBLE PRECISION,
  review_count INTEGER,
  is_mobile BOOLEAN,
  service_radius_miles INTEGER,
  is_verified BOOLEAN
);

DROP TYPE IF EXISTS public.public_barber_nearby_row CASCADE;

CREATE TYPE public.public_barber_nearby_row AS (
  id UUID,
  display_name TEXT,
  avatar_url TEXT,
  shop_name TEXT,
  city_area TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  rating DOUBLE PRECISION,
  review_count INTEGER,
  is_mobile BOOLEAN,
  service_radius_miles INTEGER,
  is_verified BOOLEAN,
  distance_miles DOUBLE PRECISION
);

-- ============================================================
-- B) HARDENED get_public_barbers() with limit
-- ============================================================

DROP FUNCTION IF EXISTS public.get_public_barbers();
DROP FUNCTION IF EXISTS public.get_public_barbers(integer);

CREATE OR REPLACE FUNCTION public.get_public_barbers(
  result_limit INTEGER DEFAULT 50
)
RETURNS SETOF public.public_barber_directory_row
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
-- CRITICAL: Lock search_path to prevent privilege escalation
SET search_path = public
AS $$
DECLARE
  clamped_limit INTEGER;
BEGIN
  -- Hard clamp limit: 1-100
  clamped_limit := GREATEST(1, LEAST(100, COALESCE(result_limit, 50)));

  RETURN QUERY
  SELECT
    pb.id,
    pb.display_name,
    pb.avatar_url,
    pb.shop_name,
    pb.city_area,
    -- Round coordinates to 4 decimal places (~11m precision)
    ROUND(pb.latitude::numeric, 4)::double precision,
    ROUND(pb.longitude::numeric, 4)::double precision,
    pb.rating,
    pb.review_count,
    pb.is_mobile,
    pb.service_radius_miles,
    pb.is_verified
  FROM public.public_barbers pb
  ORDER BY pb.rating DESC, pb.review_count DESC
  LIMIT clamped_limit;
END;
$$;

-- ============================================================
-- C) HARDENED get_nearby_barbers() with validation
-- ============================================================

DROP FUNCTION IF EXISTS public.get_nearby_barbers(double precision, double precision, integer);
DROP FUNCTION IF EXISTS public.get_nearby_barbers(double precision, double precision, integer, integer);

CREATE OR REPLACE FUNCTION public.get_nearby_barbers(
  user_lat DOUBLE PRECISION,
  user_lng DOUBLE PRECISION,
  radius_miles INTEGER DEFAULT 25,
  result_limit INTEGER DEFAULT 50
)
RETURNS SETOF public.public_barber_nearby_row
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
-- CRITICAL: Lock search_path to prevent privilege escalation
SET search_path = public
AS $$
DECLARE
  validated_lat DOUBLE PRECISION;
  validated_lng DOUBLE PRECISION;
  clamped_radius INTEGER;
  clamped_limit INTEGER;
BEGIN
  -- ========== PARAMETER VALIDATION ==========

  -- Validate latitude: must be -90 to 90
  IF user_lat IS NULL OR user_lat < -90 OR user_lat > 90 THEN
    RAISE EXCEPTION 'Invalid latitude: must be between -90 and 90';
  END IF;
  validated_lat := user_lat;

  -- Validate longitude: must be -180 to 180
  IF user_lng IS NULL OR user_lng < -180 OR user_lng > 180 THEN
    RAISE EXCEPTION 'Invalid longitude: must be between -180 and 180';
  END IF;
  validated_lng := user_lng;

  -- Clamp radius: 1-100 miles (prevents "give me entire database" attacks)
  clamped_radius := GREATEST(1, LEAST(100, COALESCE(radius_miles, 25)));

  -- Clamp limit: 1-100 results
  clamped_limit := GREATEST(1, LEAST(100, COALESCE(result_limit, 50)));

  -- ========== QUERY WITH VALIDATED PARAMS ==========

  RETURN QUERY
  WITH barbers_with_distance AS (
    SELECT
      pb.id,
      pb.display_name,
      pb.avatar_url,
      pb.shop_name,
      pb.city_area,
      pb.latitude,
      pb.longitude,
      pb.rating,
      pb.review_count,
      pb.is_mobile,
      pb.service_radius_miles,
      pb.is_verified,
      -- Haversine formula for distance in miles
      (
        3959 * acos(
          LEAST(1.0, GREATEST(-1.0,  -- Clamp to prevent NaN from floating point errors
            cos(radians(validated_lat)) * cos(radians(pb.latitude)) *
            cos(radians(pb.longitude) - radians(validated_lng)) +
            sin(radians(validated_lat)) * sin(radians(pb.latitude))
          ))
        )
      ) AS calc_distance
    FROM public.public_barbers pb
    WHERE pb.latitude IS NOT NULL
      AND pb.longitude IS NOT NULL
  )
  SELECT
    bwd.id,
    bwd.display_name,
    bwd.avatar_url,
    bwd.shop_name,
    bwd.city_area,
    -- Round coordinates to 4 decimal places (~11m precision)
    ROUND(bwd.latitude::numeric, 4)::double precision,
    ROUND(bwd.longitude::numeric, 4)::double precision,
    bwd.rating,
    bwd.review_count,
    bwd.is_mobile,
    bwd.service_radius_miles,
    bwd.is_verified,
    ROUND(bwd.calc_distance::numeric, 2)::double precision AS distance_miles
  FROM barbers_with_distance bwd
  WHERE bwd.calc_distance <= clamped_radius
  ORDER BY bwd.calc_distance ASC, bwd.rating DESC
  LIMIT clamped_limit;
END;
$$;

-- ============================================================
-- D) GRANTS - explicit permissions
-- ============================================================

GRANT EXECUTE ON FUNCTION public.get_public_barbers(integer) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_nearby_barbers(double precision, double precision, integer, integer) TO anon, authenticated;

-- ============================================================
-- E) PERFORMANCE INDEXES
-- ============================================================

-- Index for reviews aggregation (AVG + COUNT by barber_id)
CREATE INDEX IF NOT EXISTS idx_reviews_barber_id ON public.reviews(barber_id);

-- Index for barbers active status + location filtering
CREATE INDEX IF NOT EXISTS idx_barbers_active_location ON public.barbers(is_active)
  WHERE latitude IS NOT NULL AND longitude IS NOT NULL;

-- ============================================================
-- F) DOCUMENTATION
-- ============================================================

COMMENT ON TYPE public.public_barber_directory_row IS
  'Stable return type for public barber directory. Adding columns to public_barbers view will NOT expose them unless this type is updated.';

COMMENT ON TYPE public.public_barber_nearby_row IS
  'Stable return type for nearby barber search. Includes distance_miles.';

COMMENT ON FUNCTION public.get_public_barbers(integer) IS
  'Returns public barber directory with hard limit (max 100). Coordinates rounded to 4 decimals for privacy.';

COMMENT ON FUNCTION public.get_nearby_barbers(double precision, double precision, integer, integer) IS
  'Returns nearby barbers with validated params: lat (-90,90), lng (-180,180), radius (1-100mi), limit (1-100).';

COMMIT;

-- Migration rollback:
-- DROP FUNCTION IF EXISTS public.get_public_barbers(integer);
-- DROP FUNCTION IF EXISTS public.get_nearby_barbers(double precision, double precision, integer, integer);
-- DROP TYPE IF EXISTS public.public_barber_nearby_row;
-- DROP TYPE IF EXISTS public.public_barber_directory_row;
-- DROP INDEX IF EXISTS idx_reviews_barber_id;
-- DROP INDEX IF EXISTS idx_barbers_active_location;
