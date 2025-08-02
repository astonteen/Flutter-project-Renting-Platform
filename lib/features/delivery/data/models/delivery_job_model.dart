import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

enum DeliveryType { pickupDelivery, returnPickup }

enum DeliveryLeg { pickup, delivery, returnPickup, returnDelivery }

enum DeliveryStatus {
  pendingApproval,
  approved,
  driverAssigned,
  driverHeadingToPickup,
  itemCollected,
  driverHeadingToDelivery,
  itemDelivered,
  returnRequested,
  returnScheduled,
  returnCollected,
  returnDelivered,
  completed,
  cancelled
}

enum VehicleType { bike, motorcycle, car, van }

class DeliveryJobModel extends Equatable {
  final String id;
  final String rentalId;
  final String? driverId;
  final String itemName;
  final String pickupAddress;
  final String deliveryAddress;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final double fee;
  final DeliveryStatus status;
  final DeliveryType deliveryType;
  final DeliveryLeg currentLeg;
  final int estimatedDuration; // in minutes
  final double distanceKm;
  final double driverEarnings;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Approval workflow fields
  final bool lenderApprovalRequired;
  final DateTime? lenderApprovedAt;
  final DateTime? lenderApprovalTimeout;
  final bool autoApproved;

  // Return delivery fields
  final String? returnDeliveryId;
  final bool isReturnDelivery;
  final DateTime? returnScheduledTime;
  final String? originalDeliveryId;

  // Batch delivery features
  final String? batchGroupId;
  final int sequenceOrder;
  final DateTime? estimatedPickupTime;
  final DateTime? estimatedDeliveryTime;
  final DateTime? actualPickupTime;
  final DateTime? actualDeliveryTime;

  // Professional features
  final String? pickupProofImage;
  final String? deliveryProofImage;
  final String? specialInstructions;
  final int? customerRating;
  final double customerTip;
  final DateTime? pickupTime;
  final DateTime? dropoffTime;

  // Related data
  final String? customerName;
  final String? customerPhone;
  final String? ownerName;
  final String? ownerPhone;

  // User context for role-based UI
  final bool userIsRenter;
  final bool userIsOwner;

  const DeliveryJobModel({
    required this.id,
    required this.rentalId,
    this.driverId,
    required this.itemName,
    required this.pickupAddress,
    required this.deliveryAddress,
    this.pickupLatitude,
    this.pickupLongitude,
    this.deliveryLatitude,
    this.deliveryLongitude,
    required this.fee,
    required this.status,
    required this.deliveryType,
    required this.currentLeg,
    required this.estimatedDuration,
    required this.distanceKm,
    required this.driverEarnings,
    required this.createdAt,
    required this.updatedAt,
    this.lenderApprovalRequired = true,
    this.lenderApprovedAt,
    this.lenderApprovalTimeout,
    this.autoApproved = false,
    this.returnDeliveryId,
    this.isReturnDelivery = false,
    this.returnScheduledTime,
    this.originalDeliveryId,
    this.batchGroupId,
    this.sequenceOrder = 0,
    this.estimatedPickupTime,
    this.estimatedDeliveryTime,
    this.actualPickupTime,
    this.actualDeliveryTime,
    this.pickupProofImage,
    this.deliveryProofImage,
    this.specialInstructions,
    this.customerRating,
    this.customerTip = 0.0,
    this.pickupTime,
    this.dropoffTime,
    this.customerName,
    this.customerPhone,
    this.ownerName,
    this.ownerPhone,
    this.userIsRenter = false,
    this.userIsOwner = false,
  });

