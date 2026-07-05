import 'package:intl/intl.dart';

/// Mattone atomico della parte cardiaca: una lettura di battito, cioè un
/// istante piu' un valore in bpm. Da questo oggetto DataProvider ricava
/// RMSSD, baseline e stress, e i widget grafici disegnano le curve.
///
/// NOTA SUL FUSO ORARIO: gli istanti che arrivano da IMPACT vengono
/// interpretati come orario locale, senza alcuna conversione di zona. Se il
/// server restituisse i tempi in UTC, i grafici risulterebbero sfasati di
/// alcune ore. L'assunzione e' quindi "il server manda orario a muro locale".
///
/// NOTA SULLA SENTINELLA: un value pari a 0 significa "dato non utilizzabile"
/// (campo mancante, valore illeggibile oppure orario non interpretabile).
/// DataProvider tiene solo i punti con value maggiore di 0, quindi ogni dato
/// segnato con 0 viene automaticamente scartato a valle.
class HeartRate {
  final DateTime time;
  final int value;

  HeartRate({required this.time, required this.value});

  factory HeartRate.fromJson(String dateString, Map<String, dynamic> json) {
    // 1. Parsing dell'orario. Se nessun formato e' interpretabile lasciamo
    //    parsedTime a null: il dato verra' marcato come non utilizzabile.
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

    // 2. Estrazione del valore. Accettiamo sia numeri sia numeri arrivati
    //    come stringa (es. "72"), per essere coerenti con RestingHeartRate.
    int bpmValue = 0;
    final dynamic rawValue = json["value"] ?? json["bpm"];

    if (rawValue is num) {
      bpmValue = rawValue.toInt();
    } else if (rawValue is String) {
      final num? parsed = num.tryParse(rawValue);
      if (parsed != null) bpmValue = parsed.toInt();
    }

    // 3. Se l'orario non e' valido restituiamo un dato sentinella (value 0 e
    //    tempo all'epoch) che il filtro value > 0 di DataProvider scartera',
    //    invece di inventare la mezzanotte e falsare la timeline.
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
