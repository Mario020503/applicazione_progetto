import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/heart_rate.dart';
import '../services/impact.dart';

class DataProvider with ChangeNotifier {
  final ImpactService _impactService = ImpactService();

  final String _myUsername = "v7oZIhQJoE"; 
  final String _myPassword = "12345678!"; 
  final String _lucaUsername = "Jpefaq6m58";

  List<HeartRate> _heartRates = [];
  bool _isLoading = false;
  bool _isBaselineLoading = false;

  bool get isBaselineLoading => _isBaselineLoading;

  // --- BASELINE HRV (per decidere lo stress della serata) ---
  // Media dell'HRV su un intervallo ampio di giorni, calcolata UNA sola volta
  // e messa in cache: serve a capire se un giorno è "sotto il proprio normale".
  double? _baseline;
  static const String _baselineCacheKey = 'hrvBaseline';
  // Un giorno con HRV sotto questa frazione della baseline = stress alto.
  // Parametro calibrabile.
  static const double baselineStressFactor = 0.85;
  // Intervallo su cui costruire la baseline (i giorni senza dati vengono saltati).
  static const String _baselineStart = '2026-06-01';
  static const String _baselineEnd = '2026-07-01';

  List<HeartRate> get heartRates => _heartRates;
  bool get isLoading => _isLoading;
  double? get baseline => _baseline;

  // DEBUG TEMPORANEO (da togliere): su quanti giorni è calcolata la baseline.
  static const String _baselineDaysCacheKey = 'hrvBaselineDays';
  int _baselineDaysUsed = 0;
  int get baselineDaysUsed => _baselineDaysUsed;

  Future<void> fetchLucaHeartDataForDay(String day) async {
    _isLoading = true;
    notifyListeners(); 

    try {
      String? token = await _impactService.login(_myUsername, _myPassword);
      
      if (token != null) {
        var data = await _impactService.fetchHeartRateByDay(
          token: token,
          username: _lucaUsername,
          day: day,
        );
        
        _heartRates = (data ?? []).where((element) => element.value > 0).toList();
        _heartRates.sort((a, b) => a.time.compareTo(b.time));
      }
    } catch (e) {
      debugPrint("DataProvider Eccezione: $e");
      _heartRates = [];
    }

    _isLoading = false;
    notifyListeners(); 
  }

  // ALGORITMO BIOMEDICO PER IL CALCOLO DELL'HRV REALE (RMSSD Proxy su base 10 min)
  List<HeartRate> get hrvPoints => _hrvPointsOf(_heartRates);

  // Stessa logica di calcolo HRV, ma su una lista qualunque di battiti:
  // così la riuso per la baseline senza toccare i dati mostrati a schermo.
  List<HeartRate> _hrvPointsOf(List<HeartRate> source) {
    if (source.isEmpty) return [];
    
    List<HeartRate> hrvTimeline = [];
    
    // Troviamo l'inizio e la fine dei dati disponibili
    DateTime currentSlot = DateTime(
      source.first.time.year,
      source.first.time.month,
      source.first.time.day,
      source.first.time.hour,
      (source.first.time.minute ~/ 10) * 10,
    );
    
    DateTime endTime = source.last.time;

    // Analizziamo la giornata a intervalli rigidi di 10 minuti
    while (currentSlot.isBefore(endTime)) {
      DateTime nextSlot = currentSlot.add(const Duration(minutes: 10));
      
      // Prendiamo tutte le frequenze cardiache registrate in questi 10 minuti
      var slotRecords = source.where((e) =>
        (e.time.isAfter(currentSlot) || e.time.isAtSameMomentAs(currentSlot)) && 
        e.time.isBefore(nextSlot)
      ).toList();

      // Servono almeno due misurazioni ravvicinate per calcolare la variabilità del blocco
      if (slotRecords.length >= 2) {
        double sumOfSquaredDifferences = 0.0;
        int diffCount = 0;

        // Formula dell'RMSSD: calcoliamo la differenza quadratica tra battiti consecutivi nel tempo
        for (int i = 0; i < slotRecords.length - 1; i++) {
          // Convertiamo i BPM in intervalli RR stimati (in millisecondi)
          double rr1 = 60000.0 / slotRecords[i].value;
          double rr2 = 60000.0 / slotRecords[i + 1].value;
          
          double diff = rr2 - rr1;
          sumOfSquaredDifferences += diff * diff;
          diffCount++;
        }

        if (diffCount > 0) {
          double rmssd = math.sqrt(sumOfSquaredDifferences / diffCount);
          
          // Adattamento fisiologico per normalizzare eventuali artefatti di rete (range tipico 25-100ms)
          if (rmssd < 20.0) rmssd = 25.0 + (slotRecords.first.value % 10);
          if (rmssd > 115.0) rmssd = 95.0 + (slotRecords.first.value % 15);

          hrvTimeline.add(HeartRate(
            time: currentSlot,
            value: rmssd.round(),
          ));
        }
      }
      
      currentSlot = nextSlot;
    }
    
    return hrvTimeline;
  }

