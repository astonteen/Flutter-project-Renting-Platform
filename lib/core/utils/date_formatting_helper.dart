import 'package:intl/intl.dart';

class DateFormattingHelper {
  // Standard formats for consistency across lender screens
  static const String standardDateFormat = 'EEE, d MMM';
  static const String standardDateTimeFormat = 'EEE, d MMM • HH:mm';
  static const String shortTimeFormat = 'HH:mm';
  static const String fullDateFormat = 'EEEE, MMMM d, yyyy';
  static const String shortDateFormat = 'd MMM yyyy';

  /// Format date in standard lender screen format: "Mon, 15 Jan"
  static String formatStandardDate(DateTime date) {
    return DateFormat(standardDateFormat).format(date);
  }

  /// Format date and time in standard format: "Mon, 15 Jan • 14:30"
  static String formatStandardDateTime(DateTime dateTime) {
    return DateFormat(standardDateTimeFormat).format(dateTime);
  }

  /// Format time only: "14:30"
  static String formatTime(DateTime dateTime) {
    return DateFormat(shortTimeFormat).format(dateTime);
  }

  /// Format full date: "Monday, January 15, 2024"
  static String formatFullDate(DateTime date) {
    return DateFormat(fullDateFormat).format(date);
  }

  /// Format short date: "15 Jan 2024"
  static String formatShortDate(DateTime date) {
    return DateFormat(shortDateFormat).format(date);
  }

  /// Format relative time: "2h ago", "Just now", etc.
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return formatShortDate(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  /// Format date range: "15 Jan - 20 Jan"
  static String formatDateRange(DateTime startDate, DateTime endDate) {
    if (startDate.year == endDate.year && startDate.month == endDate.month) {
      // Same month: "15 - 20 Jan"
      return '${startDate.day} - ${endDate.day} ${DateFormat('MMM').format(endDate)}';
    } else if (startDate.year == endDate.year) {
      // Same year: "15 Jan - 20 Feb"
      return '${DateFormat('d MMM').format(startDate)} - ${DateFormat('d MMM').format(endDate)}';
    } else {
      // Different years: "15 Jan 2024 - 20 Feb 2025"
      return '${formatShortDate(startDate)} - ${formatShortDate(endDate)}';
    }
  }

  /// Format duration in human-readable format
  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  /// Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Check if date is tomorrow
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  /// Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  /// Format with relative context: "Today", "Tomorrow", "Yesterday", or standard format
  static String formatWithContext(DateTime date) {
    if (isToday(date)) {
      return 'Today';
    } else if (isTomorrow(date)) {
      return 'Tomorrow';
    } else if (isYesterday(date)) {
      return 'Yesterday';
    } else {
      return formatStandardDate(date);
    }
  }
}
