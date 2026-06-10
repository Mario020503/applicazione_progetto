import 'package:intl/intl.dart';

class HeartRate {
  final DateTime time;
  final int value;

  HeartRate({required this.time, required this.value});

  HeartRate.fromJson(String date, Map<String, dynamic> json) :
      time = DateFormat('yyyy-MM-dd HH:mm:ss').parse('$date ${json["time"]}'),
      value = int.parse(json["value"]);

  @override
  String toString() {
    return 'HeartRate(time: $time, value: $value)';
  }//toString
}//HeartRate