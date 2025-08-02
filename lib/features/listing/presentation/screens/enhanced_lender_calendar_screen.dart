import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/core/constants/app_constants.dart';
import 'package:rent_ease/core/services/availability_service.dart';
import 'package:rent_ease/features/listing/data/models/listing_model.dart';
import 'package:rent_ease/features/listing/presentation/bloc/listing_bloc.dart';
import 'package:rent_ease/features/home/presentation/bloc/lender_bloc.dart';
import 'package:rent_ease/features/booking/data/models/booking_model.dart';
import 'package:rent_ease/features/booking/data/models/return_indicator_model.dart';
import 'package:rent_ease/shared/widgets/loading_widget.dart';
import 'package:rent_ease/shared/widgets/error_widget.dart';
import 'package:rent_ease/features/listing/presentation/widgets/day_action_sheet.dart';

// Enhanced enum to represent different availability states
enum BookingDateState {
  none,
  singleDay,
  rangeStart,
  rangeMiddle,
  rangeEnd,
  partiallyBooked,
  fullyBooked,
  blockedPostRental,
  blockedMaintenance,
}

// Models for enhanced availability tracking
class ItemAvailability {
  final int totalQuantity;
  final int availableQuantity;
  final int bookedQuantity;
  final int blockedQuantity;
  final List<BookingModel> bookings;
  final List<AvailabilityBlock> blocks;
  final List<ReturnIndicator> returnIndicators; // Lender-only return tracking

  ItemAvailability({
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
  bool get isBlocked => blockedQuantity > 0;
  bool get isFullyBlocked => blockedQuantity == totalQuantity;
  bool get hasReturnIndicators => returnIndicators.isNotEmpty;
  bool get hasOverdueReturns => returnIndicators.any((r) => r.isOverdue);
}

class AvailabilityBlock {
  final String id;
  final String itemId;
  final String? rentalId;
  final DateTime blockedFrom;
  final DateTime blockedUntil;
  final String blockType;
  final String? reason;
  final int quantityBlocked;

  AvailabilityBlock({
    required this.id,
    required this.itemId,
    this.rentalId,
    required this.blockedFrom,
    required this.blockedUntil,
    required this.blockType,
    this.reason,
    required this.quantityBlocked,
  });
}

class EnhancedLenderCalendarScreen extends StatefulWidget {
  const EnhancedLenderCalendarScreen({super.key});

  @override
  State<EnhancedLenderCalendarScreen> createState() =>
      _EnhancedLenderCalendarScreenState();
}

class _EnhancedLenderCalendarScreenState
    extends State<EnhancedLenderCalendarScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();
  Map<DateTime, ItemAvailability> _availabilityMap = {};

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String? _selectedListingId;

  // Performance optimization: memoization for expensive calculations
  DateTime? _lastLoadedMonth;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    context.read<ListingBloc>().add(LoadMyListings());
    _loadCurrentMonthData();

    // Add observer for metrics changes
    WidgetsBinding.instance.addObserver(this);

    // Defer animations until after first frame for better performance
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeController.forward();
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    // Handle screen metrics changes (orientation, keyboard, etc.)
    super.didChangeMetrics();
  }

  // Performance-optimized data loading
  void _loadCurrentMonthData() {
    final currentMonth = DateTime(_focusedDate.year, _focusedDate.month);
    if (_lastLoadedMonth != currentMonth) {
      context.read<LenderBloc>().add(LoadBookingsForDate(_selectedDate));
      _lastLoadedMonth = currentMonth;
    }
  }

  // Lazy load availability when month changes
  void _createMinimalSampleData() {
    final Map<DateTime, ItemAvailability> minimalMap = {};
    final now = DateTime.now();

    for (int i = -15; i <= 45; i++) {
      final date = DateTime(now.year, now.month, now.day + i);
      final dateKey = DateTime(date.year, date.month, date.day);

      minimalMap[dateKey] = ItemAvailability(
        totalQuantity: 1,
        availableQuantity: 1,
        bookedQuantity: 0,
        blockedQuantity: 0,
        bookings: [],
        blocks: [],
      );
    }

    setState(() {
      _availabilityMap = minimalMap;
    });
  }

