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

  @override
  Widget build(BuildContext context) {
    const Color plotYellow = Color.fromARGB(255, 255, 196, 0);
    if (points.isEmpty) {
      return Center(child: Text(emptyMessage, style: const TextStyle(fontWeight: FontWeight.w500)));
    }

    final sortedPoints = [...points]..sort((a, b) => a.time.compareTo(b.time));
    final firstTimestamp = sortedPoints.first.time;

    final spots = sortedPoints
        .map(
          (e) => FlSpot(
            e.time.difference(firstTimestamp).inMinutes.toDouble(),
            e.value,
          ),
        )
        .toList();

    double minY = 20;
    double maxY = 120;
    double yInterval = 25; 

    final xMax = spots.last.x;
    final xInterval = xMax <= 0 ? 60.0 : xMax / 4; 

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
          
          // ASSE SINISTRO TRADOTTO
          leftTitles: AxisTitles(
            axisNameWidget: const Text(
              "HRV (ms)", 
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 255, 196, 0))
            ),
            axisNameSize: 18,
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: yInterval,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 10, color: Color.fromARGB(255, 255, 196, 0)),
                  textAlign: TextAlign.center,
                );
              },
            ),
          ),
          
          // ASSE IN BASSO TRADOTTO
          bottomTitles: AxisTitles(
            axisNameWidget: const Text(
              "Time (Hours)", // Tradotto
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 255, 196, 0))
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
                    style: const TextStyle(fontSize: 10, color: Color.fromARGB(255, 255, 196, 0)),
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
                  '${DateFormat('HH:mm').format(ts)}\n${spot.y.toStringAsFixed(0)} ms',
                    const TextStyle(color: Color.fromARGB(255, 255, 196, 0), fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 2.5, 
            color: lineColor,
            dotData: const FlDotData(show: false), 
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  lineColor.withValues(alpha: 0.35),
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
      emptyMessage: 'No HRV data available for this day', // Tradotto
      valueDecimals: 0,
    );
  }
}