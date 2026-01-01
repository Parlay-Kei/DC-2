-- Migration: Create RPC function for public barber discovery
-- Created: 2025-12-31
-- Description: Security definer function to allow anon + authed users to query public_barbers
-- Critical for: Logged-out users can browse Nearby barbers
--
-- Using RPC instead of direct view access for reliable cross-Postgres permission handling

BEGIN;

-- Drop existing function if exists (deterministic)
DROP FUNCTION IF EXISTS public.get_public_barbers();
DROP FUNCTION IF EXISTS public.get_nearby_barbers(double precision, double precision, integer);

-- Function: Get all public barbers (for list view)
CREATE OR REPLACE FUNCTION public.get_public_barbers()
RETURNS TABLE (
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
  updated_at TIMESTAMPTZ
)
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT
    id,
    display_name,
    avatar_url,
    shop_name,
    city_area,
    latitude,
    longitude,
    rating,
    review_count,
    is_mobile,
    service_radius_miles,
    is_verified,
    updated_at
  FROM public.public_barbers
  ORDER BY rating DESC, review_count DESC;
$$;

-- Function: Get nearby barbers within radius (for map view)
CREATE OR REPLACE FUNCTION public.get_nearby_barbers(
  user_lat DOUBLE PRECISION,
  user_lng DOUBLE PRECISION,
  radius_miles INTEGER DEFAULT 25
)
RETURNS TABLE (
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
  updated_at TIMESTAMPTZ,
  distance_miles DOUBLE PRECISION
)
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  WITH barbers_with_distance AS (
    SELECT
      pb.*,
      -- Haversine formula for distance in miles
      (
        3959 * acos(
          cos(radians(user_lat)) * cos(radians(pb.latitude)) *
          cos(radians(pb.longitude) - radians(user_lng)) +
          sin(radians(user_lat)) * sin(radians(pb.latitude))
        )
      ) AS distance_miles
    FROM public.public_barbers pb
    WHERE pb.latitude IS NOT NULL
      AND pb.longitude IS NOT NULL
  )
  SELECT
    id,
    display_name,
    avatar_url,
    shop_name,
    city_area,
    latitude,
    longitude,
    rating,
    review_count,
    is_mobile,
    service_radius_miles,
    is_verified,
    updated_at,
    distance_miles
  FROM barbers_with_distance
  WHERE distance_miles <= radius_miles
  ORDER BY distance_miles ASC, rating DESC;
$$;

-- Grant execute to anon and authenticated roles
GRANT EXECUTE ON FUNCTION public.get_public_barbers() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_nearby_barbers(double precision, double precision, integer) TO anon, authenticated;

-- Add comments for documentation
COMMENT ON FUNCTION public.get_public_barbers() IS
  'Returns all active barbers for public directory. Safe for anonymous access.';

COMMENT ON FUNCTION public.get_nearby_barbers(double precision, double precision, integer) IS
  'Returns barbers within specified radius of user location. Safe for anonymous access.';

COMMIT;

-- Migration rollback:
-- DROP FUNCTION IF EXISTS public.get_public_barbers();
-- DROP FUNCTION IF EXISTS public.get_nearby_barbers(double precision, double precision, integer);
