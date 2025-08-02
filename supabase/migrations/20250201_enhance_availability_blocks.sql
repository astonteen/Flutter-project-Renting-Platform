-- Enhance availability_blocks table for improved return buffer and maintenance tracking

-- Add metadata column for enhanced block information
ALTER TABLE availability_blocks ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}';

-- Add index for faster metadata queries
CREATE INDEX IF NOT EXISTS idx_availability_blocks_metadata ON availability_blocks USING GIN (metadata);

-- Add index for block type and status queries
CREATE INDEX IF NOT EXISTS idx_availability_blocks_type_status ON availability_blocks (block_type, blocked_from, blocked_until);

-- Add index for item and rental queries
CREATE INDEX IF NOT EXISTS idx_availability_blocks_item_rental ON availability_blocks (item_id, rental_id) WHERE rental_id IS NOT NULL;

-- Update existing post_rental blocks to have metadata
UPDATE availability_blocks 
SET metadata = jsonb_build_object(
  'maintenance_type', 'return_processing',
  'duration_days', EXTRACT(DAY FROM (blocked_until - blocked_from)),
  'legacy_block', true,
  'enhanced_at', NOW()
)
WHERE block_type = 'post_rental' AND (metadata IS NULL OR metadata = '{}');

-- Update existing manual blocks to have metadata
UPDATE availability_blocks 
SET metadata = jsonb_build_object(
  'maintenance_type', 'manual',
  'duration_days', EXTRACT(DAY FROM (blocked_until - blocked_from)),
  'legacy_block', true,
  'enhanced_at', NOW()
)
WHERE block_type = 'manual' AND (metadata IS NULL OR metadata = '{}');

-- Add comment for documentation
COMMENT ON COLUMN availability_blocks.metadata IS 'Enhanced metadata for tracking maintenance types, return processing, and block details';

-- Create function to get enhanced block information
CREATE OR REPLACE FUNCTION get_enhanced_block_info(item_id_param UUID, date_param DATE)
RETURNS TABLE (
  block_id UUID,
  block_type TEXT,
  maintenance_type TEXT,
  reason TEXT,
  blocked_from TIMESTAMPTZ,
  blocked_until TIMESTAMPTZ,
  duration_days INTEGER,
  metadata JSONB
) 
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    ab.id,
    ab.block_type,
    COALESCE(ab.metadata->>'maintenance_type', 'unknown') as maintenance_type,
    ab.reason,
    ab.blocked_from,
    ab.blocked_until,
    COALESCE((ab.metadata->>'duration_days')::INTEGER, 
             EXTRACT(DAY FROM (ab.blocked_until - ab.blocked_from))::INTEGER) as duration_days,
    ab.metadata
  FROM availability_blocks ab
  WHERE ab.item_id = item_id_param
    AND date_param BETWEEN ab.blocked_from::DATE AND ab.blocked_until::DATE
  ORDER BY ab.blocked_from;
END;
$$;