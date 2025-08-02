-- Add missing columns to items table that are expected by the application
-- This fixes schema mismatch issues causing listing creation failures

-- Add delivery-related columns
ALTER TABLE public.items 
ADD COLUMN IF NOT EXISTS delivery_fee DECIMAL(10,2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS requires_delivery BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS delivery_instructions TEXT;

-- Add additional application columns
ALTER TABLE public.items 
ADD COLUMN IF NOT EXISTS image_urls TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS primary_image_url TEXT,
ADD COLUMN IF NOT EXISTS features TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS specifications JSONB;

-- Add rating/review columns (for future use)
ALTER TABLE public.items 
ADD COLUMN IF NOT EXISTS rating DECIMAL(3,2),
ADD COLUMN IF NOT EXISTS view_count INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS review_count INTEGER DEFAULT 0;

-- Add comments for clarity
COMMENT ON COLUMN public.items.delivery_fee IS 'Optional delivery fee for the item in dollars';
COMMENT ON COLUMN public.items.requires_delivery IS 'Whether this item requires delivery service';
COMMENT ON COLUMN public.items.delivery_instructions IS 'Special delivery instructions for this item';
COMMENT ON COLUMN public.items.image_urls IS 'Array of image URLs for this item';
COMMENT ON COLUMN public.items.primary_image_url IS 'Primary image URL for this item';
COMMENT ON COLUMN public.items.features IS 'Array of item features/characteristics';
COMMENT ON COLUMN public.items.specifications IS 'JSON object containing item specifications';
COMMENT ON COLUMN public.items.rating IS 'Average rating of this item (1-5 stars)';
COMMENT ON COLUMN public.items.view_count IS 'Number of times this item has been viewed';
COMMENT ON COLUMN public.items.review_count IS 'Number of reviews for this item';

-- Update any existing items to have default values
UPDATE public.items 
SET delivery_fee = 0.00 
WHERE delivery_fee IS NULL;

UPDATE public.items 
SET requires_delivery = FALSE 
WHERE requires_delivery IS NULL;

UPDATE public.items 
SET image_urls = '{}' 
WHERE image_urls IS NULL;

UPDATE public.items 
SET features = '{}' 
WHERE features IS NULL;

UPDATE public.items 
SET view_count = 0 
WHERE view_count IS NULL;

UPDATE public.items 
SET review_count = 0 
WHERE review_count IS NULL; 