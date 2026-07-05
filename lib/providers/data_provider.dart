import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import '../models/heart_rate.dart';
import '../models/resting_hr.dart';
import '../services/impact.dart';

class DataProvider with ChangeNotifier {
  final ImpactService _impactService = ImpactService();

  final String _myUsername = "v7oZIhQJoE"; 
  final String _myPassword = "12345678!"; 
  final String _lucaUsername = "Jpefaq6m58";

  List<HeartRate> _heartRates = [];
  List<RestingHeartRate> _restingHeartRates = [];
  bool _isLoading = false;
  bool _isBaselineLoading = false;

  List<HeartRate> _cachedHrvPoints = [];
  List<HeartRate> _cachedStressPoints = [];
  List<BarChartGroupData> _cachedBarGroups = []; 

  bool get isBaselineLoading => _isBaselineLoading;

  double? _baseline;
  static const String _baselineCacheKey = 'hrvBaseline';
  static const double baselineStressFactor = 0.85;
  static const String _baselineStart = '2026-06-05';
  static const String _baselineEnd = '2026-07-05';

  List<HeartRate> get heartRates => _heartRates;
  List<RestingHeartRate> get restingHeartRates => _restingHeartRates;
  bool get isLoading => _isLoading;
  double? get baseline => _baseline;

  static const String _baselineCacheKeyDays = 'hrvBaselineDays';
  int _baselineDaysUsed = 0;
  int get baselineDaysUsed => _baselineDaysUsed;

  int get restingHrValue {
    if (_restingHeartRates.isEmpty) return 65;
    return _restingHeartRates.first.value;
  }

  List<HeartRate> get hrvPoints => _cachedHrvPoints;
  List<HeartRate> get stressPoints => _cachedStressPoints;
  List<BarChartGroupData> get cachedBarGroups => _cachedBarGroups; 

  Future<void> fetchLucaHeartDataForDay(String day) async {
    _isLoading = true;
    notifyListeners(); 

    try {
      if (_baseline == null || _baseline == 0) {
        await computeBaselineIfNeeded();
      }

      String? token = await _impactService.login(_myUsername, _myPassword);
      
      if (token != null) {
        var data = await _impactService.fetchHeartRateByDay(
          token: token,
          username: _lucaUsername,
          day: day,
        );
        
        _heartRates = (data ?? []).where((element) => element.value > 0).toList();
        _heartRates.sort((a, b) => a.time.compareTo(b.time));

        try {
          var rhrData = await _impactService.fetchRestingHeartRateByDay(
            token: token,
            username: _lucaUsername,
            day: day,
          );
          
          _restingHeartRates = (rhrData ?? []).where((element) => element.value > 0).toList();
          
          if (_restingHeartRates.isEmpty && _heartRates.isNotEmpty) {
            List<int> sortedBpms = _heartRates.map((e) => e.value).toList()..sort();
            int percentileIndex = (sortedBpms.length * 0.05).round().clamp(0, sortedBpms.length - 1);
            int calculatedRhr = sortedBpms[percentileIndex].clamp(40, 85);
            
            _restingHeartRates = [RestingHeartRate(date: DateTime.parse(day), value: calculatedRhr)];
          }
        } catch (e) {
          debugPrint("Errore RHR fallback: $e");
        }
        
        if (_restingHeartRates.isEmpty) {
          _restingHeartRates = [RestingHeartRate(date: DateTime.parse(day), value: 65)];
        }

        _cachedHrvPoints = _aggregateData(windowMinutes: 60);
        // DOWNSAMPLING: Calcolo dello stress tarato su finestre ottimali da 15 minuti
        _cachedStressPoints = _calculateHighResolutionStress(windowMinutes: 15);
        
        _generateAndCacheBarGroups();
      }
    } catch (e) {
      debugPrint("DataProvider Errore: $e");
      _cachedHrvPoints = [];
      _cachedStressPoints = [];
      _cachedBarGroups = [];
    }

    _isLoading = false;
    notifyListeners(); 
  }

