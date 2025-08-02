import 'package:equatable/equatable.dart';

/// Advanced availability model supporting recurring patterns and flexible booking
class AvailabilityModel extends Equatable {
  final String id;
  final String itemId;
  final DateTime startDate;
  final DateTime endDate;
  final AvailabilityType type;
  final RecurrencePattern? recurrencePattern;
  final BookingPolicy bookingPolicy;
  final PricingTier? pricingTier;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? notes;

  const AvailabilityModel({
    required this.id,
    required this.itemId,
    required this.startDate,
    required this.endDate,
    required this.type,
    this.recurrencePattern,
    required this.bookingPolicy,
    this.pricingTier,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    this.notes,
  });

  factory AvailabilityModel.fromJson(Map<String, dynamic> json) {
    return AvailabilityModel(
      id: json['id'] as String,
      itemId: json['item_id'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      type: AvailabilityType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => AvailabilityType.available,
      ),
      recurrencePattern: json['recurrence_pattern'] != null
          ? RecurrencePattern.fromJson(
              json['recurrence_pattern'] as Map<String, dynamic>)
          : null,
      bookingPolicy: BookingPolicy.fromJson(
          json['booking_policy'] as Map<String, dynamic>),
      pricingTier: json['pricing_tier'] != null
          ? PricingTier.fromJson(json['pricing_tier'] as Map<String, dynamic>)
          : null,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_id': itemId,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'type': type.name,
      'recurrence_pattern': recurrencePattern?.toJson(),
      'booking_policy': bookingPolicy.toJson(),
      'pricing_tier': pricingTier?.toJson(),
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'notes': notes,
    };
  }

  bool isAvailableOn(DateTime date) {
    if (!isActive) return false;

    // Check if date falls within the availability window
    final dateOnly = DateTime(date.year, date.month, date.day);
    final startOnly = DateTime(startDate.year, startDate.month, startDate.day);
    final endOnly = DateTime(endDate.year, endDate.month, endDate.day);

    if (dateOnly.isBefore(startOnly) || dateOnly.isAfter(endOnly)) {
      return false;
    }

    // If it's a blackout period, return false
    if (type == AvailabilityType.blackout) {
      return false;
    }

    // Check recurrence pattern if exists
    if (recurrencePattern != null) {
      return recurrencePattern!.matchesDate(date);
    }

    // Default availability
    return type == AvailabilityType.available;
  }

  double? getPriceForDate(DateTime date, double basePrice) {
    if (!isAvailableOn(date)) return null;

    if (pricingTier != null) {
      return basePrice * pricingTier!.multiplier;
    }

    return basePrice;
  }

  @override
  List<Object?> get props => [
        id,
        itemId,
        startDate,
        endDate,
        type,
        recurrencePattern,
        bookingPolicy,
        pricingTier,
        isActive,
        createdAt,
        updatedAt,
        notes,
      ];
}

enum AvailabilityType {
  available,
  blackout,
  restricted,
  maintenance,
}

/// Recurrence pattern for recurring availability
class RecurrencePattern extends Equatable {
  final RecurrenceType type;
  final int interval; // Every N days/weeks/months
  final List<int>? daysOfWeek; // 1-7 (Monday-Sunday)
  final List<int>? daysOfMonth; // 1-31
  final List<int>? monthsOfYear; // 1-12
  final DateTime? endDate;
  final int? maxOccurrences;

  const RecurrencePattern({
    required this.type,
    this.interval = 1,
    this.daysOfWeek,
    this.daysOfMonth,
    this.monthsOfYear,
    this.endDate,
    this.maxOccurrences,
  });

  factory RecurrencePattern.fromJson(Map<String, dynamic> json) {
    return RecurrencePattern(
      type: RecurrenceType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => RecurrenceType.none,
      ),
      interval: json['interval'] as int? ?? 1,
      daysOfWeek: json['days_of_week'] != null
          ? List<int>.from(json['days_of_week'] as List)
          : null,
      daysOfMonth: json['days_of_month'] != null
          ? List<int>.from(json['days_of_month'] as List)
          : null,
      monthsOfYear: json['months_of_year'] != null
          ? List<int>.from(json['months_of_year'] as List)
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      maxOccurrences: json['max_occurrences'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'interval': interval,
      'days_of_week': daysOfWeek,
      'days_of_month': daysOfMonth,
      'months_of_year': monthsOfYear,
      'end_date': endDate?.toIso8601String(),
      'max_occurrences': maxOccurrences,
    };
  }

