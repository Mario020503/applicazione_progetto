import 'package:intl/intl.dart';

class HeartRate {
  final DateTime time;
  final int value;

  HeartRate({required this.time, required this.value});

  factory HeartRate.fromJson(String dateString, Map<String, dynamic> json) {
    DateTime parsedTime;
    final String timeRaw = json["time"] ?? "00:00:00";

    // 1. Parsing sicuro del tempo
    try {
      if (timeRaw.contains('-')) {
        parsedTime = DateFormat('yyyy-MM-dd HH:mm:ss').parse(timeRaw);
      } else {
        parsedTime = DateFormat('yyyy-MM-dd HH:mm:ss').parse('$dateString $timeRaw');
      }
    } catch (e) {
      try {
        parsedTime = DateTime.parse(timeRaw.contains('-') ? timeRaw : '$dateString $timeRaw');
      } catch (_) {
        parsedTime = DateTime.parse(dateString);
      }
    }

    // 2. Estrazione sicura del valore (Previene il crash se il dato è null)
    int bpmValue = 0;
    final dynamic rawValue = json["value"] ?? json["bpm"];

    if (rawValue != null && rawValue is num) {
      bpmValue = rawValue.toInt();
    }

    return HeartRate(
      time: parsedTime,
      value: bpmValue,
    );
  }

  @override
  String toString() {
    return 'HeartRate(time: $time, value: $value)';
  }
}