import 'package:flutter/material.dart';
import 'package:rent_ease/core/constants/color_constants.dart';

class StatusCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color primaryColor;
  final Color? secondaryColor;
  final Widget? trailing;

  const StatusCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.primaryColor,
    this.secondaryColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveSecondaryColor =
        secondaryColor ?? primaryColor.withValues(alpha: 0.8);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, effectiveSecondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class DeliveryStatusCard extends StatusCard {
  const DeliveryStatusCard({
    super.key,
    required String itemName,
    super.trailing,
  }) : super(
          title: 'Delivery Request',
          subtitle:
              'A customer has requested delivery for their rental of "$itemName"',
          icon: Icons.local_shipping,
          primaryColor: ColorConstants.primaryColor,
        );
}

class WarningStatusCard extends StatusCard {
  const WarningStatusCard({
    super.key,
    required String title,
    required String subtitle,
    super.trailing,
  }) : super(
          title: title,
          subtitle: subtitle,
          icon: Icons.warning,
          primaryColor: ColorConstants.warningColor,
        );
}

class SuccessStatusCard extends StatusCard {
  const SuccessStatusCard({
    super.key,
    required String title,
    required String subtitle,
    super.trailing,
  }) : super(
          title: title,
          subtitle: subtitle,
          icon: Icons.check_circle,
          primaryColor: Colors.green,
        );
}
