import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:buzzed_buddy/providers/storico_provider.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _selectedDate;
  late DateTime _focusedDate;

  @override
  void initState() {
    super.initState();
    Intl.defaultLocale = 'en_GB';
    _selectedDate = DateTime.now();
    _focusedDate = DateTime.now();
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 196, 0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Month: ${DateFormat.yMMM('en_GB').format(_focusedDate)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: const Color.fromARGB(255, 255, 196, 0),
                          minimumSize: const Size(150, 45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _focusedDate = DateTime(
                              _focusedDate.year,
                              _focusedDate.month - 1,
                            );
                          });
                        },
                        child: const Text('← PREVIOUS MONTH'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: const Color.fromARGB(255, 255, 196, 0),
                          minimumSize: const Size(150, 45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _focusedDate = DateTime(
                              _focusedDate.year,
                              _focusedDate.month + 1,
                            );
                          });
                        },
                        child: const Text('NEXT MONTH →'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _buildCalendarGrid(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black, width: 1.5),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Date selected:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color.fromARGB(255, 255, 196, 0),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat.yMMMMEEEEd('en_GB').format(_selectedDate),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 255, 196, 0),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Builder(builder: (context) {
                          final bac = Provider.of<StoricoProvider>(context)
                              .bacDelGiorno(_selectedDate);
                          return Text(
                            bac == null
                                ? 'No drinks logged'
                                : 'Peak BAC: ${bac.toStringAsFixed(2)} g/L',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color.fromARGB(255, 255, 196, 0),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth =
        DateTime(_focusedDate.year, _focusedDate.month, 1);
    final lastDayOfMonth =
        DateTime(_focusedDate.year, _focusedDate.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday = firstDayOfMonth.weekday;

    final days = <DateTime>[];

    
    for (int i = firstWeekday - 1; i > 0; i--) {
      days.add(firstDayOfMonth.subtract(Duration(days: i)));
    }

    
    for (int i = 1; i <= daysInMonth; i++) {
      days.add(DateTime(_focusedDate.year, _focusedDate.month, i));
    }

   
    final remainingDays = 42 - days.length;
    for (int i = 1; i <= remainingDays; i++) {
      days.add(DateTime(_focusedDate.year, _focusedDate.month + 1, i));
    }

    final storico = Provider.of<StoricoProvider>(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              'Mon',
              'Tue',
              'Wed',
              'Thu',
              'Fri',
              'Sat',
              'Sun'
            ]
                .map(
                  (day) => Center(
                    child: Text(
                      day,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: days.map((day) => _buildDayCell(day, storico)).toList(),
          ),
        ],
      ),
    );
  }


  Color _fillColor(DateTime day, StoricoProvider storico) {
    if (day.month != _focusedDate.month) return Colors.grey[300]!;
    final bac = storico.bacDelGiorno(day);
    if (bac == null) return Colors.white;
    if (bac < 0.5) return Colors.green;
    if (bac < 1.5) return Colors.orange;
    return Colors.red;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _buildDayCell(DateTime day, StoricoProvider storico) {
    final fill = _fillColor(day, storico);
    final outOfMonth = day.month != _focusedDate.month;
    final isSelected = _isSameDay(day, _selectedDate);
    final isToday = _isSameDay(day, DateTime.now());

    Color borderColor;
    double borderWidth;
    if (isSelected) {
      borderColor = const Color(0xFF0E9C94);
      borderWidth = 3;
    } else if (isToday) {
      borderColor = Colors.black;
      borderWidth = 2;
    } else {
      borderColor = outOfMonth ? Colors.black.withValues(alpha: 0.2) : Colors.black;
      borderWidth = 1;
    }

    final coloredFill = !outOfMonth && fill != Colors.white;
    final textColor =
        outOfMonth ? Colors.grey : (coloredFill ? Colors.white : Colors.black);

    return GestureDetector(
      onTap: () => setState(() => _selectedDate = day),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: Center(
          child: Text(
            day.day.toString(),
            style: TextStyle(
              color: textColor,
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
