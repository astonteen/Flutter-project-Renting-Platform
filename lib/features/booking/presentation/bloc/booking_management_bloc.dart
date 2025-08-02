import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rent_ease/features/booking/data/models/booking_model.dart';
import 'package:rent_ease/features/booking/data/repositories/booking_repository.dart';
import 'package:rent_ease/core/services/notification_service.dart';

// Filter categories for booking management
enum BookingFilterCategory {
  all,
  active, // Pending + Confirmed + In Progress
  past, // Completed + Cancelled
}

// Events
abstract class BookingManagementEvent extends Equatable {
  const BookingManagementEvent();

  @override
  List<Object?> get props => [];
}

class LoadBookingsForListing extends BookingManagementEvent {
  final String listingId;

  const LoadBookingsForListing(this.listingId);

  @override
  List<Object?> get props => [listingId];
}

class RefreshBookings extends BookingManagementEvent {
  final String listingId;

  const RefreshBookings(this.listingId);

  @override
  List<Object?> get props => [listingId];
}

class UpdateBookingStatus extends BookingManagementEvent {
  final String bookingId;
  final BookingStatus status;

  const UpdateBookingStatus(this.bookingId, this.status);

  @override
  List<Object?> get props => [bookingId, status];
}

class MarkItemReady extends BookingManagementEvent {
  final String bookingId;
  final bool isReady;

  const MarkItemReady(this.bookingId, this.isReady);

  @override
  List<Object?> get props => [bookingId, isReady];
}

class AddBookingNotes extends BookingManagementEvent {
  final String bookingId;
  final String notes;

  const AddBookingNotes(this.bookingId, this.notes);

  @override
  List<Object?> get props => [bookingId, notes];
}

class FilterBookings extends BookingManagementEvent {
  final BookingFilterCategory? category;
  final String? searchQuery;

  const FilterBookings({this.category, this.searchQuery});

  @override
  List<Object?> get props => [category, searchQuery];
}

// States
abstract class BookingManagementState extends Equatable {
  const BookingManagementState();

  @override
  List<Object?> get props => [];
}

class BookingManagementInitial extends BookingManagementState {}

class BookingManagementLoading extends BookingManagementState {}

class BookingManagementLoaded extends BookingManagementState {
  final List<BookingModel> bookings;
  final List<BookingModel> filteredBookings;
  final Map<String, dynamic> statistics;
  final BookingFilterCategory? currentFilter;
  final String? searchQuery;

