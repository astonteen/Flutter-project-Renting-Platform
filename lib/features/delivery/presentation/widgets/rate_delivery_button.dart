import 'package:flutter/material.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/features/delivery/data/models/delivery_job_model.dart';
import 'package:rent_ease/features/delivery/presentation/screens/delivery_rating_screen.dart';

class RateDeliveryButton extends StatelessWidget {
  final DeliveryJobModel delivery;
  final bool hasBeenRated;

  const RateDeliveryButton({
    super.key,
    required this.delivery,
    this.hasBeenRated = false,
  });

  @override
  Widget build(BuildContext context) {
    if (hasBeenRated) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: ColorConstants.successColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: ColorConstants.successColor.withValues(alpha: 0.3),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              size: 16,
              color: ColorConstants.successColor,
            ),
            SizedBox(width: 6),
            Text(
              'Rated',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: ColorConstants.successColor,
              ),
            ),
          ],
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: () => _navigateToRating(context),
      icon: const Icon(
        Icons.star_rate,
        size: 16,
        color: ColorConstants.white,
      ),
      label: const Text(
        'Rate Delivery',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: ColorConstants.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorConstants.primaryColor,
        foregroundColor: ColorConstants.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 2,
      ),
    );
  }

  void _navigateToRating(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DeliveryRatingScreen(delivery: delivery),
      ),
    );
  }
}

// Extension to show rating button for completed deliveries
extension DeliveryJobRatingExtension on DeliveryJobModel {
  bool get canBeRated {
    return status == DeliveryStatus.itemDelivered ||
        status == DeliveryStatus.completed;
  }

  bool get hasCustomerRating {
    // This would need to be added to the model or fetched separately
    return false; // TODO: Implement actual rating check
  }
}
