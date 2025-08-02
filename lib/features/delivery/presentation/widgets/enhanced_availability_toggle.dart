import 'package:flutter/material.dart';

class EnhancedAvailabilityToggle extends StatelessWidget {
  final String driverId;
  final bool isAvailable;
  final Function(bool) onAvailabilityChanged;

  const EnhancedAvailabilityToggle({
    super.key,
    required this.driverId,
    required this.isAvailable,
    required this.onAvailabilityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isAvailable ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAvailable ? 'You are ONLINE' : 'You are OFFLINE',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isAvailable ? Colors.green : Colors.red,
                  ),
                ),
                Text(
                  isAvailable
                      ? 'Receiving delivery requests'
                      : 'Not receiving delivery requests',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isAvailable,
            onChanged: (value) {
              if (!value && isAvailable) {
                // Going offline - show confirmation dialog
                _showOfflineConfirmation(context, value);
              } else {
                // Going online - proceed directly
                onAvailabilityChanged(value);
              }
            },
            activeColor: Colors.green,
            inactiveThumbColor: Colors.red,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  void _showOfflineConfirmation(BuildContext context, bool value) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Go Offline?'),
          content: const Text(
            'Are you sure you want to go offline? You will stop receiving new delivery requests.\n\nNote: You must complete any active deliveries before going offline.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onAvailabilityChanged(value);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Go Offline'),
            ),
          ],
        );
      },
    );
  }
}
