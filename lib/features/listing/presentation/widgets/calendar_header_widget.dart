import 'package:flutter/material.dart';
import 'package:rent_ease/core/constants/calendar_constants.dart';

class CalendarHeaderWidget extends StatelessWidget {
  const CalendarHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        CalendarConstants.sectionSpacing,
        CalendarConstants.sectionSpacing + 10,
        CalendarConstants.sectionSpacing,
        CalendarConstants.sectionSpacing + 5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            CalendarConstants.calendarTitle,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: CalendarConstants.primaryTextColor,
              letterSpacing: -0.8,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            CalendarConstants.calendarSubtitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
