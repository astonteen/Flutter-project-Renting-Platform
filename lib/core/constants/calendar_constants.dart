import 'package:flutter/material.dart';
import 'package:rent_ease/core/constants/color_constants.dart';

class CalendarConstants {
  // Animation durations
  static const Duration fadeAnimationDuration = Duration(milliseconds: 300);
  static const Duration slideAnimationDuration = Duration(milliseconds: 400);

  // Calendar dimensions
  static const double calendarDayHeight = 48.0;
  static const double calendarDayMargin = 2.0;
  static const double calendarBorderRadius = 8.0;
  static const double headerPadding = 20.0;
  static const double cardBorderRadius = 16.0;
  static const double legendItemSize = 16.0;

  // Spacing
  static const double smallSpacing = 4.0;
  static const double mediumSpacing = 8.0;
  static const double largeSpacing = 12.0;
  static const double extraLargeSpacing = 16.0;
  static const double sectionSpacing = 20.0;

  // Font sizes
  static const double headerTitleSize = 28.0;
  static const double headerSubtitleSize = 16.0;
  static const double monthYearSize = 20.0;
  static const double dayNumberSize = 16.0;
  static const double weekdaySize = 14.0;
  static const double legendSize = 14.0;
  static const double sectionTitleSize = 20.0;
  static const double cardTitleSize = 18.0;
  static const double bodyTextSize = 14.0;
  static const double captionSize = 12.0;
  static const double statusBadgeSize = 10.0;

  // Colors
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color surfaceColor = Colors.white;
  static const Color headerBackgroundColor = Colors.white;
  static const Color primaryTextColor = Color(0xFF1E293B);
  static const Color secondaryTextColor = Color(0xFF64748B);
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color shadowColor = Colors.black;

  // Calendar-specific colors - Enhanced availability indicators
  // Priority order: purple (auto-block) > orange (manual block) > red (fully booked) > yellow (partially booked) > green (available)

  // Availability background colors
  static const Color availableBackgroundColor =
      Color(0xFFDCFCE7); // Light green
  static const Color partiallyBookedBackgroundColor =
      Color(0xFFFEF3C7); // Light yellow
  static const Color fullyBookedBackgroundColor =
      Color(0xFFFECDD3); // Light red
  static const Color manualBlockBackgroundColor =
      Color(0xFFFED7AA); // Light orange
  static const Color autoBlockBackgroundColor =
      Color(0xFFE9D5FF); // Light purple
  static const Color pastDateBackgroundColor =
      Color(0xFFF1F5F9); // Light gray for past dates

  // Legacy colors for backward compatibility
  static const Color bookedBackgroundColor = fullyBookedBackgroundColor;
  static Color partialBookedBackgroundColor = partiallyBookedBackgroundColor;

  // Text colors for each state
  static const Color availableTextColor = Color(0xFF065F46); // Dark green
  static const Color partiallyBookedTextColor =
      Color(0xFF92400E); // Dark yellow
  static const Color fullyBookedTextColor = Color(0xFF991B1B); // Dark red
  static const Color manualBlockTextColor = Color(0xFFC2410C); // Dark orange
  static const Color autoBlockTextColor = Color(0xFF7C2D12); // Dark purple
  static const Color pastDateTextColor =
      Color(0xFF94A3B8); // Light gray for past dates

  // Border and selection colors
  static const Color todayBorderColor = Colors.blue;
  static const Color selectedBorderColor = ColorConstants.primaryColor;

  // Badge colors
  static const Color badgeBackgroundColor =
      Color(0xCC000000); // Semi-transparent black
  static const Color badgeTextColor = Colors.white;

  // Status colors
  static const Color confirmedColor = Colors.green;
  static const Color pendingColor = Colors.orange;
  static const Color inProgressColor = Colors.blue;
  static const Color completedColor = Colors.purple;
  static const Color cancelledColor = Colors.red;
  static const Color errorColor = Colors.red;
  static const Color successColor = ColorConstants.successColor;

