import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/core/utils/date_formatting_helper.dart';
import 'package:rent_ease/features/delivery/data/models/delivery_job_model.dart';
import 'package:rent_ease/features/booking/data/models/booking_model.dart';

class LenderActionDashboard extends StatelessWidget {
  final List<DeliveryJobModel> pendingApprovals;
  final List<BookingModel> upcomingHandoffs;
  final List<BookingModel> upcomingReturns;
  final int unreadMessages;
  final VoidCallback? onRefresh;

  const LenderActionDashboard({
    super.key,
    required this.pendingApprovals,
    required this.upcomingHandoffs,
    required this.upcomingReturns,
    required this.unreadMessages,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final hasActions = pendingApprovals.isNotEmpty ||
        upcomingHandoffs.isNotEmpty ||
        upcomingReturns.isNotEmpty ||
        unreadMessages > 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            if (!hasActions) _buildEmptyState() else _buildActionItems(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Action Required',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ColorConstants.textColor,
                  ),
            ),
            Text(
              'Items needing your attention',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ColorConstants.grey,
                  ),
            ),
          ],
        ),
        Row(
          children: [
            if (onRefresh != null)
              IconButton(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                iconSize: 20,
                tooltip: 'Refresh',
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getTotalActionsCount() > 0
                    ? ColorConstants.warningColor.withAlpha(25)
                    : ColorConstants.successColor.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getTotalActionsCount() > 0
                    ? '${_getTotalActionsCount()}'
                    : 'All Clear',
                style: TextStyle(
                  color: _getTotalActionsCount() > 0
                      ? ColorConstants.warningColor
                      : ColorConstants.successColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorConstants.successColor.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 32,
              color: ColorConstants.successColor,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'All caught up!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: ColorConstants.textColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'No pending actions. Check back later or refresh to see new updates.',
            style: TextStyle(
              color: ColorConstants.grey,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionItems(BuildContext context) {
    return Column(
      children: [
        // Pending Delivery Approvals
        if (pendingApprovals.isNotEmpty)
          _buildActionSection(
            context,
            title: 'Delivery Approvals',
            count: pendingApprovals.length,
            icon: Icons.local_shipping_outlined,
            color: ColorConstants.warningColor,
            items: pendingApprovals
                .take(3)
                .map((delivery) => _ActionItem(
                      title: delivery.itemName,
                      subtitle:
                          'Customer: ${delivery.customerName ?? "Unknown"}',
                      trailing: 'Approve delivery',
                      onTap: () =>
                          context.go('/delivery/approval/${delivery.id}'),
                    ))
                .toList(),
            viewAllAction: pendingApprovals.length > 3
                ? () => context.go('/deliveries?filter=pending_approval')
                : null,
          ),

        // Upcoming Handoffs
        if (upcomingHandoffs.isNotEmpty) ...[
          if (pendingApprovals.isNotEmpty) const SizedBox(height: 20),
          _buildActionSection(
            context,
            title: 'Upcoming Handoffs',
            count: upcomingHandoffs.length,
            icon: Icons.handshake_outlined,
            color: ColorConstants.infoColor,
            items: upcomingHandoffs
                .take(3)
                .map((booking) => _ActionItem(
                      title: booking.listingName,
                      subtitle: 'To: ${booking.renterName}',
                      trailing: DateFormattingHelper.formatWithContext(
                          booking.startDate),
                      onTap: () => context.go('/bookings/${booking.id}'),
                    ))
                .toList(),
            viewAllAction: upcomingHandoffs.length > 3
                ? () => context.go('/bookings?filter=upcoming')
                : null,
          ),
        ],

        // Upcoming Returns
        if (upcomingReturns.isNotEmpty) ...[
          if (pendingApprovals.isNotEmpty || upcomingHandoffs.isNotEmpty)
            const SizedBox(height: 20),
          _buildActionSection(
            context,
            title: 'Upcoming Returns',
            count: upcomingReturns.length,
            icon: Icons.assignment_return_outlined,
            color: ColorConstants.primaryColor,
            items: upcomingReturns
                .take(3)
                .map((booking) => _ActionItem(
                      title: booking.listingName,
                      subtitle: 'From: ${booking.renterName}',
                      trailing: DateFormattingHelper.formatWithContext(
                          booking.endDate),
                      onTap: () => context.go('/bookings/${booking.id}'),
                    ))
                .toList(),
            viewAllAction: upcomingReturns.length > 3
                ? () => context.go('/bookings?filter=returning')
                : null,
          ),
        ],

        // Unread Messages
        if (unreadMessages > 0) ...[
          if (pendingApprovals.isNotEmpty ||
              upcomingHandoffs.isNotEmpty ||
              upcomingReturns.isNotEmpty)
            const SizedBox(height: 20),
          _buildActionSection(
            context,
            title: 'Unread Messages',
            count: unreadMessages,
            icon: Icons.message_outlined,
            color: ColorConstants.secondaryColor,
            items: [
              _ActionItem(
                title: '$unreadMessages new messages',
                subtitle: 'From renters and support',
                trailing: 'View all',
                onTap: () => context.go('/messages'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildActionSection(
    BuildContext context, {
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required List<_ActionItem> items,
    VoidCallback? viewAllAction,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.textColor,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map((item) => _buildActionItemTile(item)),
        if (viewAllAction != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton(
              onPressed: viewAllAction,
              style: TextButton.styleFrom(
                foregroundColor: color,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('View all $count items'),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionItemTile(_ActionItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.subtitle != null)
                    Text(
                      item.subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: ColorConstants.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.trailing,
                  style: const TextStyle(
                    fontSize: 12,
                    color: ColorConstants.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: ColorConstants.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int _getTotalActionsCount() {
    return pendingApprovals.length +
        upcomingHandoffs.length +
        upcomingReturns.length +
        unreadMessages;
  }
}

class _ActionItem {
  final String title;
  final String? subtitle;
  final String trailing;
  final VoidCallback onTap;

  const _ActionItem({
    required this.title,
    this.subtitle,
    required this.trailing,
    required this.onTap,
  });
}
