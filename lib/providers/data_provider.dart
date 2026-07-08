import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/heart_rate.dart';
import '../models/resting_hr.dart';
import '../services/impact.dart';

class DataProvider with ChangeNotifier {
  final ImpactService _impactService = ImpactService();


  final String _myUsername = "v7oZIhQJoE";
  final String _myPassword = "12345678!";
  final String _lucaUsername = "Jpefaq6m58";

  
  bool _isAuthorized = false;

  List<HeartRate> _heartRates = [];
  List<RestingHeartRate> _restingHeartRates = [];
  bool _isLoading = false;
  bool _isBaselineLoading = false;

  List<HeartRate> _cachedHrvPoints = [];
  List<HeartRate> _cachedStressPoints = [];

  bool get isBaselineLoading => _isBaselineLoading;

  double? _baseline;
  static const String _baselineCacheKey = 'hrvBaseline';
  static const double baselineStressFactor = 0.85;

 
  static const String _baselineStart = '2026-06-04';
  static const String _baselineEnd = '2026-07-04';

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


  Future<bool> _ensureAuthorized() async {
    if (_isAuthorized) return true;
    _isAuthorized = await _impactService.login(_myUsername, _myPassword);
    return _isAuthorized;
  }

  Future<void> fetchLucaHeartDataForDay(String day) async {
    _isLoading = true;
    notifyListeners(); 

    try {
      final bool authorized = await _ensureAuthorized();

      if (authorized) {
        var data = await _impactService.fetchHeartRateByDay(
          patient: _lucaUsername,
          day: day,
        );
        
        _heartRates = (data ?? []).where((element) => element.value > 0).toList();
        _heartRates.sort((a, b) => a.time.compareTo(b.time));

        try {
          var rhrData = await _impactService.fetchRestingHeartRateByDay(
            patient: _lucaUsername,
            day: day,
          );
          
          _restingHeartRates = (rhrData ?? []).where((element) => element.value > 0).toList();

          if (_restingHeartRates.isEmpty && _heartRates.isNotEmpty) {
            _restingHeartRates = [RestingHeartRate(date: DateTime.parse(day), value: _estimateRestingHr(_heartRates))];
          }
        } catch (_) {

        }
          
        
        if (_restingHeartRates.isEmpty) {
          _restingHeartRates = [RestingHeartRate(date: DateTime.parse(day), value: 65)];
        }

        _cachedHrvPoints = _aggregateData(windowMinutes: 60);
        _cachedStressPoints = _calculateStressTimeline(windowMinutes: 15);
      }
    } catch (_) {
      _cachedHrvPoints = [];
      _cachedStressPoints = [];
    }

    _isLoading = false;
    notifyListeners();
  }