  // Shadow configurations
  static List<BoxShadow> get cardShadow => [
        const BoxShadow(
          color: Color.fromRGBO(0, 0, 0, 0.04),
          blurRadius: 10,
          offset: Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get headerShadow => [
        const BoxShadow(
          color: Color.fromRGBO(0, 0, 0, 0.05),
          blurRadius: 10,
          offset: Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get lightShadow => [
        const BoxShadow(
          color: Color.fromRGBO(0, 0, 0, 0.02),
          blurRadius: 6,
          offset: Offset(0, 2),
        ),
      ];

  // Border configurations
  static Border get defaultBorder => Border.all(color: borderColor);
  static Border get selectedBorder =>
      Border.all(color: selectedBorderColor, width: 2);
  static Border get todayBorder =>
      Border.all(color: todayBorderColor, width: 2);

  // Text styles
  static const TextStyle headerTitleStyle = TextStyle(
    fontSize: headerTitleSize,
    fontWeight: FontWeight.bold,
    color: primaryTextColor,
    letterSpacing: -0.5,
  );

  static TextStyle headerSubtitleStyle = TextStyle(
    fontSize: headerSubtitleSize,
    color: Colors.grey[600],
    fontWeight: FontWeight.w400,
  );

  static const TextStyle monthYearStyle = TextStyle(
    fontSize: monthYearSize,
    fontWeight: FontWeight.w600,
    color: primaryTextColor,
  );

  static const TextStyle dayNumberStyle = TextStyle(
    fontSize: dayNumberSize,
    fontWeight: FontWeight.w500,
    color: primaryTextColor,
  );

  static const TextStyle selectedDayStyle = TextStyle(
    fontSize: dayNumberSize,
    fontWeight: FontWeight.w600,
    color: primaryTextColor,
  );

  static const TextStyle bookedDayStyle = TextStyle(
    fontSize: dayNumberSize,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );

  static TextStyle weekdayStyle = TextStyle(
    fontSize: weekdaySize,
    fontWeight: FontWeight.w600,
    color: Colors.grey[600],
  );

  static TextStyle legendStyle = TextStyle(
    fontSize: legendSize,
    color: Colors.grey[700],
  );

  static const TextStyle sectionTitleStyle = TextStyle(
    fontSize: sectionTitleSize,
    fontWeight: FontWeight.w600,
    color: primaryTextColor,
  );

  static const TextStyle cardTitleStyle = TextStyle(
    fontSize: cardTitleSize,
    fontWeight: FontWeight.w600,
    color: primaryTextColor,
  );

  static TextStyle bodyTextStyle = TextStyle(
    fontSize: bodyTextSize,
    color: Colors.grey[600],
  );

  static const TextStyle statusBadgeStyle = TextStyle(
    fontSize: statusBadgeSize,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // Weekday labels
  static const List<String> weekdayLabels = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat'
  ];

  // Legend items
  static const List<LegendItem> legendItems = [
    LegendItem(
        label: 'Available',
        color: availableBackgroundColor,
        textColor: primaryTextColor),
    LegendItem(
        label: 'Booked', color: bookedBackgroundColor, textColor: Colors.white),
    LegendItem(
        label: 'Partial',
        color: null,
        textColor: primaryTextColor), // Dynamic color
    LegendItem(
        label: 'Manual Block',
        color: null,
        textColor: primaryTextColor), // Dynamic color
    LegendItem(
        label: 'Auto-Block',
        color: null,
        textColor: primaryTextColor), // Dynamic color
  ];

  // Messages
  static const String calendarTitle = 'Rental Calendar';
  static const String calendarSubtitle = 'Manage your rental schedule';
  static const String selectPropertyLabel = 'Select Property';
  static const String availabilityLegendTitle = 'Availability Legend';
  static const String bookingsTitle = 'Bookings';
  static const String noBookingsTitle = 'No bookings for this date';
  static const String noBookingsSubtitle =
      'This date is available for new bookings';
  static const String loadingAvailability = 'Loading availability...';
  static const String todayTooltip = 'Go to Today';
  static const String refreshTooltip = 'Refresh';
  static const String dateBlockedMessage = 'Date blocked for maintenance';
  static const String dateUnblockedMessage = 'Date unblocked';
  static const String noManualBlocksMessage =
      'No manual blocks found on this date';
  static const String failedToBlockMessage = 'Failed to block date';
  static const String failedToUnblockMessage = 'Failed to unblock date';
  static const String failedToLoadMessage = 'Failed to load availability';
  static const String selectListingFirstMessage =
      'Please select a listing first';

  // Icon sizes
  static const double headerIconSize = 20.0;
  static const double cardIconSize = 20.0;
  static const double smallIconSize = 16.0;

  // Batch processing
  static const int availabilityBatchSize = 7; // Days to process at once
  static const int maxCacheSize = 50; // Maximum cached months per listing
}

class LegendItem {
  final String label;
  final Color? color; // null means dynamic color
  final Color textColor;

  const LegendItem({
    required this.label,
    required this.color,
    required this.textColor,
  });
}
