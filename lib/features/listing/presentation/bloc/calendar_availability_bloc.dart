import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rent_ease/core/services/availability_service.dart';
import 'package:rent_ease/features/booking/data/models/booking_model.dart';
import 'package:rent_ease/features/booking/data/models/return_indicator_model.dart';

// Events
abstract class CalendarAvailabilityEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadCalendarAvailability extends CalendarAvailabilityEvent {
  final String listingId;
  final DateTime month;

  LoadCalendarAvailability({
    required this.listingId,
    required this.month,
  });

  @override
  List<Object?> get props => [listingId, month];
}

class BlockDate extends CalendarAvailabilityEvent {
  final String listingId;
  final DateTime date;
  final String reason;

  BlockDate({
    required this.listingId,
    required this.date,
    this.reason = 'Manually blocked for maintenance',
  });

  @override
  List<Object?> get props => [listingId, date, reason];
}

class UnblockDate extends CalendarAvailabilityEvent {
  final String listingId;
  final DateTime date;

  UnblockDate({
    required this.listingId,
    required this.date,
  });

  @override
  List<Object?> get props => [listingId, date];
}

class RefreshAvailability extends CalendarAvailabilityEvent {
  final String listingId;
  final DateTime month;

  RefreshAvailability({
    required this.listingId,
    required this.month,
  });

  @override
  List<Object?> get props => [listingId, month];
}

// States
abstract class CalendarAvailabilityState extends Equatable {
  @override
  List<Object?> get props => [];
}

class CalendarAvailabilityInitial extends CalendarAvailabilityState {}

class CalendarAvailabilityLoading extends CalendarAvailabilityState {}

class CalendarAvailabilityLoaded extends CalendarAvailabilityState {
  final Map<DateTime, ItemAvailability> availabilityMap;
  final String currentListingId;
  final DateTime currentMonth;

  CalendarAvailabilityLoaded({
    required this.availabilityMap,
    required this.currentListingId,
    required this.currentMonth,
  });

  @override
  List<Object?> get props => [availabilityMap, currentListingId, currentMonth];

  CalendarAvailabilityLoaded copyWith({
    Map<DateTime, ItemAvailability>? availabilityMap,
    String? currentListingId,
    DateTime? currentMonth,
  }) {
    return CalendarAvailabilityLoaded(
      availabilityMap: availabilityMap ?? this.availabilityMap,
      currentListingId: currentListingId ?? this.currentListingId,
      currentMonth: currentMonth ?? this.currentMonth,
    );
  }
}

class CalendarAvailabilityError extends CalendarAvailabilityState {
  final String message;
  final String? listingId;
  final DateTime? month;

  CalendarAvailabilityError({
    required this.message,
    this.listingId,
    this.month,
  });

  @override
  List<Object?> get props => [message, listingId, month];
}

class CalendarAvailabilityActionSuccess extends CalendarAvailabilityState {
  final String message;
  final Map<DateTime, ItemAvailability> availabilityMap;
  final String currentListingId;
  final DateTime currentMonth;

  CalendarAvailabilityActionSuccess({
    required this.message,
    required this.availabilityMap,
    required this.currentListingId,
    required this.currentMonth,
  });

  @override
  List<Object?> get props =>
      [message, availabilityMap, currentListingId, currentMonth];
}

// Enhanced data models
class ItemAvailability extends Equatable {
  final int totalQuantity;
  final int availableQuantity;
  final int bookedQuantity;
  final int blockedQuantity;
  final List<BookingModel> bookings;
  final List<AvailabilityBlock> blocks;
  final List<ReturnIndicator> returnIndicators; // Lender-only return tracking

  const ItemAvailability({
    required this.totalQuantity,
    required this.availableQuantity,
    required this.bookedQuantity,
    required this.blockedQuantity,
    required this.bookings,
    required this.blocks,
    this.returnIndicators = const [],
  });

  bool get isFullyAvailable => availableQuantity == totalQuantity;
  bool get isPartiallyAvailable =>
      availableQuantity > 0 && availableQuantity < totalQuantity;
  bool get isFullyBooked => availableQuantity == 0 && blockedQuantity == 0;
  bool get isBlocked => blockedQuantity > 0 || blocks.isNotEmpty;
  bool get isFullyBlocked => blockedQuantity == totalQuantity;
  bool get hasReturnIndicators => returnIndicators.isNotEmpty;
  bool get hasOverdueReturns => returnIndicators.any((r) => r.isOverdue);

