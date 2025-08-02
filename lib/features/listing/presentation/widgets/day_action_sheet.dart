import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/features/listing/presentation/bloc/calendar_availability_bloc.dart';
import 'package:rent_ease/features/booking/data/models/booking_model.dart';
import 'package:rent_ease/core/services/availability_service.dart';
import 'package:rent_ease/core/services/supabase_service.dart';

enum DayAction { block, unblock, cancel }

class DayActionSheet extends StatefulWidget {
  final DateTime selectedDate;
  final bool isBlocked;
  final ItemAvailability? availability;

  const DayActionSheet({
    super.key,
    required this.selectedDate,
    this.isBlocked = false,
    this.availability,
  });

  @override
  State<DayActionSheet> createState() => _DayActionSheetState();
}

class _DayActionSheetState extends State<DayActionSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ColorConstants.primaryColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: ColorConstants.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Manage Date',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _formatDate(widget.selectedDate),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context, DayAction.cancel),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Scrollable content area
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Availability Overview
                  _buildAvailabilityOverview(),
                  const SizedBox(height: 20),

                  // Detailed Breakdown
                  if (widget.availability != null) ...[
                    _buildDetailedBreakdown(),
                    const SizedBox(height: 20),
                  ],

                  // Action Buttons
                  if (!widget.isBlocked) ...[
                    _buildActionTile(
                      icon: Icons.block,
                      title: 'Block this date',
                      subtitle: 'Mark as unavailable for maintenance',
                      color: ColorConstants.warningColor,
                      onTap: () => _showBlockDialog(context),
                    ),
                  ] else ...[
                    _buildActionTile(
                      icon: Icons.lock_open,
                      title: 'Unblock this date',
                      subtitle: 'Make available for booking',
                      color: ColorConstants.successColor,
                      onTap: () => Navigator.pop(context, DayAction.unblock),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityOverview() {
    if (widget.availability == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey),
            SizedBox(width: 12),
            Text('No availability data for this date'),
          ],
        ),
      );
    }

    final freeUnits = widget.availability!.totalQuantity -
        widget.availability!.bookedQuantity -
        widget.availability!.blockedQuantity;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (widget.availability!.blocks.any((b) => b.blockType == 'post_rental')) {
      statusColor = Colors.purple;
      statusText = 'Return Buffer Active';
      statusIcon = Icons.schedule;
    } else if (widget.availability!.blocks.isNotEmpty) {
      statusColor = Colors.orange;
      statusText = 'Manually Blocked';
      statusIcon = Icons.block;
    } else if (freeUnits == 0) {
      statusColor = Colors.red;
      statusText = 'Fully Booked';
      statusIcon = Icons.event_busy;
    } else if (freeUnits < widget.availability!.totalQuantity) {
      statusColor = Colors.amber;
      statusText = 'Partially Booked';
      statusIcon = Icons.event_available;
    } else {
      statusColor = Colors.green;
      statusText = 'Available';
      statusIcon = Icons.check_circle;
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatusItem(
                    'Available',
                    '$freeUnits',
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatusItem(
                    'Booked',
                    '${widget.availability!.bookedQuantity}',
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatusItem(
                    'Blocked',
                    '${widget.availability!.blockedQuantity}',
                    Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildStatusItem(
                    'Total',
                    '${widget.availability!.totalQuantity}',
                    Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedBreakdown() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detailed Breakdown',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Bookings
            if (widget.availability!.bookings.isNotEmpty) ...[
              const Text(
                'Active Bookings',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...widget.availability!.bookings
                  .map((booking) => _buildBookingItem(booking)),
              const SizedBox(height: 16),
            ],

            // Blocks
            if (widget.availability!.blocks.isNotEmpty) ...[
              const Text(
                'Blocked Periods',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...widget.availability!.blocks
                  .map((block) => _buildBlockItem(block)),
            ],

            if (widget.availability!.bookings.isEmpty &&
                widget.availability!.blocks.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 12),
                    Text('This date is completely available'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBookingItem(BookingModel booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blue,
            child: Text(
              booking.renterName.isNotEmpty
                  ? booking.renterName[0].toUpperCase()
                  : 'R',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.renterName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${DateFormat('MMM dd').format(booking.startDate)} - ${DateFormat('MMM dd').format(booking.endDate)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(booking.status.name),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  booking.status.name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_canCompleteRental(booking)) ...[
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _completeRental(booking),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'COMPLETE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBlockItem(AvailabilityBlock block) {
    Color blockColor =
        block.blockType == 'post_rental' ? Colors.purple : Colors.orange;
    String blockTypeLabel =
        block.blockType == 'post_rental' ? 'Return Buffer' : 'Manual Block';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: blockColor.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: blockColor.withAlpha(77)),
      ),
      child: Row(
        children: [
          Icon(
            block.blockType == 'post_rental' ? Icons.schedule : Icons.block,
            color: blockColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  blockTypeLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: blockColor,
                  ),
                ),
                if (block.reason != null) ...[
                  Text(
                    block.reason!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                Text(
                  'Until ${DateFormat('MMM dd, yyyy').format(block.blockedUntil)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withAlpha(51)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _showBlockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block Date'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Block ${_formatDate(widget.selectedDate)} for maintenance?'),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, DayAction.block);
            },
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.purple;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  /// Check if a rental can be completed by the lender
  bool _canCompleteRental(BookingModel booking) {
    // Only show complete button for confirmed or inProgress rentals that have ended
    final hasEnded = DateTime.now().isAfter(booking.endDate);
    return hasEnded &&
        (booking.status == BookingStatus.confirmed ||
            booking.status == BookingStatus.inProgress);
  }

  /// Complete a rental and trigger auto-block creation
  Future<void> _completeRental(BookingModel booking) async {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final currentUserId = SupabaseService.currentUser?.id;

      await AvailabilityService.completeRental(
        rentalId: booking.id,
        lenderId: currentUserId,
      );

      // Show success message
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content:
              Text('Rental completed successfully. Return buffer activated.'),
          backgroundColor: Colors.green,
        ),
      );
      navigator.pop();
    } catch (e) {
      // Show error message
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Failed to complete rental: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
