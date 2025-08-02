import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rent_ease/core/constants/color_constants.dart';

class MonthPagerCalendar extends StatefulWidget {
  final DateTime selectedDate;
  final DateTime focusedDate;
  final Function(DateTime) onDateSelected;
  final Function(DateTime) onMonthChanged;
  final Widget Function(DateTime) cellBuilder;
  final String? selectedListingName;
  final VoidCallback? onShowColorLegend;

  const MonthPagerCalendar({
    super.key,
    required this.selectedDate,
    required this.focusedDate,
    required this.onDateSelected,
    required this.onMonthChanged,
    required this.cellBuilder,
    this.selectedListingName,
    this.onShowColorLegend,
  });

  @override
  State<MonthPagerCalendar> createState() => _MonthPagerCalendarState();
}

class _MonthPagerCalendarState extends State<MonthPagerCalendar> {
  late PageController _pageController;
  late DateTime _currentMonth;
  final DateTime _initialMonth =
      DateTime(2023, 1); // Starting month for calendar
  final DateTime _finalMonth = DateTime(2030, 12); // Ending month for calendar

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(widget.focusedDate.year, widget.focusedDate.month);
    final initialPage = _getMonthIndex(_currentMonth);
    _pageController = PageController(initialPage: initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _getMonthIndex(DateTime month) {
    final startYear = _initialMonth.year;
    final startMonth = _initialMonth.month;
    final targetYear = month.year;
    final targetMonth = month.month;

    return (targetYear - startYear) * 12 + (targetMonth - startMonth);
  }

  DateTime _getMonthFromIndex(int index) {
    final startYear = _initialMonth.year;
    final startMonth = _initialMonth.month;

    final totalMonths = startMonth + index - 1;
    final year = startYear + (totalMonths ~/ 12);
    final month = (totalMonths % 12) + 1;

    return DateTime(year, month);
  }

  int _getTotalPages() {
    return _getMonthIndex(_finalMonth) - _getMonthIndex(_initialMonth) + 1;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildCalendarHeader(),
        const SizedBox(height: 16),
        _buildMonthPager(),
      ],
    );
  }

  Widget _buildCalendarHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMMM yyyy').format(_currentMonth),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: ColorConstants.textColor,
                      ),
                ),
                if (widget.selectedListingName != null)
                  Text(
                    'Viewing: ${widget.selectedListingName}',
                    style: const TextStyle(
                      color: ColorConstants.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          Row(
            children: [
              if (widget.onShowColorLegend != null)
                IconButton(
                  onPressed: widget.onShowColorLegend,
                  icon: const Icon(Icons.info_outline),
                  tooltip: 'Color Legend',
                  style: IconButton.styleFrom(
                    backgroundColor: ColorConstants.primaryColor.withAlpha(25),
                    foregroundColor: ColorConstants.primaryColor,
                  ),
                ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _navigateToMonth(-1),
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous Month',
              ),
              IconButton(
                onPressed: () => _navigateToMonth(1),
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next Month',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthPager() {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        itemCount: _getTotalPages(),
        itemBuilder: (context, index) {
          final month = _getMonthFromIndex(index);
          return _buildMonthView(month);
        },
      ),
    );
  }

  Widget _buildMonthView(DateTime month) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final firstWeekday = firstDayOfMonth.weekday;

    // Calculate starting position (Sunday = 0, Monday = 1, etc.)
    final startingPosition = firstWeekday % 7;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildDaysOfWeekHeader(),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: 42, // 6 weeks × 7 days
              itemBuilder: (context, index) {
                final dayIndex = index - startingPosition;

                if (dayIndex < 0 || dayIndex >= daysInMonth) {
                  // Empty cell for days outside current month
                  return const SizedBox.shrink();
                }

                final date = DateTime(month.year, month.month, dayIndex + 1);
                return widget.cellBuilder(date);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysOfWeekHeader() {
    const weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Row(
      children: weekdays
          .map((day) => Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(
                      color: ColorConstants.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  void _navigateToMonth(int direction) {
    final currentPage = _pageController.page?.round() ?? 0;
    final newPage = (currentPage + direction).clamp(0, _getTotalPages() - 1);

    _pageController.animateToPage(
      newPage,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int page) {
    final newMonth = _getMonthFromIndex(page);
    setState(() {
      _currentMonth = newMonth;
    });
    widget.onMonthChanged(newMonth);
  }

  void jumpToMonth(DateTime month) {
    final targetPage = _getMonthIndex(month);
    if (targetPage >= 0 && targetPage < _getTotalPages()) {
      _pageController.animateToPage(
        targetPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
}
