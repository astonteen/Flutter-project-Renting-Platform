import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rent_ease/features/home/data/repositories/lender_repository.dart';
import 'package:rent_ease/features/booking/data/models/booking_model.dart';

// Events
abstract class LenderEvent extends Equatable {
  const LenderEvent();

  @override
  List<Object?> get props => [];
}

class LoadLenderDashboard extends LenderEvent {
  const LoadLenderDashboard();
}

class LoadBookingsForDate extends LenderEvent {
  final DateTime date;

  const LoadBookingsForDate(this.date);

  @override
  List<Object?> get props => [date];
}

class LoadRecentBookings extends LenderEvent {
  const LoadRecentBookings();
}

class LoadEarningsData extends LenderEvent {
  final DateTime startDate;
  final DateTime endDate;

  const LoadEarningsData({
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [startDate, endDate];
}

class RefreshLenderData extends LenderEvent {
  const RefreshLenderData();
}

class LoadAllBookings extends LenderEvent {
  const LoadAllBookings();
}

class LoadBookingDetails extends LenderEvent {
  final String bookingId;

  const LoadBookingDetails(this.bookingId);

  @override
  List<Object?> get props => [bookingId];
}

class LoadUpcomingHandoffs extends LenderEvent {
  const LoadUpcomingHandoffs();
}

class LoadUpcomingReturns extends LenderEvent {
  const LoadUpcomingReturns();
}

class UpdateBookingStatus extends LenderEvent {
  final String bookingId;
  final BookingStatus status;

  const UpdateBookingStatus({
    required this.bookingId,
    required this.status,
  });

  @override
  List<Object?> get props => [bookingId, status];
}

// States
abstract class LenderState extends Equatable {
  const LenderState();

  @override
  List<Object?> get props => [];
}

class LenderInitial extends LenderState {
  const LenderInitial();
}

class LenderLoading extends LenderState {
  const LenderLoading();
}

class LenderDashboardLoaded extends LenderState {
  final Map<String, dynamic> dashboardStats;
  final List<BookingModel> recentBookings;

  const LenderDashboardLoaded({
    required this.dashboardStats,
    required this.recentBookings,
  });

  @override
  List<Object?> get props => [dashboardStats, recentBookings];
}

class BookingsForDateLoaded extends LenderState {
  final DateTime date;
  final List<BookingModel> bookings;

  const BookingsForDateLoaded({
    required this.date,
    required this.bookings,
  });

  @override
  List<Object?> get props => [date, bookings];
}

class EarningsDataLoaded extends LenderState {
  final List<Map<String, dynamic>> earningsData;
  final DateTime startDate;
  final DateTime endDate;

  const EarningsDataLoaded({
    required this.earningsData,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [earningsData, startDate, endDate];
}

class AllBookingsLoaded extends LenderState {
  final List<BookingModel> bookings;

  const AllBookingsLoaded({required this.bookings});

  @override
  List<Object?> get props => [bookings];
}

class BookingDetailsLoaded extends LenderState {
  final BookingModel booking;

  const BookingDetailsLoaded({required this.booking});

  @override
  List<Object?> get props => [booking];
}

class UpcomingHandoffsLoaded extends LenderState {
  final List<BookingModel> handoffs;

  const UpcomingHandoffsLoaded({required this.handoffs});

  @override
  List<Object?> get props => [handoffs];
}

class UpcomingReturnsLoaded extends LenderState {
  final List<BookingModel> returns;

  const UpcomingReturnsLoaded({required this.returns});

  @override
  List<Object?> get props => [returns];
}

class BookingStatusUpdated extends LenderState {
  final BookingModel booking;

  const BookingStatusUpdated({required this.booking});

  @override
  List<Object?> get props => [booking];
}

class LenderError extends LenderState {
  final String message;

  const LenderError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class LenderBloc extends Bloc<LenderEvent, LenderState> {
  final LenderRepository _lenderRepository;

  LenderBloc({
    required LenderRepository lenderRepository,
  })  : _lenderRepository = lenderRepository,
        super(const LenderInitial()) {
    on<LoadLenderDashboard>(_onLoadLenderDashboard);
    on<LoadBookingsForDate>(_onLoadBookingsForDate);
    on<LoadRecentBookings>(_onLoadRecentBookings);
    on<LoadEarningsData>(_onLoadEarningsData);
    on<RefreshLenderData>(_onRefreshLenderData);
    on<LoadAllBookings>(_onLoadAllBookings);
    on<LoadBookingDetails>(_onLoadBookingDetails);
    on<LoadUpcomingHandoffs>(_onLoadUpcomingHandoffs);
    on<LoadUpcomingReturns>(_onLoadUpcomingReturns);
    on<UpdateBookingStatus>(_onUpdateBookingStatus);
  }

  Future<void> _onLoadLenderDashboard(
    LoadLenderDashboard event,
    Emitter<LenderState> emit,
  ) async {
    try {
      emit(const LenderLoading());

      // Load dashboard stats and recent bookings in parallel
      final results = await Future.wait([
        _lenderRepository.getLenderDashboardStats(),
        _lenderRepository.getRecentBookings(limit: 5),
      ]);

      final dashboardStats = results[0] as Map<String, dynamic>;
      final recentBookings = results[1] as List<BookingModel>;

      emit(LenderDashboardLoaded(
        dashboardStats: dashboardStats,
        recentBookings: recentBookings,
      ));
    } catch (e) {
      emit(LenderError('Failed to load lender dashboard: ${e.toString()}'));
    }
  }

  Future<void> _onLoadBookingsForDate(
    LoadBookingsForDate event,
    Emitter<LenderState> emit,
  ) async {
    try {
      emit(const LenderLoading());

      final bookings = await _lenderRepository.getBookingsForDate(event.date);

      emit(BookingsForDateLoaded(
        date: event.date,
        bookings: bookings,
      ));
    } catch (e) {
      emit(LenderError('Failed to load bookings for date: ${e.toString()}'));
    }
  }

  Future<void> _onLoadRecentBookings(
    LoadRecentBookings event,
    Emitter<LenderState> emit,
  ) async {
    try {
      emit(const LenderLoading());

      final bookings = await _lenderRepository.getRecentBookings();

      // For now, we'll emit this as dashboard loaded with empty stats
      // In a real app, you might want a separate state for just recent bookings
      emit(LenderDashboardLoaded(
        dashboardStats: const {},
        recentBookings: bookings,
      ));
    } catch (e) {
      emit(LenderError('Failed to load recent bookings: ${e.toString()}'));
    }
  }

  Future<void> _onLoadEarningsData(
    LoadEarningsData event,
    Emitter<LenderState> emit,
  ) async {
    try {
      emit(const LenderLoading());

      final earningsData = await _lenderRepository.getEarningsData(
        startDate: event.startDate,
        endDate: event.endDate,
      );

      emit(EarningsDataLoaded(
        earningsData: earningsData,
        startDate: event.startDate,
        endDate: event.endDate,
      ));
    } catch (e) {
      emit(LenderError('Failed to load earnings data: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshLenderData(
    RefreshLenderData event,
    Emitter<LenderState> emit,
  ) async {
    // Refresh by reloading dashboard data
    add(const LoadLenderDashboard());
  }

  Future<void> _onLoadAllBookings(
    LoadAllBookings event,
    Emitter<LenderState> emit,
  ) async {
    try {
      emit(const LenderLoading());
      final bookings = await _lenderRepository.getAllBookings();
      emit(AllBookingsLoaded(bookings: bookings));
    } catch (e) {
      emit(LenderError('Failed to load bookings: ${e.toString()}'));
    }
  }

  Future<void> _onLoadBookingDetails(
    LoadBookingDetails event,
    Emitter<LenderState> emit,
  ) async {
    try {
      emit(const LenderLoading());
      final booking =
          await _lenderRepository.getBookingDetails(event.bookingId);
      emit(BookingDetailsLoaded(booking: booking));
    } catch (e) {
      emit(LenderError('Failed to load booking details: ${e.toString()}'));
    }
  }

  Future<void> _onLoadUpcomingHandoffs(
    LoadUpcomingHandoffs event,
    Emitter<LenderState> emit,
  ) async {
    try {
      final now = DateTime.now();
      final nextWeek = now.add(const Duration(days: 7));
      final handoffs =
          await _lenderRepository.getUpcomingHandoffs(now, nextWeek);
      emit(UpcomingHandoffsLoaded(handoffs: handoffs));
    } catch (e) {
      emit(LenderError('Failed to load upcoming handoffs: ${e.toString()}'));
    }
  }

  Future<void> _onLoadUpcomingReturns(
    LoadUpcomingReturns event,
    Emitter<LenderState> emit,
  ) async {
    try {
      final now = DateTime.now();
      final nextWeek = now.add(const Duration(days: 7));
      final returns = await _lenderRepository.getUpcomingReturns(now, nextWeek);
      emit(UpcomingReturnsLoaded(returns: returns));
    } catch (e) {
      emit(LenderError('Failed to load upcoming returns: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateBookingStatus(
    UpdateBookingStatus event,
    Emitter<LenderState> emit,
  ) async {
    try {
      final updatedBooking = await _lenderRepository.updateBookingStatus(
        event.bookingId,
        event.status,
      );
      emit(BookingStatusUpdated(booking: updatedBooking));
    } catch (e) {
      emit(LenderError('Failed to update booking status: ${e.toString()}'));
    }
  }
}