  Future<void> _loadAvailabilityForListings(List<ListingModel> listings) async {
    if (listings.isEmpty) return;

    final firstListing = _selectedListingId != null
        ? listings.firstWhere((l) => l.id == _selectedListingId,
            orElse: () => listings.first)
        : listings.first;

    final startDate = DateTime(_focusedDate.year, _focusedDate.month - 1, 1);
    final endDate = DateTime(_focusedDate.year, _focusedDate.month + 2, 0);

    try {
      // Get both availability data and return indicators for lenders
      final availabilityData =
          await AvailabilityService.getItemAvailabilityRange(
        itemId: firstListing.id,
        startDate: startDate,
        endDate: endDate,
      );

      final returnIndicatorsData =
          await AvailabilityService.getReturnIndicatorsForItem(
        itemId: firstListing.id,
        startDate: startDate,
        endDate: endDate,
      );

      final Map<DateTime, ItemAvailability> newAvailabilityMap = {};

      availabilityData.forEach((date, data) {
        List<BookingModel> bookings = [];
        List<AvailabilityBlock> blocks = [];
        List<ReturnIndicator> returnIndicators = [];

        try {
          bookings = (data['bookings'] as List<dynamic>?)
                  ?.map((bookingData) {
                    try {
                      return BookingModel.fromJson(
                          bookingData as Map<String, dynamic>);
                    } catch (e) {
                      debugPrint('Error parsing booking data: $e');
                      return null;
                    }
                  })
                  .where((booking) => booking != null)
                  .cast<BookingModel>()
                  .toList() ??
              [];
        } catch (e) {
          debugPrint('Error processing bookings for date $date: $e');
        }

        try {
          blocks = (data['blocks'] as List<dynamic>?)
                  ?.map((blockData) {
                    try {
                      return AvailabilityBlock(
                        id: blockData['id'] ?? '',
                        itemId: blockData['item_id'] ?? '',
                        rentalId: blockData['rental_id'],
                        blockedFrom: DateTime.parse(blockData['blocked_from']),
                        blockedUntil:
                            DateTime.parse(blockData['blocked_until']),
                        blockType: blockData['block_type'] ?? 'manual',
                        reason: blockData['reason'],
                        quantityBlocked: blockData['quantity_blocked'] ?? 1,
                      );
                    } catch (e) {
                      debugPrint('Error parsing block data: $e');
                      return null;
                    }
                  })
                  .where((block) => block != null)
                  .cast<AvailabilityBlock>()
                  .toList() ??
              [];
        } catch (e) {
          debugPrint('Error processing blocks for date $date: $e');
        }

        // Find return indicators for this date
        try {
          returnIndicators = returnIndicatorsData
              .where((indicator) {
                final indicatorDate = DateTime(
                  indicator['expected_return_date'].year,
                  indicator['expected_return_date'].month,
                  indicator['expected_return_date'].day,
                );
                final currentDate = DateTime(date.year, date.month, date.day);
                return indicatorDate.isAtSameMomentAs(currentDate);
              })
              .map((indicatorData) {
                try {
                  return ReturnIndicator.fromJson(indicatorData);
                } catch (e) {
                  debugPrint('Error parsing return indicator data: $e');
                  return null;
                }
              })
              .where((indicator) => indicator != null)
              .cast<ReturnIndicator>()
              .toList();
        } catch (e) {
          debugPrint('Error processing return indicators for date $date: $e');
        }

        newAvailabilityMap[date] = ItemAvailability(
          totalQuantity: data['total_quantity'] ?? 1,
          availableQuantity: data['available_quantity'] ?? 1,
          bookedQuantity: data['booked_quantity'] ?? 0,
          blockedQuantity: data['blocked_quantity'] ?? 0,
          bookings: bookings,
          blocks: blocks,
          returnIndicators: returnIndicators,
        );
      });

      setState(() {
        _availabilityMap = newAvailabilityMap;
      });

      debugPrint(
          'Successfully loaded availability data for ${newAvailabilityMap.length} dates');
    } catch (e) {
      debugPrint('Error loading availability for listings: $e');
      _createMinimalSampleData();
    }
  }

  void _reloadAvailabilityForCurrentMonth() {
    final listingState = context.read<ListingBloc>().state;
    if (listingState is MyListingsLoaded && listingState.listings.isNotEmpty) {
      _loadAvailabilityForListings(listingState.listings);
    }
  }

