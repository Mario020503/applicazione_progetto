import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:buzzed_buddy/models/heart_rate.dart';

class HrPoint {
  const HrPoint({required this.time, required this.value});

  final DateTime time;
  final double value;
}

class HrPlot extends StatelessWidget {
  const HrPlot({
    super.key,
    required this.points,
    required this.lineColor,
    required this.emptyMessage,
    this.valueDecimals = 0,
  });

  final List<HrPoint> points;
  final Color lineColor;
  final String emptyMessage;
  final int valueDecimals;

  List<List<HrPoint>> _splitIntoSegments(List<HrPoint> sortedPoints, int maxGapMinutes) {
    if (sortedPoints.isEmpty) return [];
    
    List<List<HrPoint>> segments = [];
    List<HrPoint> currentSegment = [sortedPoints.first];

    for (int i = 1; i < sortedPoints.length; i++) {
      final difference = sortedPoints[i].time.difference(sortedPoints[i - 1].time).inMinutes;
      
      if (difference > maxGapMinutes) {
        segments.add(currentSegment);
        currentSegment = [];
      }
      currentSegment.add(sortedPoints[i]);
    }
    
    if (currentSegment.isNotEmpty) {
      segments.add(currentSegment);
    }
    return segments;
  }

  @override
  Widget build(BuildContext context) {
    const Color plotYellow = Color.fromARGB(255, 255, 196, 0);
    if (points.isEmpty) {
      return Center(child: Text(emptyMessage, style: const TextStyle(fontWeight: FontWeight.w500)));
    }

    final sortedPoints = [...points]..sort((a, b) => a.time.compareTo(b.time));
    final firstTimestamp = sortedPoints.first.time;

    final double xMax = sortedPoints.last.time.difference(firstTimestamp).inMinutes.toDouble();
    final xInterval = xMax <= 0 ? 60.0 : xMax / 4; 

    double minY = 0;
    double maxY = 150; // allineato al limite superiore dei punti HRV (clamp 10..150)
    double yInterval = 25;

    final segments = _splitIntoSegments(sortedPoints, 75);

    final List<LineChartBarData> lineBarsData = segments.map((segment) {
      final spots = segment.map((e) {
        return FlSpot(
          e.time.difference(firstTimestamp).inMinutes.toDouble(),
          e.value,
        );
      }).toList();

      return LineChartBarData(
        spots: spots,
        isCurved: true, 
        barWidth: 3.0, 
        color: lineColor,
        dotData: const FlDotData(show: true), 
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              lineColor.withValues(alpha: 0.25),
              lineColor.withValues(alpha: 0.0),
            ],
          ),
        ),
      );
    }).toList();

    return LineChart(
      LineChartData(
        backgroundColor: Colors.black,
        minX: 0,
        maxX: xMax == 0 ? 1 : xMax,
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: yInterval,
          verticalInterval: xInterval,
          getDrawingHorizontalLine: (value) => FlLine(color: plotYellow.withValues(alpha: 0.18), strokeWidth: 1),
          getDrawingVerticalLine: (value) => FlLine(color: plotYellow.withValues(alpha: 0.08), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            axisNameWidget: const Text(
              "HRV (ms)", 
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: plotYellow)
            ),
            axisNameSize: 18,
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: yInterval,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 10, color: plotYellow),
                  textAlign: TextAlign.center,
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            axisNameWidget: const Text(
              "Time (Hours)", 
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: plotYellow)
            ),
            axisNameSize: 16,
            sideTitles: SideTitles(
              showTitles: true,
              interval: xInterval,
              getTitlesWidget: (value, meta) {
                final date = firstTimestamp.add(Duration(minutes: value.round()));
                return SideTitleWidget(
                  meta: meta,
                  space: 4,
                  child: Text(
                    DateFormat('HH:mm').format(date),
                    style: const TextStyle(fontSize: 10, color: plotYellow),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            left: BorderSide(color: plotYellow.withValues(alpha: 0.6)),
            bottom: BorderSide(color: plotYellow.withValues(alpha: 0.6)),
            right: BorderSide.none,
            top: BorderSide.none,
          ),
        ),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final ts = firstTimestamp.add(Duration(minutes: spot.x.round()));
                return LineTooltipItem(
                  'Time: ${DateFormat('HH:mm').format(ts)}\nAvg HRV: ${spot.y.toStringAsFixed(valueDecimals)} ms',
                  const TextStyle(color: plotYellow, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: lineBarsData,
      ),
    );
  }
}

class CustomPlotHR extends StatelessWidget {
  const CustomPlotHR({
    super.key,
    required this.hrData,
    required this.selectedDate,
  });

  final List<HeartRate> hrData;
  final DateTime selectedDate;

  @override
  Widget build(BuildContext context) {
    final String targetDateStr = selectedDate.toString().split(' ')[0];

    final points = hrData
        .where((e) => e.time.toString().startsWith(targetDateStr))
        .map(
          (e) => HrPoint(
            time: e.time,
            value: e.value.toDouble(),
          ),
        )
        .toList();

    return HrPlot(
      points: points,
      lineColor: const Color.fromARGB(255, 255, 196, 0),
      emptyMessage: 'No HRV data available for this day',
      valueDecimals: 0,
    );
  }
}
