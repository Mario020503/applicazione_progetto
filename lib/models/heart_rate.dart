// /data/v1/heart_rate/patients/{username}/daterange/start_date/{start_date}/end_date/{end_date}/
// /data/v1/heart_rate/patients/{username}/day/{day}/

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