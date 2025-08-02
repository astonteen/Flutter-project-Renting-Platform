import 'package:flutter/material.dart';
import 'package:rent_ease/features/delivery/data/models/delivery_batch_model.dart';
import 'package:rent_ease/features/delivery/data/models/delivery_job_model.dart';

class BatchDeliveryCard extends StatelessWidget {
  final DeliveryBatchModel batch;
  final Function(String jobId, DeliveryStatus status)? onJobStatusUpdate;

  const BatchDeliveryCard({
    super.key,
    required this.batch,
    this.onJobStatusUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_shipping, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Batch #${batch.id.substring(0, 8)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getBatchStatusColor(batch.status.name),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    batch.status.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress Bar
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: batch.totalDeliveries > 0
                        ? batch.completedDeliveries / batch.totalDeliveries
                        : 0,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getBatchStatusColor(batch.status.name),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${batch.totalDeliveries > 0 ? ((batch.completedDeliveries / batch.totalDeliveries) * 100).toInt() : 0}%',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${batch.completedDeliveries}/${batch.totalDeliveries} deliveries completed',
              style: const TextStyle(color: Colors.grey),
            ),

            if (batch.estimatedTotalTime != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Est. ${batch.estimatedTotalTime} min total',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),
            const Text(
              'Delivery Sequence:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),

            // Show next delivery info if available
            if (batch.nextDelivery != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.navigation, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Next Delivery:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Delivery #${batch.nextDelivery!.id.substring(0, 8)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Type: ${batch.nextDelivery!.currentLeg.name.replaceAll('_', ' ').toUpperCase()}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    if (batch.nextDelivery!.currentLeg == DeliveryLeg.pickup)
                      Text('📍 ${batch.nextDelivery!.pickupAddress}')
                    else
                      Text('🏁 ${batch.nextDelivery!.deliveryAddress}'),
                    if (onJobStatusUpdate != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _handleNextAction(context),
                              icon: const Icon(Icons.check),
                              label: Text(_getNextActionText()),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getBatchStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getNextActionText() {
    if (batch.nextDelivery == null) return 'Complete';

    switch (batch.nextDelivery!.currentLeg) {
      case DeliveryLeg.pickup:
        return 'Mark as Picked Up';
      case DeliveryLeg.delivery:
        return 'Mark as Delivered';
      case DeliveryLeg.returnPickup:
        return 'Mark Return Picked Up';
      case DeliveryLeg.returnDelivery:
        return 'Mark Return Delivered';
    }
  }

  void _handleNextAction(BuildContext context) {
    if (batch.nextDelivery == null || onJobStatusUpdate == null) return;

    final nextJob = batch.nextDelivery!;
    DeliveryStatus nextStatus;

    switch (nextJob.currentLeg) {
      case DeliveryLeg.pickup:
        nextStatus = DeliveryStatus.itemCollected;
        break;
      case DeliveryLeg.delivery:
        nextStatus = DeliveryStatus.itemDelivered;
        break;
      case DeliveryLeg.returnPickup:
        nextStatus = DeliveryStatus.returnCollected;
        break;
      case DeliveryLeg.returnDelivery:
        nextStatus = DeliveryStatus.returnDelivered;
        break;
    }

    onJobStatusUpdate!(nextJob.id, nextStatus);
  }
}