  void _animateToToday() {
    _slideController.reset();
    _slideController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: RefreshIndicator(
              onRefresh: () async {
                _reloadAvailabilityForCurrentMonth();
              },
              child: Column(
                children: [
                  _buildEnhancedHeader(context),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          _buildListingSelector(),
                          _buildEnhancedCalendar(),
                          _buildSelectedDateInfo(),
                          _buildBookingsSection(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color.fromARGB(13, 0, 0, 0),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rental Calendar',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your rental schedule',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  _buildHeaderButton(
                    icon: Icons.today_rounded,
                    onPressed: () {
                      setState(() {
                        _selectedDate = DateTime.now();
                        _focusedDate = DateTime.now();
                      });
                      _animateToToday();
                    },
                    tooltip: 'Go to Today',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: IconButton(
          icon: Icon(icon, color: const Color(0xFF475569)),
          onPressed: onPressed,
          iconSize: 20,
        ),
      ),
    );
  }

  Widget _buildListingSelector() {
    return MultiBlocListener(
      listeners: [
        BlocListener<LenderBloc, LenderState>(
          listener: (context, state) {
            if (state is BookingsForDateLoaded) {
              // Update booking data
            }
          },
        ),
        BlocListener<ListingBloc, ListingState>(
          listener: (context, state) {
            if (state is MyListingsLoaded) {
              setState(() {
                if (_selectedListingId == null && state.listings.isNotEmpty) {
                  _selectedListingId = state.listings.first.id;
                }
              });
              _loadAvailabilityForListings(state.listings);
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
              margin: const EdgeInsets.all(20),
              child: CustomErrorWidget(
                message: state.message,
                onRetry: () {
                  context.read<ListingBloc>().add(LoadMyListings());
                },
              ),
            );
          }

          if (state is MyListingsLoaded && state.listings.isNotEmpty) {
            return Container(
              margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Property',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: state.listings.map((listing) {
                        final isSelected = _selectedListingId == listing.id;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedListingId = listing.id;
                            });
                            _loadAvailabilityForListings([listing]);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? ColorConstants.primaryColor
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? ColorConstants.primaryColor
                                    : const Color(0xFFE2E8F0),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color.fromARGB(13, 0, 0, 0),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.home_rounded,
                                  size: 16,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey[600],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  listing.name.length > 20
                                      ? '${listing.name.substring(0, 20)}...'
                                      : listing.name,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey[800],
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

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEnhancedCalendar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(10, 0, 0, 0),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildCalendarHeader(),
          _buildCalendarGrid(),
          _buildAvailabilityLegend(),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 24),
            onPressed: () {
              setState(() {
                _focusedDate = DateTime(
                  _focusedDate.year,
                  _focusedDate.month - 1,
                );
              });
              _reloadAvailabilityForCurrentMonth();
            },
            color: const Color(0xFF475569),
          ),
          Text(
            DateFormat('MMMM yyyy').format(_focusedDate),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, size: 24),
            onPressed: () {
              setState(() {
                _focusedDate = DateTime(
                  _focusedDate.year,
                  _focusedDate.month + 1,
                );
              });
              _reloadAvailabilityForCurrentMonth();
            },
            color: const Color(0xFF475569),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final lastDayOfMonth =
        DateTime(_focusedDate.year, _focusedDate.month + 1, 0);
    final firstDayWeekday = firstDayOfMonth.weekday % 7;
    final daysInMonth = lastDayOfMonth.day;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          // Weekday headers
          const Row(
            children: [
              Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Sun',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Mon',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Tue',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Wed',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Thu',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Fri',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Sat',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Calendar grid
          for (int week = 0; week < 6; week++)
            Row(
              children: List.generate(7, (dayOfWeek) {
                final dayNumber = week * 7 + dayOfWeek + 1 - firstDayWeekday;
                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return const Expanded(child: SizedBox(height: 48));
                }

                final date =
                    DateTime(_focusedDate.year, _focusedDate.month, dayNumber);
                return Expanded(child: _buildCalendarDay(date));
              }),
            ),
        ],
      ),
    );
  }

  // Enhanced calendar day background with preparation period indicators
  Widget _buildCalendarDay(DateTime date) {
    final dateKey = DateTime(date.year, date.month, date.day);
    final isSelected = dateKey.isAtSameMomentAs(
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day));
    final isToday = dateKey.isAtSameMomentAs(
        DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0));
    final availability = _availabilityMap[dateKey];

    Color backgroundColor = Colors.transparent;
    Color? borderColor;
    Color textColor = const Color(0xFF1E293B);

    // Add preparation period indicator
    Widget? preparationIndicator;

    if (availability != null) {
      // Check for preparation periods for upcoming bookings
      for (final booking in availability.bookings) {
        if (booking.status == BookingStatus.confirmed) {
          final maxDaysEarly = booking.isDeliveryRequired
              ? AppConstants.maxDaysEarlyDelivery
              : AppConstants.maxDaysEarlyPickup;
          final preparationStartDate =
              booking.startDate.subtract(Duration(days: maxDaysEarly));
          final preparationEndDate =
              booking.startDate.subtract(const Duration(days: 1));

          // Check if current date is in preparation period
          if (dateKey.isAfter(
                  preparationStartDate.subtract(const Duration(days: 1))) &&
              dateKey
                  .isBefore(preparationEndDate.add(const Duration(days: 1)))) {
            if (!booking.isItemReady) {
              // Add small preparation indicator
              preparationIndicator = Positioned(
                top: 2,
                right: 2,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                ),
              );
            }
            break;
          }
        }
      }

      // Original availability logic
      if (availability.isFullyBooked) {
        backgroundColor = ColorConstants.primaryColor;
        textColor = Colors.white;
      } else if (availability.isPartiallyAvailable) {
        backgroundColor = const Color.fromARGB(77, 29, 191, 115);
      } else if (availability.isBlocked) {
        // Manual blocks only (post_rental blocks are now return indicators)
        backgroundColor =
            const Color.fromARGB(77, 255, 152, 0); // Orange for manual blocks
      } else if (availability.hasReturnIndicators) {
        // Return indicators - light blue for return tracking (lender-only)
        if (availability.hasOverdueReturns) {
          backgroundColor =
              const Color.fromARGB(77, 244, 67, 54); // Light red for overdue
        } else {
          backgroundColor = const Color.fromARGB(
              77, 33, 150, 243); // Light blue for pending returns
        }
      }
    }

