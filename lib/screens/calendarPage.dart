import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

   @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _selectedDate;
  late DateTime _focusedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _focusedDate = DateTime.now();
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const color.fromRGBO(255, 255, 196, 0),
      appBar: AppBar(
        title: const Text('Calendario'),
        backgroundColor: const color.fromRGBO(255, 255, 196, 0),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Mese: ${DateFormat.yMMM('it_IT').format(_focusedDate)}',
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
                        onPressed: () {
                          setState(() {
                            _focusedDate = DateTime(
                              _focusedDate.year,
                              _focusedDate.month - 1,
                            );
                          });
                        },
                        child: const Text('← MESE PRECEDENTE'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _focusedDate = DateTime(
                              _focusedDate.year,
                              _focusedDate.month + 1,
                            );
                          });
                        },
                        child: const Text('PROSSIMO MESE →'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Calendar grid
            _buildCalendarGrid(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Data selezionata:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat.yMMMMEEEEd('it_IT').format(_selectedDate),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Torna indietro'),
                  ),
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

    // Add previous month's days
    for (int i = firstWeekday - 1; i > 0; i--) {
      days.add(firstDayOfMonth.subtract(Duration(days: i)));
    }

    // Add current month's days
    for (int i = 1; i <= daysInMonth; i++) {
      days.add(DateTime(_focusedDate.year, _focusedDate.month, i));
    }

    // Add next month's days
    final remainingDays = 42 - days.length;
    for (int i = 1; i <= remainingDays; i++) {
      days.add(DateTime(_focusedDate.year, _focusedDate.month + 1, i));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // Weekday headers
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              'Lun',
              'Mar',
              'Mer',
              'Gio',
              'Ven',
              'Sab',
              'Dom'
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
          // Calendar days
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: days
                .map(
                  (day) => GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDate = day;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: day.month != _focusedDate.month
                            ? Colors.grey[300]
                            : (_selectedDate.day == day.day &&
                                    _selectedDate.month == day.month &&
                                    _selectedDate.year == day.year)
                                ? Colors.blue
                                : (day.day == DateTime.now().day &&
                                        day.month == DateTime.now().month &&
                                        day.year == DateTime.now().year)
                                    ? Colors.orange
                                    : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: day.month != _focusedDate.month
                              ? Colors.transparent
                              : Colors.grey,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          day.day.toString(),
                          style: TextStyle(
                            color: day.month != _focusedDate.month
                                ? Colors.grey
                                : (_selectedDate.day == day.day &&
                                        _selectedDate.month == day.month &&
                                        _selectedDate.year == day.year)
                                    ? Colors.white
                                    : Colors.black,
                            fontWeight: day.day == DateTime.now().day &&
                                    day.month == DateTime.now().month &&
                                    day.year == DateTime.now().year
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