  bool matchesDate(DateTime date) {
    switch (type) {
      case RecurrenceType.none:
        return true;
      case RecurrenceType.daily:
        return _matchesDaily(date);
      case RecurrenceType.weekly:
        return _matchesWeekly(date);
      case RecurrenceType.monthly:
        return _matchesMonthly(date);
      case RecurrenceType.yearly:
        return _matchesYearly(date);
    }
  }

  bool _matchesDaily(DateTime date) {
    // Simple daily recurrence - every N days
    return true; // Simplified for demo
  }

  bool _matchesWeekly(DateTime date) {
    if (daysOfWeek == null) return true;
    return daysOfWeek!.contains(date.weekday);
  }

  bool _matchesMonthly(DateTime date) {
    if (daysOfMonth == null) return true;
    return daysOfMonth!.contains(date.day);
  }

  bool _matchesYearly(DateTime date) {
    if (monthsOfYear == null) return true;
    return monthsOfYear!.contains(date.month);
  }

  @override
  List<Object?> get props => [
        type,
        interval,
        daysOfWeek,
        daysOfMonth,
        monthsOfYear,
        endDate,
        maxOccurrences,
      ];
}

enum RecurrenceType {
  none,
  daily,
  weekly,
  monthly,
  yearly,
}

/// Booking policy for flexible booking options
class BookingPolicy extends Equatable {
  final bool instantBooking;
  final int? approvalTimeHours; // Hours to approve booking
  final int minAdvanceHours; // Minimum hours in advance
  final int maxAdvanceDays; // Maximum days in advance
  final CancellationPolicy cancellationPolicy;
  final ModificationPolicy modificationPolicy;
  final List<BookingRestriction> restrictions;

  const BookingPolicy({
    this.instantBooking = false,
    this.approvalTimeHours,
    this.minAdvanceHours = 24,
    this.maxAdvanceDays = 365,
    required this.cancellationPolicy,
    required this.modificationPolicy,
    this.restrictions = const [],
  });

