# Expo Notifications Setup Guide

This guide will help you complete the migration from Firebase Cloud Messaging to Expo Push Notifications as recommended by Supabase.

## 🎯 Overview

We've migrated your RentEase app from Firebase Cloud Messaging to Expo Push Notifications for the following benefits:

- **Simplified Setup**: No need to manage Firebase service accounts or certificates
- **Cross-Platform**: Same API for iOS and Android
- **Supabase Recommended**: Official recommendation from Supabase documentation
- **Better Developer Experience**: Easier testing and debugging

## 📋 Prerequisites

Before you begin, make sure you have:

1. **Expo Account**: Create one at [expo.dev](https://expo.dev)
2. **Expo CLI**: Install with `npm install -g @expo/cli`
3. **Supabase Project**: Your existing project will work
4. **Physical Device**: Push notifications require a real device for testing

## 🚀 Setup Steps

### Step 1: Get Expo Access Token

1. Go to [Expo Access Token Settings](https://expo.dev/accounts/[account]/settings/access-tokens)
2. Create a new token with "Enhanced Security for Push Notifications" enabled
3. Copy the token - you'll need it for the Supabase Edge Function

### Step 2: Update Supabase Edge Function Environment

Set the Expo access token in your Supabase project:

```bash
# In your supabase directory
echo "EXPO_ACCESS_TOKEN=your_expo_access_token_here" >> .env

# Deploy the updated edge function
supabase functions deploy send-push-notification

# Set the environment variable
supabase secrets set --env-file .env
```

### Step 3: Run Database Migration

Apply the database migration to support Expo push tokens:

```bash
supabase db push
```

This will:
- Update the `user_devices` table structure
- Add Expo token validation functions
- Create helper functions for device management

### Step 4: Update Dependencies

The `pubspec.yaml` has already been updated. Run:

```bash
flutter pub get
```

### Step 5: Test the Setup

1. **Run the test script**:
   ```bash
   dart run test_expo_notifications.dart
   ```

2. **Test in your app**:
   - Build and run your app on a physical device
   - Sign in to trigger token registration
   - Check the Supabase `user_devices` table for new Expo tokens
   - Test notifications through your app's delivery flow

## 🔧 Configuration Details

### Expo Push Token Format

Expo push tokens follow this format:
- `ExponentPushToken[xxxxxxxxxxxxxxxxxxxxxx]`
- `ExpoPushToken[xxxxxxxxxxxxxxxxxxxxxx]`

The system automatically validates token formats and rejects invalid ones.

### Database Schema Changes

The migration adds:
- Token format validation
- Helper functions for device management
- Improved indexing for performance
- Automatic cleanup of invalid tokens

### Notification Preferences

Users can control notifications through:
- **Push Enabled**: Master switch for all push notifications
- **Delivery Notifications**: Updates about delivery status
- **Booking Notifications**: Booking confirmations and updates
- **Message Notifications**: New messages from other users
- **Payment Notifications**: Payment confirmations and issues

## 📱 Mobile App Integration

### Token Registration

The app automatically:
1. Requests notification permissions
2. Generates an Expo-compatible push token
3. Stores the token in Supabase `user_devices` table
4. Updates the token when the user logs in/out

### Local Notifications

For foreground notifications, the app uses `flutter_local_notifications` to show in-app alerts.

### Permission Handling

The app requests notification permissions on:
- First app launch
- User login
- When enabling notifications in settings

## 🧪 Testing Notifications

### Test via Supabase Dashboard

1. Go to your Supabase project dashboard
2. Navigate to Table Editor → `user_devices`
3. Find a user's active device token
4. Use the Expo Push Tool or call your edge function directly

### Test via Edge Function

```bash
curl -X POST 'https://your-project.supabase.co/functions/v1/send-push-notification' \
  -H 'Authorization: Bearer YOUR_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "user_id": "user-uuid-here",
    "title": "Test Notification",
    "body": "This is a test notification",
    "data": {"type": "test"}
  }'
```

### Test via Expo Push Tool

Visit [expo.dev/notifications](https://expo.dev/notifications) and send a test notification using a user's push token.

## 🔍 Troubleshooting

### Common Issues

1. **Invalid Token Format**
   - Check that tokens start with `ExponentPushToken[` or `ExpoPushToken[`
   - Verify token generation in the app

2. **Permission Denied**
   - Ensure users have granted notification permissions
   - Check device notification settings

3. **Tokens Not Updating**
   - Verify the app calls `ExpoNotificationService.initialize()`
   - Check that users are logged in when registering tokens

4. **Edge Function Errors**
   - Verify `EXPO_ACCESS_TOKEN` is set correctly
   - Check Supabase function logs for detailed errors

### Debugging Tips

1. **Check Logs**:
   ```bash
   supabase functions logs send-push-notification
   ```

2. **Verify Database**:
   ```sql
   SELECT * FROM user_devices WHERE is_active = true;
   ```

3. **Test Token Validation**:
   ```sql
   SELECT validate_expo_push_token('ExponentPushToken[test]');
   ```

## 📈 Monitoring

### Key Metrics to Monitor

- **Token Registration Rate**: How many users successfully register tokens
- **Notification Delivery Rate**: Success rate of push notifications
- **User Engagement**: Click-through rates on notifications

### Database Queries

```sql
-- Active devices count
SELECT COUNT(*) FROM user_devices WHERE is_active = true;

-- Notification preferences distribution
SELECT 
  (preferences->>'push_enabled')::boolean as push_enabled,
  COUNT(*) 
FROM user_devices 
WHERE is_active = true 
GROUP BY push_enabled;

-- Recent notification logs
SELECT * FROM push_notification_logs 
ORDER BY created_at DESC 
LIMIT 100;
```

## 🔒 Security Considerations

1. **Token Storage**: Expo push tokens are stored securely in Supabase
2. **Access Control**: Only authenticated users can register tokens
3. **Token Validation**: All tokens are validated before use
4. **Automatic Cleanup**: Invalid tokens are automatically deactivated

## 📚 Additional Resources

- [Expo Push Notifications Documentation](https://docs.expo.dev/push-notifications/overview/)
- [Supabase Edge Functions Guide](https://supabase.com/docs/guides/functions)
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)

## 🎉 Next Steps

1. Deploy your updated app to test devices
2. Monitor notification delivery rates
3. Gather user feedback on notification experience
4. Consider implementing rich notifications with images and actions

---

**Need Help?** Check the troubleshooting section above or review the Supabase and Expo documentation for additional guidance.