  List<HeartRate> _calculateRawRmssdPoints(int windowMinutes) {
    if (_heartRates.isEmpty) return [];
    
    List<HeartRate> computedPoints = [];
    DateTime currentSlot = DateTime(
      _heartRates.first.time.year,
      _heartRates.first.time.month,
      _heartRates.first.time.day,
      _heartRates.first.time.hour,
      (_heartRates.first.time.minute ~/ windowMinutes) * windowMinutes,
    );
    
    DateTime endTime = _heartRates.last.time;
    final int rhrBaseline = restingHrValue;
    
    int sourceIndex = 0;
    final int sourceLength = _heartRates.length;

    while (currentSlot.isBefore(endTime)) {
      DateTime nextSlot = currentSlot.add(Duration(minutes: windowMinutes));
      List<HeartRate> slotRecords = [];
      
      while (sourceIndex < sourceLength && _heartRates[sourceIndex].time.isBefore(currentSlot)) {
        sourceIndex++;
      }
      
      int tempIndex = sourceIndex;
      while (tempIndex < sourceLength && _heartRates[tempIndex].time.isBefore(nextSlot)) {
        slotRecords.add(_heartRates[tempIndex]);
        tempIndex++;
      }

      if (slotRecords.isNotEmpty && slotRecords.length >= 2) {
        double avgBpm = slotRecords.map((e) => e.value).reduce((a, b) => a + b) / slotRecords.length;
        double sumOfSquaredDifferences = 0.0;
        int diffCount = 0;

        for (int i = 0; i < slotRecords.length - 1; i++) {
          double rr1 = 60000.0 / slotRecords[i].value;
          double rr2 = 60000.0 / slotRecords[i + 1].value;
          if (rr1 < 350.0 || rr1 > 1500.0 || rr2 < 350.0 || rr2 > 1500.0) continue;
          
          double diff = rr2 - rr1;
          if (diff.abs() > 300.0) continue;

          sumOfSquaredDifferences += diff * diff;
          diffCount++;
        }

        if (diffCount > 0) {
          double rawRmssd = math.sqrt(sumOfSquaredDifferences / diffCount);
          double cronotropicFactor = avgBpm / rhrBaseline;
          
          if (avgBpm > (rhrBaseline + 35)) cronotropicFactor = 0.4;

          double correctedRmssd = rawRmssd * cronotropicFactor;
          computedPoints.add(HeartRate(
            time: currentSlot,
            value: correctedRmssd.clamp(10.0, 150.0).round(),
          ));
        }
      }
      currentSlot = nextSlot;
    }
    return computedPoints;
  }

  List<HeartRate> _aggregateData({required int windowMinutes}) {
    List<HeartRate> basePoints = _calculateRawRmssdPoints(5);
    if (basePoints.isEmpty) return [];

    Map<int, List<int>> hourlyGroups = {};
    Map<int, DateTime> hourlyTimestamps = {};

    for (var p in basePoints) {
      int hourKey = p.time.hour;
      hourlyGroups.putIfAbsent(hourKey, () => []).add(p.value);
      hourlyTimestamps.putIfAbsent(hourKey, () => DateTime(p.time.year, p.time.month, p.time.day, hourKey, 0));
    }

    List<HeartRate> results = [];
    var sortedHours = hourlyGroups.keys.toList()..sort();
    for (int hour in sortedHours) {
      results.add(HeartRate(
        time: hourlyTimestamps[hour]!,
        value: (hourlyGroups[hour]!.reduce((a, b) => a + b) / hourlyGroups[hour]!.length).round(),
      ));
    }
    return results;
  }

  List<HeartRate> _calculateHighResolutionStress({required int windowMinutes}) {
    List<HeartRate> hrvPointsForWindow = _calculateRawRmssdPoints(windowMinutes);
    final b = _baseline;
    if (b == null || b == 0 || hrvPointsForWindow.isEmpty) return [];
    
    final int rhr = restingHrValue;
    List<HeartRate> stressPointsTimeline = [];

    for (var p in hrvPointsForWindow) {
      final slotRecords = _heartRates.where((e) =>
        (e.time.isAfter(p.time) || e.time.isAtSameMomentAs(p.time)) && 
        e.time.isBefore(p.time.add(Duration(minutes: windowMinutes)))
      ).toList();

      if (slotRecords.isEmpty) continue;

      double avgBpm = slotRecords.map((e) => e.value).reduce((a, b) => a + b) / slotRecords.length;

      if (avgBpm > (rhr + 40)) {
        continue;
      }

      double ratio = p.value / b;
      double stressScore;

      if (ratio < 1.0) {
        double deficit = 1.0 - ratio;
        stressScore = 30.0 + (deficit * 45.0); 
      } else {
        double surplus = ratio - 1.0;
        stressScore = math.max(5.0, 30.0 - (surplus * 25.0));
      }

      double bpmElevation = math.max(0.0, avgBpm - rhr);
      if (bpmElevation > 5) {
        stressScore += math.sqrt(bpmElevation - 5) * 3.5;
      }

      stressPointsTimeline.add(HeartRate(
        time: p.time,
        value: stressScore.clamp(5.0, 98.0).round(),
      ));
    }

    return stressPointsTimeline;
  }

