import 'package:equatable/equatable.dart';

enum BookingStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled,
  overdue,
}

extension BookingStatusExtension on BookingStatus {
  String get displayName {
    switch (this) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.inProgress:
        return 'In Progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.overdue:
        return 'Overdue';
    }
  }

  String get colorCode {
    switch (this) {
      case BookingStatus.pending:
        return '#FF9800'; // Orange
      case BookingStatus.confirmed:
        return '#4CAF50'; // Green
      case BookingStatus.inProgress:
        return '#2196F3'; // Blue
      case BookingStatus.completed:
        return '#9E9E9E'; // Grey
      case BookingStatus.cancelled:
        return '#F44336'; // Red
      case BookingStatus.overdue:
        return '#D32F2F'; // Dark Red
    }
  }
}

class BookingModel extends Equatable {
  final String id;
  final String listingId;
  final String listingName;
  final String listingImageUrl;
  final String renterId;
  final String renterName;
  final String renterEmail;
  final String? renterPhone;
  final String? renterAvatarUrl;
  final double renterRating;
  final int renterReviewCount;
  final DateTime startDate;
  final DateTime endDate;
  final double totalAmount;
  final double securityDeposit;
  final BookingStatus status;
  final String? specialRequests;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeliveryRequired;
  final String? deliveryAddress;
  final double? deliveryFee;
  final bool isDepositPaid;
  final bool isItemReady;
  final String? conversationId;

  // Delivery status tracking
  final bool? hasReturnDelivery;
  final String? returnDeliveryStatus;
  final bool? isReturnCompleted;

  const BookingModel({
    required this.id,
    required this.listingId,
    required this.listingName,
    required this.listingImageUrl,
    required this.renterId,
    required this.renterName,
    required this.renterEmail,
    this.renterPhone,
    this.renterAvatarUrl,
    required this.renterRating,
    required this.renterReviewCount,
    required this.startDate,
    required this.endDate,
    required this.totalAmount,
    required this.securityDeposit,
    required this.status,
    this.specialRequests,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeliveryRequired,
    this.deliveryAddress,
    this.deliveryFee,
    required this.isDepositPaid,
    required this.isItemReady,
    this.conversationId,
    this.hasReturnDelivery,
    this.returnDeliveryStatus,
    this.isReturnCompleted,
  });

  int get durationInDays {
    return endDate.difference(startDate).inDays + 1;
  }

  String get durationDisplay {
    final days = durationInDays;
    if (days == 1) return '1 day';
    if (days < 7) return '$days days';
    if (days == 7) return '1 week';
    if (days < 30) return '${(days / 7).ceil()} weeks';
    return '${(days / 30).ceil()} months';
  }

  bool get isUpcoming {
    final now = DateTime.now();
    return startDate.isAfter(now) &&
        (status == BookingStatus.confirmed || status == BookingStatus.pending);
  }

  bool get isActive {
    final now = DateTime.now();
    return startDate.isBefore(now) &&
        endDate.isAfter(now) &&
        status == BookingStatus.inProgress;
  }

  bool get isPastDue {
    final now = DateTime.now();
    return endDate.isBefore(now) &&
        status != BookingStatus.completed &&
        status != BookingStatus.cancelled;
  }

  int get daysUntilStart {
    final now = DateTime.now();
    return startDate.difference(now).inDays;
  }

