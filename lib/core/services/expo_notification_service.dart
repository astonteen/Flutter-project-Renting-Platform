import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:rent_ease/core/services/supabase_service.dart';
import 'package:rent_ease/core/services/app_navigation_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// Expo Push Notification Service
/// Handles registration, token management, and push notifications using Expo's service
class ExpoNotificationService {
  static final ExpoNotificationService _instance =
      ExpoNotificationService._internal();
  factory ExpoNotificationService() => _instance;
  ExpoNotificationService._internal();

  static const String _expoPushUrl = 'https://exp.host/--/api/v2/push/send';

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  String? _expoPushToken;
  bool _isInitialized = false;

  /// Initialize the Expo notification service
  static Future<void> initialize() async {
    await _instance._initializeLocalNotifications();
    await _instance._requestPermissions();
    await _instance._registerForPushNotifications();
    _instance._isInitialized = true;
    debugPrint('✅ ExpoNotificationService initialized');
  }

  /// Initialize local notifications for foreground handling
  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('📱 Notification tapped: ${response.payload}');

    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        AppNavigationService.handleNotificationTap(data);
      } catch (e) {
        debugPrint('❌ Error parsing notification payload: $e');
      }
    }
  }

  /// Request notification permissions
  Future<bool> _requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final permission = await Permission.notification.request();
      return permission.isGranted;
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      final permission = await Permission.notification.request();
      return permission.isGranted;
    }
    return true;
  }

  /// Register for push notifications and get Expo push token
  Future<void> _registerForPushNotifications() async {
    try {
      // For Flutter apps, we need to generate a device-specific token
      // This is a simplified approach - in a real Expo app, this would be handled by Expo SDK
      final deviceId = await _getDeviceId();

      if (deviceId != null) {
        // Create a mock Expo push token format for Flutter apps
        _expoPushToken = 'ExponentPushToken[${deviceId.substring(0, 22)}]';

        // Store the token in Supabase
        await _storeTokenInSupabase(_expoPushToken!);

        debugPrint(
            '📱 Expo push token registered: ${_expoPushToken!.substring(0, 30)}...');
      }
    } catch (e) {
      debugPrint('❌ Error registering for push notifications: $e');
    }
  }

  /// Get device ID (simplified implementation)
  Future<String?> _getDeviceId() async {
    try {
      // In a real implementation, you'd use device_info_plus or similar
      // For now, generate a consistent ID based on user
      final userId = SupabaseService.currentUser?.id;
      if (userId != null) {
        return '${userId}_${DateTime.now().millisecondsSinceEpoch}';
      }
    } catch (e) {
      debugPrint('❌ Error getting device ID: $e');
    }
    return null;
  }

  /// Store Expo push token in Supabase
  Future<void> _storeTokenInSupabase(String token) async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return;

    try {
      // Use upsert with conflict resolution to handle duplicate tokens
      await SupabaseService.client.from('user_devices').upsert(
        {
          'user_id': userId,
          'device_token': token,
          'device_type':
              defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
          'is_active': true,
          'preferences': {
            'push_enabled': true,
            'delivery_notifications': true,
            'booking_notifications': true,
            'message_notifications': true,
            'payment_notifications': true,
          },
          'last_seen': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id,device_token', // Handle the unique constraint
      );

      debugPrint('✅ Expo push token stored in Supabase');
    } catch (e) {
      debugPrint('❌ Error storing token in Supabase: $e');

      // If still failing, try to update existing record
      if (e.toString().contains('duplicate key') ||
          e.toString().contains('23505')) {
        try {
          await SupabaseService.client
              .from('user_devices')
              .update({
                'is_active': true,
                'last_seen': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('user_id', userId)
              .eq('device_token', token);
          debugPrint('✅ Updated existing device token record');
        } catch (updateError) {
          debugPrint('❌ Failed to update existing token: $updateError');
        }
      }
    }
  }

  /// Send a push notification via Expo Push Service
  static Future<bool> sendPushNotification({
    required String expoPushToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? sound = 'default',
  }) async {
    try {
      final message = {
        'to': expoPushToken,
        'sound': sound,
        'title': title,
        'body': body,
        'data': data ?? {},
      };

      final response = await http.post(
        Uri.parse(_expoPushUrl),
        headers: {
          'Accept': 'application/json',
          'Accept-encoding': 'gzip, deflate',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        debugPrint('✅ Push notification sent: $responseData');
        return true;
      } else {
        debugPrint(
            '❌ Failed to send push notification: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error sending push notification: $e');
      return false;
    }
  }

  /// Send notification to multiple tokens
  static Future<Map<String, bool>> sendBulkPushNotifications({
    required List<String> expoPushTokens,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? sound = 'default',
  }) async {
    final results = <String, bool>{};

    try {
      final messages = expoPushTokens
          .map((token) => {
                'to': token,
                'sound': sound,
                'title': title,
                'body': body,
                'data': data ?? {},
              })
          .toList();

      final response = await http.post(
        Uri.parse(_expoPushUrl),
        headers: {
          'Accept': 'application/json',
          'Accept-encoding': 'gzip, deflate',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(messages),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as List;

        for (int i = 0; i < expoPushTokens.length; i++) {
          final token = expoPushTokens[i];
          final result = responseData[i];
          results[token] = result['status'] == 'ok';
        }

        debugPrint(
            '✅ Bulk push notifications sent: ${results.length} tokens processed');
      } else {
        debugPrint(
            '❌ Failed to send bulk push notifications: ${response.statusCode} - ${response.body}');
        // Mark all as failed
        for (final token in expoPushTokens) {
          results[token] = false;
        }
      }
    } catch (e) {
      debugPrint('❌ Error sending bulk push notifications: $e');
      // Mark all as failed
      for (final token in expoPushTokens) {
        results[token] = false;
      }
    }

    return results;
  }

  /// Show local notification (for foreground notifications)
  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'delivery_channel',
      'Delivery Notifications',
      channelDescription: 'Notifications for delivery updates',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Update notification preferences
  Future<void> updateNotificationPreferences({
    bool? pushEnabled,
    bool? deliveryNotifications,
    bool? bookingNotifications,
    bool? messageNotifications,
    bool? paymentNotifications,
  }) async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) return;

      final preferences = <String, dynamic>{};
      if (pushEnabled != null) preferences['push_enabled'] = pushEnabled;
      if (deliveryNotifications != null) {
        preferences['delivery_notifications'] = deliveryNotifications;
      }
      if (bookingNotifications != null) {
        preferences['booking_notifications'] = bookingNotifications;
      }
      if (messageNotifications != null) {
        preferences['message_notifications'] = messageNotifications;
      }
      if (paymentNotifications != null) {
        preferences['payment_notifications'] = paymentNotifications;
      }

      if (preferences.isNotEmpty) {
        await SupabaseService.client
            .from('user_devices')
            .update({'preferences': preferences})
            .eq('user_id', userId)
            .eq('is_active', true);

        debugPrint('✅ Notification preferences updated');
      }
    } catch (e) {
      debugPrint('❌ Error updating notification preferences: $e');
    }
  }

  /// Get current Expo push token
  String? get expoPushToken => _expoPushToken;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final permission = await Permission.notification.status;
    return permission.isGranted;
  }

  /// Refresh push token (call when user logs in/out)
  Future<void> refreshPushToken() async {
    if (_isInitialized) {
      await _registerForPushNotifications();
    }
  }

  /// Dispose resources
  void dispose() {
    // Clean up any resources if needed
    debugPrint('🧹 ExpoNotificationService disposed');
  }
}
