import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/parametric_study.dart';

class SensitivityChart extends StatelessWidget {
  final Map<String, double> sensitivityAnalysis;

  const SensitivityChart({
    Key? key,
    required this.sensitivityAnalysis,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ordenar parâmetros por sensibilidade (valor absoluto)
    final sortedEntries = sensitivityAnalysis.entries.toList()
      ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));

    // Preparar dados para o gráfico
    final barGroups = <BarChartGroupData>[];
    final titles = <String>[];

    for (int i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      final paramName = _formatParameterName(entry.key);
      final sensitivity = entry.value;

      titles.add(paramName);
      
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: sensitivity,
              color: sensitivity > 0 
                  ? Colors.blue 
                  : Colors.red,
              width: 20,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 1.1,
        minY: -1.1,
        groupsSpace: 12,
        barGroups: barGroups,
        gridData: FlGridData(
          show: true,
          checkToShowHorizontalLine: (value) => 
              value == 0 || value == 0.5 || value == -0.5 || value == 1.0 || value == -1.0,
          getDrawingHorizontalLine: (value) {
            if (value == 0) {
              return FlLine(
                color: Colors.grey.shade400,
                strokeWidth: 2,
              );
            }
            return FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= titles.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    titles[value.toInt()],
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              },
              reservedSize: 60,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                String text;
                switch (value.toInt()) {
                  case -1:
                    text = '-1.0';
                    break;
                  case -0:
                    text = '0.0';
                    break;
                  case 1:
                    text = '1.0';
                    break;
                  default:
                    return const SizedBox.shrink();
                }
                return Text(
                  text,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                );
              },
              reservedSize: 30,
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueGrey,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final paramName = titles[group.x.toInt()];
              final sensitivity = rod.toY;
              return BarTooltipItem(
                '$paramName\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: 'Sensibilidade: ${(sensitivity * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String _formatParameterName(String paramName) {
    switch (paramName) {
      case 'torch_power':
        return 'Potência da Tocha';
      case 'torch_efficiency':
        return 'Eficiência da Tocha';
      case 'thermal_conductivity':
        return 'Condutividade Térmica';
      case 'specific_heat':
        return 'Calor Específico';
      case 'density':
        return 'Densidade';
      case 'emissivity':
        return 'Emissividade';
      case 'time_step':
        return 'Passo de Tempo';
      case 'max_iterations':
        return 'Máximo de Iterações';
      case 'convergence_tolerance':
        return 'Tolerância de Convergência';
      case 'ambient_temperature':
        return 'Temperatura Ambiente';
      default:
        return paramName;
    }
  }
}