    if (isSelected) {
      borderColor = ColorConstants.primaryColor;
    } else if (isToday) {
      borderColor = Colors.blue;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = date;
        });
      },
      onLongPress: () async {
        final action = await showModalBottomSheet<DayAction>(
          context: context,
          builder: (context) => DayActionSheet(
            selectedDate: date,
            isBlocked: availability?.isBlocked ?? false,
          ),
        );

        if (action != null && action != DayAction.cancel) {
          _handleDayAction(action, date);
        }
      },
      child: Container(
        height: 48,
        margin: const EdgeInsets.all(2),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                border: borderColor != null
                    ? Border.all(color: borderColor, width: 2)
                    : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: isSelected || isToday
                        ? FontWeight.w600
                        : FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            if (preparationIndicator != null) preparationIndicator,
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityLegend() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Availability Legend',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildLegendItem(
                  'Available', Colors.transparent, const Color(0xFF1E293B)),
              _buildLegendItem(
                  'Booked', ColorConstants.primaryColor, Colors.white),
              _buildLegendItem(
                  'Partial',
                  const Color.fromARGB(77, 29, 191, 115),
                  const Color(0xFF1E293B)),
              _buildLegendItem(
                  'Manual Block',
                  const Color.fromARGB(77, 255, 152, 0),
                  const Color(0xFF1E293B)),
              _buildLegendItem(
                  'Auto-Block',
                  const Color.fromARGB(77, 156, 39, 176),
                  const Color(0xFF1E293B)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: color == Colors.transparent
                ? Border.all(color: const Color(0xFFE2E8F0))
                : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedDateInfo() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.04).round()),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ColorConstants.primaryColor.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.calendar_today_rounded,
              color: ColorConstants.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                _buildAvailabilityStatus(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityStatus() {
    final dateKey =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final availability = _availabilityMap[dateKey];

    if (availability != null) {
      return Text(
        '${availability.availableQuantity}/${availability.totalQuantity} available',
        style: TextStyle(
          color: availability.availableQuantity > 0
              ? Colors.green[600]
              : Colors.red[600],
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return Text(
      'Loading availability...',
      style: TextStyle(
        color: Colors.grey[600],
        fontSize: 14,
      ),
    );
  }

  Widget _buildBookingsSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Bookings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ColorConstants.primaryColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  DateFormat('MMM d').format(_selectedDate),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ColorConstants.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildBookingsList(),
        ],
      ),
    );
  }

  Widget _buildBookingsList() {
    final dateKey =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final availability = _availabilityMap[dateKey];

    if (availability == null || availability.bookings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.event_available_rounded,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'No bookings for this date',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'This date is available for new bookings',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: availability.bookings.map((booking) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(5),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _buildBookingCard(booking),
        );
      }).toList(),
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    final isMultiDay = booking.startDate.day != booking.endDate.day;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getStatusColor(booking.status).withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.home_rounded,
                  size: 20,
                  color: _getStatusColor(booking.status),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.listingName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rented to: ${booking.renterName}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(booking.status),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  booking.status.name.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              // Add ready status indicator for confirmed bookings
              if (booking.status == BookingStatus.confirmed) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getReadyStatusColor(booking),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color:
                          _getReadyStatusColor(booking).withValues(alpha: 0.7),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getReadyStatusText(booking),
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w500,
                      color: _getReadyStatusTextColor(booking),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 16,
                color: Colors.grey[500],
              ),
              const SizedBox(width: 6),
              Text(
                isMultiDay
                    ? '${DateFormat('MMM d').format(booking.startDate)} - ${DateFormat('MMM d').format(booking.endDate)}'
                    : 'Full day rental',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              Text(
                '\$${booking.totalAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return Colors.green;
      case BookingStatus.pending:
        return Colors.orange;
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

  Color _getReadyStatusColor(BookingModel booking) {
    if (booking.status != BookingStatus.confirmed) return Colors.grey;

    final now = DateTime.now();
    final canMarkReady = _canMarkReady(booking, now);
    final canPickupNow = booking.isItemReady &&
        (now.isAfter(booking.startDate) ||
            now.isAtSameMomentAs(booking.startDate));

    if (canPickupNow) {
      return Colors.green; // Ready & available for pickup
    } else if (booking.isItemReady) {
      return Colors.orange; // Prepared but not yet available
    } else if (canMarkReady) {
      return Colors.blue; // Can be marked ready
    } else {
      return Colors.grey; // Too early to prepare
    }
  }

  String _getReadyStatusText(BookingModel booking) {
    if (booking.status != BookingStatus.confirmed) return '';

    final now = DateTime.now();
    final canMarkReady = _canMarkReady(booking, now);
    final canPickupNow = booking.isItemReady &&
        (now.isAfter(booking.startDate) ||
            now.isAtSameMomentAs(booking.startDate));

    if (canPickupNow) {
      return 'AVAILABLE';
    } else if (booking.isItemReady) {
      return 'PREPARED';
    } else if (canMarkReady) {
      return 'CAN PREP';
    } else {
      return 'TOO EARLY';
    }
  }

  Color _getReadyStatusTextColor(BookingModel booking) {
    return Colors.white; // All status texts are white for visibility
  }

  bool _canMarkReady(BookingModel booking, DateTime now) {
    final maxDaysEarly = booking.isDeliveryRequired
        ? AppConstants.maxDaysEarlyDelivery
        : AppConstants.maxDaysEarlyPickup;
    final earliestReadyDate =
        booking.startDate.subtract(Duration(days: maxDaysEarly));
    return now.isAfter(earliestReadyDate) ||
        now.isAtSameMomentAs(earliestReadyDate);
  }

  void _handleDayAction(DayAction action, DateTime date) {
    switch (action) {
      case DayAction.block:
        _blockDate(date);
        break;
      case DayAction.unblock:
        _unblockDate(date);
        break;
      case DayAction.cancel:
        break;
    }
  }

  void _blockDate(DateTime date) async {
    if (_selectedListingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a listing first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Block the date (single day)
      final startDate = DateTime(date.year, date.month, date.day);
      final endDate = startDate.add(const Duration(hours: 23, minutes: 59));

      await AvailabilityService.createManualBlock(
        itemId: _selectedListingId!,
        startDate: startDate,
        endDate: endDate,
        reason: 'Manually blocked for maintenance',
        quantityToBlock: 1,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Date ${DateFormat('MMM d').format(date)} blocked for maintenance'),
          backgroundColor: ColorConstants.successColor,
        ),
      );

      // Refresh availability data
      _reloadAvailabilityForCurrentMonth();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to block date: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _unblockDate(DateTime date) async {
    if (_selectedListingId == null) return;

    try {
      final dateKey = DateTime(date.year, date.month, date.day);
      final availability = _availabilityMap[dateKey];

      if (availability != null && availability.blocks.isNotEmpty) {
        // Remove all manual blocks for this date (keep auto-blocks)
        for (final block in availability.blocks) {
          if (block.blockType == 'manual') {
            await AvailabilityService.removeManualBlock(blockId: block.id);
          }
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Date ${DateFormat('MMM d').format(date)} unblocked'),
            backgroundColor: ColorConstants.successColor,
          ),
        );

        // Refresh availability data
        _reloadAvailabilityForCurrentMonth();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No manual blocks found on this date'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to unblock date: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
