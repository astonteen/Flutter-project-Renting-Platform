import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:rent_ease/core/constants/calendar_constants.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/core/utils/date_utils.dart' as app_date_utils;
import 'package:rent_ease/features/listing/data/models/listing_model.dart';
import 'package:rent_ease/features/listing/presentation/bloc/listing_bloc.dart';
import 'package:rent_ease/features/booking/data/models/booking_model.dart';
import 'package:rent_ease/features/listing/presentation/bloc/calendar_availability_bloc.dart';
import 'package:rent_ease/features/listing/presentation/widgets/calendar_header_widget.dart';
import 'package:rent_ease/features/listing/presentation/widgets/calendar_grid_widget.dart';
import 'package:rent_ease/features/listing/presentation/widgets/day_action_sheet.dart';
import 'package:rent_ease/shared/widgets/loading_widget.dart';
import 'package:rent_ease/shared/widgets/error_widget.dart';

class RefactoredLenderCalendarScreen extends StatefulWidget {
  const RefactoredLenderCalendarScreen({super.key});

  @override
  State<RefactoredLenderCalendarScreen> createState() =>
      _RefactoredLenderCalendarScreenState();
}

class _RefactoredLenderCalendarScreenState
    extends State<RefactoredLenderCalendarScreen>
    with TickerProviderStateMixin {
  DateTime _selectedDate = app_date_utils.DateUtils.today;
  DateTime _focusedDate = app_date_utils.DateUtils.today;
  String? _selectedListingId;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadInitialData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: CalendarConstants.fadeAnimationDuration,
      vsync: this,
    );
    _slideController = AnimationController(
      duration: CalendarConstants.slideAnimationDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    // Defer animations until after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeController.forward();
      _slideController.forward();
    });
  }

  void _loadInitialData() {
    context.read<ListingBloc>().add(LoadMyListings());
  }

  void _handleListingChanged(String listingId) {
    setState(() {
      _selectedListingId = listingId;
    });
    _loadAvailabilityForCurrentMonth();
  }

  void _loadAvailabilityForCurrentMonth() {
    if (_selectedListingId != null) {
      context.read<CalendarAvailabilityBloc>().add(
            LoadCalendarAvailability(
              listingId: _selectedListingId!,
              month: _focusedDate,
            ),
          );
    }
  }

  void _handleDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  void _handleDateLongPressed(DateTime date) async {
    if (_selectedListingId == null) {
      _showMessage(CalendarConstants.selectListingFirstMessage, isError: true);
      return;
    }

    final availabilityState = context.read<CalendarAvailabilityBloc>().state;
    bool isBlocked = false;
    ItemAvailability? availability;

    if (availabilityState is CalendarAvailabilityLoaded) {
      final dateKey = app_date_utils.DateUtils.normalizeDate(date);
      availability = availabilityState.availabilityMap[dateKey];
      isBlocked = availability?.isBlocked ?? false;
    }

    final action = await showModalBottomSheet<DayAction>(
      context: context,
      builder: (context) => DayActionSheet(
        selectedDate: date,
        isBlocked: isBlocked,
        availability: availability,
      ),
    );

    if (action != null && action != DayAction.cancel) {
      _handleDayAction(action, date);
    }
  }

  void _handleDayAction(DayAction action, DateTime date) {
    if (_selectedListingId == null) return;

    switch (action) {
      case DayAction.block:
        context.read<CalendarAvailabilityBloc>().add(
              BlockDate(
                listingId: _selectedListingId!,
                date: date,
              ),
            );
        break;
      case DayAction.unblock:
        context.read<CalendarAvailabilityBloc>().add(
              UnblockDate(
                listingId: _selectedListingId!,
                date: date,
              ),
            );
        break;
      case DayAction.cancel:
        break;
    }
  }

  void _handleMonthChanged(DateTime newMonth) {
    setState(() {
      _focusedDate = newMonth;
    });
    _loadAvailabilityForCurrentMonth();
  }

  void _refreshAvailability() {
    if (_selectedListingId != null) {
      context.read<CalendarAvailabilityBloc>().add(
            RefreshAvailability(
              listingId: _selectedListingId!,
              month: _focusedDate,
            ),
          );
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? CalendarConstants.errorColor
            : CalendarConstants.successColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CalendarConstants.backgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                const CalendarHeaderWidget(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      _refreshAvailability();
                      // Add a small delay to show the refresh indicator
                      await Future.delayed(const Duration(milliseconds: 500));
                    },
                    color: CalendarConstants.primaryTextColor,
                    backgroundColor: Colors.white,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      child: Column(
                        children: [
                          _buildListingSelector(),
                          _buildCalendarSection(),
                          _buildSelectedDateInfo(),
                          _buildBookingsSection(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListingSelector() {
    return MultiBlocListener(
      listeners: [
        BlocListener<ListingBloc, ListingState>(
          listener: (context, state) {
            if (state is MyListingsLoaded) {
              if (_selectedListingId == null && state.listings.isNotEmpty) {
                setState(() {
                  _selectedListingId = state.listings.first.id;
                });
                _loadAvailabilityForCurrentMonth();
              }
            } else if (state is ListingError) {
              _showMessage(state.message, isError: true);
            }
          },
        ),
        BlocListener<CalendarAvailabilityBloc, CalendarAvailabilityState>(
          listener: (context, state) {
            if (state is CalendarAvailabilityError) {
              _showMessage(state.message, isError: true);
            } else if (state is CalendarAvailabilityActionSuccess) {
              _showMessage(state.message);
            }
          },
        ),
      ],
      child: BlocBuilder<ListingBloc, ListingState>(
        builder: (context, state) {
          if (state is ListingLoading) {
            return const SizedBox(height: 80, child: LoadingWidget());
          }

          if (state is ListingError) {
            return Container(
              margin: const EdgeInsets.all(CalendarConstants.sectionSpacing),
              child: CustomErrorWidget(
                message: state.message,
                onRetry: () =>
                    context.read<ListingBloc>().add(LoadMyListings()),
              ),
            );
          }

          if (state is MyListingsLoaded && state.listings.isNotEmpty) {
            return _ListingSelector(
              listings: state.listings,
              selectedListingId: _selectedListingId,
              onListingSelected: _handleListingChanged,
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildCalendarSection() {
    return BlocBuilder<CalendarAvailabilityBloc, CalendarAvailabilityState>(
      builder: (context, state) {
        Map<DateTime, ItemAvailability> availabilityMap = {};

        if (state is CalendarAvailabilityLoaded) {
          availabilityMap = state.availabilityMap;
        }

        return CalendarGridWidget(
          focusedDate: _focusedDate,
          selectedDate: _selectedDate,
          availabilityMap: availabilityMap,
          onDateSelected: _handleDateSelected,
          onDateLongPressed: _handleDateLongPressed,
          onPreviousMonth: () => _handleMonthChanged(
            app_date_utils.DateUtils.previousMonth(_focusedDate),
          ),
          onNextMonth: () => _handleMonthChanged(
            app_date_utils.DateUtils.nextMonth(_focusedDate),
          ),
        );
      },
    );
  }

  Widget _buildSelectedDateInfo() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        CalendarConstants.sectionSpacing,
        0,
        CalendarConstants.sectionSpacing,
        CalendarConstants.extraLargeSpacing,
      ),
      padding: const EdgeInsets.all(CalendarConstants.sectionSpacing),
      decoration: BoxDecoration(
        color: CalendarConstants.surfaceColor,
        borderRadius: BorderRadius.circular(CalendarConstants.cardBorderRadius),
        boxShadow: CalendarConstants.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(CalendarConstants.largeSpacing),
            decoration: BoxDecoration(
              color: ColorConstants.primaryColor.withAlpha(25),
              borderRadius:
                  BorderRadius.circular(CalendarConstants.largeSpacing),
            ),
            child: const Icon(
              Icons.calendar_today_rounded,
              color: ColorConstants.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: CalendarConstants.extraLargeSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                  style: CalendarConstants.cardTitleStyle,
                ),
                const SizedBox(height: CalendarConstants.smallSpacing),
                _buildAvailabilityStatus(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityStatus() {
    return BlocBuilder<CalendarAvailabilityBloc, CalendarAvailabilityState>(
      builder: (context, state) {
        if (state is CalendarAvailabilityLoaded) {
          final dateKey = app_date_utils.DateUtils.normalizeDate(_selectedDate);
          final availability = state.availabilityMap[dateKey];

          if (availability != null) {
            return Text(
              '${availability.availableQuantity}/${availability.totalQuantity} available',
              style: CalendarConstants.bodyTextStyle.copyWith(
                color: availability.availableQuantity > 0
                    ? CalendarConstants.confirmedColor
                    : CalendarConstants.errorColor,
                fontWeight: FontWeight.w500,
              ),
            );
          }
        }

        return Text(
          CalendarConstants.loadingAvailability,
          style: CalendarConstants.bodyTextStyle,
        );
      },
    );
  }

  Widget _buildBookingsSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        CalendarConstants.sectionSpacing,
        0,
        CalendarConstants.sectionSpacing,
        CalendarConstants.sectionSpacing,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                CalendarConstants.bookingsTitle,
                style: CalendarConstants.sectionTitleStyle,
              ),
              const SizedBox(width: CalendarConstants.mediumSpacing),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: CalendarConstants.mediumSpacing,
                  vertical: CalendarConstants.smallSpacing,
                ),
                decoration: BoxDecoration(
                  color: ColorConstants.primaryColor.withAlpha(25),
                  borderRadius:
                      BorderRadius.circular(CalendarConstants.mediumSpacing),
                ),
                child: Text(
                  DateFormat('MMM d').format(_selectedDate),
                  style: CalendarConstants.bodyTextStyle.copyWith(
                    fontSize: CalendarConstants.captionSize,
                    fontWeight: FontWeight.w600,
                    color: ColorConstants.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: CalendarConstants.extraLargeSpacing),
          _buildBookingsList(),
        ],
      ),
    );
  }

  Widget _buildBookingsList() {
    return BlocBuilder<CalendarAvailabilityBloc, CalendarAvailabilityState>(
      builder: (context, state) {
        if (state is CalendarAvailabilityLoading) {
          return const LoadingWidget();
        }

        if (state is CalendarAvailabilityLoaded) {
          final dateKey = app_date_utils.DateUtils.normalizeDate(_selectedDate);
          final availability = state.availabilityMap[dateKey];

          if (availability == null || availability.bookings.isEmpty) {
            return _buildEmptyBookingsState();
          }

          return Column(
            children: availability.bookings.map((booking) {
              return Container(
                margin: const EdgeInsets.only(
                    bottom: CalendarConstants.largeSpacing),
                decoration: BoxDecoration(
                  color: CalendarConstants.surfaceColor,
                  borderRadius:
                      BorderRadius.circular(CalendarConstants.largeSpacing),
                  border: CalendarConstants.defaultBorder,
                  boxShadow: CalendarConstants.lightShadow,
                ),
                child: _BookingCard(booking: booking),
              );
            }).toList(),
          );
        }

        return _buildEmptyBookingsState();
      },
    );
  }

  Widget _buildEmptyBookingsState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(CalendarConstants.largeSpacing),
        border: CalendarConstants.defaultBorder,
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_available_rounded,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: CalendarConstants.largeSpacing),
          Text(
            CalendarConstants.noBookingsTitle,
            style: CalendarConstants.cardTitleStyle.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: CalendarConstants.smallSpacing),
          Text(
            CalendarConstants.noBookingsSubtitle,
            style: CalendarConstants.bodyTextStyle.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

class _ListingSelector extends StatelessWidget {
  final List<ListingModel> listings;
  final String? selectedListingId;
  final ValueChanged<String> onListingSelected;

  const _ListingSelector({
    required this.listings,
    required this.selectedListingId,
    required this.onListingSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        CalendarConstants.sectionSpacing,
        CalendarConstants.extraLargeSpacing,
        CalendarConstants.sectionSpacing,
        CalendarConstants.mediumSpacing,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            CalendarConstants.selectPropertyLabel,
            style: CalendarConstants.cardTitleStyle,
          ),
          const SizedBox(height: CalendarConstants.largeSpacing),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: listings.map((listing) {
                final isSelected = selectedListingId == listing.id;
                return GestureDetector(
                  onTap: () => onListingSelected(listing.id),
                  child: Container(
                    margin: const EdgeInsets.only(
                        right: CalendarConstants.largeSpacing),
                    padding: const EdgeInsets.symmetric(
                      horizontal: CalendarConstants.extraLargeSpacing,
                      vertical: CalendarConstants.largeSpacing,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? ColorConstants.primaryColor
                          : CalendarConstants.surfaceColor,
                      borderRadius:
                          BorderRadius.circular(CalendarConstants.largeSpacing),
                      border: Border.all(
                        color: isSelected
                            ? ColorConstants.primaryColor
                            : CalendarConstants.borderColor,
                      ),
                      boxShadow: CalendarConstants.cardShadow,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.home_rounded,
                          size: CalendarConstants.smallIconSize,
                          color: isSelected ? Colors.white : Colors.grey[600],
                        ),
                        const SizedBox(width: CalendarConstants.mediumSpacing),
                        Text(
                          listing.name.length > 20
                              ? '${listing.name.substring(0, 20)}...'
                              : listing.name,
                          style: CalendarConstants.bodyTextStyle.copyWith(
                            color: isSelected ? Colors.white : Colors.grey[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;

  const _BookingCard({required this.booking});

  String _getStatusText(BookingModel booking) {
    return booking.status.name.toUpperCase();
  }

  Color _getStatusColor(BookingModel booking) {
    switch (booking.status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.confirmed:
        return Colors.green;
      case BookingStatus.inProgress:
        return Colors.blue;
      case BookingStatus.completed:
        return Colors.purple;
      case BookingStatus.cancelled:
        return Colors.red;
      case BookingStatus.overdue:
        return Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: Name, Status, Amount
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.renterName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (booking.renterRating > 0)
                      Row(
                        children: [
                          Icon(Icons.star, size: 14, color: Colors.amber[600]),
                          const SizedBox(width: 4),
                          Text(
                            booking.renterRating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              // Simple status badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(booking),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _getStatusText(booking),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Amount
              Text(
                '\$${booking.totalAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Dates and delivery info
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                '${DateFormat('MMM dd').format(booking.startDate)} - ${DateFormat('MMM dd').format(booking.endDate)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              if (booking.isDeliveryRequired) ...[
                const SizedBox(width: 16),
                Icon(Icons.local_shipping, size: 16, color: Colors.blue[600]),
                const SizedBox(width: 4),
                Text(
                  'Delivery',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
