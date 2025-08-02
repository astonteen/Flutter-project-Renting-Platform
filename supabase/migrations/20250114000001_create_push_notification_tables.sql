-- Create user_devices table for FCM token management
CREATE TABLE IF NOT EXISTS user_devices (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    device_token TEXT NOT NULL,
    device_type TEXT NOT NULL CHECK (device_type IN ('ios', 'android')),
    device_name TEXT,
    app_version TEXT,
    os_version TEXT,
    is_active BOOLEAN DEFAULT true,
    last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Ensure one active token per device
    UNIQUE(user_id, device_token)
);

-- Create user_notification_preferences table
CREATE TABLE IF NOT EXISTS user_notification_preferences (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    delivery_notifications BOOLEAN DEFAULT true,
    booking_notifications BOOLEAN DEFAULT true,
    message_notifications BOOLEAN DEFAULT true,
    payment_notifications BOOLEAN DEFAULT true,
    marketing_notifications BOOLEAN DEFAULT false,
    push_enabled BOOLEAN DEFAULT true,
    email_enabled BOOLEAN DEFAULT true,
    sms_enabled BOOLEAN DEFAULT false,
    quiet_hours_start TIME,
    quiet_hours_end TIME,
    timezone TEXT DEFAULT 'UTC',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- One preference record per user
    UNIQUE(user_id)
);

-- Create push_notification_logs table for tracking sent notifications
CREATE TABLE IF NOT EXISTS push_notification_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    device_token TEXT NOT NULL,
    notification_type TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    data JSONB,
    image_url TEXT,
    status TEXT NOT NULL CHECK (status IN ('pending', 'sent', 'delivered', 'failed', 'clicked')),
    error_message TEXT,
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    delivered_at TIMESTAMP WITH TIME ZONE,
    clicked_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create notification_templates table for reusable notification templates