  const BookingManagementLoaded({
    required this.bookings,
    required this.filteredBookings,
    required this.statistics,
    this.currentFilter,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [
        bookings,
        filteredBookings,
        statistics,
        currentFilter,
        searchQuery,
      ];

  BookingManagementLoaded copyWith({
    List<BookingModel>? bookings,
    List<BookingModel>? filteredBookings,
    Map<String, dynamic>? statistics,
    BookingFilterCategory? currentFilter,
    String? searchQuery,
  }) {
    return BookingManagementLoaded(
      bookings: bookings ?? this.bookings,
      filteredBookings: filteredBookings ?? this.filteredBookings,
      statistics: statistics ?? this.statistics,
      currentFilter: currentFilter ?? this.currentFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class BookingManagementError extends BookingManagementState {
  final String message;

  const BookingManagementError(this.message);

  @override
  List<Object?> get props => [message];
}

class BookingActionSuccess extends BookingManagementState {
  final String message;

  const BookingActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class BookingManagementBloc
    extends Bloc<BookingManagementEvent, BookingManagementState> {
  final BookingRepository _repository;

  BookingManagementBloc({
    required BookingRepository repository,
  })  : _repository = repository,
        super(BookingManagementInitial()) {
    on<LoadBookingsForListing>(_onLoadBookingsForListing);
    on<RefreshBookings>(_onRefreshBookings);
    on<UpdateBookingStatus>(_onUpdateBookingStatus);
    on<MarkItemReady>(_onMarkItemReady);
    on<AddBookingNotes>(_onAddBookingNotes);
    on<FilterBookings>(_onFilterBookings);
  }

  Future<void> _onLoadBookingsForListing(
    LoadBookingsForListing event,
    Emitter<BookingManagementState> emit,
  ) async {
    emit(BookingManagementLoading());

    try {
      final bookings = await _repository.getBookingsForListing(event.listingId);
      final statistics =
          await _repository.getBookingStatistics(event.listingId);

      emit(BookingManagementLoaded(
        bookings: bookings,
        filteredBookings: bookings,
        statistics: statistics,
      ));
    } catch (e) {
      emit(BookingManagementError('Failed to load bookings: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshBookings(
    RefreshBookings event,
    Emitter<BookingManagementState> emit,
  ) async {
    if (state is BookingManagementLoaded) {
      try {
        final bookings =
            await _repository.getBookingsForListing(event.listingId);
        final statistics =
            await _repository.getBookingStatistics(event.listingId);
        final currentState = state as BookingManagementLoaded;

        final filteredBookings = _applyFilters(
          bookings,
          currentState.currentFilter,
          currentState.searchQuery,
        );

        emit(currentState.copyWith(
          bookings: bookings,
          filteredBookings: filteredBookings,
          statistics: statistics,
        ));
      } catch (e) {
        emit(BookingManagementError(
            'Failed to refresh bookings: ${e.toString()}'));
      }
    }
  }

  Future<void> _onUpdateBookingStatus(
    UpdateBookingStatus event,
    Emitter<BookingManagementState> emit,
  ) async {
    if (state is BookingManagementLoaded) {
      try {
        await _repository.updateBookingStatus(event.bookingId, event.status);

        // Update local state
        final currentState = state as BookingManagementLoaded;
        final updatedBookings = currentState.bookings.map((booking) {
          if (booking.id == event.bookingId) {
            return booking.copyWith(
              status: event.status,
              updatedAt: DateTime.now(),
            );
          }
          return booking;
        }).toList();

        final filteredBookings = _applyFilters(
          updatedBookings,
          currentState.currentFilter,
          currentState.searchQuery,
        );

        emit(currentState.copyWith(
          bookings: updatedBookings,
          filteredBookings: filteredBookings,
        ));

        emit(const BookingActionSuccess('Booking status updated successfully'));
      } catch (e) {
        emit(BookingManagementError(
            'Failed to update booking status: ${e.toString()}'));
      }
    }
  }

  Future<void> _onMarkItemReady(
    MarkItemReady event,
    Emitter<BookingManagementState> emit,
  ) async {
    if (state is BookingManagementLoaded) {
      try {
        await _repository.markItemReady(event.bookingId,
            isReady: event.isReady);

        // Update local state
        final currentState = state as BookingManagementLoaded;
        final updatedBookings = currentState.bookings.map((booking) {
          if (booking.id == event.bookingId) {
            return booking.copyWith(
              isItemReady: event.isReady,
              updatedAt: DateTime.now(),
            );
          }
          return booking;
        }).toList();

        // Find the updated booking for notification
        final updatedBooking = updatedBookings.firstWhere(
          (booking) => booking.id == event.bookingId,
        );

        // Send notification to renter when item is marked ready (not when unmarked)
        if (event.isReady) {
          await NotificationService.showItemReadyNotification(
            bookingId: updatedBooking.id,
            itemName: updatedBooking.listingName,
            renterName: updatedBooking.renterName,
            renterId: updatedBooking.renterId,
          );
        }

        final filteredBookings = _applyFilters(
          updatedBookings,
          currentState.currentFilter,
          currentState.searchQuery,
        );

        emit(currentState.copyWith(
          bookings: updatedBookings,
          filteredBookings: filteredBookings,
        ));

        emit(BookingActionSuccess(
          event.isReady ? 'Item marked as ready' : 'Item marked as not ready',
        ));
      } catch (e) {
        emit(BookingManagementError(
            'Failed to update item readiness: ${e.toString()}'));
      }
    }
  }

  Future<void> _onAddBookingNotes(
    AddBookingNotes event,
    Emitter<BookingManagementState> emit,
  ) async {
    if (state is BookingManagementLoaded) {
      try {
        await _repository.addNotes(event.bookingId, event.notes);

        // Update local state
        final currentState = state as BookingManagementLoaded;
        final updatedBookings = currentState.bookings.map((booking) {
          if (booking.id == event.bookingId) {
            return booking.copyWith(
              notes: event.notes,
              updatedAt: DateTime.now(),
            );
          }
          return booking;
        }).toList();

        final filteredBookings = _applyFilters(
          updatedBookings,
          currentState.currentFilter,
          currentState.searchQuery,
        );

        emit(currentState.copyWith(
          bookings: updatedBookings,
          filteredBookings: filteredBookings,
        ));

        emit(const BookingActionSuccess('Notes added successfully'));
      } catch (e) {
        emit(BookingManagementError('Failed to add notes: ${e.toString()}'));
      }
    }
  }

  void _onFilterBookings(
    FilterBookings event,
    Emitter<BookingManagementState> emit,
  ) {
    if (state is BookingManagementLoaded) {
      final currentState = state as BookingManagementLoaded;

      final filteredBookings = _applyFilters(
        currentState.bookings,
        event.category,
        event.searchQuery,
      );

      emit(currentState.copyWith(
        filteredBookings: filteredBookings,
        currentFilter: event.category,
        searchQuery: event.searchQuery,
      ));
    }
  }

  List<BookingModel> _applyFilters(
    List<BookingModel> bookings,
    BookingFilterCategory? categoryFilter,
    String? searchQuery,
  ) {
    var filtered = bookings;

    // Apply category filter
    if (categoryFilter != null) {
      if (categoryFilter == BookingFilterCategory.active) {
        // "Active" tab: Pending + Confirmed + In Progress
        filtered = filtered
            .where((booking) =>
                booking.status == BookingStatus.pending ||
                booking.status == BookingStatus.confirmed ||
                booking.status == BookingStatus.inProgress)
            .toList();
      } else if (categoryFilter == BookingFilterCategory.past) {
        // "Past" tab: Completed + Cancelled
        filtered = filtered
            .where((booking) =>
                booking.status == BookingStatus.completed ||
                booking.status == BookingStatus.cancelled)
            .toList();
      } else {
        // "All" tab or no filter
        filtered = bookings; // No filter applied
      }
    }

    // Apply search filter
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((booking) {
        return booking.renterName.toLowerCase().contains(query) ||
            booking.renterEmail.toLowerCase().contains(query) ||
            booking.specialRequests?.toLowerCase().contains(query) == true ||
            booking.notes?.toLowerCase().contains(query) == true;
      }).toList();
    }

    return filtered;
  }

  // Helper methods for UI
  List<BookingModel> get upcomingBookings {
    if (state is BookingManagementLoaded) {
      final currentState = state as BookingManagementLoaded;
      return currentState.bookings
          .where((booking) => booking.isUpcoming)
          .toList();
    }
    return [];
  }

  List<BookingModel> get activeBookings {
    if (state is BookingManagementLoaded) {
      final currentState = state as BookingManagementLoaded;
      return currentState.bookings
          .where((booking) => booking.isActive)
          .toList();
    }
    return [];
  }

  List<BookingModel> get pendingBookings {
    if (state is BookingManagementLoaded) {
      final currentState = state as BookingManagementLoaded;
      return currentState.bookings
          .where((booking) => booking.status == BookingStatus.pending)
          .toList();
    }
    return [];
  }

  BookingModel? get nextUpcomingBooking {
    final upcoming = upcomingBookings;
    if (upcoming.isEmpty) return null;

    upcoming.sort((a, b) => a.startDate.compareTo(b.startDate));
    return upcoming.first;
  }
}
