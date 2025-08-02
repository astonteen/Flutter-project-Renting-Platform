import 'package:equatable/equatable.dart';
import 'delivery_job_model.dart';

enum BatchStatus { active, completed, cancelled }

class DeliveryBatchModel extends Equatable {
  final String id;
  final String driverId;
  final BatchStatus status;
  final List<DeliveryJobModel> deliveries;
  final int totalDeliveries;
  final int completedDeliveries;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? estimatedTotalTime; // in minutes
  final int? actualTotalTime; // in minutes

  const DeliveryBatchModel({
    required this.id,
    required this.driverId,
    required this.status,
    required this.deliveries,
    required this.totalDeliveries,
    required this.completedDeliveries,
    required this.createdAt,
    required this.updatedAt,
    this.estimatedTotalTime,
    this.actualTotalTime,
  });

  factory DeliveryBatchModel.fromJson(Map<String, dynamic> json) {
    return DeliveryBatchModel(
      id: json['id'] as String,
      driverId: json['driver_id'] as String,
      status: _parseStatus(json['status'] as String),
      deliveries: const [], // Will be populated separately
      totalDeliveries: json['total_deliveries'] as int? ?? 0,
      completedDeliveries: json['completed_deliveries'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      estimatedTotalTime: json['estimated_total_time'] as int?,
      actualTotalTime: json['actual_total_time'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driver_id': driverId,
      'status': _statusToString(status),
      'total_deliveries': totalDeliveries,
      'completed_deliveries': completedDeliveries,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'estimated_total_time': estimatedTotalTime,
      'actual_total_time': actualTotalTime,
    };
  }

  // Helper methods
  bool get isActive => status == BatchStatus.active;
  bool get isCompleted => status == BatchStatus.completed;

  double get completionPercentage {
    if (totalDeliveries == 0) return 0.0;
    return (completedDeliveries / totalDeliveries) * 100;
  }

  String get progressText => '$completedDeliveries/$totalDeliveries completed';

  String get statusDisplayText {
    switch (status) {
      case BatchStatus.active:
        return 'Active';
      case BatchStatus.completed:
        return 'Completed';
      case BatchStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get estimatedTimeText {
    if (estimatedTotalTime == null) return 'Calculating...';
    final hours = estimatedTotalTime! ~/ 60;
    final minutes = estimatedTotalTime! % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  // Get next delivery in sequence
  DeliveryJobModel? get nextDelivery {
    try {
      return deliveries
          .where((d) => !d.isCompleted)
          .reduce((a, b) => a.sequenceOrder < b.sequenceOrder ? a : b);
    } catch (e) {
      return null;
    }
  }

  // Get current pickup deliveries (not yet picked up)
  List<DeliveryJobModel> get pendingPickups {
    return deliveries
        .where((d) =>
            d.status == DeliveryStatus.driverAssigned ||
            d.status == DeliveryStatus.driverHeadingToPickup)
        .toList()
      ..sort((a, b) => a.sequenceOrder.compareTo(b.sequenceOrder));
  }

  // Get deliveries ready for dropoff
  List<DeliveryJobModel> get pendingDropoffs {
    return deliveries
        .where((d) =>
            d.status == DeliveryStatus.itemCollected ||
            d.status == DeliveryStatus.driverHeadingToDelivery)
        .toList()
      ..sort((a, b) => a.sequenceOrder.compareTo(b.sequenceOrder));
  }

  DeliveryBatchModel copyWith({
    String? id,
    String? driverId,
    BatchStatus? status,
    List<DeliveryJobModel>? deliveries,
    int? totalDeliveries,
    int? completedDeliveries,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? estimatedTotalTime,
    int? actualTotalTime,
  }) {
    return DeliveryBatchModel(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      status: status ?? this.status,
      deliveries: deliveries ?? this.deliveries,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      completedDeliveries: completedDeliveries ?? this.completedDeliveries,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      estimatedTotalTime: estimatedTotalTime ?? this.estimatedTotalTime,
      actualTotalTime: actualTotalTime ?? this.actualTotalTime,
    );
  }

  @override
  List<Object?> get props => [
        id,
        driverId,
        status,
        deliveries,
        totalDeliveries,
        completedDeliveries,
        createdAt,
        updatedAt,
        estimatedTotalTime,
        actualTotalTime,
      ];

  @override
  String toString() {
    return 'DeliveryBatchModel(id: $id, status: $statusDisplayText, progress: $progressText)';
  }

  // Private helper methods
  static BatchStatus _parseStatus(String status) {
    switch (status) {
      case 'active':
        return BatchStatus.active;
      case 'completed':
        return BatchStatus.completed;
      case 'cancelled':
        return BatchStatus.cancelled;
      default:
        return BatchStatus.active;
    }
  }

  static String _statusToString(BatchStatus status) {
    switch (status) {
      case BatchStatus.active:
        return 'active';
      case BatchStatus.completed:
        return 'completed';
      case BatchStatus.cancelled:
        return 'cancelled';
    }
  }
}