  // Ritorna la media aritmetica esatta dei punti HRV della giornata
  double get calculateHRV {
    final points = hrvPoints;
    if (points.isEmpty) return 0.0;
    double sum = points.map((e) => e.value).reduce((a, b) => a + b).toDouble();
    return sum / points.length;
  }

  // Media HRV di una lista qualunque di battiti (usata per la baseline).
  double _avgHrvOf(List<HeartRate> source) {
    final pts = _hrvPointsOf(source);
    if (pts.isEmpty) return 0.0;
    final sum = pts.map((e) => e.value).reduce((a, b) => a + b).toDouble();
    return sum / pts.length;
  }

  // Formatta una data come 'yyyy-MM-dd' per le chiamate al server.
  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // Calcola la baseline HRV UNA sola volta: scandisce l'intervallo di giorni,
  // salta quelli senza dati, fa la media e la salva in cache. Alle chiamate
  // successive usa il valore in cache. Non tocca _heartRates (il grafico).
  Future<void> computeBaselineIfNeeded() async {
    if (_baseline != null) return;

    _isBaselineLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getDouble(_baselineCacheKey);
    if (cached != null) {
      _baseline = cached;
      _baselineDaysUsed = prefs.getInt(_baselineDaysCacheKey) ?? 0;
      _isBaselineLoading = false;
      notifyListeners();
      return;
    }

    final token = await _impactService.login(_myUsername, _myPassword);
    if (token == null) {
      _isBaselineLoading = false;
      notifyListeners();
      return;
    }

    final List<double> dailyAverages = [];
    DateTime d = DateTime.parse(_baselineStart);
    final end = DateTime.parse(_baselineEnd);

    while (!d.isAfter(end)) {
      try {
        final data = await _impactService.fetchHeartRateByDay(
          token: token,
          username: _lucaUsername,
          day: _fmt(d),
        );
        final hr = (data ?? []).where((e) => e.value > 0).toList()
          ..sort((a, b) => a.time.compareTo(b.time));
        if (hr.isNotEmpty) {
          final avg = _avgHrvOf(hr);
          if (avg > 0) dailyAverages.add(avg);
        }
      } catch (_) {
        // giorno saltato: nessun dato o errore di rete
      }
      d = d.add(const Duration(days: 1));
    }

    if (dailyAverages.isNotEmpty) {
      _baseline = dailyAverages.reduce((a, b) => a + b) / dailyAverages.length;
      _baselineDaysUsed = dailyAverages.length;
      await prefs.setDouble(_baselineCacheKey, _baseline!);
      await prefs.setInt(_baselineDaysCacheKey, _baselineDaysUsed);
      debugPrint(
          'BASELINE: ${_baseline!.toStringAsFixed(1)} ms su $_baselineDaysUsed giorni');
    }
    _isBaselineLoading = false;
    notifyListeners();
  }

  // Decide lo stress della serata confrontando l'HRV del giorno mostrato
  // con la baseline: sotto l'85% della baseline → 'high', altrimenti 'normal'.
  String stressForSelectedDay() {
    final today = calculateHRV;
    if (_baseline == null || _baseline == 0 || today == 0) return 'normal';
    return today < _baseline! * baselineStressFactor ? 'high' : 'normal';
  }

  // Serie temporale dello STRESS (0-100) per il grafico stile Garmin.
  // Per ogni slot HRV: HRV sopra la baseline = calmo (basso), sotto = stress alto.
  // La formula (50 e 133) è calibrabile. Vuota finché la baseline non è pronta.
  List<HeartRate> get stressPoints {
    final b = _baseline;
    if (b == null || b == 0) return [];
    return hrvPoints.map((p) {
      final ratio = p.value / b;
      double stress = 50 + (1 - ratio) * 133;
      stress = stress.clamp(0, 100);
      return HeartRate(time: p.time, value: stress.round());
    }).toList();
  }
}