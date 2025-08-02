import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rent_ease/core/constants/calendar_constants.dart';
import 'package:rent_ease/core/utils/date_utils.dart' as app_date_utils;
import 'package:rent_ease/features/listing/presentation/bloc/calendar_availability_bloc.dart';

typedef DateSelectionCallback = void Function(DateTime date);
typedef DateActionCallback = void Function(DateTime date);

class CalendarGridWidget extends StatelessWidget {
  final DateTime focusedDate;
  final DateTime selectedDate;
  final Map<DateTime, ItemAvailability> availabilityMap;
  final DateSelectionCallback onDateSelected;
  final DateActionCallback onDateLongPressed;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  const CalendarGridWidget({
    super.key,
    required this.focusedDate,
    required this.selectedDate,
    required this.availabilityMap,
    required this.onDateSelected,
    required this.onDateLongPressed,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        CalendarConstants.sectionSpacing,
        CalendarConstants.mediumSpacing,
        CalendarConstants.sectionSpacing,
        CalendarConstants.extraLargeSpacing,
      ),
      decoration: BoxDecoration(
        color: CalendarConstants.surfaceColor,
        borderRadius: BorderRadius.circular(CalendarConstants.cardBorderRadius),
        boxShadow: CalendarConstants.cardShadow,
      ),
      child: Column(
        children: [
          _CalendarHeader(
            focusedDate: focusedDate,
            onPreviousMonth: onPreviousMonth,
            onNextMonth: onNextMonth,
          ),
          _CalendarGrid(
            focusedDate: focusedDate,
            selectedDate: selectedDate,
            availabilityMap: availabilityMap,
            onDateSelected: onDateSelected,
            onDateLongPressed: onDateLongPressed,
          ),
          _AvailabilityLegend(),
        ],
      ),
    );
  }
}