  @override
  List<Object?> get props => [
        totalQuantity,
        availableQuantity,
        bookedQuantity,
        blockedQuantity,
        bookings,
        blocks,
        returnIndicators,
      ];
}

class AvailabilityBlock extends Equatable {
  final String id;
  final String itemId;
  final String? rentalId;
  final DateTime blockedFrom;
  final DateTime blockedUntil;
  final String blockType;
  final String? reason;
  final int quantityBlocked;

  const AvailabilityBlock({
    required this.id,
    required this.itemId,
    this.rentalId,
    required this.blockedFrom,
    required this.blockedUntil,
    required this.blockType,
    this.reason,
    required this.quantityBlocked,
  });

  @override
  List<Object?> get props => [
        id,
        itemId,
        rentalId,
        blockedFrom,
        blockedUntil,
        blockType,
        reason,
        quantityBlocked,
      ];
}

// BLoC implementation
class CalendarAvailabilityBloc
    extends Bloc<CalendarAvailabilityEvent, CalendarAvailabilityState> {
  final Map<String, Map<DateTime, ItemAvailability>> _cache = {};

  CalendarAvailabilityBloc() : super(CalendarAvailabilityInitial()) {
    on<LoadCalendarAvailability>(_onLoadCalendarAvailability);
    on<BlockDate>(_onBlockDate);
    on<UnblockDate>(_onUnblockDate);
    on<RefreshAvailability>(_onRefreshAvailability);
  }

  String _getCacheKey(String listingId, DateTime month) {
    return '${listingId}_${month.year}_${month.month}';
  }

  Future<void> _onLoadCalendarAvailability(
    LoadCalendarAvailability event,
    Emitter<CalendarAvailabilityState> emit,
  ) async {
    emit(CalendarAvailabilityLoading());

    try {
      final cacheKey = _getCacheKey(event.listingId, event.month);

      // Check cache first
      if (_cache.containsKey(cacheKey)) {
        emit(CalendarAvailabilityLoaded(
          availabilityMap: _cache[cacheKey]!,
          currentListingId: event.listingId,
          currentMonth: event.month,
        ));
        return;
      }

      // Load from service
      final availabilityMap = await _loadAvailabilityForMonth(
        event.listingId,
        event.month,
      );

      // Cache the result
      _cache[cacheKey] = availabilityMap;

      emit(CalendarAvailabilityLoaded(
        availabilityMap: availabilityMap,
        currentListingId: event.listingId,
        currentMonth: event.month,
      ));
    } catch (e) {
      emit(CalendarAvailabilityError(
        message: 'Failed to load availability: $e',
        listingId: event.listingId,
        month: event.month,
      ));
    }
  }

  Future<void> _onBlockDate(
    BlockDate event,
    Emitter<CalendarAvailabilityState> emit,
  ) async {
    try {
      final startDate =
          DateTime(event.date.year, event.date.month, event.date.day);
      final endDate = startDate.add(const Duration(hours: 23, minutes: 59));

      await AvailabilityService.createManualBlock(
        itemId: event.listingId,
        startDate: startDate,
        endDate: endDate,
        reason: event.reason,
        quantityToBlock: 1,
      );

      // Invalidate cache and reload
      final month = DateTime(event.date.year, event.date.month);
      final cacheKey = _getCacheKey(event.listingId, month);
      _cache.remove(cacheKey);

      // Reload current month
      add(RefreshAvailability(
        listingId: event.listingId,
        month: month,
      ));
    } catch (e) {
      emit(CalendarAvailabilityError(
        message: 'Failed to block date: $e',
        listingId: event.listingId,
        month: DateTime(event.date.year, event.date.month),
      ));
    }
  }

  Future<void> _onUnblockDate(
    UnblockDate event,
    Emitter<CalendarAvailabilityState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is! CalendarAvailabilityLoaded) return;

      final dateKey =
          DateTime(event.date.year, event.date.month, event.date.day);
      final availability = currentState.availabilityMap[dateKey];

      if (availability != null && availability.blocks.isNotEmpty) {
        // Remove all manual blocks for this date
        for (final block in availability.blocks) {
          if (block.blockType == 'manual') {
            await AvailabilityService.removeManualBlock(blockId: block.id);
          }
        }

        // Invalidate cache and reload
        final month = DateTime(event.date.year, event.date.month);
        final cacheKey = _getCacheKey(event.listingId, month);
        _cache.remove(cacheKey);

        add(RefreshAvailability(
          listingId: event.listingId,
          month: month,
        ));
      } else {
        emit(CalendarAvailabilityError(
          message: 'No manual blocks found on this date',
          listingId: event.listingId,
          month: DateTime(event.date.year, event.date.month),
        ));
      }
    } catch (e) {
      emit(CalendarAvailabilityError(
        message: 'Failed to unblock date: $e',
        listingId: event.listingId,
        month: DateTime(event.date.year, event.date.month),
      ));
    }
  }

  Future<void> _onRefreshAvailability(
    RefreshAvailability event,
    Emitter<CalendarAvailabilityState> emit,
  ) async {
    try {
      // Force reload by removing from cache
      final cacheKey = _getCacheKey(event.listingId, event.month);
      _cache.remove(cacheKey);

      final availabilityMap = await _loadAvailabilityForMonth(
        event.listingId,
        event.month,
      );

      _cache[cacheKey] = availabilityMap;

      emit(CalendarAvailabilityLoaded(
        availabilityMap: availabilityMap,
        currentListingId: event.listingId,
        currentMonth: event.month,
      ));
    } catch (e) {
      emit(CalendarAvailabilityError(
        message: 'Failed to refresh availability: $e',
        listingId: event.listingId,
        month: event.month,
      ));
    }
  }

  Future<Map<DateTime, ItemAvailability>> _loadAvailabilityForMonth(
    String listingId,
    DateTime month,
  ) async {
    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 0);

    final availabilityData = await AvailabilityService.getItemAvailabilityRange(
      itemId: listingId,
      startDate: startDate,
      endDate: endDate,
    );

    final Map<DateTime, ItemAvailability> monthAvailability = {};

    availabilityData.forEach((date, data) {
      final bookings = _parseBookings(data['bookings']);
      final blocks = _parseBlocks(data['blocks']);

      final totalQuantity = (data['total_quantity'] as int?) ?? 1;
      final bookedQuantity = bookings.length;
      final blockedQuantity =
          blocks.fold<int>(0, (sum, block) => sum + block.quantityBlocked);

      monthAvailability[date] = ItemAvailability(
        totalQuantity: totalQuantity,
        availableQuantity: totalQuantity - bookedQuantity - blockedQuantity,
        bookedQuantity: bookedQuantity,
        blockedQuantity: blockedQuantity,
        bookings: bookings,
        blocks: blocks,
      );
    });

    return monthAvailability;
  }

  List<BookingModel> _parseBookings(dynamic bookingsData) {
    if (bookingsData == null) return [];

    try {
      return (bookingsData as List<dynamic>)
          .map((bookingData) {
            try {
              return BookingModel.fromJson(bookingData as Map<String, dynamic>);
            } catch (e) {
              return null;
            }
          })
          .where((booking) => booking != null)
          .cast<BookingModel>()
          .toList();
    } catch (e) {
      return [];
    }
  }

  List<AvailabilityBlock> _parseBlocks(dynamic blocksData) {
    if (blocksData == null) return [];

    try {
      return (blocksData as List<dynamic>)
          .map((blockData) {
            try {
              // Handle different date formats
              DateTime parseDateTime(dynamic dateValue) {
                if (dateValue is DateTime) return dateValue;
                if (dateValue is String) return DateTime.parse(dateValue);
                throw FormatException('Invalid date format: $dateValue');
              }

              return AvailabilityBlock(
                id: blockData['id']?.toString() ?? '',
                itemId: blockData['item_id']?.toString() ?? '',
                rentalId: blockData['rental_id']?.toString(),
                blockedFrom: parseDateTime(blockData['blocked_from']),
                blockedUntil: parseDateTime(blockData['blocked_until']),
                blockType: blockData['block_type']?.toString() ?? 'manual',
                reason: blockData['reason']?.toString(),
                quantityBlocked: (blockData['quantity_blocked'] as int?) ?? 1,
              );
            } catch (e) {
              print('Error parsing block data: $e');
              print('Block data: $blockData');
              return null;
            }
          })
          .where((block) => block != null)
          .cast<AvailabilityBlock>()
          .toList();
    } catch (e) {
      print('Error parsing blocks array: $e');
      return [];
    }
  }

  void clearCache() {
    _cache.clear();
  }

  void clearCacheForListing(String listingId) {
    _cache.removeWhere((key, _) => key.startsWith(listingId));
  }
}
