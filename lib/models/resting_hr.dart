// /data/v1/resting_heart_rate/patients/{username}/daterange/start_date/{start_date}/end_date/{end_date}/
// /data/v1/resting_heart_rate/patients/{username}/day/{day}/

import 'package:intl/intl.dart';

class RestingHR {
  final DateTime time;
  final int value;

  RestingHR({required this.time, required this.value});

  RestingHR.fromJson(String date, Map<String, dynamic> json) :
      time = DateFormat('yyyy-MM-dd HH:mm:ss').parse('$date ${json["time"]}'),
      value = int.parse(json["value"]);

  @override
  String toString() {
    return 'RestingHR(time: $time, value: $value)';
  }//toString
}//RestingHR