import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/parametric_study.dart';
import 'dart:math' as math;

class ResultHeatmap extends StatefulWidget {
  final ParametricStudyResult studyResult;
  final String xParameter;
  final String yParameter;

  const ResultHeatmap({
    Key? key,
    required this.studyResult,
    required this.xParameter,
    required this.yParameter,
  }) : super(key: key);

  @override
  State<ResultHeatmap> createState() => _ResultHeatmapState();
}

class _ResultHeatmapState extends State<ResultHeatmap> {
  // Dados processados para o mapa de calor
  late List<List<double>> _heatmapData;
  late List<double> _xValues;
  late List<double> _yValues;
  late double _minValue;
  late double _maxValue;
  
  @override
  void initState() {
    super.initState();
    _processData();
  }
  
  @override
  void didUpdateWidget(ResultHeatmap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.studyResult != widget.studyResult ||
        oldWidget.xParameter != widget.xParameter ||
        oldWidget.yParameter != widget.yParameter) {
      _processData();
    }
  }
  
  void _processData() {
    // Extrair valores únicos para os parâmetros X e Y
    final xValueSet = <double>{};
    final yValueSet = <double>{};
    
    for (final result in widget.studyResult.simulationResults) {
      if (result.parameterValues.containsKey(widget.xParameter) &&
          result.parameterValues.containsKey(widget.yParameter)) {
        xValueSet.add(result.parameterValues[widget.xParameter]!);
        yValueSet.add(result.parameterValues[widget.yParameter]!);
      }
    }
    
    _xValues = xValueSet.toList()..sort();
    _yValues = yValueSet.toList()..sort();
    
    // Inicializar matriz de dados com NaN (para valores ausentes)
    _heatmapData = List.generate(
      _yValues.length,
      (_) => List.filled(_xValues.length, double.nan),
    );
    
    // Preencher matriz com valores da métrica alvo
    for (final result in widget.studyResult.simulationResults) {
      if (result.parameterValues.containsKey(widget.xParameter) &&
          result.parameterValues.containsKey(widget.yParameter)) {
        final xValue = result.parameterValues[widget.xParameter]!;
        final yValue = result.parameterValues[widget.yParameter]!;
        
        final xIndex = _xValues.indexOf(xValue);
        final yIndex = _yValues.indexOf(yValue);
        
        if (xIndex >= 0 && yIndex >= 0) {
          _heatmapData[yIndex][xIndex] = result.targetMetricValue;
        }
      }
    }
    
    // Encontrar valores mínimo e máximo para a escala de cores
    _minValue = double.infinity;
    _maxValue = double.negativeInfinity;
    
    for (final row in _heatmapData) {
      for (final value in row) {
        if (!value.isNaN) {
          _minValue = math.min(_minValue, value);
          _maxValue = math.max(_maxValue, value);
        }
      }
    }
    
    // Ajustar para evitar divisão por zero
    if (_minValue == _maxValue) {
      _minValue -= 0.1;
      _maxValue += 0.1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _buildHeatmap(),
        ),
        const SizedBox(height: 16),
        _buildColorScale(),
      ],
    );
  }
  
  Widget _buildHeatmap() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = constraints.maxWidth / _xValues.length;
        final cellHeight = constraints.maxHeight / _yValues.length;
        
        return Stack(
          children: [
            // Células do mapa de calor
            ...List.generate(_yValues.length, (yIndex) {
              return List.generate(_xValues.length, (xIndex) {
                final value = _heatmapData[yIndex][xIndex];
                
                if (value.isNaN) {
                  return const SizedBox.shrink();
                }
                
                final normalizedValue = (value - _minValue) / (_maxValue - _minValue);
                final color = _getColorForValue(normalizedValue);
                
                return Positioned(
                  left: xIndex * cellWidth,
                  top: yIndex * cellHeight,
                  width: cellWidth,
                  height: cellHeight,
                  child: GestureDetector(
                    onTap: () => _showValueDetails(xIndex, yIndex, value),
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        border: Border.all(
                          color: Colors.white,
                          width: 0.5,
                        ),
                      ),
                    ),
                  ),
                );
              });
            }).expand((widgets) => widgets).toList(),
            
            // Eixo X
            Positioned(
              left: 0,
              bottom: 0,
              right: 0,
              height: 30,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _xValues.map((value) {
                  return SizedBox(
                    width: cellWidth,
                    child: Text(
                      value.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  );
                }).toList(),
              ),
            ),
            
            // Eixo Y
            Positioned(
              left: 0,
              top: 0,
              bottom: 30,
              width: 30,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _yValues.map((value) {
                  return SizedBox(
                    height: cellHeight,
                    child: Center(
                      child: Text(
                        value.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  );
                }).toList().reversed.toList(),
              ),
            ),
            
            // Rótulo do eixo X
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  _formatParameterName(widget.xParameter),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            
            // Rótulo do eixo Y
            Positioned(
              top: 0,
              left: 0,
              bottom: 0,
              child: RotatedBox(
                quarterTurns: 3,
                child: Center(
                  child: Text(
                    _formatParameterName(widget.yParameter),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildColorScale() {
    return SizedBox(
      height: 30,
      child: Row(
        children: [
          Text(
            _minValue.toStringAsFixed(1),
            style: const TextStyle(fontSize: 10),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade900,
                    Colors.blue.shade500,
                    Colors.green.shade500,
                    Colors.yellow,
                    Colors.orange,
                    Colors.red,
                  ],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Text(
            _maxValue.toStringAsFixed(1),
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }
  
  Color _getColorForValue(double normalizedValue) {
    // Escala de cores: azul escuro -> azul -> verde -> amarelo -> laranja -> vermelho
    if (normalizedValue <= 0) {
      return Colors.blue.shade900;
    } else if (normalizedValue <= 0.2) {
      return Color.lerp(Colors.blue.shade900, Colors.blue.shade500, normalizedValue * 5)!;
    } else if (normalizedValue <= 0.4) {
      return Color.lerp(Colors.blue.shade500, Colors.green.shade500, (normalizedValue - 0.2) * 5)!;
    } else if (normalizedValue <= 0.6) {
      return Color.lerp(Colors.green.shade500, Colors.yellow, (normalizedValue - 0.4) * 5)!;
    } else if (normalizedValue <= 0.8) {
      return Color.lerp(Colors.yellow, Colors.orange, (normalizedValue - 0.6) * 5)!;
    } else if (normalizedValue <= 1.0) {
      return Color.lerp(Colors.orange, Colors.red, (normalizedValue - 0.8) * 5)!;
    } else {
      return Colors.red;
    }
  }
  
  void _showValueDetails(int xIndex, int yIndex, double value) {
    final xValue = _xValues[xIndex];
    final yValue = _yValues[yIndex];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalhes do Ponto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_formatParameterName(widget.xParameter)}: ${xValue.toStringAsFixed(2)}'),
            Text('${_formatParameterName(widget.yParameter)}: ${yValue.toStringAsFixed(2)}'),
            const Divider(),
            Text(
              '${_formatMetricName(widget.studyResult.config.targetMetric)}: ${value.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
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
  
  String _formatMetricName(String metric) {
    switch (metric) {
      case 'max_temperature':
        return 'Temperatura Máxima';
      case 'min_temperature':
        return 'Temperatura Mínima';
      case 'avg_temperature':
        return 'Temperatura Média';
      case 'max_gradient':
        return 'Gradiente Máximo';
      case 'avg_gradient':
        return 'Gradiente Médio';
      case 'max_heat_flux':
        return 'Fluxo de Calor Máximo';
      case 'avg_heat_flux':
        return 'Fluxo de Calor Médio';
      case 'total_energy':
        return 'Energia Total';
      case 'heating_rate':
        return 'Taxa de Aquecimento';
      case 'energy_efficiency':
        return 'Eficiência Energética';
      default:
        return metric;
    }
  }
}