  /// User-friendly status text that customers actually understand
  String get statusDisplayText {
    switch (status) {
      case DeliveryStatus.pendingApproval:
        return lenderApprovalRequired
            ? 'Waiting for owner approval'
            : 'Processing request';
      case DeliveryStatus.approved:
        return 'Looking for a driver';
      case DeliveryStatus.driverAssigned:
        return 'Driver assigned';
      case DeliveryStatus.driverHeadingToPickup:
        return 'Driver is on the way to collect';
      case DeliveryStatus.itemCollected:
        return 'Item collected - heading to you!';
      case DeliveryStatus.driverHeadingToDelivery:
        return 'Out for delivery';
      case DeliveryStatus.itemDelivered:
        return 'Delivered successfully';
      case DeliveryStatus.returnRequested:
        return 'Return requested';
      case DeliveryStatus.returnScheduled:
        return 'Return pickup scheduled';
      case DeliveryStatus.returnCollected:
        return 'Item collected for return';
      case DeliveryStatus.returnDelivered:
        return 'Returned to owner';
      case DeliveryStatus.completed:
        return 'Completed';
      case DeliveryStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Detailed status message with context
  String get statusDetailMessage {
    switch (status) {
      case DeliveryStatus.pendingApproval:
        if (lenderApprovalTimeout != null) {
          final timeLeft = lenderApprovalTimeout!.difference(DateTime.now());
          if (timeLeft.isNegative) {
            return 'Auto-approval in progress';
          }
          final hoursLeft = timeLeft.inHours;
          final minutesLeft = timeLeft.inMinutes % 60;
          return 'Auto-approval in ${hoursLeft}h ${minutesLeft}m if not approved';
        }
        return 'The item owner needs to approve your delivery request';
      case DeliveryStatus.approved:
        return 'We\'re finding the best driver for your delivery';
      case DeliveryStatus.driverAssigned:
        return 'Your driver is preparing for pickup';
      case DeliveryStatus.driverHeadingToPickup:
        return 'Your driver is on the way to collect the item';
      case DeliveryStatus.itemCollected:
        return 'The item has been safely collected and is now heading to you';
      case DeliveryStatus.driverHeadingToDelivery:
        return 'Your item is on the way to your delivery address';
      case DeliveryStatus.itemDelivered:
        return 'Your item has been delivered successfully. Enjoy!';
      case DeliveryStatus.returnRequested:
        return 'Return delivery has been requested';
      case DeliveryStatus.returnScheduled:
        return 'Return pickup has been scheduled';
      case DeliveryStatus.returnCollected:
        return 'Item collected and heading back to owner';
      case DeliveryStatus.returnDelivered:
        return 'Item successfully returned to the owner';
      case DeliveryStatus.completed:
        return 'Delivery completed successfully';
      case DeliveryStatus.cancelled:
        return 'Delivery was cancelled';
    }
  }

  /// Progress percentage (0-100) for progress bars
  int get progressPercentage {
    switch (status) {
      case DeliveryStatus.pendingApproval:
        return 10;
      case DeliveryStatus.approved:
        return 20;
      case DeliveryStatus.driverAssigned:
        return 30;
      case DeliveryStatus.driverHeadingToPickup:
        return 45;
      case DeliveryStatus.itemCollected:
        return 60;
      case DeliveryStatus.driverHeadingToDelivery:
        return 80;
      case DeliveryStatus.itemDelivered:
        return 100;
      case DeliveryStatus.returnRequested:
        return 100;
      case DeliveryStatus.returnScheduled:
        return 100;
      case DeliveryStatus.returnCollected:
        return 100;
      case DeliveryStatus.returnDelivered:
        return 100;
      case DeliveryStatus.completed:
        return 100;
      case DeliveryStatus.cancelled:
        return 0;
    }
  }

  /// Whether this delivery needs lender approval
  bool get needsApproval => lenderApprovalRequired && lenderApprovedAt == null;

  /// Whether approval has timed out and should auto-approve
  bool get approvalTimedOut {
    if (!lenderApprovalRequired || lenderApprovalTimeout == null) return false;
    return DateTime.now().isAfter(lenderApprovalTimeout!);
  }

  /// Whether this delivery is approved and ready for driver assignment
  bool get isApproved => lenderApprovedAt != null || autoApproved;

  /// Whether this delivery is active (in progress)
  bool get isActive => [
        DeliveryStatus.driverAssigned,
        DeliveryStatus.driverHeadingToPickup,
        DeliveryStatus.itemCollected,
        DeliveryStatus.driverHeadingToDelivery,
      ].contains(status);

  /// Whether this delivery is completed
  bool get isCompleted => [
        DeliveryStatus.itemDelivered,
        DeliveryStatus.completed,
        DeliveryStatus.returnDelivered,
      ].contains(status);

  /// Whether this delivery is cancelled
  bool get isCancelled => status == DeliveryStatus.cancelled;

  /// Get the next action text for the driver
  String get nextDriverAction {
    switch (status) {
      case DeliveryStatus.pendingApproval:
        return 'Awaiting Approval';
      case DeliveryStatus.approved:
        return 'Accept Job';
      case DeliveryStatus.driverAssigned:
        return 'Head to Pickup';
      case DeliveryStatus.driverHeadingToPickup:
        return 'Confirm Pickup';
      case DeliveryStatus.itemCollected:
        return 'Head to Delivery';
      case DeliveryStatus.driverHeadingToDelivery:
        return 'Confirm Delivery';
      case DeliveryStatus.itemDelivered:
        return 'Job Complete';
      case DeliveryStatus.returnRequested:
        return 'Return Requested';
      case DeliveryStatus.returnScheduled:
        return 'Return Scheduled';
      case DeliveryStatus.returnCollected:
        return 'Returning Item';
      case DeliveryStatus.returnDelivered:
        return 'Return Complete';
      case DeliveryStatus.completed:
        return 'Completed';
      case DeliveryStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Factory constructor from JSON with enhanced field mapping
  factory DeliveryJobModel.fromJson(Map<String, dynamic> json) {
    return DeliveryJobModel(
      id: json['id'] ?? '',
      rentalId: json['rental_id'] ?? '',
      driverId: json['driver_id'],
      itemName: json['item_name'] ?? 'Unknown Item',
      pickupAddress: json['pickup_address'] ?? '',
      deliveryAddress: json['dropoff_address'] ?? '',
      pickupLatitude: _parseCoordinate(json['pickup_latitude']),
      pickupLongitude: _parseCoordinate(json['pickup_longitude']),
      deliveryLatitude: _parseCoordinate(json['dropoff_latitude']),
      deliveryLongitude: _parseCoordinate(json['dropoff_longitude']),
      fee: (json['fee'] as num?)?.toDouble() ?? 0.0,
      status: _parseDeliveryStatus(json['status']),
      deliveryType: _parseDeliveryType(json['delivery_type']),
      currentLeg: _parseDeliveryLeg(json['current_leg']),
      estimatedDuration: json['estimated_duration'] ?? 30,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      driverEarnings: (json['driver_earnings'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(
          json['updated_at'] ?? DateTime.now().toIso8601String()),
      lenderApprovalRequired: json['lender_approval_required'] ?? true,
      lenderApprovedAt: json['lender_approved_at'] != null
          ? DateTime.parse(json['lender_approved_at'])
          : null,
      lenderApprovalTimeout: json['lender_approval_timeout'] != null
          ? DateTime.parse(json['lender_approval_timeout'])
          : null,
      autoApproved: json['auto_approved'] ?? false,
      returnDeliveryId: json['return_delivery_id'],
      isReturnDelivery: json['is_return_delivery'] ?? false,
      returnScheduledTime: json['return_scheduled_time'] != null
          ? DateTime.parse(json['return_scheduled_time'])
          : null,
      originalDeliveryId: json['original_delivery_id'],
      batchGroupId: json['batch_group_id'],
      sequenceOrder: json['sequence_order'] ?? 0,
      estimatedPickupTime: json['estimated_pickup_time'] != null
          ? DateTime.parse(json['estimated_pickup_time'])
          : null,
      estimatedDeliveryTime: json['estimated_delivery_time'] != null
          ? DateTime.parse(json['estimated_delivery_time'])
          : null,
      actualPickupTime: json['actual_pickup_time'] != null
          ? DateTime.parse(json['actual_pickup_time'])
          : null,
      actualDeliveryTime: json['actual_delivery_time'] != null
          ? DateTime.parse(json['actual_delivery_time'])
          : null,
      pickupProofImage: json['pickup_proof_image'],
      deliveryProofImage: json['delivery_proof_image'],
      specialInstructions: json['special_instructions'],
      customerRating: json['customer_rating'],
      customerTip: (json['customer_tip'] as num?)?.toDouble() ?? 0.0,
      pickupTime: json['pickup_time'] != null
          ? DateTime.parse(json['pickup_time'])
          : null,
      dropoffTime: json['dropoff_time'] != null
          ? DateTime.parse(json['dropoff_time'])
          : null,
      customerName: json['customer_name'],
      customerPhone: json['customer_phone'],
      ownerName: json['owner_name'],
      ownerPhone: json['owner_phone'],
      userIsRenter: json['user_is_renter'] as bool? ?? false,
      userIsOwner: json['user_is_owner'] as bool? ?? false,
    );
  }

  /// Enhanced status parsing with new statuses
  static DeliveryStatus _parseDeliveryStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending_approval':
        return DeliveryStatus.pendingApproval;
      case 'approved':
        return DeliveryStatus.approved;
      case 'driver_assigned':
        return DeliveryStatus.driverAssigned;
      case 'driver_heading_to_pickup':
        return DeliveryStatus.driverHeadingToPickup;
      case 'item_collected':
        return DeliveryStatus.itemCollected;
      case 'driver_heading_to_delivery':
        return DeliveryStatus.driverHeadingToDelivery;
      case 'item_delivered':
        return DeliveryStatus.itemDelivered;
      case 'return_requested':
        return DeliveryStatus.returnRequested;
      case 'return_scheduled':
        return DeliveryStatus.returnScheduled;
      case 'return_collected':
        return DeliveryStatus.returnCollected;
      case 'return_delivered':
        return DeliveryStatus.returnDelivered;
      case 'completed':
        return DeliveryStatus.completed;
      case 'cancelled':
        return DeliveryStatus.cancelled;
      default:
        return DeliveryStatus.pendingApproval;
    }
  }

  static DeliveryType _parseDeliveryType(String? type) {
    switch (type?.toLowerCase()) {
      case 'return_pickup':
        return DeliveryType.returnPickup;
      case 'pickup_delivery':
      default:
        return DeliveryType.pickupDelivery;
    }
  }

  static DeliveryLeg _parseDeliveryLeg(String? leg) {
    switch (leg?.toLowerCase()) {
      case 'delivery':
        return DeliveryLeg.delivery;
      case 'return_pickup':
        return DeliveryLeg.returnPickup;
      case 'return_delivery':
        return DeliveryLeg.returnDelivery;
      default:
        return DeliveryLeg.delivery;
    }
  }

  static double? _parseCoordinate(dynamic value) {
    debugPrint('Parsing coordinate: $value (type: ${value.runtimeType})');
    if (value is String) {
      final parsed = double.tryParse(value);
      debugPrint('Parsed string coordinate: $parsed');
      return parsed;
    } else if (value is num) {
      final parsed = value.toDouble();
      debugPrint('Parsed numeric coordinate: $parsed');
      return parsed;
    }
    debugPrint('Could not parse coordinate: $value');
    return null;
  }

  @override
  List<Object?> get props => [
        id,
        rentalId,
        driverId,
        itemName,
        pickupAddress,
        deliveryAddress,
        pickupLatitude,
        pickupLongitude,
        deliveryLatitude,
        deliveryLongitude,
        fee,
        status,
        deliveryType,
        currentLeg,
        estimatedDuration,
        distanceKm,
        driverEarnings,
        createdAt,
        updatedAt,
        lenderApprovalRequired,
        lenderApprovedAt,
        lenderApprovalTimeout,
        autoApproved,
        returnDeliveryId,
        isReturnDelivery,
        returnScheduledTime,
        originalDeliveryId,
        batchGroupId,
        sequenceOrder,
        estimatedPickupTime,
        estimatedDeliveryTime,
        actualPickupTime,
        actualDeliveryTime,
        pickupProofImage,
        deliveryProofImage,
        specialInstructions,
        customerRating,
        customerTip,
        pickupTime,
        dropoffTime,
        customerName,
        customerPhone,
        ownerName,
        ownerPhone,
        userIsRenter,
        userIsOwner,
      ];

  DeliveryJobModel copyWith({
    String? id,
    String? rentalId,
    String? driverId,
    String? itemName,
    String? pickupAddress,
    String? deliveryAddress,
    double? pickupLatitude,
    double? pickupLongitude,
    double? deliveryLatitude,
    double? deliveryLongitude,
    double? fee,
    DeliveryStatus? status,
    DeliveryType? deliveryType,
    DeliveryLeg? currentLeg,
    int? estimatedDuration,
    double? distanceKm,
    double? driverEarnings,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? lenderApprovalRequired,
    DateTime? lenderApprovedAt,
    DateTime? lenderApprovalTimeout,
    bool? autoApproved,
    String? returnDeliveryId,
    bool? isReturnDelivery,
    DateTime? returnScheduledTime,
    String? originalDeliveryId,
    String? batchGroupId,
    int? sequenceOrder,
    DateTime? estimatedPickupTime,
    DateTime? estimatedDeliveryTime,
    DateTime? actualPickupTime,
    DateTime? actualDeliveryTime,
    String? pickupProofImage,
    String? deliveryProofImage,
    String? specialInstructions,
    int? customerRating,
    double? customerTip,
    DateTime? pickupTime,
    DateTime? dropoffTime,
    String? customerName,
    String? customerPhone,
    String? ownerName,
    String? ownerPhone,
  }) {
    return DeliveryJobModel(
      id: id ?? this.id,
      rentalId: rentalId ?? this.rentalId,
      driverId: driverId ?? this.driverId,
      itemName: itemName ?? this.itemName,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      pickupLatitude: pickupLatitude ?? this.pickupLatitude,
      pickupLongitude: pickupLongitude ?? this.pickupLongitude,
      deliveryLatitude: deliveryLatitude ?? this.deliveryLatitude,
      deliveryLongitude: deliveryLongitude ?? this.deliveryLongitude,
      fee: fee ?? this.fee,
      status: status ?? this.status,
      deliveryType: deliveryType ?? this.deliveryType,
      currentLeg: currentLeg ?? this.currentLeg,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      distanceKm: distanceKm ?? this.distanceKm,
      driverEarnings: driverEarnings ?? this.driverEarnings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lenderApprovalRequired:
          lenderApprovalRequired ?? this.lenderApprovalRequired,
      lenderApprovedAt: lenderApprovedAt ?? this.lenderApprovedAt,
      lenderApprovalTimeout:
          lenderApprovalTimeout ?? this.lenderApprovalTimeout,
      autoApproved: autoApproved ?? this.autoApproved,
      returnDeliveryId: returnDeliveryId ?? this.returnDeliveryId,
      isReturnDelivery: isReturnDelivery ?? this.isReturnDelivery,
      returnScheduledTime: returnScheduledTime ?? this.returnScheduledTime,
      originalDeliveryId: originalDeliveryId ?? this.originalDeliveryId,
      batchGroupId: batchGroupId ?? this.batchGroupId,
      sequenceOrder: sequenceOrder ?? this.sequenceOrder,
      estimatedPickupTime: estimatedPickupTime ?? this.estimatedPickupTime,
      estimatedDeliveryTime:
          estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      actualPickupTime: actualPickupTime ?? this.actualPickupTime,
      actualDeliveryTime: actualDeliveryTime ?? this.actualDeliveryTime,
      pickupProofImage: pickupProofImage ?? this.pickupProofImage,
      deliveryProofImage: deliveryProofImage ?? this.deliveryProofImage,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      customerRating: customerRating ?? this.customerRating,
      customerTip: customerTip ?? this.customerTip,
      pickupTime: pickupTime ?? this.pickupTime,
      dropoffTime: dropoffTime ?? this.dropoffTime,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
    );
  }

  /// Convert to JSON for API calls
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rental_id': rentalId,
      'driver_id': driverId,
      'item_name': itemName,
      'pickup_address': pickupAddress,
      'dropoff_address': deliveryAddress,
      'pickup_latitude': pickupLatitude,
      'pickup_longitude': pickupLongitude,
      'dropoff_latitude': deliveryLatitude,
      'dropoff_longitude': deliveryLongitude,
      'fee': fee,
      'status': _deliveryStatusToString(status),
      'delivery_type': _deliveryTypeToString(deliveryType),
      'current_leg': _deliveryLegToString(currentLeg),
      'estimated_duration': estimatedDuration,
      'distance_km': distanceKm,
      'driver_earnings': driverEarnings,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'lender_approval_required': lenderApprovalRequired,
      'lender_approved_at': lenderApprovedAt?.toIso8601String(),
      'lender_approval_timeout': lenderApprovalTimeout?.toIso8601String(),
      'auto_approved': autoApproved,
      'return_delivery_id': returnDeliveryId,
      'is_return_delivery': isReturnDelivery,
      'return_scheduled_time': returnScheduledTime?.toIso8601String(),
      'original_delivery_id': originalDeliveryId,
      'batch_group_id': batchGroupId,
      'sequence_order': sequenceOrder,
      'estimated_pickup_time': estimatedPickupTime?.toIso8601String(),
      'estimated_delivery_time': estimatedDeliveryTime?.toIso8601String(),
      'actual_pickup_time': actualPickupTime?.toIso8601String(),
      'actual_delivery_time': actualDeliveryTime?.toIso8601String(),
      'pickup_proof_image': pickupProofImage,
      'delivery_proof_image': deliveryProofImage,
      'special_instructions': specialInstructions,
      'customer_rating': customerRating,
      'customer_tip': customerTip,
      'pickup_time': pickupTime?.toIso8601String(),
      'dropoff_time': dropoffTime?.toIso8601String(),
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'owner_name': ownerName,
      'owner_phone': ownerPhone,
    };
  }

  static String _deliveryStatusToString(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pendingApproval:
        return 'pending_approval';
      case DeliveryStatus.approved:
        return 'approved';
      case DeliveryStatus.driverAssigned:
        return 'driver_assigned';
      case DeliveryStatus.driverHeadingToPickup:
        return 'driver_heading_to_pickup';
      case DeliveryStatus.itemCollected:
        return 'item_collected';
      case DeliveryStatus.driverHeadingToDelivery:
        return 'driver_heading_to_delivery';
      case DeliveryStatus.itemDelivered:
        return 'item_delivered';
      case DeliveryStatus.returnRequested:
        return 'return_requested';
      case DeliveryStatus.returnScheduled:
        return 'return_scheduled';
      case DeliveryStatus.returnCollected:
        return 'return_collected';
      case DeliveryStatus.returnDelivered:
        return 'return_delivered';
      case DeliveryStatus.completed:
        return 'completed';
      case DeliveryStatus.cancelled:
        return 'cancelled';
    }
  }

  static String _deliveryTypeToString(DeliveryType type) {
    switch (type) {
      case DeliveryType.returnPickup:
        return 'return_pickup';
      case DeliveryType.pickupDelivery:
        return 'pickup_delivery';
    }
  }

  static String _deliveryLegToString(DeliveryLeg leg) {
    switch (leg) {
      case DeliveryLeg.pickup:
        return 'pickup';
      case DeliveryLeg.delivery:
        return 'delivery';
      case DeliveryLeg.returnPickup:
        return 'return_pickup';
      case DeliveryLeg.returnDelivery:
        return 'return_delivery';
    }
  }
}
