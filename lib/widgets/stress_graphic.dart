import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:buzzed_buddy/models/heart_rate.dart';

// Grafico dello STRESS nel tempo, stile Garmin: barre colorate per fascia
// (blu = calmo → rosso = stress alto). I dati arrivano da DataProvider.stressPoints,
// dove ogni punto ha value = livello di stress 0-100 di uno slot da 10 minuti.
class StressPlot extends StatelessWidget {
  const StressPlot({
    super.key,
    required this.points,
    required this.emptyMessage,
    this.isLoading = false,
  });

  final List<HeartRate> points; // value = livello di stress 0-100
  final String emptyMessage;
  final bool isLoading;

  // Colore per fascia di stress (stile Garmin).
  static Color colorFor(int stress) {
    if (stress < 25) return Colors.blue;      // calmo
    if (stress < 50) return Colors.teal;      // basso
    if (stress < 75) return Colors.orange;    // medio
    return Colors.red;                        // alto
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          CircularProgressIndicator(color: Color.fromARGB(255, 255, 196, 0)),
          SizedBox(height: 12),
          Text(
            'Computing baseline…',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 255, 196, 0),
            ),
          ),
        ],
      );
    }

    if (points.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Color.fromARGB(255, 255, 196, 0),
          ),
        ),
      );
    }

    final sorted = [...points]..sort((a, b) => a.time.compareTo(b.time));

    final groups = <BarChartGroupData>[
      for (int i = 0; i < sorted.length; i++)
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: sorted[i].value.toDouble(),
              color: colorFor(sorted[i].value),
              width: 2,
            ),
          ],
        ),
    ];

    // Mostriamo un'etichetta oraria ogni ~1/4 dei punti, per non affollare.
    final labelEvery = (sorted.length / 4).ceil().clamp(1, sorted.length);

    const Color plotYellow = Color.fromARGB(255, 255, 196, 0);
    return Column(
      children: [
        Container(
          color: Colors.black,
          height: 180,
          child: BarChart(
            BarChartData(
              minY: 0,
              maxY: 100,
              barGroups: groups,
              groupsSpace: 2,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 25,
                getDrawingHorizontalLine: (v) =>
                    FlLine(color: plotYellow.withOpacity(0.18), strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  axisNameWidget: const Text(
                    'Stress',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 255, 196, 0)),
                  ),
                  axisNameSize: 18,
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 25,
                    getTitlesWidget: (v, meta) => Text(
                      v.toInt().toString(),
                      style: const TextStyle(fontSize: 10, color: Color.fromARGB(255, 255, 196, 0)),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, meta) {
                      final i = v.toInt();
                      if (i < 0 || i >= sorted.length || i % labelEvery != 0) {
                        return const SizedBox.shrink();
                      }
                      return SideTitleWidget(
                        meta: meta,
                        space: 4,
                        child: Text(
                          DateFormat('HH:mm').format(sorted[i].time),
                          style: const TextStyle(fontSize: 10, color: Color.fromARGB(255, 255, 196, 0)),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final t = sorted[group.x].time;
                    return BarTooltipItem(
                      '${DateFormat('HH:mm').format(t)}\nStress ${rod.toY.toInt()}',
                      const TextStyle(
                          color: Color.fromARGB(255, 255, 196, 0), fontWeight: FontWeight.bold),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Legenda delle fasce
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
        Text(label, style: const TextStyle(fontSize: 11, color: Color.fromARGB(255, 255, 196, 0))),
      ],
    );
  }
}
