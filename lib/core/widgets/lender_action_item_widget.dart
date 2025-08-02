import 'package:flutter/material.dart';
import 'package:rent_ease/core/router/app_routes.dart';
import 'package:rent_ease/features/home/data/models/lender_action_item.dart';

class LenderActionItemWidget extends StatelessWidget {
  final LenderActionItem action;
  final VoidCallback? onActionPressed;

  const LenderActionItemWidget({
    super.key,
    required this.action,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Priority badge and due time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: action.priority.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: action.priority.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        action.priority.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: action.priority.color,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (action.dueTime != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 12,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDueTime(action.dueTime!),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Main content
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Action icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: action.type.icon == Icons.error
                        ? Colors.red.shade50
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    action.type.icon,
                    size: 24,
                    color: action.type.icon == Icons.error
                        ? Colors.red.shade600
                        : Colors.blue.shade600,
                  ),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        action.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        action.subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Item and renter details
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (action.itemName.isNotEmpty) ...[
                            Row(
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 16,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    action.itemName,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                          ],
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 16,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  action.renterName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onActionPressed ?? () => _handleActionTap(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: action.priority.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  action.type.actionButtonText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDueTime(DateTime dueTime) {
    final now = DateTime.now();
    final difference = dueTime.difference(now);

    if (difference.isNegative) {
      final pastDifference = now.difference(dueTime);
      if (pastDifference.inMinutes < 60) {
        return '${pastDifference.inMinutes}m overdue';
      } else if (pastDifference.inHours < 24) {
        return '${pastDifference.inHours}h overdue';
      } else {
        return '${pastDifference.inDays}d overdue';
      }
    }

    if (difference.inMinutes < 60) {
      return 'in ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'in ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'in ${difference.inDays}d';
    } else {
      return 'in ${(difference.inDays / 7).floor()}w';
    }
  }

  void _handleActionTap(BuildContext context) {
    switch (action.type) {
      case ActionType.approveDelivery:
        if (action.relatedId != null) {
          AppRoutes.goToDeliveryApproval(context, action.relatedId!);
        }
        break;
      case ActionType.prepareForPickup:
      case ActionType.confirmReturn:
        // Navigate to booking details or rental management
        if (action.relatedId != null) {
          // AppRoutes.goToBookingDetails(context, action.relatedId!);
        }
        break;
      case ActionType.respondToMessage:
        AppRoutes.goToNotifications(context);
        break;
      case ActionType.contactRenter:
        AppRoutes.goToNotifications(context);
        break;
      case ActionType.rescheduleDelivery:
        if (action.relatedId != null) {
          AppRoutes.goToDeliveryApproval(context, action.relatedId!);
        }
        break;
      case ActionType.markItemReady:
        AppRoutes.goToLenderCalendar(context);
        break;
      case ActionType.reviewOverdue:
        if (action.relatedId != null) {
          // AppRoutes.goToBookingDetails(context, action.relatedId!);
        }
        break;
    }
  }
}