class _CalendarHeader extends StatelessWidget {
  final DateTime focusedDate;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  const _CalendarHeader({
    required this.focusedDate,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(CalendarConstants.sectionSpacing),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 24),
            onPressed: onPreviousMonth,
            color: CalendarConstants.secondaryTextColor,
          ),
          Text(
            DateFormat('MMMM yyyy').format(focusedDate),
            style: CalendarConstants.monthYearStyle,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, size: 24),
            onPressed: onNextMonth,
            color: CalendarConstants.secondaryTextColor,
          ),
        ],
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final DateTime focusedDate;
  final DateTime selectedDate;
  final Map<DateTime, ItemAvailability> availabilityMap;
  final DateSelectionCallback onDateSelected;
  final DateActionCallback onDateLongPressed;

  const _CalendarGrid({
    required this.focusedDate,
    required this.selectedDate,
    required this.availabilityMap,
    required this.onDateSelected,
    required this.onDateLongPressed,
  });

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = app_date_utils.DateUtils.startOfMonth(focusedDate);

    final firstDayWeekday =
        app_date_utils.DateUtils.getFirstDayOfWeek(firstDayOfMonth);
    final daysInMonth = app_date_utils.DateUtils.getDaysInMonth(focusedDate);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CalendarConstants.sectionSpacing,
        0,
        CalendarConstants.sectionSpacing,
        CalendarConstants.sectionSpacing,
      ),
      child: Column(
        children: [
          // Weekday headers
          Row(
            children: CalendarConstants.weekdayLabels
                .map((day) => Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: CalendarConstants.largeSpacing,
                          ),
                          child: Text(
                            day,
                            style: CalendarConstants.weekdayStyle,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          // Calendar grid
          for (int week = 0; week < 6; week++)
            Row(
              children: List.generate(7, (dayOfWeek) {
                final dayNumber = week * 7 + dayOfWeek + 1 - firstDayWeekday;
                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return const Expanded(
                    child:
                        SizedBox(height: CalendarConstants.calendarDayHeight),
                  );
                }

                final date =
                    DateTime(focusedDate.year, focusedDate.month, dayNumber);
                return Expanded(
                  child: _CalendarDay(
                    date: date,
                    selectedDate: selectedDate,
                    availability: availabilityMap[
                        app_date_utils.DateUtils.normalizeDate(date)],
                    onTap: () => onDateSelected(date),
                    onLongPress: () => onDateLongPressed(date),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }
}

class _CalendarDay extends StatelessWidget {
  final DateTime date;
  final DateTime selectedDate;
  final ItemAvailability? availability;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _CalendarDay({
    required this.date,
    required this.selectedDate,
    required this.availability,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = app_date_utils.DateUtils.isSameDay(date, selectedDate);
    final isToday = app_date_utils.DateUtils.isToday(date);
    final isPastDate = date.isBefore(DateTime.now());

    final backgroundColor = _getBackgroundColor();
    final textColor = _getTextColor();
    final border = _getBorder(isSelected, isToday);

    return GestureDetector(
      onTap: isPastDate ? null : onTap,
      onLongPress: isPastDate ? null : onLongPress,
      child: Container(
        height: CalendarConstants.calendarDayHeight,
        margin: const EdgeInsets.all(CalendarConstants.calendarDayMargin),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius:
              BorderRadius.circular(CalendarConstants.calendarBorderRadius),
          border: border,
        ),
        child: Stack(
          children: [
            // Day number
            Center(
              child: Text(
                '${date.day}',
                style: _getTextStyle(isSelected, isToday, textColor),
              ),
            ),
            // Simple availability indicator
            if (availability != null && !isPastDate)
              Positioned(
                right: 4,
                top: 4,
                child: _buildAvailabilityIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityIndicator() {
    final freeUnits = availability!.totalQuantity -
        availability!.bookedQuantity -
        availability!.blockedQuantity;

    // Simple color dot based on availability
    Color indicatorColor;
    if (availability!.blocks.isNotEmpty) {
      indicatorColor = Colors.orange; // Blocked
    } else if (freeUnits == 0) {
      indicatorColor = Colors.red; // Fully booked
    } else if (freeUnits < availability!.totalQuantity) {
      indicatorColor = Colors.yellow; // Partially booked
    } else {
      return const SizedBox.shrink(); // Fully available - no indicator needed
    }

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: indicatorColor,
        shape: BoxShape.circle,
      ),
    );
  }

  Color _getBackgroundColor() {
    // Past dates - simple gray
    if (date.isBefore(DateTime.now())) {
      return Colors.grey[100]!;
    }

    // No availability data - default light background
    if (availability == null) {
      return Colors.green[50]!;
    }

    // Simple status-based colors
    final freeUnits = availability!.totalQuantity -
        availability!.bookedQuantity -
        availability!.blockedQuantity;

    if (availability!.blocks.isNotEmpty) {
      return Colors.orange[50]!; // Blocked
    } else if (freeUnits == 0) {
      return Colors.red[50]!; // Fully booked
    } else if (freeUnits < availability!.totalQuantity) {
      return Colors.yellow[50]!; // Partially booked
    } else {
      return Colors.green[50]!; // Available
    }
  }

  Color _getTextColor() {
    // Past dates - muted text
    if (date.isBefore(DateTime.now())) {
      return Colors.grey[500]!;
    }

    // Dark text for all other states
    return Colors.grey[800]!;
  }

  Border? _getBorder(bool isSelected, bool isToday) {
    if (isSelected) {
      return Border.all(
        color: CalendarConstants.selectedBorderColor,
        width: 2,
      );
    } else if (isToday) {
      return Border.all(
        color: CalendarConstants.todayBorderColor,
        width: 2,
      );
    }
    return null;
  }

  TextStyle _getTextStyle(bool isSelected, bool isToday, Color textColor) {
    return CalendarConstants.dayNumberStyle.copyWith(
      color: textColor,
      fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
    );
  }
}

class _AvailabilityLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        CalendarConstants.sectionSpacing,
        0,
        CalendarConstants.sectionSpacing,
        CalendarConstants.sectionSpacing,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            CalendarConstants.availabilityLegendTitle,
            style: CalendarConstants.cardTitleStyle,
          ),
          SizedBox(height: CalendarConstants.largeSpacing),
          Wrap(
            spacing: CalendarConstants.extraLargeSpacing,
            runSpacing: CalendarConstants.mediumSpacing,
            children: [
              _LegendItem(
                label: 'Available',
                color: CalendarConstants.availableBackgroundColor,
                textColor: CalendarConstants.availableTextColor,
                badge: 'n/n',
                hasBorder: true,
              ),
              _LegendItem(
                label: 'Partially Booked',
                color: CalendarConstants.partiallyBookedBackgroundColor,
                textColor: CalendarConstants.partiallyBookedTextColor,
                badge: 'x/n',
              ),
              _LegendItem(
                label: 'Fully Booked',
                color: CalendarConstants.fullyBookedBackgroundColor,
                textColor: CalendarConstants.fullyBookedTextColor,
                badge: '0/n',
              ),
              _LegendItem(
                label: 'Manual Block',
                color: CalendarConstants.manualBlockBackgroundColor,
                textColor: CalendarConstants.manualBlockTextColor,
                badge: 'MB',
              ),
              _LegendItem(
                label: 'Return Buffer',
                color: CalendarConstants.autoBlockBackgroundColor,
                textColor: CalendarConstants.autoBlockTextColor,
                badge: 'RB',
              ),
            ],
          ),
          SizedBox(height: CalendarConstants.mediumSpacing),
          Text(
            'Badges show: free units/total (x/n) or block type (RB/MB)',
            style: TextStyle(
              fontSize: CalendarConstants.captionSize,
              color: CalendarConstants.secondaryTextColor,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final String badge;
  final bool hasBorder;

  const _LegendItem({
    required this.label,
    required this.color,
    required this.textColor,
    required this.badge,
    this.hasBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: CalendarConstants.legendItemSize,
          height: CalendarConstants.legendItemSize,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: hasBorder
                ? Border.all(color: CalendarConstants.borderColor)
                : null,
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  '1',
                  style: TextStyle(
                    fontSize: 8,
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                  decoration: BoxDecoration(
                    color: CalendarConstants.badgeBackgroundColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      fontSize: 6,
                      color: CalendarConstants.badgeTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: CalendarConstants.mediumSpacing),
        Text(
          label,
          style: const TextStyle(
            fontSize: CalendarConstants.legendSize,
            color: CalendarConstants.primaryTextColor,
          ),
        ),
      ],
    );
  }
}