CREATE TABLE IF NOT EXISTS notification_templates (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    template_name TEXT NOT NULL UNIQUE,
    notification_type TEXT NOT NULL,
    title_template TEXT NOT NULL,
    body_template TEXT NOT NULL,
    data_template JSONB,
    image_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_user_devices_user_id ON user_devices(user_id);
CREATE INDEX IF NOT EXISTS idx_user_devices_active ON user_devices(user_id, is_active);
CREATE INDEX IF NOT EXISTS idx_user_notification_preferences_user_id ON user_notification_preferences(user_id);
CREATE INDEX IF NOT EXISTS idx_push_notification_logs_user_id ON push_notification_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_push_notification_logs_status ON push_notification_logs(status);
CREATE INDEX IF NOT EXISTS idx_push_notification_logs_sent_at ON push_notification_logs(sent_at);
CREATE INDEX IF NOT EXISTS idx_notification_templates_type ON notification_templates(notification_type);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add updated_at triggers
CREATE TRIGGER update_user_devices_updated_at 
    BEFORE UPDATE ON user_devices 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_notification_preferences_updated_at 
    BEFORE UPDATE ON user_notification_preferences 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_notification_templates_updated_at 
    BEFORE UPDATE ON notification_templates 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security (RLS)
ALTER TABLE user_devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_notification_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE push_notification_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_templates ENABLE ROW LEVEL SECURITY;

-- RLS Policies for user_devices
CREATE POLICY "Users can view their own devices" ON user_devices
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own devices" ON user_devices
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own devices" ON user_devices
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own devices" ON user_devices
    FOR DELETE USING (auth.uid() = user_id);

-- RLS Policies for user_notification_preferences
CREATE POLICY "Users can view their own preferences" ON user_notification_preferences
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own preferences" ON user_notification_preferences
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own preferences" ON user_notification_preferences
    FOR UPDATE USING (auth.uid() = user_id);

-- RLS Policies for push_notification_logs
CREATE POLICY "Users can view their own notification logs" ON push_notification_logs
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Service role can insert notification logs" ON push_notification_logs
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Service role can update notification logs" ON push_notification_logs
    FOR UPDATE USING (true);

-- RLS Policies for notification_templates (admin only)
CREATE POLICY "Anyone can view active templates" ON notification_templates
    FOR SELECT USING (is_active = true);

-- Insert default notification templates
INSERT INTO notification_templates (template_name, notification_type, title_template, body_template, data_template) VALUES
('delivery_driver_assigned', 'delivery_update', 'Driver Assigned! 🚗', 'A driver has been assigned to deliver your {{item_name}}. They will be in touch soon!', '{"type": "delivery_update", "target_screen": "/delivery/{{delivery_id}}"}'),
('delivery_picked_up', 'delivery_update', 'Item Picked Up! 📦', 'Your {{item_name}} has been collected and is now heading to you.', '{"type": "delivery_update", "target_screen": "/delivery/{{delivery_id}}"}'),
('delivery_completed', 'delivery_update', 'Delivered Successfully! 🎉', 'Your {{item_name}} has been delivered successfully. Enjoy your rental!', '{"type": "delivery_update", "target_screen": "/delivery/{{delivery_id}}"}'),
('booking_confirmed', 'booking_update', 'Booking Confirmed! ✅', 'Your booking for {{item_name}} has been confirmed for {{booking_date}}.', '{"type": "booking_update", "target_screen": "/booking/{{booking_id}}"}'),
('booking_cancelled', 'booking_update', 'Booking Cancelled', 'Your booking for {{item_name}} has been cancelled. You will receive a full refund.', '{"type": "booking_update", "target_screen": "/booking/{{booking_id}}"}'),
('payment_successful', 'payment_update', 'Payment Successful! 💳', 'Your payment of ${{amount}} for {{item_name}} has been processed successfully.', '{"type": "payment_update", "target_screen": "/payment/{{payment_id}}"}'),
('new_message', 'message', 'New Message 💬', '{{sender_name}}: {{message_preview}}', '{"type": "message", "target_screen": "/messages/{{conversation_id}}"}'),
('item_ready', 'booking_update', 'Item Ready for Pickup! 📦', 'Your rental {{item_name}} is ready for pickup. Please collect it at your convenience.', '{"type": "booking_update", "target_screen": "/booking/{{booking_id}}"}'),
('return_reminder', 'booking_update', 'Return Reminder ⏰', 'Don''t forget to return {{item_name}} by {{return_date}}. Schedule a return pickup if needed.', '{"type": "booking_update", "target_screen": "/booking/{{booking_id}}"}')
ON CONFLICT (template_name) DO NOTHING;

-- Create function to get user devices for push notifications
CREATE OR REPLACE FUNCTION get_user_devices(target_user_id UUID)
RETURNS TABLE (
    device_token TEXT,
    device_type TEXT,
    preferences JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ud.device_token,
        ud.device_type,
        to_jsonb(unp.*) as preferences
    FROM user_devices ud
    LEFT JOIN user_notification_preferences unp ON ud.user_id = unp.user_id
    WHERE ud.user_id = target_user_id 
    AND ud.is_active = true
    AND ud.last_seen > NOW() - INTERVAL '30 days'; -- Only active devices
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to log notification attempts
CREATE OR REPLACE FUNCTION log_push_notification(
    target_user_id UUID,
    target_device_token TEXT,
    notification_type_param TEXT,
    title_param TEXT,
    body_param TEXT,
    data_param JSONB DEFAULT NULL,
    image_url_param TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    log_id UUID;
BEGIN
    INSERT INTO push_notification_logs (
        user_id,
        device_token,
        notification_type,
        title,
        body,
        data,
        image_url,
        status
    ) VALUES (
        target_user_id,
        target_device_token,
        notification_type_param,
        title_param,
        body_param,
        data_param,
        image_url_param,
        'pending'
    ) RETURNING id INTO log_id;
    
    RETURN log_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to update notification status
CREATE OR REPLACE FUNCTION update_notification_status(
    log_id_param UUID,
    status_param TEXT,
    error_message_param TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE push_notification_logs 
    SET 
        status = status_param,
        error_message = error_message_param,
        delivered_at = CASE WHEN status_param = 'delivered' THEN NOW() ELSE delivered_at END,
        clicked_at = CASE WHEN status_param = 'clicked' THEN NOW() ELSE clicked_at END
    WHERE id = log_id_param;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER; 