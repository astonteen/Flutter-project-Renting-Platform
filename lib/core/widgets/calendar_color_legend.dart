import 'package:flutter/material.dart';
import 'package:rent_ease/core/constants/color_constants.dart';

class CalendarColorLegend extends StatelessWidget {
  const CalendarColorLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Calendar Legend',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: ColorConstants.textColor,
                    ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey.withAlpha(25),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Simple Availability Status
          Text(
            'Availability Status',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.textColor,
                ),
          ),
          const SizedBox(height: 16),

          _buildSimpleLegendItem(
            color: Colors.green[50]!,
            title: 'Available',
            subtitle: 'Items available for booking',
            icon: Icons.check_circle,
          ),

          _buildSimpleLegendItem(
            color: Colors.yellow[50]!,
            title: 'Partially Booked',
            subtitle: 'Some items booked, others available',
            icon: Icons.circle,
            dotColor: Colors.yellow,
          ),

          _buildSimpleLegendItem(
            color: Colors.red[50]!,
            title: 'Fully Booked',
            subtitle: 'No items available',
            icon: Icons.cancel,
            dotColor: Colors.red,
          ),

          _buildSimpleLegendItem(
            color: Colors.orange[50]!,
            title: 'Blocked',
            subtitle: 'Unavailable due to maintenance or return processing',
            icon: Icons.block,
            dotColor: Colors.orange,
          ),

          _buildSimpleLegendItem(
            color: Colors.grey[100]!,
            title: 'Past Date',
            subtitle: 'Date has already passed',
            icon: Icons.history,
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // Simple tip
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorConstants.primaryColor.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: ColorConstants.primaryColor,
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tap any date to view details, long-press to block dates',
                    style: TextStyle(
                      color: ColorConstants.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleLegendItem({
    required Color color,
    required String title,
    required String subtitle,
    required IconData icon,
    Color? dotColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // Background color sample
          Container(
            width: 40,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!, width: 1),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(icon, color: Colors.grey[600], size: 16),
                ),
                // Add dot indicator if specified
                if (dotColor != null)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: ColorConstants.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void showCalendarColorLegend(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const CalendarColorLegend(),
  );
}
