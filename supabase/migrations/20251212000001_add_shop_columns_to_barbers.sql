-- Migration: Add shop and home service columns to barbers table
-- Created: 2025-12-12
-- Description: Adds shop_name, shop_address, offers_home_service, and travel_fee_per_mile columns

-- Add shop_name column
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'barbers'
    AND column_name = 'shop_name'
  ) THEN
    ALTER TABLE public.barbers ADD COLUMN shop_name TEXT;
  END IF;
END $$;

-- Add shop_address column
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'barbers'
    AND column_name = 'shop_address'
  ) THEN
    ALTER TABLE public.barbers ADD COLUMN shop_address TEXT;
  END IF;
END $$;

-- Add offers_home_service column
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'barbers'
    AND column_name = 'offers_home_service'
  ) THEN
    ALTER TABLE public.barbers ADD COLUMN offers_home_service BOOLEAN DEFAULT false;
  END IF;
END $$;

-- Add travel_fee_per_mile column
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'barbers'
    AND column_name = 'travel_fee_per_mile'
  ) THEN
    ALTER TABLE public.barbers ADD COLUMN travel_fee_per_mile DECIMAL(10,2);
  END IF;
END $$;

-- Add comments for documentation
COMMENT ON COLUMN public.barbers.shop_name IS 'Name of the barber shop or business';
COMMENT ON COLUMN public.barbers.shop_address IS 'Physical address of the barber shop';
COMMENT ON COLUMN public.barbers.offers_home_service IS 'Whether the barber offers mobile/home service';
COMMENT ON COLUMN public.barbers.travel_fee_per_mile IS 'Fee charged per mile for home service (in local currency)';

-- Migration rollback (if needed, run these commands manually):
-- ALTER TABLE public.barbers DROP COLUMN IF EXISTS shop_name;
-- ALTER TABLE public.barbers DROP COLUMN IF EXISTS shop_address;
-- ALTER TABLE public.barbers DROP COLUMN IF EXISTS offers_home_service;
-- ALTER TABLE public.barbers DROP COLUMN IF EXISTS travel_fee_per_mile;
