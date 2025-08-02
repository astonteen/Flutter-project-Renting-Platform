import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rent_ease/core/constants/color_constants.dart';
import 'package:rent_ease/core/widgets/custom_button.dart';
import 'package:rent_ease/features/home/data/models/rental_item_model.dart';
import 'package:rent_ease/features/payment/presentation/screens/payment_screen.dart';
import 'package:rent_ease/features/profile/data/models/saved_address_model.dart';
import 'package:rent_ease/features/profile/presentation/screens/address_selection_screen.dart';
import 'package:rent_ease/core/services/availability_service.dart';
import 'package:rent_ease/core/utils/date_utils.dart' as app_date_utils;
import 'package:rent_ease/features/listing/presentation/bloc/calendar_availability_bloc.dart';
import 'package:rent_ease/features/booking/data/models/booking_model.dart';
import 'package:rent_ease/core/constants/calendar_constants.dart';
import 'package:intl/intl.dart';

class BookingScreen extends StatefulWidget {
  final RentalItemModel item;

  const BookingScreen({
    super.key,
    required this.item,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedDuration = 'daily';
  final TextEditingController _notesController = TextEditingController();
  SavedAddressModel? _selectedAddress;
  String _manualAddress = '';
  final TextEditingController _deliveryInstructionsController =
      TextEditingController();
  bool _needsDelivery = false;

  // Calendar state
  DateTime _focusedDate = DateTime.now();
  Map<DateTime, ItemAvailability> _availabilityMap = {};
  bool _isLoadingAvailability = false;

  @override
  void initState() {
    super.initState();
    _loadAvailabilityForCurrentMonth();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailabilityForCurrentMonth() async {
    setState(() {
      _isLoadingAvailability = true;
    });

    try {
      final startDate = app_date_utils.DateUtils.startOfMonth(_focusedDate);
      final endDate = app_date_utils.DateUtils.endOfMonth(_focusedDate);

      final availabilityData =
          await AvailabilityService.getItemAvailabilityRange(
        itemId: widget.item.id,
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

      if (mounted) {
        setState(() {
          _availabilityMap = monthAvailability;
          _isLoadingAvailability = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAvailability = false;
        });
      }
    }
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
              return null;
            }
          })
          .where((block) => block != null)
          .cast<AvailabilityBlock>()
          .toList();
    } catch (e) {
      return [];
    }
  }

  int _calculateDays() {
    if (_startDate == null || _endDate == null) return 0;
    return _endDate!.difference(_startDate!).inDays + 1;
  }

