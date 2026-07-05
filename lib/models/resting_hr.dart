import 'package:intl/intl.dart';

/// Frequenza cardiaca a riposo di una giornata. A valle si usa solo il campo
/// [value], come denominatore fisiologico nel fattore cronotropo e nella
/// timeline dello stress dentro DataProvider. Il campo [date] oggi non e'
/// letto da nessuno: e' tenuto per completezza del modello.
///
/// NOTA SULLA SENTINELLA: un value pari a 0 significa "dato non utilizzabile"
/// (mancante, illeggibile o fuori dal range fisiologico plausibile).
/// DataProvider tiene solo i resting con value maggiore di 0, quindi uno 0
/// fa subentrare la stima basata sui dati reali invece di un denominatore
/// assurdo.
class RestingHeartRate {
  final DateTime date;
  final int value;

  RestingHeartRate({required this.date, required this.value});

  factory RestingHeartRate.fromJson(String dateString, Map<String, dynamic> json) {
    // La data non e' l'asse dei calcoli (a valle conta solo value), quindi se
    // l'orario e' illeggibile non scartiamo il dato: lo ancoriamo al giorno
    // interrogato (dateString), che e' l'informazione corretta. Mai inventare
    // "oggi" con DateTime.now().
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

    // Estrazione del valore: numero oppure numero arrivato come stringa,
    // arrotondato (per una media a riposo arrotondare e' piu' corretto).
    int rhrValue = 0;
    final dynamic rawValue = json["value"];
    if (rawValue is num) {
      rhrValue = rawValue.toDouble().round();
    } else if (rawValue is String) {
      final double? parsed = double.tryParse(rawValue);
      if (parsed != null) rhrValue = parsed.round();
    }

    // Controllo di plausibilita' fisiologica. Una frequenza a riposo umana sta
    // ragionevolmente tra circa 30 e 130 bpm; fuori da questa finestra il dato
    // e' spazzatura del sensore. Lo marchiamo con 0 (sentinella) cosi' il
    // filtro value > 0 di DataProvider lo scarta e subentra la stima sui dati
    // reali. Le soglie sono volutamente larghe e regolabili.
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
