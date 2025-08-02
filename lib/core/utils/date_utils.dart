/// Date utilities for calendar operations and date normalization
class DateUtils {
  /// Normalizes a DateTime to start of day (00:00:00.000)
  static DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Gets the start of the month for a given date
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Gets the end of the month for a given date
  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  /// Gets the start of the next month
  static DateTime nextMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 1);
  }

  /// Gets the start of the previous month
  static DateTime previousMonth(DateTime date) {
    return DateTime(date.year, date.month - 1, 1);
  }

  /// Checks if two dates are on the same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Checks if a date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return isSameDay(date, now);
  }

  /// Gets today at start of day
  static DateTime get today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Gets the first day of the week for calendar grid calculation
  static int getFirstDayOfWeek(DateTime firstDayOfMonth) {
    // Convert to 0-6 where Sunday = 0
    return firstDayOfMonth.weekday % 7;
  }

  /// Gets the number of days in a month
  static int getDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  /// Creates a date range from start to end (inclusive)
  static List<DateTime> getDateRange(DateTime start, DateTime end) {
    final dates = <DateTime>[];
    var current = normalizeDate(start);
    final normalizedEnd = normalizeDate(end);

    while (current.isBefore(normalizedEnd) ||
        current.isAtSameMomentAs(normalizedEnd)) {
      dates.add(current);
      current = current.add(const Duration(days: 1));
    }

    return dates;
  }

  /// Checks if a date falls within a range (inclusive)
  static bool isDateInRange(DateTime date, DateTime start, DateTime end) {
    final normalizedDate = normalizeDate(date);
    final normalizedStart = normalizeDate(start);
    final normalizedEnd = normalizeDate(end);

    return (normalizedDate.isAtSameMomentAs(normalizedStart) ||
            normalizedDate.isAfter(normalizedStart)) &&
        (normalizedDate.isAtSameMomentAs(normalizedEnd) ||
            normalizedDate.isBefore(normalizedEnd));
  }

  /// Formats a date range for display
  static String formatDateRange(DateTime start, DateTime end) {
    if (isSameDay(start, end)) {
      return 'Full day rental';
    }

    // Simple format for now - can be enhanced with intl
    return '${start.month}/${start.day} - ${end.month}/${end.day}';
  }

  /// Gets all dates in a month as normalized DateTime objects
  static List<DateTime> getDatesInMonth(DateTime month) {
    final firstDay = startOfMonth(month);
    final lastDay = endOfMonth(month);
    return getDateRange(firstDay, lastDay);
  }

  /// Gets the week containing a specific date
  static List<DateTime> getWeekContaining(DateTime date) {
    final normalized = normalizeDate(date);
    final weekday = normalized.weekday % 7; // Sunday = 0
    final startOfWeek = normalized.subtract(Duration(days: weekday));
    return getDateRange(startOfWeek, startOfWeek.add(const Duration(days: 6)));
  }

  /// Calculates the number of months between two dates
  static int monthsBetween(DateTime start, DateTime end) {
    return (end.year - start.year) * 12 + (end.month - start.month);
  }

  /// Gets a calendar grid for a month (includes leading/trailing dates)
  static List<List<DateTime?>> getCalendarGrid(DateTime month) {
    final firstDayOfMonth = startOfMonth(month);

    final firstDayWeekday = getFirstDayOfWeek(firstDayOfMonth);
    final daysInMonth = getDaysInMonth(month);

    final weeks = <List<DateTime?>>[];
    var currentWeek = <DateTime?>[];

    // Add leading empty cells
    for (int i = 0; i < firstDayWeekday; i++) {
      currentWeek.add(null);
    }

    // Add days of the month
    for (int day = 1; day <= daysInMonth; day++) {
      if (currentWeek.length == 7) {
        weeks.add(currentWeek);
        currentWeek = <DateTime?>[];
      }
      currentWeek.add(DateTime(month.year, month.month, day));
    }

    // Add trailing empty cells
    while (currentWeek.length < 7) {
      currentWeek.add(null);
    }
    weeks.add(currentWeek);

    return weeks;
  }
}
