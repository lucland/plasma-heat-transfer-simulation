import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/simulation_results.dart';
import '../models/metrics.dart';

class TemperatureChart extends ConsumerWidget {
  final SimulationResults simulationResults;
  final SimulationMetrics metrics;

  const TemperatureChart({
    Key? key,
    required this.simulationResults,
    required this.metrics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Criar dados para o gráfico
    final spots = _createDataPoints();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 50,
          verticalInterval: 1,
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value % 2 == 0 || value == simulationResults.timeSteps - 1) {
                  final time = value * simulationResults.timeStep;
                  return Text(
                    '${time.toStringAsFixed(1)}s',
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}°C',
                  style: const TextStyle(fontSize: 10),
                );
              },
              reservedSize: 42,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300),
        ),
        minX: 0,
        maxX: simulationResults.timeSteps - 1.0,
        minY: metrics.minTemperature - 10,
        maxY: metrics.maxTemperature + 10,
        lineBarsData: [
          // Temperatura máxima
          LineChartBarData(
            spots: spots['max']!,
            isCurved: true,
            color: Colors.red,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: AreaData(
              show: false,
            ),
          ),
          // Temperatura média
          LineChartBarData(
            spots: spots['avg']!,
            isCurved: true,
            color: Colors.orange,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: AreaData(
              show: false,
            ),
          ),
          // Temperatura mínima
          LineChartBarData(
            spots: spots['min']!,
            isCurved: true,
            color: Colors.blue,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: AreaData(
              show: false,
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                final time = spot.x * simulationResults.timeStep;
                String label;
                if (spot.barIndex == 0) {
                  label = 'Máx: ${spot.y.toStringAsFixed(1)}°C';
                } else if (spot.barIndex == 1) {
                  label = 'Média: ${spot.y.toStringAsFixed(1)}°C';
                } else {
                  label = 'Mín: ${spot.y.toStringAsFixed(1)}°C';
                }
                return LineTooltipItem(
                  '$label\nTempo: ${time.toStringAsFixed(1)}s',
                  const TextStyle(color: Colors.white),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Map<String, List<FlSpot>> _createDataPoints() {
    // Em uma implementação real, esses dados viriam dos resultados da simulação
    // Aqui estamos criando dados sintéticos para demonstração
    
    final maxSpots = <FlSpot>[];
    final avgSpots = <FlSpot>[];
    final minSpots = <FlSpot>[];
    
    // Criar pontos para cada passo de tempo
    for (int i = 0; i < simulationResults.timeSteps; i++) {
      // Temperatura máxima (crescente e depois estabiliza)
      final maxTemp = i < simulationResults.timeSteps / 2
          ? metrics.minTemperature + (metrics.maxTemperature - metrics.minTemperature) * (i / (simulationResults.timeSteps / 2))
          : metrics.maxTemperature;
      
      // Temperatura média (crescente mais lenta)
      final avgTemp = i < simulationResults.timeSteps * 0.7
          ? metrics.minTemperature + (metrics.avgTemperature - metrics.minTemperature) * (i / (simulationResults.timeSteps * 0.7))
          : metrics.avgTemperature;
      
      // Temperatura mínima (crescente ainda mais lenta)
      final minTemp = i < simulationResults.timeSteps * 0.9
          ? metrics.minTemperature + ((metrics.minTemperature + 50) - metrics.minTemperature) * (i / (simulationResults.timeSteps * 0.9))
          : metrics.minTemperature + 50;
      
      maxSpots.add(FlSpot(i.toDouble(), maxTemp));
      avgSpots.add(FlSpot(i.toDouble(), avgTemp));
      minSpots.add(FlSpot(i.toDouble(), minTemp));
    }
    
    return {
      'max': maxSpots,
      'avg': avgSpots,
      'min': minSpots,
    };
  }
}
