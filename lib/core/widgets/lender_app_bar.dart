import 'package:flutter/material.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/core/router/app_routes.dart';

class LenderAppBar extends StatelessWidget {
  final int unreadMessages;
  final DateTime? lastSyncTime;
  final String title;
  final String subtitle;

  const LenderAppBar({
    super.key,
    required this.unreadMessages,
    this.lastSyncTime,
    this.title = 'Welcome back!',
    this.subtitle = '',
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 100,
      floating: true,
      pinned: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: ColorConstants.textColor,
                              ),
                        ),
                        if (lastSyncTime != null)
                          Text(
                            subtitle.isNotEmpty
                                ? subtitle
                                : 'Last synced ${_getRelativeTime(lastSyncTime!)}',
                            style: const TextStyle(
                              color: ColorConstants.grey,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  _buildNotificationButton(context),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationButton(BuildContext context) {
    return IconButton(
      onPressed: () => AppRoutes.goToNotifications(context),
      icon: Stack(
        children: [
          const Icon(Icons.notifications_outlined),
          if (unreadMessages > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: ColorConstants.errorColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  '$unreadMessages',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getRelativeTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