  Widget _buildCalendarHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                _focusedDate =
                    DateTime(_focusedDate.year, _focusedDate.month - 1, 1);
              });
              _loadAvailabilityForCurrentMonth();
            },
            icon: const Icon(Icons.chevron_left),
          ),
          Text(
            DateFormat('MMMM yyyy').format(_focusedDate),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _focusedDate =
                    DateTime(_focusedDate.year, _focusedDate.month + 1, 1);
              });
              _loadAvailabilityForCurrentMonth();
            },
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final monthStart = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final monthEnd = DateTime(_focusedDate.year, _focusedDate.month + 1, 0);
    final firstDayOfWeek = monthStart.weekday;
    final daysInMonth = monthEnd.day;

    return Column(
      children: [
        // Weekday headers
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),

        // Calendar days
        Container(
          padding: const EdgeInsets.all(8),
          child: Table(
            children:
                _buildCalendarRows(monthStart, daysInMonth, firstDayOfWeek),
          ),
        ),
      ],
    );
  }

  List<TableRow> _buildCalendarRows(
      DateTime monthStart, int daysInMonth, int firstDayOfWeek) {
    final List<TableRow> rows = [];
    final List<Widget> currentWeek = [];

    // Add empty cells for days before the first day of the month
    final startPadding = (firstDayOfWeek % 7);
    for (int i = 0; i < startPadding; i++) {
      currentWeek.add(const SizedBox(height: 44));
    }

    // Add days of the month
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(monthStart.year, monthStart.month, day);
      currentWeek.add(_buildCalendarDay(date));

      // If we've filled a week, add it to rows and start a new week
      if (currentWeek.length == 7) {
        rows.add(TableRow(children: List.from(currentWeek)));
        currentWeek.clear();
      }
    }

    // Fill the last week with empty cells if needed
    while (currentWeek.length < 7 && currentWeek.isNotEmpty) {
      currentWeek.add(const SizedBox(height: 44));
    }

    if (currentWeek.isNotEmpty) {
      rows.add(TableRow(children: List.from(currentWeek)));
    }

    return rows;
  }

  Widget _buildCalendarDay(DateTime date) {
    final dateKey = app_date_utils.DateUtils.normalizeDate(date);
    final availability = _availabilityMap[dateKey];
    final isToday = app_date_utils.DateUtils.isToday(date);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final isPast = normalizedDate.isBefore(today);

    Color backgroundColor = Colors.transparent;
    Color textColor = Colors.black;
    bool isSelectable = true;

    if (isPast) {
      textColor = Colors.grey[400]!;
      isSelectable = false;
    } else if (availability != null) {
      // Apply enhanced color priority logic: purple > orange > red > yellow > green

      // Note: post_rental blocks (return buffers) are no longer shown to renters
      // They are now return indicators visible only to lenders

      // Check for manual blocks
      if (availability.blocks.any((block) => block.blockType == 'manual')) {
        backgroundColor = CalendarConstants.manualBlockBackgroundColor;
        textColor = CalendarConstants.manualBlockTextColor;
        isSelectable = false;
      }
      // Calculate free units for booking status
      else {
        final freeUnits = availability.totalQuantity -
            availability.bookedQuantity -
            availability.blockedQuantity;

        if (freeUnits == 0) {
          backgroundColor = CalendarConstants.fullyBookedBackgroundColor;
          textColor = CalendarConstants.fullyBookedTextColor;
          isSelectable = false;
        } else if (freeUnits < availability.totalQuantity) {
          backgroundColor = CalendarConstants.partiallyBookedBackgroundColor;
          textColor = CalendarConstants.partiallyBookedTextColor;
        } else {
          backgroundColor = CalendarConstants.availableBackgroundColor;
          textColor = CalendarConstants.availableTextColor;
        }
      }
    } else {
      backgroundColor = CalendarConstants.availableBackgroundColor;
      textColor = CalendarConstants.availableTextColor;
    }

    // Check if date is selected
    final isStartDate = _startDate != null &&
        app_date_utils.DateUtils.isSameDay(date, _startDate!);
    final isEndDate =
        _endDate != null && app_date_utils.DateUtils.isSameDay(date, _endDate!);
    final isInRange = _startDate != null &&
        _endDate != null &&
        date.isAfter(_startDate!) &&
        date.isBefore(_endDate!);

    if (isStartDate || isEndDate) {
      backgroundColor = ColorConstants.primaryColor;
      textColor = Colors.white;
    } else if (isInRange) {
      backgroundColor = ColorConstants.primaryColor.withAlpha(77);
    }

    return GestureDetector(
      onTap: isSelectable ? () => _selectDate(date) : null,
      child: Container(
        height: 44, // Slightly larger for better touch targets
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: isToday
              ? Border.all(color: Colors.orange, width: 2)
              : (isStartDate || isEndDate)
                  ? Border.all(color: ColorConstants.primaryColor, width: 2)
                  : null,
          boxShadow: (isStartDate || isEndDate)
              ? [
                  BoxShadow(
                    color: ColorConstants.primaryColor.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isSelectable ? () => _selectDate(date) : null,
            borderRadius: BorderRadius.circular(8),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: (isStartDate || isEndDate || isToday)
                          ? FontWeight.bold
                          : FontWeight.w500,
                      fontSize:
                          (isStartDate || isEndDate) ? 16 : (isToday ? 15 : 14),
                    ),
                  ),
                  // Add lightning indicator for today
                  if (isToday && !isStartDate && !isEndDate && isSelectable)
                    Container(
                      margin: const EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.flash_on,
                        size: 8,
                        color: Colors.orange[600],
                      ),
                    ),
                  // Add small selection indicators
                  if (isStartDate && isEndDate)
                    Container(
                      width: 6,
                      height: 2,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    )
                  else if (isStartDate)
                    Container(
                      width: 8,
                      height: 2,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    )
                  else if (isEndDate)
                    Container(
                      width: 8,
                      height: 2,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(1),
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

  void _selectDate(DateTime date) {
    setState(() {
      final isStartDate = _startDate != null &&
          app_date_utils.DateUtils.isSameDay(date, _startDate!);
      final isEndDate = _endDate != null &&
          app_date_utils.DateUtils.isSameDay(date, _endDate!);

      // Handle deselection - clicking on selected dates
      if (isStartDate && isEndDate) {
        // Single day selection - clear both
        _startDate = null;
        _endDate = null;
        _showSelectionFeedback('Selection cleared');
        return;
      } else if (isStartDate) {
        // Clicked on start date - make end date the new start (if exists)
        if (_endDate != null) {
          _startDate = _endDate;
          _endDate = null;
          _showSelectionFeedback('Start date updated');
        } else {
          _startDate = null;
          _showSelectionFeedback('Selection cleared');
        }
        return;
      } else if (isEndDate) {
        // Clicked on end date - remove it
        _endDate = null;
        _showSelectionFeedback('End date removed');
        return;
      }

      // Handle new selections
      if (_startDate == null || (_startDate != null && _endDate != null)) {
        // Starting a new selection or replacing complete selection
        _startDate = date;
        _endDate = null;
        final isSameDayBooking = app_date_utils.DateUtils.isToday(date);
        _showSelectionFeedback(isSameDayBooking
            ? 'Start date selected (Same day booking! ⚡)'
            : 'Start date selected');
      } else if (_startDate != null && _endDate == null) {
        // Selecting end date
        if (date.isAfter(_startDate!)) {
          _endDate = date;
          final days = _endDate!.difference(_startDate!).inDays + 1;
          final hasToday = app_date_utils.DateUtils.isToday(_startDate!) ||
              app_date_utils.DateUtils.isToday(_endDate!);
          _showSelectionFeedback(hasToday
              ? '$days day${days > 1 ? 's' : ''} selected (includes same day! ⚡)'
              : '$days day${days > 1 ? 's' : ''} selected');
        } else if (date.isBefore(_startDate!)) {
          // If selected date is before start date, make it the new start date
          _endDate = _startDate;
          _startDate = date;
          final days = _endDate!.difference(_startDate!).inDays + 1;
          final hasToday = app_date_utils.DateUtils.isToday(_startDate!) ||
              app_date_utils.DateUtils.isToday(_endDate!);
          _showSelectionFeedback(hasToday
              ? '$days day${days > 1 ? 's' : ''} selected (includes same day! ⚡)'
              : '$days day${days > 1 ? 's' : ''} selected');
        } else {
          // Same date as start - single day selection
          final isSameDayBooking = app_date_utils.DateUtils.isToday(date);
          _showSelectionFeedback(isSameDayBooking
              ? 'Same day booking selected! ⚡'
              : 'Single day selected');
        }
      }
    });
  }

  void _showSelectionFeedback(String message) {
    // Show brief feedback without being intrusive
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 1000),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
      ),
    );
  }

  String _getSelectionTitle() {
    if (_startDate != null && _endDate != null) {
      final isSameDay =
          app_date_utils.DateUtils.isSameDay(_startDate!, _endDate!);
      if (isSameDay) {
        final isSameDayBooking = app_date_utils.DateUtils.isToday(_startDate!);
        return isSameDayBooking ? 'Same Day Booking ⚡' : 'Single Day Rental';
      }
      final hasToday = app_date_utils.DateUtils.isToday(_startDate!) ||
          app_date_utils.DateUtils.isToday(_endDate!);
      return hasToday
          ? 'Date Range Selected (includes today ⚡)'
          : 'Date Range Selected';
    } else if (_startDate != null) {
      final isSameDayBooking = app_date_utils.DateUtils.isToday(_startDate!);
      return isSameDayBooking
          ? 'Same Day Start Selected ⚡'
          : 'Start Date Selected';
    }
    return 'Select Dates';
  }

  void _clearSelection() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _showSelectionFeedback('Selection cleared');
  }

  bool _isSameDayBooking() {
    if (_startDate == null) return false;

    // Check if it's a single day booking for today
    if (_endDate == null) {
      return app_date_utils.DateUtils.isToday(_startDate!);
    }

    // Check if it's a same day booking (start and end on same day, which is today)
    final isSameDay =
        app_date_utils.DateUtils.isSameDay(_startDate!, _endDate!);
    return isSameDay && app_date_utils.DateUtils.isToday(_startDate!);
  }

  Widget _buildDateInfo(String label, DateTime date, IconData icon) {
    final dayName = DateFormat('EEEE').format(date);
    final dateStr = DateFormat('MMM dd, yyyy').format(date);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: ColorConstants.primaryColor, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$dayName, $dateStr',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSelectionOptions() {
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    final nextWeek = today.add(const Duration(days: 7));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Select',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildQuickSelectChip('Today', today, today),
              const SizedBox(width: 8),
              _buildQuickSelectChip('Tomorrow', tomorrow, tomorrow),
              const SizedBox(width: 8),
              _buildQuickSelectChip('This Weekend', _getNextWeekend(),
                  _getNextWeekend().add(const Duration(days: 1))),
              const SizedBox(width: 8),
              _buildQuickSelectChip(
                  'Next Week', nextWeek, nextWeek.add(const Duration(days: 6))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickSelectChip(String label, DateTime start, DateTime end) {
    final isSelectable = _canSelectDateRange(start, end);
    final isToday = label == 'Today';
    final isSameDayBooking = isToday && app_date_utils.DateUtils.isToday(start);

    return GestureDetector(
      onTap: isSelectable ? () => _selectDateRange(start, end, label) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelectable
              ? (isSameDayBooking ? Colors.orange[50] : Colors.blue[50])
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelectable
                ? (isSameDayBooking ? Colors.orange[200]! : Colors.blue[200]!)
                : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSameDayBooking) ...[
              Icon(
                Icons.flash_on,
                size: 14,
                color: Colors.orange[700],
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelectable
                    ? (isSameDayBooking ? Colors.orange[700] : Colors.blue[700])
                    : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  DateTime _getNextWeekend() {
    final today = DateTime.now();
    final daysUntilSaturday = (6 - today.weekday) % 7;
    return today
        .add(Duration(days: daysUntilSaturday == 0 ? 7 : daysUntilSaturday));
  }

  bool _canSelectDateRange(DateTime start, DateTime end) {
    // Check if the date range is available (includes same day booking)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final normalizedStart = DateTime(start.year, start.month, start.day);

    // Allow booking from today onwards
    return !normalizedStart.isBefore(today);
  }

  void _selectDateRange(DateTime start, DateTime end, String label) {
    setState(() {
      _startDate = start;
      _endDate = app_date_utils.DateUtils.isSameDay(start, end) ? null : end;
    });
    _showSelectionFeedback('$label selected');
  }

  Widget _buildCalendarLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              const Text(
                'Calendar Guide',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Availability legend
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _buildLegendItem(CalendarConstants.availableBackgroundColor,
                  CalendarConstants.availableTextColor, 'Available'),
              _buildLegendItem(
                  CalendarConstants.partiallyBookedBackgroundColor,
                  CalendarConstants.partiallyBookedTextColor,
                  'Partially Available'),
              _buildLegendItem(CalendarConstants.fullyBookedBackgroundColor,
                  CalendarConstants.fullyBookedTextColor, 'Fully Booked'),
              _buildLegendItem(CalendarConstants.manualBlockBackgroundColor,
                  CalendarConstants.manualBlockTextColor, 'Blocked'),
              // Note: Return Buffer removed - renters don't need to see return indicators
              _buildLegendItem(
                  ColorConstants.primaryColor, Colors.white, 'Selected'),
            ],
          ),

          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.touch_app, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Text(
                      'How to Select:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '• Tap once to select start date\n'
                  '• Tap again to select end date\n'
                  '• Tap selected dates to deselect\n'
                  '• Use quick select options for common ranges\n'
                  '• Same day booking available! ⚡',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[600],
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
      Color backgroundColor, Color textColor, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  double _calculateTotalCost() {
    final days = _calculateDays();
    if (days == 0) return 0;

    double baseCost = 0;
    switch (_selectedDuration) {
      case 'daily':
        baseCost = widget.item.pricePerDay * days;
        break;
      case 'weekly':
        if (widget.item.pricePerWeek != null) {
          final weeks = (days / 7).ceil();
          baseCost = widget.item.pricePerWeek! * weeks;
        } else {
          baseCost = widget.item.pricePerDay * days;
        }
        break;
      case 'monthly':
        if (widget.item.pricePerMonth != null) {
          final months = (days / 30).ceil();
          baseCost = widget.item.pricePerMonth! * months;
        } else {
          baseCost = widget.item.pricePerDay * days;
        }
        break;
    }

    // Add delivery fee if needed
    double deliveryFee = _needsDelivery ? 15.0 : 0.0;

    return baseCost + deliveryFee;
  }

  String _getDeliveryAddress() {
    if (_selectedAddress != null) {
      return _selectedAddress!.fullAddress;
    }
    return _manualAddress;
  }

  void _proceedToPayment() {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select rental dates')),
      );
      return;
    }

    // Validate delivery address if delivery is needed
    if (_needsDelivery && _getDeliveryAddress().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select or enter a delivery address')),
      );
      return;
    }

    // Navigate to payment screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          item: widget.item,
          startDate: _startDate!,
          endDate: _endDate!,
          totalAmount: _calculateTotalCost(),
          needsDelivery: _needsDelivery,
          deliveryAddress: _needsDelivery ? _getDeliveryAddress() : null,
          deliveryInstructions: _needsDelivery &&
                  _deliveryInstructionsController.text.trim().isNotEmpty
              ? _deliveryInstructionsController.text.trim()
              : null,
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Book Item'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item summary
            _buildItemSummary(),
            const SizedBox(height: 24),

            // Date selection
            _buildDateSelection(),
            const SizedBox(height: 24),

            // Duration options
            _buildDurationOptions(),
            const SizedBox(height: 24),

            // Delivery options
            _buildDeliveryOptions(),
            const SizedBox(height: 24),

            // Additional notes
            _buildNotesSection(),
            const SizedBox(height: 24),

            // Cost breakdown
            _buildCostBreakdown(),
            const SizedBox(height: 100), // Space for bottom button
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildItemSummary() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                widget.item.primaryImageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (widget.item.ownerName != null)
                    Text(
                      'by ${widget.item.ownerName}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    widget.item.formattedPricePerDay,
                    style: const TextStyle(
                      color: ColorConstants.primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Rental Period',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Calendar view
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildCalendarHeader(),
              if (_isLoadingAvailability)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                )
              else
                _buildCalendarGrid(),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Enhanced selected dates display with actions
        if (_startDate != null || _endDate != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  ColorConstants.primaryColor.withOpacity(0.05),
                  ColorConstants.primaryColor.withOpacity(0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: ColorConstants.primaryColor.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ColorConstants.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.event_available,
                        color: ColorConstants.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getSelectionTitle(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          if (_startDate != null && _endDate != null)
                            Text(
                              'Duration: ${_calculateDays()} day${_calculateDays() > 1 ? 's' : ''}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _clearSelection,
                      icon: const Icon(Icons.clear, size: 18),
                      label: const Text('Clear'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_startDate != null)
                  _buildDateInfo('Start Date', _startDate!, Icons.play_arrow),
                if (_startDate != null && _endDate != null)
                  const SizedBox(height: 8),
                if (_endDate != null)
                  _buildDateInfo('End Date', _endDate!, Icons.stop),

                // Same day booking notice
                if (_startDate != null && _isSameDayBooking())
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange[100]!,
                          Colors.orange[50]!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.flash_on,
                            color: Colors.orange[700], size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Same day booking! Your rental can start today.',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Quick selection shortcuts
          _buildQuickSelectionOptions(),
        ],

        // Legend
        const SizedBox(height: 16),
        _buildCalendarLegend(),
      ],
    );
  }

  Widget _buildDurationOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pricing Option',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildDurationChip(
                'daily', 'Daily', widget.item.formattedPricePerDay),
            const SizedBox(width: 12),
            if (widget.item.pricePerWeek != null)
              _buildDurationChip('weekly', 'Weekly',
                  '\$${widget.item.pricePerWeek!.toStringAsFixed(0)}/week'),
            const SizedBox(width: 12),
            if (widget.item.pricePerMonth != null)
              _buildDurationChip('monthly', 'Monthly',
                  '\$${widget.item.pricePerMonth!.toStringAsFixed(0)}/month'),
          ],
        ),
      ],
    );
  }

  Widget _buildDurationChip(String value, String label, String price) {
    final isSelected = _selectedDuration == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedDuration = value),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? ColorConstants.primaryColor : Colors.white,
            border: Border.all(
              color:
                  isSelected ? ColorConstants.primaryColor : Colors.grey[300]!,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                price,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Delivery Options',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Modern delivery toggle card
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _needsDelivery
                  ? ColorConstants.primaryColor.withOpacity(0.3)
                  : Colors.grey[300]!,
            ),
            color: _needsDelivery
                ? ColorConstants.primaryColor.withOpacity(0.03)
                : Colors.white,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _needsDelivery = !_needsDelivery),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _needsDelivery
                            ? ColorConstants.primaryColor.withOpacity(0.1)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _needsDelivery
                            ? Icons.local_shipping
                            : Icons.local_shipping_outlined,
                        color: _needsDelivery
                            ? ColorConstants.primaryColor
                            : Colors.grey[600],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'I need delivery',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Delivery fee: \$15.00',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _needsDelivery
                            ? ColorConstants.primaryColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _needsDelivery
                              ? ColorConstants.primaryColor
                              : Colors.grey[400]!,
                          width: 2,
                        ),
                      ),
                      child: _needsDelivery
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        if (_needsDelivery) ...[
          const SizedBox(height: 20),
          _buildAddressSelector(),
          const SizedBox(height: 16),

          // Enhanced delivery instructions field
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: TextField(
              controller: _deliveryInstructionsController,
              decoration: InputDecoration(
                labelText: 'Delivery Instructions (Optional)',
                hintText:
                    'e.g., Ring doorbell twice, Leave at front door, Call on arrival...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: ColorConstants.primaryColor, width: 2),
                ),
                contentPadding: const EdgeInsets.all(16),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Colors.blue[600],
                  ),
                ),
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
              maxLines: 3,
              minLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAddressSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Delivery Address',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(width: 4),
            Text(
              '*',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Modern address selection card
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hasSelectedAddress()
                  ? ColorConstants.primaryColor.withOpacity(0.3)
                  : Colors.grey[300]!,
              width: _hasSelectedAddress() ? 2 : 1,
            ),
            color: _hasSelectedAddress()
                ? ColorConstants.primaryColor.withOpacity(0.03)
                : Colors.white,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openAddressSelection(),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _hasSelectedAddress()
                            ? ColorConstants.primaryColor.withOpacity(0.1)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _hasSelectedAddress()
                            ? Icons.location_on
                            : Icons.location_on_outlined,
                        color: _hasSelectedAddress()
                            ? ColorConstants.primaryColor
                            : Colors.grey[600],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getAddressDisplayText(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: _hasSelectedAddress()
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: _hasSelectedAddress()
                                  ? Colors.black87
                                  : Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          if (_selectedAddress != null &&
                              _selectedAddress!.label.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: ColorConstants.primaryColor
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _selectedAddress!.displayLabel,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: ColorConstants.primaryColor,
                                ),
                              ),
                            )
                          else if (_manualAddress.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Manual Entry',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.orange[700],
                                ),
                              ),
                            )
                          else
                            Text(
                              _getAddressSubtitle(),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[500],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getAddressDisplayText() {
    if (_selectedAddress != null) {
      return _selectedAddress!.fullAddress;
    } else if (_manualAddress.isNotEmpty) {
      return _manualAddress;
    }
    return 'Select or enter delivery address';
  }

  String _getAddressSubtitle() {
    if (_selectedAddress != null) {
      return 'From saved addresses';
    } else if (_manualAddress.isNotEmpty) {
      return 'Manually entered';
    }
    return 'Tap to choose from saved addresses or enter manually';
  }

  bool _hasSelectedAddress() {
    return _selectedAddress != null || _manualAddress.isNotEmpty;
  }

  void _openAddressSelection() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddressSelectionScreen(
          selectedAddress: _selectedAddress,
          onAddressSelected: (address) {
            setState(() {
              if (address != null) {
                // User selected a saved address
                _selectedAddress = address;
                _manualAddress = ''; // Clear manual address

                // Show confirmation feedback
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Selected: ${address.displayLabel}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              } else {
                // User wants to enter manual address
                _selectedAddress = null;
                // Small delay to let the address selection screen close first
                Future.delayed(const Duration(milliseconds: 300), () {
                  _showManualAddressDialog();
                });
              }
            });
          },
        ),
      ),
    );
  }

  void _showManualAddressDialog() {
    final controller = TextEditingController(text: _manualAddress);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ColorConstants.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.edit_location_alt,
                color: ColorConstants.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Enter Delivery Address',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please provide your complete delivery address including street, city, postal code, and any apartment/unit numbers.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'e.g., 123 Main St, Apt 4B\nAnytown, ST 12345',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: ColorConstants.primaryColor, width: 2),
                ),
                contentPadding: const EdgeInsets.all(16),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.location_on_outlined,
                    size: 20,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              maxLines: 4,
              minLines: 3,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final address = controller.text.trim();
              if (address.isNotEmpty) {
                setState(() {
                  _manualAddress = address;
                  _selectedAddress =
                      null; // Clear saved address when using manual
                });
                Navigator.of(context).pop();

                // Show success feedback
                Future.delayed(const Duration(milliseconds: 300), () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Manual address saved successfully',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid address'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstants.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Save Address',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Notes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _notesController,
          decoration: InputDecoration(
            hintText: 'Any special instructions or requests...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildCostBreakdown() {
    final days = _calculateDays();
    final totalCost = _calculateTotalCost();
    final deliveryFee = _needsDelivery ? 15.0 : 0.0;
    final itemCost = totalCost - deliveryFee;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cost Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (days > 0) ...[
              _buildCostRow('Item rental ($days day${days > 1 ? 's' : ''})',
                  '\$${itemCost.toStringAsFixed(2)}'),
              if (_needsDelivery)
                _buildCostRow(
                    'Delivery fee', '\$${deliveryFee.toStringAsFixed(2)}'),
              if (widget.item.securityDeposit != null)
                _buildCostRow('Security deposit',
                    '\$${widget.item.securityDeposit!.toStringAsFixed(2)}'),
              const Divider(),
              _buildCostRow(
                'Total',
                '\$${totalCost.toStringAsFixed(2)}',
                isTotal: true,
              ),
            ] else ...[
              Column(
                children: [
                  Text(
                    'Select dates to see cost breakdown',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flash_on,
                            size: 16, color: Colors.orange[700]),
                        const SizedBox(width: 6),
                        Text(
                          'Same day booking available!',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCostRow(String label, String amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? ColorConstants.primaryColor : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final totalCost = _calculateTotalCost();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Cost',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  totalCost > 0
                      ? '\$${totalCost.toStringAsFixed(2)}'
                      : 'Select dates',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ColorConstants.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: CustomButton(
              text: 'Proceed to Payment',
              onPressed: totalCost > 0 ? _proceedToPayment : null,
            ),
          ),
        ],
      ),
    );
  }
}
