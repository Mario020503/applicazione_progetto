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
    this.showEmptyLoading = false,
  });

  final List<HeartRate> points; 
  final String emptyMessage;
  final bool isLoading;
  final bool showEmptyLoading;

  static Color colorFor(int stress) {
    if (stress < 25) return Colors.blue;    // Calm
    if (stress < 50) return Colors.teal;    // Low
    if (stress < 75) return Colors.orange;  // Medium
    return Colors.red;                      // High
  }

  @override
  Widget build(BuildContext context) {
    const Color wingBlue = Color(0xFF86F5F0); // azzurro delle ali del logo

    if (isLoading || (showEmptyLoading && points.isEmpty)) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: wingBlue),
          const SizedBox(height: 12),
          Text(
            isLoading ? 'Computing baseline...' : emptyMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, color: wingBlue),
          ),
        ],
      );
    }

    if (points.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(fontWeight: FontWeight.w500, color: wingBlue),
        ),
      );
    }

    final sorted = [...points]..sort((a, b) => a.time.compareTo(b.time));
    final firstTimestamp = DateTime(sorted.first.time.year, sorted.first.time.month, sorted.first.time.day, 0, 0);

    final groups = <BarChartGroupData>[];
    const int stepMinutes = 15;
    const int totalSlots = 1440 ~/ stepMinutes; // 96 slot totali in una giornata

    // COSTRUZIONE DELLA MATRICE FISSA DELLE 24 ORE:
    // Generiamo ogni singolo slot da 15 minuti per forzare i veri spazi vuoti nel grafico
    for (int slot = 0; slot < totalSlots; slot++) {
      final int currentMinutes = slot * stepMinutes;
      final DateTime slotTime = firstTimestamp.add(Duration(minutes: currentMinutes));

      // Cerchiamo se esiste un dato reale registrato in questa specifica finestra temporale
      final matchingPoint = sorted.any((p) => p.time.hour == slotTime.hour && (p.time.minute ~/ stepMinutes) == (slotTime.minute ~/ stepMinutes))
          ? sorted.firstWhere((p) => p.time.hour == slotTime.hour && (p.time.minute ~/ stepMinutes) == (slotTime.minute ~/ stepMinutes))
          : null;

      if (matchingPoint != null) {
        // C'è un dato reale: inseriamo la barra colorata
        groups.add(
          BarChartGroupData(
            x: slot,
            barRods: [
              BarChartRodData(
                toY: matchingPoint.value.toDouble(),
                color: colorFor(matchingPoint.value),
                width: 2.2,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
              ),
            ],
          ),
        );
      } else {
        // NON CI SONO DATI: Inseriamo una barra trasparente per bloccare lo spazio e mostrare il vuoto
        groups.add(
          BarChartGroupData(
            x: slot,
            barRods: [
              BarChartRodData(
                toY: 0,
                color: Colors.transparent,
                width: 2.2,
              ),
            ],
          ),
        );
      }
    }

    // Mostriamo un'etichetta oraria ogni 6 ore (00:00, 06:00, 12:00, 18:00, 00:00) per un asse X perfetto
    const double xInterval = 24; // Ogni 24 slot da 15 minuti corrispondono esattamente a 6 ore

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
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 25,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: wingBlue.withValues(alpha: 0.18),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  axisNameWidget: const Text(
                    'Stress',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: wingBlue),
                  ),
                  axisNameSize: 18,
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 25,
                    getTitlesWidget: (v, meta) => Text(
                      v.toInt().toString(),
                      style: const TextStyle(fontSize: 10, color: wingBlue),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: xInterval,
                    getTitlesWidget: (v, meta) {
                      final slotIndex = v.toInt();
                      if (slotIndex < 0 || slotIndex > totalSlots || slotIndex % 24 != 0) {
                        return const SizedBox.shrink();
                      }
                      final labelTime = firstTimestamp.add(Duration(minutes: slotIndex * stepMinutes));
                      return SideTitleWidget(
                        meta: meta,
                        space: 4,
                        child: Text(
                          DateFormat('HH:mm').format(labelTime),
                          style: const TextStyle(fontSize: 10, color: wingBlue),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    // Nascondiamo il tooltip se tocchiamo uno spazio vuoto (trasparente)
                    if (rod.toY == 0) return null;

                    final t = firstTimestamp.add(Duration(minutes: group.x * stepMinutes));
                    return BarTooltipItem(
                      '${DateFormat('HH:mm').format(t)}\nStress: ${rod.toY.toInt()}',
                      const TextStyle(color: wingBlue, fontWeight: FontWeight.bold),
                    );
                  },
                ),
              ),
            ),
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
          style: const TextStyle(fontSize: 11, color: Color(0xFF86F5F0)),
        ),
      ],
    );
  }
}
