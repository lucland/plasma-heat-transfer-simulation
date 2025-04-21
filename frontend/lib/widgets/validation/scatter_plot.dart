import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

class ScatterPlot extends ConsumerWidget {
  final List<double> referenceValues;
  final List<double> simulatedValues;

  const ScatterPlot({
    Key? key,
    required this.referenceValues,
    required this.simulatedValues,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Verificar se os dados são válidos
    if (referenceValues.isEmpty || simulatedValues.isEmpty || 
        referenceValues.length != simulatedValues.length) {
      return const Center(child: Text('Dados inválidos para o gráfico'));
    }

    // Encontrar limites
    final maxReference = referenceValues.reduce((a, b) => a > b ? a : b);
    final minReference = referenceValues.reduce((a, b) => a < b ? a : b);
    final maxSimulated = simulatedValues.reduce((a, b) => a > b ? a : b);
    final minSimulated = simulatedValues.reduce((a, b) => a < b ? a : b);
    
    final maxValue = maxReference > maxSimulated ? maxReference : maxSimulated;
    final minValue = minReference < minSimulated ? minReference : minSimulated;
    
    // Adicionar margem
    final range = maxValue - minValue;
    final margin = range * 0.1;
    
    // Criar pontos para o gráfico
    final spots = List.generate(
      referenceValues.length,
      (index) => FlSpot(referenceValues[index], simulatedValues[index]),
    );
    
    // Criar pontos para a linha de referência (y = x)
    final referenceLine = [
      FlSpot(minValue - margin, minValue - margin),
      FlSpot(maxValue + margin, maxValue + margin),
    ];

    return ScatterChart(
      ScatterChartData(
        scatterSpots: spots.map((spot) => 
          ScatterSpot(
            spot.x,
            spot.y,
            dotPainter: FlDotCirclePainter(
              color: _getPointColor(spot.x, spot.y),
              strokeWidth: 1,
              strokeColor: Colors.white,
            ),
          )
        ).toList(),
        minX: minValue - margin,
        maxX: maxValue + margin,
        minY: minValue - margin,
        maxY: maxValue + margin,
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300),
        ),
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: true,
          horizontalInterval: 50,
          verticalInterval: 50,
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
            axisNameWidget: const Text('Valores de Referência (°C)'),
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value % 100 == 0) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            axisNameWidget: const Text('Valores Simulados (°C)'),
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value % 100 == 0) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 40,
            ),
          ),
        ),
        scatterTouchData: ScatterTouchData(
          enabled: true,
          touchTooltipData: ScatterTouchTooltipData(
            tooltipBgColor: Colors.blueGrey,
            getTooltipItems: (ScatterSpot touchedSpot) {
              return ScatterTooltipItem(
                'Referência: ${touchedSpot.x.toStringAsFixed(1)} °C\nSimulado: ${touchedSpot.y.toStringAsFixed(1)} °C\nErro: ${(touchedSpot.y - touchedSpot.x).toStringAsFixed(1)} °C',
                textStyle: const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
      ),
      swapAnimationDuration: const Duration(milliseconds: 600),
    );
  }

  Color _getPointColor(double reference, double simulated) {
    final error = (simulated - reference).abs();
    final relativeError = error / reference;
    
    if (relativeError < 0.05) {
      return Colors.green;
    } else if (relativeError < 0.15) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