  int _estimateRestingHr(List<HeartRate> source) {
    if (source.isEmpty) return 65;
    final sortedBpms = source.map((e) => e.value).toList()..sort();
    final percentileIndex = (sortedBpms.length * 0.05).round().clamp(0, sortedBpms.length - 1);
    return sortedBpms[percentileIndex].clamp(40, 85);
  }

  
  List<HeartRate> _calculateRawRmssdPoints(List<HeartRate> source, int windowMinutes, int rhrBaseline) {
    if (source.isEmpty) return [];

    List<HeartRate> computedPoints = [];
    DateTime currentSlot = DateTime(
      source.first.time.year,
      source.first.time.month,
      source.first.time.day,
      source.first.time.hour,
      (source.first.time.minute ~/ windowMinutes) * windowMinutes,
    );

    DateTime endTime = source.last.time;

    int sourceIndex = 0;
    final int sourceLength = source.length;

    while (currentSlot.isBefore(endTime)) {
      DateTime nextSlot = currentSlot.add(Duration(minutes: windowMinutes));
      List<HeartRate> slotRecords = [];

      while (sourceIndex < sourceLength && source[sourceIndex].time.isBefore(currentSlot)) {
        sourceIndex++;
      }

      int tempIndex = sourceIndex;
      while (tempIndex < sourceLength && source[tempIndex].time.isBefore(nextSlot)) {
        slotRecords.add(source[tempIndex]);
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
    
    List<HeartRate> basePoints = _calculateRawRmssdPoints(_heartRates, 5, _estimateRestingHr(_heartRates));
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


  List<HeartRate> _calculateStressTimeline({required int windowMinutes}) {
    final int rhr = _estimateRestingHr(_heartRates);
    List<HeartRate> hrvBaselinePoints = _calculateRawRmssdPoints(_heartRates, windowMinutes, rhr);
    final b = _baseline;
    if (b == null || b == 0 || hrvBaselinePoints.isEmpty) return [];

    return hrvBaselinePoints.map((p) {
      final slotRecords = _heartRates.where((e) =>
        (e.time.isAfter(p.time) || e.time.isAtSameMomentAs(p.time)) && 
        e.time.isBefore(p.time.add(Duration(minutes: windowMinutes)))
      ).toList();

      double currentBpm = slotRecords.isNotEmpty 
          ? (slotRecords.map((e) => e.value).reduce((a, b) => a + b) / slotRecords.length)
          : (rhr + 8).toDouble();

  
      double ratio = p.value / b;
      double hrvStressComponent;

      if (ratio < 1.0) {
        hrvStressComponent = 25.0 + (1.0 - ratio) * 65.0;
      } else {
        hrvStressComponent = math.max(5.0, 25.0 - (ratio - 1.0) * 20.0);
      }

      double bpmElevation = math.max(0.0, currentBpm - rhr);
      double sympatheticBpmBoost = (bpmElevation / 45.0).clamp(0.0, 1.0) * 25.0;

      
      double finalStressScore = hrvStressComponent + sympatheticBpmBoost;

      return HeartRate(
        time: p.time, 
        value: finalStressScore.clamp(5.0, 98.0).round(),
      );
    }).toList();
  }

  double get calculateHRV => _avgHrvOf(_heartRates);

  
  double _avgHrvOf(List<HeartRate> source) {
    if (source.isEmpty) return 0.0;
    final rhrEstimate = _estimateRestingHr(source);
    final rawPoints = _calculateRawRmssdPoints(source, 5, rhrEstimate);
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

      if (_heartRates.isNotEmpty) {
        _cachedStressPoints = _calculateStressTimeline(windowMinutes: 15);
      }
      _isBaselineLoading = false;
      notifyListeners();
      return;
    }

    final bool authorized = await _ensureAuthorized();
    if (!authorized) {
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
          patient: _lucaUsername,
          day: _fmt(d),
        );
        final hr = (data ?? []).where((e) => e.value > 0).toList()
          ..sort((a, b) => a.time.compareTo(b.time));
        if (hr.isNotEmpty) {
          final avg = _avgHrvOf(hr);
          if (avg > 0) dailyAverages.add(avg);
        }
      } catch (_) {}
      d = d.add(const Duration(days: 1));
    }

    if (dailyAverages.isNotEmpty) {
      _baseline = dailyAverages.reduce((a, b) => a + b) / dailyAverages.length;
      _baselineDaysUsed = dailyAverages.length;
      await prefs.setDouble(_baselineCacheKey, _baseline!);
      await prefs.setInt(_baselineCacheKeyDays, _baselineDaysUsed);
    }

    if (_baseline != null && _heartRates.isNotEmpty) {
      _cachedStressPoints = _calculateStressTimeline(windowMinutes: 15);
    }
    _isBaselineLoading = false;
    notifyListeners();
  }

  String stressForSelectedDay() {
    final today = calculateHRV;
    if (_baseline == null || _baseline == 0 || today == 0) return 'normal';
    return today < _baseline! * baselineStressFactor ? 'high' : 'normal';
  }
}
