class BookingModel {
  final String id;
  final String itemId;
  final String renterId;
  final String ownerId;
  final DateTime startDate;
  final DateTime endDate;
  final double totalAmount;
  final double securityDeposit;
  final String status; // pending, confirmed, active, completed, cancelled
  final bool
      needsDelivery; // Note: delivery details (address, instructions) are stored in deliveries table
  final String? deliveryPartnerId;
  final double? deliveryFee;
  final bool isItemReady; // New field for ready status
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? cancelReason;
  final Map<String, dynamic>? metadata;
  final DateTime? customerRatedAt; // When customer (renter) rated
  final DateTime? ownerRatedAt; // When owner rated

  const BookingModel({
    required this.id,
    required this.itemId,
    required this.renterId,
    required this.ownerId,
    required this.startDate,
    required this.endDate,
    required this.totalAmount,
    required this.securityDeposit,
    required this.status,
    required this.needsDelivery,
    this.deliveryPartnerId,
    this.deliveryFee,
    required this.isItemReady,
    required this.createdAt,
    required this.updatedAt,
    this.cancelReason,
    this.metadata,
    this.customerRatedAt,
    this.ownerRatedAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String,
      itemId: json['item_id'] as String,
      renterId: json['renter_id'] as String,
      ownerId: json['owner_id'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      totalAmount:
          (json['total_price'] as num).toDouble(), // Database uses total_price
      securityDeposit: (json['security_deposit'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String,
      needsDelivery: json['delivery_required'] as bool? ??
          false, // Database uses delivery_required
      deliveryPartnerId: json['delivery_partner_id'] as String?,
      deliveryFee: json['delivery_fee'] != null
          ? (json['delivery_fee'] as num).toDouble()
          : null,
      isItemReady: json['is_item_ready'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      cancelReason: json['cancel_reason'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      customerRatedAt: json['customer_rated_at'] != null
          ? DateTime.parse(json['customer_rated_at'] as String)
          : null,
      ownerRatedAt: json['owner_rated_at'] != null
          ? DateTime.parse(json['owner_rated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_id': itemId,
      'renter_id': renterId,
      'owner_id': ownerId,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'total_amount': totalAmount,
      'security_deposit': securityDeposit,
      'status': status,
      'delivery_required': needsDelivery, // Use database field name
      'delivery_partner_id': deliveryPartnerId,
      'delivery_fee': deliveryFee,
      'is_item_ready': isItemReady,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'cancel_reason': cancelReason,
      'metadata': metadata,
    };
  }

  // Helper methods
  int get rentalDays {
    return endDate.difference(startDate).inDays + 1;
  }

  double get dailyRate {
    return totalAmount / rentalDays;
  }

  bool get isActive {
    return status == 'in_progress' ||
        status == 'active' ||
        status == 'confirmed';
  }

  bool get canBeCancelled {
    return status == 'pending' || status == 'confirmed';
  }

  String get formattedDateRange {
    final startFormatted =
        '${startDate.day}/${startDate.month}/${startDate.year}';
    final endFormatted = '${endDate.day}/${endDate.month}/${endDate.year}';
    return '$startFormatted - $endFormatted';
  }

  String get statusDisplayText {
    switch (status) {
      case 'pending':
        return 'Awaiting Confirmation';
      case 'confirmed':
        return 'Confirmed';
      case 'in_progress':
      case 'active':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  BookingModel copyWith({
    String? id,
    String? itemId,
    String? renterId,
    String? ownerId,
    DateTime? startDate,
    DateTime? endDate,
    double? totalAmount,
    double? securityDeposit,
    String? status,
    bool? needsDelivery,
    String? deliveryPartnerId,
    double? deliveryFee,
    bool? isItemReady,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? cancelReason,
    Map<String, dynamic>? metadata,
  }) {
    return BookingModel(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      renterId: renterId ?? this.renterId,
      ownerId: ownerId ?? this.ownerId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalAmount: totalAmount ?? this.totalAmount,
      securityDeposit: securityDeposit ?? this.securityDeposit,
      status: status ?? this.status,
      needsDelivery: needsDelivery ?? this.needsDelivery,
      deliveryPartnerId: deliveryPartnerId ?? this.deliveryPartnerId,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      isItemReady: isItemReady ?? this.isItemReady,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cancelReason: cancelReason ?? this.cancelReason,
      metadata: metadata ?? this.metadata,
    );
  }
}
