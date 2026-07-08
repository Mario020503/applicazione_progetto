import 'package:intl/intl.dart';


class RestingHeartRate {
  final DateTime date;
  final int value;

  RestingHeartRate({required this.date, required this.value});

  factory RestingHeartRate.fromJson(String dateString, Map<String, dynamic> json) {
    
    DateTime parsedDate;
    final String timeRaw = (json["time"]?.toString()) ?? "00:00:00";

    try {
      if (timeRaw.contains('-')) {
        parsedDate = DateTime.parse(timeRaw);
      } else {
        parsedDate = DateFormat('yyyy-MM-dd HH:mm:ss').parse('$dateString $timeRaw');
      }
    } catch (_) {
      try {
        parsedDate = DateTime.parse(dateString);
      } catch (_) {
        parsedDate = DateTime.fromMillisecondsSinceEpoch(0);
      }
    }


    int rhrValue = 0;
    final dynamic rawValue = json["value"];
    if (rawValue is num) {
      rhrValue = rawValue.toDouble().round();
    } else if (rawValue is String) {
      final double? parsed = double.tryParse(rawValue);
      if (parsed != null) rhrValue = parsed.round();
    }

   
    const int minPlausibleRhr = 30;
    const int maxPlausibleRhr = 130;
    if (rhrValue < minPlausibleRhr || rhrValue > maxPlausibleRhr) {
      rhrValue = 0;
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