  factory BookingPolicy.fromJson(Map<String, dynamic> json) {
    return BookingPolicy(
      instantBooking: json['instant_booking'] as bool? ?? false,
      approvalTimeHours: json['approval_time_hours'] as int?,
      minAdvanceHours: json['min_advance_hours'] as int? ?? 24,
      maxAdvanceDays: json['max_advance_days'] as int? ?? 365,
      cancellationPolicy: CancellationPolicy.fromJson(
        json['cancellation_policy'] as Map<String, dynamic>,
      ),
      modificationPolicy: ModificationPolicy.fromJson(
        json['modification_policy'] as Map<String, dynamic>,
      ),
      restrictions: json['restrictions'] != null
          ? (json['restrictions'] as List)
              .map(
                  (r) => BookingRestriction.fromJson(r as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'instant_booking': instantBooking,
      'approval_time_hours': approvalTimeHours,
      'min_advance_hours': minAdvanceHours,
      'max_advance_days': maxAdvanceDays,
      'cancellation_policy': cancellationPolicy.toJson(),
      'modification_policy': modificationPolicy.toJson(),
      'restrictions': restrictions.map((r) => r.toJson()).toList(),
    };
  }

  bool canBookAt(DateTime requestTime, DateTime bookingStart) {
    final hoursInAdvance = bookingStart.difference(requestTime).inHours;
    final daysInAdvance = bookingStart.difference(requestTime).inDays;

    if (hoursInAdvance < minAdvanceHours) return false;
    if (daysInAdvance > maxAdvanceDays) return false;

    // Check restrictions
    for (final restriction in restrictions) {
      if (!restriction.allows(requestTime, bookingStart)) {
        return false;
      }
    }

    return true;
  }

  @override
  List<Object?> get props => [
        instantBooking,
        approvalTimeHours,
        minAdvanceHours,
        maxAdvanceDays,
        cancellationPolicy,
        modificationPolicy,
        restrictions,
      ];
}

class CancellationPolicy extends Equatable {
  final bool allowCancellation;
  final int? freeHoursBefore; // Hours before start for free cancellation
  final double? penaltyPercentage; // Percentage penalty after free period
  final double? flatPenaltyFee; // Flat penalty fee

  const CancellationPolicy({
    this.allowCancellation = true,
    this.freeHoursBefore,
    this.penaltyPercentage,
    this.flatPenaltyFee,
  });

  factory CancellationPolicy.fromJson(Map<String, dynamic> json) {
    return CancellationPolicy(
      allowCancellation: json['allow_cancellation'] as bool? ?? true,
      freeHoursBefore: json['free_hours_before'] as int?,
      penaltyPercentage: json['penalty_percentage'] != null
          ? (json['penalty_percentage'] as num).toDouble()
          : null,
      flatPenaltyFee: json['flat_penalty_fee'] != null
          ? (json['flat_penalty_fee'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allow_cancellation': allowCancellation,
      'free_hours_before': freeHoursBefore,
      'penalty_percentage': penaltyPercentage,
      'flat_penalty_fee': flatPenaltyFee,
    };
  }

  @override
  List<Object?> get props => [
        allowCancellation,
        freeHoursBefore,
        penaltyPercentage,
        flatPenaltyFee,
      ];
}

class ModificationPolicy extends Equatable {
  final bool allowModification;
  final int? freeModificationHours;
  final double? modificationFee;

  const ModificationPolicy({
    this.allowModification = true,
    this.freeModificationHours,
    this.modificationFee,
  });

  factory ModificationPolicy.fromJson(Map<String, dynamic> json) {
    return ModificationPolicy(
      allowModification: json['allow_modification'] as bool? ?? true,
      freeModificationHours: json['free_modification_hours'] as int?,
      modificationFee: json['modification_fee'] != null
          ? (json['modification_fee'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allow_modification': allowModification,
      'free_modification_hours': freeModificationHours,
      'modification_fee': modificationFee,
    };
  }

  @override
  List<Object?> get props => [
        allowModification,
        freeModificationHours,
        modificationFee,
      ];
}

class BookingRestriction extends Equatable {
  final RestrictionType type;
  final Map<String, dynamic> parameters;

  const BookingRestriction({
    required this.type,
    required this.parameters,
  });

  factory BookingRestriction.fromJson(Map<String, dynamic> json) {
    return BookingRestriction(
      type: RestrictionType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => RestrictionType.none,
      ),
      parameters: json['parameters'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'parameters': parameters,
    };
  }

  bool allows(DateTime requestTime, DateTime bookingStart) {
    switch (type) {
      case RestrictionType.none:
        return true;
      case RestrictionType.noWeekends:
        return bookingStart.weekday < 6; // Monday = 1, Sunday = 7
      case RestrictionType.businessHoursOnly:
        final hour = bookingStart.hour;
        return hour >= 9 && hour <= 17; // 9 AM to 5 PM
      case RestrictionType.minimumDuration:
        // Would need end time to check this properly
        return true;
      case RestrictionType.maximumDuration:
        // Would need end time to check this properly
        return true;
    }
  }

  @override
  List<Object?> get props => [type, parameters];
}

enum RestrictionType {
  none,
  noWeekends,
  businessHoursOnly,
  minimumDuration,
  maximumDuration,
}

/// Pricing tier for dynamic pricing
class PricingTier extends Equatable {
  final String name;
  final double multiplier; // Multiplier for base price
  final String? description;
  final DateTime? validFrom;
  final DateTime? validUntil;

  const PricingTier({
    required this.name,
    required this.multiplier,
    this.description,
    this.validFrom,
    this.validUntil,
  });

  factory PricingTier.fromJson(Map<String, dynamic> json) {
    return PricingTier(
      name: json['name'] as String,
      multiplier: (json['multiplier'] as num).toDouble(),
      description: json['description'] as String?,
      validFrom: json['valid_from'] != null
          ? DateTime.parse(json['valid_from'] as String)
          : null,
      validUntil: json['valid_until'] != null
          ? DateTime.parse(json['valid_until'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'multiplier': multiplier,
      'description': description,
      'valid_from': validFrom?.toIso8601String(),
      'valid_until': validUntil?.toIso8601String(),
    };
  }

  bool isValidOn(DateTime date) {
    if (validFrom != null && date.isBefore(validFrom!)) return false;
    if (validUntil != null && date.isAfter(validUntil!)) return false;
    return true;
  }

  @override
  List<Object?> get props => [
        name,
        multiplier,
        description,
        validFrom,
        validUntil,
      ];
}

/// Predefined pricing tiers
class PricingTiers {
  static const standard = PricingTier(
    name: 'Standard',
    multiplier: 1.0,
    description: 'Regular pricing',
  );

  static const peak = PricingTier(
    name: 'Peak',
    multiplier: 1.5,
    description: 'High demand periods',
  );

  static const weekend = PricingTier(
    name: 'Weekend',
    multiplier: 1.25,
    description: 'Weekend premium',
  );

  static const holiday = PricingTier(
    name: 'Holiday',
    multiplier: 2.0,
    description: 'Holiday premium',
  );

  static const discount = PricingTier(
    name: 'Discount',
    multiplier: 0.8,
    description: 'Promotional pricing',
  );
}