  String get timeUntilStart {
    final days = daysUntilStart;
    if (days == 0) return 'Today';
    if (days == 1) return 'Tomorrow';
    if (days < 7) return 'In $days days';
    if (days < 30) return 'In ${(days / 7).ceil()} weeks';
    return 'In ${(days / 30).ceil()} months';
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String,
      listingId: json['listing_id'] as String,
      listingName: json['listing_name'] as String? ?? '',
      listingImageUrl: json['listing_image_url'] as String? ?? '',
      renterId: json['renter_id'] as String,
      renterName: json['renter_name'] as String? ?? '',
      renterEmail: json['renter_email'] as String? ?? '',
      renterPhone: json['renter_phone'] as String?,
      renterAvatarUrl: json['renter_avatar_url'] as String?,
      renterRating: (json['renter_rating'] as num?)?.toDouble() ?? 0.0,
      renterReviewCount: json['renter_review_count'] as int? ?? 0,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      totalAmount: (json['total_amount'] as num).toDouble(),
      securityDeposit: (json['security_deposit'] as num?)?.toDouble() ?? 0.0,
      status: BookingStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => BookingStatus.pending,
      ),
      specialRequests: json['special_requests'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isDeliveryRequired: json['is_delivery_required'] as bool? ?? false,
      deliveryAddress: json['delivery_address'] as String?,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble(),
      isDepositPaid: json['is_deposit_paid'] as bool? ?? false,
      isItemReady: json['is_item_ready'] as bool? ?? false,
      conversationId: json['conversation_id'] as String?,
      hasReturnDelivery: json['has_return_delivery'] as bool?,
      returnDeliveryStatus: json['return_delivery_status'] as String?,
      isReturnCompleted: json['is_return_completed'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'listing_id': listingId,
      'listing_name': listingName,
      'listing_image_url': listingImageUrl,
      'renter_id': renterId,
      'renter_name': renterName,
      'renter_email': renterEmail,
      'renter_phone': renterPhone,
      'renter_avatar_url': renterAvatarUrl,
      'renter_rating': renterRating,
      'renter_review_count': renterReviewCount,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'total_amount': totalAmount,
      'security_deposit': securityDeposit,
      'status': status.name,
      'special_requests': specialRequests,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_delivery_required': isDeliveryRequired,
      'delivery_address': deliveryAddress,
      'delivery_fee': deliveryFee,
      'is_deposit_paid': isDepositPaid,
      'is_item_ready': isItemReady,
      'conversation_id': conversationId,
      'has_return_delivery': hasReturnDelivery,
      'return_delivery_status': returnDeliveryStatus,
      'is_return_completed': isReturnCompleted,
    };
  }

  BookingModel copyWith({
    String? id,
    String? listingId,
    String? listingName,
    String? listingImageUrl,
    String? renterId,
    String? renterName,
    String? renterEmail,
    String? renterPhone,
    String? renterAvatarUrl,
    double? renterRating,
    int? renterReviewCount,
    DateTime? startDate,
    DateTime? endDate,
    double? totalAmount,
    double? securityDeposit,
    BookingStatus? status,
    String? specialRequests,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeliveryRequired,
    String? deliveryAddress,
    double? deliveryFee,
    bool? isDepositPaid,
    bool? isItemReady,
    String? conversationId,
    bool? hasReturnDelivery,
    String? returnDeliveryStatus,
    bool? isReturnCompleted,
  }) {
    return BookingModel(
      id: id ?? this.id,
      listingId: listingId ?? this.listingId,
      listingName: listingName ?? this.listingName,
      listingImageUrl: listingImageUrl ?? this.listingImageUrl,
      renterId: renterId ?? this.renterId,
      renterName: renterName ?? this.renterName,
      renterEmail: renterEmail ?? this.renterEmail,
      renterPhone: renterPhone ?? this.renterPhone,
      renterAvatarUrl: renterAvatarUrl ?? this.renterAvatarUrl,
      renterRating: renterRating ?? this.renterRating,
      renterReviewCount: renterReviewCount ?? this.renterReviewCount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalAmount: totalAmount ?? this.totalAmount,
      securityDeposit: securityDeposit ?? this.securityDeposit,
      status: status ?? this.status,
      specialRequests: specialRequests ?? this.specialRequests,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeliveryRequired: isDeliveryRequired ?? this.isDeliveryRequired,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      isDepositPaid: isDepositPaid ?? this.isDepositPaid,
      isItemReady: isItemReady ?? this.isItemReady,
      conversationId: conversationId ?? this.conversationId,
      hasReturnDelivery: hasReturnDelivery ?? this.hasReturnDelivery,
      returnDeliveryStatus: returnDeliveryStatus ?? this.returnDeliveryStatus,
      isReturnCompleted: isReturnCompleted ?? this.isReturnCompleted,
    );
  }

  @override
  List<Object?> get props => [
        id,
        listingId,
        listingName,
        listingImageUrl,
        renterId,
        renterName,
        renterEmail,
        renterPhone,
        renterAvatarUrl,
        renterRating,
        renterReviewCount,
        startDate,
        endDate,
        totalAmount,
        securityDeposit,
        status,
        specialRequests,
        notes,
        createdAt,
        updatedAt,
        isDeliveryRequired,
        deliveryAddress,
        deliveryFee,
        isDepositPaid,
        isItemReady,
        conversationId,
        hasReturnDelivery,
        returnDeliveryStatus,
        isReturnCompleted,
      ];
}