  // MASSIMA OTTIMIZZAZIONE GRAFICA: Genera solo 96 gruppi stabili invece di 288, eliminando i lag nativi
  void _generateAndCacheBarGroups() {
    if (_cachedStressPoints.isEmpty) {
      _cachedBarGroups = [];
      return;
    }

    final sorted = [..._cachedStressPoints]..sort((a, b) => a.time.compareTo(b.time));
    final firstTimestamp = DateTime(sorted.first.time.year, sorted.first.time.month, sorted.first.time.day, 0, 0);
    
    final Map<String, int> stressLookupTable = {};
    for (var p in sorted) {
      final String key = '${p.time.hour}_${p.time.minute ~/ 15}';
      stressLookupTable[key] = p.value;
    }

    final List<BarChartGroupData> builtGroups = [];
    const int stepMinutes = 15;
    const int totalSlots = 1440 ~/ stepMinutes; // 96 barre totali

    Color colorFor(int stress) {
      if (stress < 25) return Colors.blue;    
      if (stress < 50) return Colors.teal;    
      if (stress < 75) return Colors.orange;  
      return Colors.red;                      
    }

    for (int slot = 0; slot < totalSlots; slot++) {
      final int currentMinutes = slot * stepMinutes;
      final DateTime slotTime = firstTimestamp.add(Duration(minutes: currentMinutes));
      final String key = '${slotTime.hour}_${slotTime.minute ~/ 15}';

      final int? stressValue = stressLookupTable[key];

      if (stressValue != null) {
        builtGroups.add(
          BarChartGroupData(
            x: slot,
            barRods: [
              BarChartRodData(
                toY: stressValue.toDouble(),
                color: colorFor(stressValue),
                width: 2.8, // Barre leggermente più larghe per riempire lo schermo armonicamente
                borderRadius: const BorderRadius.vertical(top: Radius.circular(1.5)),
              ),
            ],
          ),
        );
      } else {
        builtGroups.add(
          BarChartGroupData(
            x: slot,
            barRods: [
              BarChartRodData(
                toY: 0,
                color: Colors.transparent,
                width: 2.8,
              ),
            ],
          ),
        );
      }
    }
    _cachedBarGroups = builtGroups;
  }

  double get calculateHRV {
    final points = hrvPoints;
    if (points.isEmpty) return 0.0;
    double sum = points.map((e) => e.value).reduce((a, b) => a + b).toDouble();
    return sum / points.length;
  }

  double _avgHrvOf(List<HeartRate> source) {
    if (source.isEmpty) return 0.0;
    List<HeartRate> rawPoints = _calculateRawRmssdPoints(5);
    if (rawPoints.isEmpty) return 0.0;
    double sum = rawPoints.map((e) => e.value).reduce((a, b) => a + b).toDouble();
    return sum / rawPoints.length;
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> computeBaselineIfNeeded() async {
    if (_baseline != null) return;
    _isBaselineLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getDouble(_baselineCacheKey);
    if (cached != null) {
      _baseline = cached;
      _baselineDaysUsed = prefs.getInt(_baselineCacheKeyDays) ?? 0;
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

    final List<Future<void>> downloadTasks = [];
    final List<double> dailyAverages = [];
    
    DateTime d = DateTime.parse(_baselineStart);
    final end = DateTime.parse(_baselineEnd);

    while (!d.isAfter(end)) {
      final DateTime currentTargetDate = d;
      downloadTasks.add(() async {
        try {
          final data = await _impactService.fetchHeartRateByDay(
            token: token,
            username: _lucaUsername,
            day: _fmt(currentTargetDate),
          );
          final hr = (data ?? []).where((e) => e.value > 0).toList();
          if (hr.isNotEmpty) {
            hr.sort((a, b) => a.time.compareTo(b.time));
            final avg = _avgHrvOf(hr);
            if (avg > 0) {
              synchronized(dailyAverages, () => dailyAverages.add(avg));
            }
          }
        } catch (_) {}
      }());
      d = d.add(const Duration(days: 1));
    }

    await Future.wait(downloadTasks);

    if (dailyAverages.isNotEmpty) {
      _baseline = dailyAverages.reduce((a, b) => a + b) / dailyAverages.length;
      _baselineDaysUsed = dailyAverages.length;
      await prefs.setDouble(_baselineCacheKey, _baseline!);
      await prefs.setInt(_baselineCacheKeyDays, _baselineDaysUsed);
    }
    _isBaselineLoading = false;
    notifyListeners();
  }

  void synchronized(dynamic lock, void Function() block) {
    block(); 
  }

  String stressForSelectedDay() {
    final today = calculateHRV;
    if (_baseline == null || _baseline == 0 || today == 0) return 'normal';
    return today < _baseline! * baselineStressFactor ? 'high' : 'normal';
  }
}