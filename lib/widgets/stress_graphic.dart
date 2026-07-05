import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:buzzed_buddy/models/heart_rate.dart';

class StressPlot extends StatelessWidget {
  const StressPlot({
    super.key,
    required this.points,
    required this.emptyMessage,
    this.isLoading = false,
    required this.precomputedGroups, 
  });

  final List<HeartRate> points; 
  final String emptyMessage;
  final bool isLoading;
  final List<BarChartGroupData> precomputedGroups; 

  @override
  Widget build(BuildContext context) {
    const Color plotYellow = Color.fromARGB(255, 255, 196, 0);

    if (isLoading) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          CircularProgressIndicator(color: plotYellow),
          SizedBox(height: 12),
          Text(
            'Computing baseline...',
            style: TextStyle(fontWeight: FontWeight.bold, color: plotYellow),
          ),
        ],
      );
    }

    if (points.isEmpty || precomputedGroups.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(fontWeight: FontWeight.w500, color: plotYellow),
        ),
      );
    }

    final sorted = [...points]..sort((a, b) => a.time.compareTo(b.time));
    final firstTimestamp = DateTime(sorted.first.time.year, sorted.first.time.month, sorted.first.time.day, 0, 0);

    return Column(
      children: [
        Container(
          color: Colors.black,
          height: 180,
          child: BarChart(
            BarChartData(
              minY: 0,
              maxY: 100,
              barGroups: precomputedGroups, 
              gridData: const FlGridData(show: false), 
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  axisNameWidget: const Text(
                    'Stress',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: plotYellow),
                  ),
                  axisNameSize: 18,
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 25,
                    getTitlesWidget: (v, meta) => Text(
                      v.toInt().toString(),
                      style: const TextStyle(fontSize: 10, color: plotYellow),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 24, // 24 slot da 15 minuti equivalgono a un'etichetta ogni 6 ore reali (96 / 4 = 24)
                    getTitlesWidget: (v, meta) {
                      final slotIndex = v.toInt();
                      if (slotIndex < 0 || slotIndex >= 96 || slotIndex % 24 != 0) {
                        return const SizedBox.shrink();
                      }
                      final labelTime = firstTimestamp.add(Duration(minutes: slotIndex * 15));
                      return SideTitleWidget(
                        meta: meta,
                        space: 4,
                        child: Text(
                          DateFormat('HH:mm').format(labelTime),
                          style: const TextStyle(fontSize: 10, color: plotYellow),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                enabled: true,
                handleBuiltInTouches: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    if (rod.toY == 0) return null;
                    final t = firstTimestamp.add(Duration(minutes: group.x * 15));
                    return BarTooltipItem(
                      '${DateFormat('HH:mm').format(t)}\nStress: ${rod.toY.toInt()}',
                      const TextStyle(color: plotYellow, fontWeight: FontWeight.bold),
                    );
                  },
                ),
              ),
            ),
            duration: Duration.zero, 
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children: const [
            _LegendDot(color: Colors.blue, label: 'Calm'),
            _LegendDot(color: Colors.teal, label: 'Low'),
            _LegendDot(color: Colors.orange, label: 'Medium'),
            _LegendDot(color: Colors.red, label: 'High'),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color.fromARGB(255, 255, 196, 0)),
        ),
      ],
    );
  }
}