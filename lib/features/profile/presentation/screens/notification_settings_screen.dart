import 'package:flutter/material.dart';
import 'package:rent_ease/core/services/supabase_service.dart';
import 'package:rent_ease/core/services/expo_notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _isLoading = true;
  bool _deliveryNotifications = true;
  bool _bookingNotifications = true;
  bool _messageNotifications = true;
  bool _paymentNotifications = true;
  bool _marketingNotifications = false;

  TimeOfDay? _quietHoursStart;
  TimeOfDay? _quietHoursEnd;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreferences();
  }

  Future<void> _loadNotificationPreferences() async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) return;

      final response = await SupabaseService.client
          .from('user_notification_preferences')
          .select('*')
          .eq('user_id', user.id)
          .maybeSingle();

      if (response != null) {
        setState(() {
          _deliveryNotifications = response['delivery_notifications'] ?? true;
          _bookingNotifications = response['booking_notifications'] ?? true;
          _messageNotifications = response['message_notifications'] ?? true;
          _paymentNotifications = response['payment_notifications'] ?? true;
          _marketingNotifications =
              response['marketing_notifications'] ?? false;

          // Parse quiet hours
          if (response['quiet_hours_start'] != null) {
            final start = response['quiet_hours_start'] as String;
            final parts = start.split(':');
            _quietHoursStart = TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
          }

          if (response['quiet_hours_end'] != null) {
            final end = response['quiet_hours_end'] as String;
            final parts = end.split(':');
            _quietHoursEnd = TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading notification preferences: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveNotificationPreferences() async {
    try {
      // Update Expo notification preferences
      await ExpoNotificationService().updateNotificationPreferences(
        deliveryNotifications: _deliveryNotifications,
        bookingNotifications: _bookingNotifications,
        messageNotifications: _messageNotifications,
        paymentNotifications: _paymentNotifications,
      );

      // Save additional preferences to database
      final user = SupabaseService.currentUser;
      if (user != null) {
        await SupabaseService.client
            .from('user_notification_preferences')
            .upsert({
          'user_id': user.id,
          'delivery_notifications': _deliveryNotifications,
          'booking_notifications': _bookingNotifications,
          'message_notifications': _messageNotifications,
          'payment_notifications': _paymentNotifications,
          'marketing_notifications': _marketingNotifications,
          'quiet_hours_start': _quietHoursStart?.format(context),
          'quiet_hours_end': _quietHoursEnd?.format(context),
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification preferences saved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving preferences: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectQuietHoursStart() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _quietHoursStart ?? const TimeOfDay(hour: 22, minute: 0),
    );

    if (picked != null) {
      setState(() {
        _quietHoursStart = picked;
      });
    }
  }

  Future<void> _selectQuietHoursEnd() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _quietHoursEnd ?? const TimeOfDay(hour: 8, minute: 0),
    );

    if (picked != null) {
      setState(() {
        _quietHoursEnd = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saveNotificationPreferences,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Notification Types
                  const Text(
                    'Notification Types',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildNotificationTypeCard(
                    icon: Icons.local_shipping,
                    title: 'Delivery Updates',
                    subtitle: 'Driver assignments, pickup & delivery status',
                    value: _deliveryNotifications,
                    onChanged: (value) {
                      setState(() {
                        _deliveryNotifications = value;
                      });
                    },
                  ),

                  _buildNotificationTypeCard(
                    icon: Icons.calendar_today,
                    title: 'Booking Updates',
                    subtitle: 'Confirmations, cancellations, and reminders',
                    value: _bookingNotifications,
                    onChanged: (value) {
                      setState(() {
                        _bookingNotifications = value;
                      });
                    },
                  ),

                  _buildNotificationTypeCard(
                    icon: Icons.message,
                    title: 'Messages',
                    subtitle: 'New messages from other users',
                    value: _messageNotifications,
                    onChanged: (value) {
                      setState(() {
                        _messageNotifications = value;
                      });
                    },
                  ),

                  _buildNotificationTypeCard(
                    icon: Icons.payment,
                    title: 'Payment Updates',
                    subtitle: 'Payment confirmations and receipts',
                    value: _paymentNotifications,
                    onChanged: (value) {
                      setState(() {
                        _paymentNotifications = value;
                      });
                    },
                  ),

                  _buildNotificationTypeCard(
                    icon: Icons.campaign,
                    title: 'Marketing & Promotions',
                    subtitle: 'Special offers and app updates',
                    value: _marketingNotifications,
                    onChanged: (value) {
                      setState(() {
                        _marketingNotifications = value;
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  // Quiet Hours
                  const Text(
                    'Quiet Hours',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Set quiet hours to avoid notifications during specific times',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTimeSelector(
                                  label: 'Start Time',
                                  time: _quietHoursStart,
                                  onTap: _selectQuietHoursStart,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTimeSelector(
                                  label: 'End Time',
                                  time: _quietHoursEnd,
                                  onTap: _selectQuietHoursEnd,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildNotificationTypeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              icon,
              color: value && onChanged != null ? Colors.blue : Colors.grey,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: onChanged != null ? null : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector({
    required String label,
    required TimeOfDay? time,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time?.format(context) ?? 'Not set',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
