import 'package:intl/intl.dart';

class RestingHeartRate {
  final DateTime date;
  final int value;

  RestingHeartRate({required this.date, required this.value});

  factory RestingHeartRate.fromJson(String dateString, Map<String, dynamic> json) {
    DateTime parsedDate;
    final String timeRaw = json["time"] ?? "00:00:00";

    try {
      if (timeRaw.contains('-') || timeRaw.contains('/')) {
        parsedDate = DateTime.parse(timeRaw);
      } else {
        parsedDate = DateFormat('yyyy-MM-dd HH:mm:ss').parse('$dateString $timeRaw');
      }
    } catch (e) {
      try {
        parsedDate = DateTime.parse(dateString);
      } catch (_) {
        parsedDate = DateTime.now();
      }
    }

    int rhrValue = 0;
    final dynamic rawValue = json["value"];

    if (rawValue != null) {
      if (rawValue is num) {
        rhrValue = rawValue.toDouble().round();
      } else if (rawValue is String) {
        final double? parsedDouble = double.tryParse(rawValue);
        if (parsedDouble != null) {
          rhrValue = parsedDouble.round();
        }
      }
    }

    return RestingHeartRate(
      date: parsedDate,
      value: rhrValue,
    );
  }

  @override
  String toString() {
    return 'RestingHeartRate(date: $date, value: $value)';
  }
}