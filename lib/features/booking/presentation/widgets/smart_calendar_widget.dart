import 'package:flutter/material.dart';
// import 'package:table_calendar/table_calendar.dart';

class SmartCalendarWidget extends StatefulWidget {
  // TODO: Implement when table_calendar package is added
  // This widget requires: table_calendar package

  const SmartCalendarWidget({super.key});

  @override
  State<SmartCalendarWidget> createState() => _SmartCalendarWidgetState();
}

class _SmartCalendarWidgetState extends State<SmartCalendarWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Smart Calendar',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Container(
            height: 300,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'Calendar widget will be implemented\nwhen table_calendar package is added',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
