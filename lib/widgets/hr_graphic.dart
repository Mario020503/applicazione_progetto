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
    this.valueDecimals = 2,
  });

  final List<HrPoint> points;
  final Color lineColor;
  final String emptyMessage;
  final int valueDecimals;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Center(child: Text(emptyMessage));
    }

    final sortedPoints = [...points]
      ..sort((a, b) => a.time.compareTo(b.time));
    final firstTimestamp = sortedPoints.first.time;

    final spots = sortedPoints
        .map(
          (e) => FlSpot(
            e.time.difference(firstTimestamp).inMinutes.toDouble(),
            e.value,
          ),
        )
        .toList();

    final minY = sortedPoints
        .map((e) => e.value)
        .reduce((a, b) => a < b ? a : b);
    final maxY = sortedPoints
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b);
    final yRange = (maxY - minY).abs();
    final yPadding = yRange < 0.01 ? 10.0 : yRange * 0.15;

    final xMax = spots.last.x;
    final tickCount = spots.length < 5 ? spots.length : 5;
    final xInterval = tickCount <= 1 || xMax <= 0
        ? 1.0
        : xMax / (tickCount - 1);
    final yInterval = yRange < 0.01 ? 5.0 : (yRange/4);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: xMax == 0 ? 1 : xMax,
        minY: (minY - yPadding)< 0 ? 0 : minY - yPadding,
        maxY: maxY + yPadding,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: yInterval,
          verticalInterval: xInterval,
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              interval: yInterval,
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: xInterval,
              getTitlesWidget: (value, meta) {
                final date = firstTimestamp.add(
                  Duration(minutes: value.round()),
                );
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    DateFormat('HH:mm').format(date),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: const Border(
            left: BorderSide(color: Colors.black12),
            bottom: BorderSide(color: Colors.black12),
            right: BorderSide.none,
            top: BorderSide.none,
          ),
        ),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final ts = firstTimestamp.add(
                  Duration(minutes: spot.x.round()),
                );
                return LineTooltipItem(
                  '${DateFormat('HH:mm').format(ts)}\n${spot.y.toStringAsFixed(valueDecimals)}',
                  const TextStyle(color: Colors.white),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 2,
            color: lineColor,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  lineColor.withValues(alpha: 0.45),
                  lineColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<HrPoint> filterPointsByDay({
  required List<HrPoint> points,
  required DateTime selectedDate,
}) {
  return points.where((e) {
    return e.time.year == selectedDate.year &&
        e.time.month == selectedDate.month &&
        e.time.day == selectedDate.day;
  }).toList();
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
    final points = filterPointsByDay(
      points: hrData
          .map(
            (e) => HrPoint(
              time: e.time,
              value: e.value.toDouble(),
            ),
          )
          .toList(),
      selectedDate: selectedDate,
    );

    return HrPlot(
      points: points,
      lineColor: const Color(0xFF89453C),
      emptyMessage: 'No heart rate data available',
      valueDecimals: 0,
    );
  }
}
