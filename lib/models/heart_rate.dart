import 'package:intl/intl.dart';

class HeartRate {
  final DateTime time;
  final int value;

  HeartRate({required this.time, required this.value});

  factory HeartRate.fromJson(String dateString, Map<String, dynamic> json) {
    DateTime? parsedTime;
    final String timeRaw = (json["time"]?.toString()) ?? "00:00:00";

    try {
      if (timeRaw.contains('-')) {
        parsedTime = DateFormat('yyyy-MM-dd HH:mm:ss').parse(timeRaw);
      } else {
        parsedTime = DateFormat('yyyy-MM-dd HH:mm:ss').parse('$dateString $timeRaw');
      }
    } catch (_) {
      try {
        parsedTime = DateTime.parse(timeRaw.contains('-') ? timeRaw : '$dateString $timeRaw');
      } catch (_) {
        parsedTime = null; // orario non interpretabile: dato da scartare
      }
    }


    int bpmValue = 0;
    final dynamic rawValue = json["value"] ?? json["bpm"];

    if (rawValue is num) {
      bpmValue = rawValue.toInt();
    } else if (rawValue is String) {
      final num? parsed = num.tryParse(rawValue);
      if (parsed != null) bpmValue = parsed.toInt();
    }

   
    if (parsedTime == null) {
      return HeartRate(time: DateTime.fromMillisecondsSinceEpoch(0), value: 0);
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
