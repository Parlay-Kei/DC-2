-- Migration: Create public_barbers view for discovery
-- Created: 2025-12-31
-- Description: Safe public surface for barber directory (anon + authed users)
-- Critical for: Nearby barber discovery without exposing full profiles/users table
--
-- SECURITY: Only exposes fields safe for public directory
-- - NO email, phone, exact address, payout info, internal flags
-- - lat/lng are BUSINESS locations (shop or barber-controlled GPS), not home addresses
--
-- NOTE: Joins with profiles table for display name and avatar
-- NOTE: Ratings are computed from reviews table (not stored on barbers)
-- Requires: 20251231000000_create_profiles_table.sql to run first

BEGIN;

-- Drop existing view if exists (deterministic)
DROP VIEW IF EXISTS public.public_barbers;

-- Create safe public directory view
-- Joins barbers table with profiles for display name and avatar
-- Falls back to shop_name if no profile name available
-- Computes rating and review_count from reviews table
CREATE VIEW public.public_barbers AS
SELECT
  b.id,
  COALESCE(p.full_name, b.shop_name, 'Barber') AS display_name,
  p.avatar_url,
  b.shop_name,
  b.location AS city_area,  -- General area, not exact address
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
  AND b.location_type IS NOT NULL;  -- Required by DB constraint + onboarding checklist

-- Add comment for documentation
COMMENT ON VIEW public.public_barbers IS
  'Safe public directory of active barbers for discovery. Contains only fields safe for anonymous access.';

COMMIT;

-- Migration rollback:
-- DROP VIEW IF EXISTS public.public_barbers;
