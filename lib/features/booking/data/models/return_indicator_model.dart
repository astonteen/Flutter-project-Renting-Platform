class ReturnIndicator {
  final String id;
  final String itemId;
  final String rentalId;
  final DateTime expectedReturnDate;
  final DateTime? actualReturnDate;
  final String returnStatus; // pending, overdue, completed, extended
  final int bufferDays;
  final String? reason;
  final String? notes;
  final DateTime? rentalStartDate;
  final DateTime? rentalEndDate;
  final double? rentalPrice;
  final String? renterId;

  const ReturnIndicator({
    required this.id,
    required this.itemId,
    required this.rentalId,
    required this.expectedReturnDate,
    this.actualReturnDate,
    required this.returnStatus,
    required this.bufferDays,
    this.reason,
    this.notes,
    this.rentalStartDate,
    this.rentalEndDate,
    this.rentalPrice,
    this.renterId,
  });

  factory ReturnIndicator.fromJson(Map<String, dynamic> json) {
    return ReturnIndicator(
      id: json['id'] as String,
      itemId: json['item_id'] as String,
      rentalId: json['rental_id'] as String,
      expectedReturnDate:
          DateTime.parse(json['expected_return_date'] as String),
      actualReturnDate: json['actual_return_date'] != null
          ? DateTime.parse(json['actual_return_date'] as String)
          : null,
      returnStatus: json['return_status'] as String? ?? 'pending',
      bufferDays: json['buffer_days'] as int? ?? 0,
      reason: json['reason'] as String?,
      notes: json['notes'] as String?,
      rentalStartDate: json['rental_start_date'] != null
          ? DateTime.parse(json['rental_start_date'] as String)
          : null,
      rentalEndDate: json['rental_end_date'] != null
          ? DateTime.parse(json['rental_end_date'] as String)
          : null,
      rentalPrice: json['rental_price'] != null
          ? double.parse(json['rental_price'].toString())
          : null,
      renterId: json['renter_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_id': itemId,
      'rental_id': rentalId,
      'expected_return_date': expectedReturnDate.toIso8601String(),
      'actual_return_date': actualReturnDate?.toIso8601String(),
      'return_status': returnStatus,
      'buffer_days': bufferDays,
      'reason': reason,
      'notes': notes,
      'rental_start_date': rentalStartDate?.toIso8601String(),
      'rental_end_date': rentalEndDate?.toIso8601String(),
      'rental_price': rentalPrice,
      'renter_id': renterId,
    };
  }

  bool get isOverdue =>
      returnStatus == 'pending' && expectedReturnDate.isBefore(DateTime.now());

  bool get isCompleted => returnStatus == 'completed';

  bool get isExtended => returnStatus == 'extended';

  String get statusDisplayText {
    switch (returnStatus) {
      case 'pending':
        return isOverdue ? 'Overdue' : 'Pending Return';
      case 'overdue':
        return 'Overdue';
      case 'completed':
        return 'Returned';
      case 'extended':
        return 'Extended';
      default:
        return 'Unknown';
    }
  }

  ReturnIndicator copyWith({
    String? id,
    String? itemId,
    String? rentalId,
    DateTime? expectedReturnDate,
    DateTime? actualReturnDate,
    String? returnStatus,
    int? bufferDays,
    String? reason,
    String? notes,
    DateTime? rentalStartDate,
    DateTime? rentalEndDate,
    double? rentalPrice,
    String? renterId,
  }) {
    return ReturnIndicator(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      rentalId: rentalId ?? this.rentalId,
      expectedReturnDate: expectedReturnDate ?? this.expectedReturnDate,
      actualReturnDate: actualReturnDate ?? this.actualReturnDate,
      returnStatus: returnStatus ?? this.returnStatus,
      bufferDays: bufferDays ?? this.bufferDays,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      rentalStartDate: rentalStartDate ?? this.rentalStartDate,
      rentalEndDate: rentalEndDate ?? this.rentalEndDate,
      rentalPrice: rentalPrice ?? this.rentalPrice,
      renterId: renterId ?? this.renterId,
    );
  }
}
