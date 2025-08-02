-- Enhancement migration for saved_addresses table
-- Adds indexes, constraints, and triggers for better performance and data integrity

-- Add indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_saved_addresses_user_id ON saved_addresses(user_id);
CREATE INDEX IF NOT EXISTS idx_saved_addresses_user_default ON saved_addresses(user_id, is_default) WHERE is_default = true;
CREATE INDEX IF NOT EXISTS idx_saved_addresses_created_at ON saved_addresses(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_saved_addresses_search ON saved_addresses USING gin(to_tsvector('english', label || ' ' || address_line_1 || ' ' || city));

-- Add constraint to ensure only one default address per user
CREATE UNIQUE INDEX IF NOT EXISTS idx_saved_addresses_unique_default 
ON saved_addresses(user_id) 
WHERE is_default = true;

-- Add check constraints for data validation
ALTER TABLE saved_addresses 
ADD CONSTRAINT IF NOT EXISTS chk_label_not_empty 
CHECK (length(trim(label)) > 0);

ALTER TABLE saved_addresses 
ADD CONSTRAINT IF NOT EXISTS chk_address_line_1_not_empty 
CHECK (length(trim(address_line_1)) > 0);

ALTER TABLE saved_addresses 
ADD CONSTRAINT IF NOT EXISTS chk_city_not_empty 
CHECK (length(trim(city)) > 0);

ALTER TABLE saved_addresses 
ADD CONSTRAINT IF NOT EXISTS chk_state_not_empty 
CHECK (length(trim(state)) > 0);

ALTER TABLE saved_addresses 
ADD CONSTRAINT IF NOT EXISTS chk_postal_code_not_empty 
CHECK (length(trim(postal_code)) > 0);

ALTER TABLE saved_addresses 
ADD CONSTRAINT IF NOT EXISTS chk_country_not_empty 
CHECK (length(trim(country)) > 0);

-- Add constraint for reasonable field lengths
ALTER TABLE saved_addresses 
ADD CONSTRAINT IF NOT EXISTS chk_label_length 
CHECK (length(label) <= 100);

ALTER TABLE saved_addresses 
ADD CONSTRAINT IF NOT EXISTS chk_address_line_1_length 
CHECK (length(address_line_1) <= 255);

ALTER TABLE saved_addresses 
ADD CONSTRAINT IF NOT EXISTS chk_address_line_2_length 
CHECK (address_line_2 IS NULL OR length(address_line_2) <= 255);

ALTER TABLE saved_addresses 
ADD CONSTRAINT IF NOT EXISTS chk_city_length 
CHECK (length(city) <= 100);

ALTER TABLE saved_addresses 
ADD CONSTRAINT IF NOT EXISTS chk_state_length 
CHECK (length(state) <= 100);

ALTER TABLE saved_addresses 
ADD CONSTRAINT IF NOT EXISTS chk_postal_code_length 
CHECK (length(postal_code) <= 20);

ALTER TABLE saved_addresses 
ADD CONSTRAINT IF NOT EXISTS chk_country_length 
CHECK (length(country) <= 100);

-- Create or replace function to handle default address logic
CREATE OR REPLACE FUNCTION handle_default_address()
RETURNS TRIGGER AS $$
BEGIN
  -- If setting an address as default, unset all other defaults for this user
  IF NEW.is_default = true THEN
    UPDATE saved_addresses 
    SET is_default = false, updated_at = NOW()
    WHERE user_id = NEW.user_id 
      AND id != NEW.id 
      AND is_default = true;
  END IF;
  
  -- If this is the user's first address, make it default
  IF NOT EXISTS (
    SELECT 1 FROM saved_addresses 
    WHERE user_id = NEW.user_id 
      AND id != COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid)
  ) THEN
    NEW.is_default = true;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for default address handling
DROP TRIGGER IF EXISTS trigger_handle_default_address ON saved_addresses;
CREATE TRIGGER trigger_handle_default_address
  BEFORE INSERT OR UPDATE ON saved_addresses
  FOR EACH ROW
  EXECUTE FUNCTION handle_default_address();

-- Create function to prevent deletion of the last address if it's default
CREATE OR REPLACE FUNCTION prevent_delete_last_default()
RETURNS TRIGGER AS $$
BEGIN
  -- If deleting a default address, check if user has other addresses
  IF OLD.is_default = true THEN
    -- Count remaining addresses for this user
    IF (SELECT COUNT(*) FROM saved_addresses WHERE user_id = OLD.user_id AND id != OLD.id) > 0 THEN
      -- Set the most recently created address as default
      UPDATE saved_addresses 
      SET is_default = true, updated_at = NOW()
      WHERE user_id = OLD.user_id 
        AND id != OLD.id
      ORDER BY created_at DESC 
      LIMIT 1;
    END IF;
  END IF;
  
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for handling default address deletion
DROP TRIGGER IF EXISTS trigger_prevent_delete_last_default ON saved_addresses;
CREATE TRIGGER trigger_prevent_delete_last_default
  BEFORE DELETE ON saved_addresses
  FOR EACH ROW
  EXECUTE FUNCTION prevent_delete_last_default();

-- Add RLS (Row Level Security) policies for better security
ALTER TABLE saved_addresses ENABLE ROW LEVEL SECURITY;

-- Policy for users to only see their own addresses
CREATE POLICY "Users can view own addresses" ON saved_addresses
  FOR SELECT USING (auth.uid() = user_id);

-- Policy for users to only insert their own addresses
CREATE POLICY "Users can insert own addresses" ON saved_addresses
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Policy for users to only update their own addresses
CREATE POLICY "Users can update own addresses" ON saved_addresses
  FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Policy for users to only delete their own addresses
CREATE POLICY "Users can delete own addresses" ON saved_addresses
  FOR DELETE USING (auth.uid() = user_id);

-- Create a view for address statistics (optional, for analytics)
CREATE OR REPLACE VIEW saved_addresses_stats AS
SELECT 
  user_id,
  COUNT(*) as total_addresses,
  COUNT(*) FILTER (WHERE is_default = true) as default_addresses,
  MIN(created_at) as first_address_created,
  MAX(created_at) as last_address_created,
  COUNT(DISTINCT country) as countries_count,
  COUNT(DISTINCT state) as states_count,
  COUNT(DISTINCT city) as cities_count
FROM saved_addresses
GROUP BY user_id;

-- Grant appropriate permissions
GRANT SELECT ON saved_addresses_stats TO authenticated;

-- Add comments for documentation
COMMENT ON TABLE saved_addresses IS 'Stores user saved addresses with validation and security constraints';
COMMENT ON COLUMN saved_addresses.user_id IS 'Foreign key to auth.users, identifies the address owner';
COMMENT ON COLUMN saved_addresses.is_default IS 'Indicates if this is the user default address (only one per user)';
COMMENT ON COLUMN saved_addresses.label IS 'User-friendly label for the address (e.g., Home, Work)';
COMMENT ON INDEX idx_saved_addresses_unique_default IS 'Ensures only one default address per user';
COMMENT ON FUNCTION handle_default_address() IS 'Manages default address logic and ensures data consistency';
COMMENT ON FUNCTION prevent_delete_last_default() IS 'Handles default address reassignment when deleting addresses';