-- Migration: Migrate from Firebase to Expo Push Notifications
-- This migration updates the user_devices table to support Expo push tokens
-- and cleans up Firebase-specific configurations

-- Update existing device tokens to be compatible with Expo format (if needed)
-- Note: This is a placeholder - actual tokens will be updated by the app when users re-register

-- Add a comment to the device_token column to indicate it now stores Expo push tokens
COMMENT ON COLUMN user_devices.device_token IS 'Expo push token in format: ExponentPushToken[...] or ExpoPushToken[...]';

-- Update the preferences JSON structure to be more explicit about notification types
-- Ensure all existing records have the proper preference structure
UPDATE user_devices 
SET preferences = COALESCE(preferences, '{}'::jsonb) || jsonb_build_object(
  'push_enabled', COALESCE((preferences->>'push_enabled')::boolean, true),
  'delivery_notifications', COALESCE((preferences->>'delivery_notifications')::boolean, true),
  'booking_notifications', COALESCE((preferences->>'booking_notifications')::boolean, true),
  'message_notifications', COALESCE((preferences->>'message_notifications')::boolean, true),
  'payment_notifications', COALESCE((preferences->>'payment_notifications')::boolean, true)
)
WHERE preferences IS NULL OR 
      NOT (preferences ? 'push_enabled') OR
      NOT (preferences ? 'delivery_notifications') OR
      NOT (preferences ? 'booking_notifications') OR
      NOT (preferences ? 'message_notifications') OR
      NOT (preferences ? 'payment_notifications');

-- Create an index on device_token for faster lookups
CREATE INDEX IF NOT EXISTS idx_user_devices_device_token 
ON user_devices USING btree (device_token) 
WHERE is_active = true;

-- Create an index on user_id and is_active for faster user device queries
CREATE INDEX IF NOT EXISTS idx_user_devices_user_active 
ON user_devices USING btree (user_id, is_active) 
WHERE is_active = true;

-- Add a function to validate Expo push token format
CREATE OR REPLACE FUNCTION validate_expo_push_token(token text)
RETURNS boolean
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
  -- Check if token matches Expo push token format
  -- ExponentPushToken[...] or ExpoPushToken[...]
  RETURN token ~ '^(Exponent|Expo)PushToken\[.+\]$';
END;
$$;

-- Add a check constraint to ensure device tokens are valid Expo tokens (optional, can be enabled later)
-- ALTER TABLE user_devices ADD CONSTRAINT check_expo_token_format 
-- CHECK (validate_expo_push_token(device_token));

-- Update the get_user_devices function to work with Expo tokens
CREATE OR REPLACE FUNCTION get_user_devices(target_user_id uuid)
RETURNS TABLE (
  device_token text,
  device_type text,
  preferences jsonb,
  last_seen timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    ud.device_token,
    ud.device_type,
    ud.preferences,
    ud.last_seen
  FROM user_devices ud
  WHERE ud.user_id = target_user_id
    AND ud.is_active = true
    AND ud.device_token IS NOT NULL
    AND validate_expo_push_token(ud.device_token)
  ORDER BY ud.last_seen DESC;
END;
$$;

-- Create a function to clean up invalid or old device tokens
CREATE OR REPLACE FUNCTION cleanup_invalid_device_tokens()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  cleanup_count INTEGER;
BEGIN
  -- Mark devices with invalid token formats as inactive
  UPDATE user_devices 
  SET is_active = false
  WHERE is_active = true 
    AND (device_token IS NULL OR NOT validate_expo_push_token(device_token));
  
  GET DIAGNOSTICS cleanup_count = ROW_COUNT;
  
  -- Also clean up devices that haven't been seen in over 90 days
  UPDATE user_devices 
  SET is_active = false
  WHERE is_active = true 
    AND last_seen < NOW() - INTERVAL '90 days';
  
  RETURN cleanup_count;
END;
$$;

-- Create a function to update device preferences
CREATE OR REPLACE FUNCTION update_device_preferences(
  target_user_id uuid,
  new_preferences jsonb
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE user_devices
  SET preferences = preferences || new_preferences
  WHERE user_id = target_user_id 
    AND is_active = true;
  
  RETURN FOUND;
END;
$$;

-- Add some helpful comments
COMMENT ON FUNCTION validate_expo_push_token(text) IS 'Validates that a token matches Expo push token format';
COMMENT ON FUNCTION get_user_devices(uuid) IS 'Returns active devices for a user with valid Expo push tokens';
COMMENT ON FUNCTION cleanup_invalid_device_tokens() IS 'Marks devices with invalid tokens as inactive';
COMMENT ON FUNCTION update_device_preferences(uuid, jsonb) IS 'Updates notification preferences for all active devices of a user';

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION validate_expo_push_token(text) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION get_user_devices(uuid) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION cleanup_invalid_device_tokens() TO service_role;
GRANT EXECUTE ON FUNCTION update_device_preferences(uuid, jsonb) TO authenticated, service_role;