import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rent_ease/features/rental/data/models/booking_model.dart';
import 'package:rent_ease/features/rental/data/models/rental_booking_model.dart';
import 'package:rent_ease/features/rental/data/repositories/booking_repository.dart';
import 'package:rent_ease/core/services/notification_service.dart';
import 'package:rent_ease/core/services/supabase_service.dart';

// Events
abstract class BookingEvent extends Equatable {
  const BookingEvent();

  @override
  List<Object?> get props => [];
}

class CreateBooking extends BookingEvent {
  final String itemId;
  final String renterId;
  final DateTime startDate;
  final DateTime endDate;
  final double totalAmount;
  final String? notes;

  const CreateBooking({
    required this.itemId,
    required this.renterId,
    required this.startDate,
    required this.endDate,
    required this.totalAmount,
    this.notes,
  });

  @override
  List<Object?> get props => [
        itemId,
        renterId,
        startDate,
        endDate,
        totalAmount,
        notes,
      ];
}

class LoadUserBookings extends BookingEvent {
  final String userId;

  const LoadUserBookings(this.userId);

  @override
  List<Object?> get props => [userId];
}

class UpdateBookingStatus extends BookingEvent {
  final String bookingId;
  final String status;

  const UpdateBookingStatus({
    required this.bookingId,
    required this.status,
  });

  @override
  List<Object?> get props => [bookingId, status];
}

// States
abstract class BookingState extends Equatable {
  const BookingState();

  @override
  List<Object?> get props => [];
}

class BookingInitial extends BookingState {}

class BookingLoading extends BookingState {}

class BookingSuccess extends BookingState {
  final BookingModel booking;

  const BookingSuccess(this.booking);

  @override
  List<Object?> get props => [booking];
}

class BookingsLoaded extends BookingState {
  final List<RentalBookingModel> bookings;

  const BookingsLoaded(this.bookings);

  @override
  List<Object?> get props => [bookings];
}

class BookingError extends BookingState {
  final String message;

  const BookingError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final BookingRepository _bookingRepository;

  BookingBloc({BookingRepository? bookingRepository})
      : _bookingRepository = bookingRepository ?? BookingRepository(),
        super(BookingInitial()) {
    on<CreateBooking>(_onCreateBooking);
    on<LoadUserBookings>(_onLoadUserBookings);
    on<UpdateBookingStatus>(_onUpdateBookingStatus);
  }

  Future<void> _onCreateBooking(
    CreateBooking event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingLoading());

    try {
      // Get item details for security deposit
      final itemResponse = await SupabaseService.client
          .from('items')
          .select('security_deposit, name')
          .eq('id', event.itemId)
          .single();

      final securityDeposit =
          (itemResponse['security_deposit'] as num?)?.toDouble() ?? 0.0;
      final itemName = itemResponse['name'] as String;

      // Create booking using repository
      final booking = await _bookingRepository.createBooking(
        itemId: event.itemId,
        renterId: event.renterId,
        startDate: event.startDate,
        endDate: event.endDate,
        totalAmount: event.totalAmount,
        securityDeposit: securityDeposit,
      );

      // Send booking confirmation notification
      await NotificationService.showBookingNotification(
        bookingId: booking.id,
        title: 'Booking Confirmed!',
        message:
            'Your booking for $itemName has been confirmed and is pending approval.',
        type: BookingNotificationType.bookingConfirmed,
      );

      // Schedule reminder notification (1 hour before start)
      final reminderTime = booking.startDate.subtract(const Duration(hours: 1));
      if (reminderTime.isAfter(DateTime.now())) {
        await NotificationService.scheduleBookingReminder(
          bookingId: booking.id,
          itemName: itemName,
          reminderTime: reminderTime,
        );
      }

      emit(BookingSuccess(booking));
    } catch (e) {
      emit(BookingError('Failed to create booking: ${e.toString()}'));
    }
  }

  Future<void> _onLoadUserBookings(
    LoadUserBookings event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingLoading());

    try {
      // Load user's bookings from database
      final bookings = await _bookingRepository.getUserBookings(event.userId);
      debugPrint(
          '🎯 BookingBloc: Loaded ${bookings.length} rentals for user ${event.userId}');
      for (var booking in bookings) {
        debugPrint(
            '📋 Rental: ${booking.displayItemName} - Status: ${booking.status}');
      }
      emit(BookingsLoaded(bookings));
    } catch (e) {
      emit(BookingError('Failed to load bookings: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateBookingStatus(
    UpdateBookingStatus event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingLoading());

    try {
      // Update booking status in database
      await _bookingRepository.updateBookingStatus(
          event.bookingId, event.status);

      // Emit success and reload bookings if needed
      emit(BookingInitial());
    } catch (e) {
      emit(BookingError('Failed to update booking: ${e.toString()}'));
    }
  }
}
