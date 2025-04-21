import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/simulation_results.dart';
import '../state/simulation_state.dart';

class SimulationScreen extends ConsumerStatefulWidget {
  const SimulationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends ConsumerState<SimulationScreen> {
  int _currentTimeStep = 0;
  bool _showColorScale = true;

  @override
  Widget build(BuildContext context) {
    final simulationState = ref.watch(simulationStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Simulação de Fornalha de Plasma'),
        actions: [
          IconButton(
            icon: Icon(_showColorScale ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              setState(() {
                _showColorScale = !_showColorScale;
              });
            },
            tooltip: 'Mostrar/ocultar escala de cores',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusBar(simulationState),
          Expanded(
            child: _buildSimulationView(simulationState),
          ),
          if (simulationState.isCompleted || simulationState.isRunning || simulationState.isPaused)
            _buildTimeControls(simulationState),
        ],
      ),
    );
  }

  Widget _buildStatusBar(SimulationState state) {
    String statusText;
    Color statusColor;

    switch (state.status) {
      case SimulationStatus.notStarted:
        statusText = 'Não iniciada';
        statusColor = Colors.grey;
        break;
      case SimulationStatus.running:
        statusText = 'Em execução (${(state.progress * 100).toStringAsFixed(1)}%)';
        statusColor = Colors.blue;
        break;
      case SimulationStatus.paused:
        statusText = 'Pausada (${(state.progress * 100).toStringAsFixed(1)}%)';
        statusColor = Colors.orange;
        break;
      case SimulationStatus.completed:
        statusText = 'Concluída (${state.executionTime.toStringAsFixed(2)}s)';
        statusColor = Colors.green;
        break;
      case SimulationStatus.failed:
        statusText = 'Falha: ${state.errorMessage ?? "Erro desconhecido"}';
        statusColor = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8.0),
      color: statusColor.withOpacity(0.2),
      child: Row(
        children: [
          Icon(
            state.isRunning
                ? Icons.play_arrow
                : state.isPaused
                    ? Icons.pause
                    : state.isCompleted
                        ? Icons.check_circle
                        : state.isFailed
                            ? Icons.error
                            : Icons.hourglass_empty,
            color: statusColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (state.isRunning)
            ElevatedButton(
              onPressed: () {
                ref.read(simulationStateProvider.notifier).pauseSimulation();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text('Pausar'),
            )
          else if (state.isPaused)
            ElevatedButton(
              onPressed: () {
                ref.read(simulationStateProvider.notifier).resumeSimulation();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: const Text('Retomar'),
            )
          else if (state.status == SimulationStatus.notStarted)
            ElevatedButton(
              onPressed: () {
                ref.read(simulationStateProvider.notifier).startSimulation();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: const Text('Iniciar'),
            ),
        ],
      ),
    );
  }

  Widget _buildSimulationView(SimulationState state) {
    if (state.status == SimulationStatus.notStarted) {
      return const Center(
        child: Text('Configure os parâmetros e inicie a simulação'),
      );
    }

    if (state.isFailed) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Erro na simulação: ${state.errorMessage ?? "Erro desconhecido"}',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (state.isRunning && state.results == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Simulação em andamento: ${(state.progress * 100).toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Se temos resultados (parciais ou completos), mostrar visualização
    if (state.results != null) {
      return _buildHeatmapVisualization(state.results!);
    }

    // Caso padrão
    return const Center(
      child: Text('Aguardando dados da simulação...'),
    );
  }

  Widget _buildHeatmapVisualization(SimulationResults results) {
    // Limitar o passo de tempo atual ao número de passos disponíveis
    final maxTimeStep = results.timeSteps - 1;
    if (_currentTimeStep > maxTimeStep) {
      _currentTimeStep = maxTimeStep;
    }

    // Obter dados de temperatura para o passo de tempo atual
    final temperatureData = results.getTemperatureAtStep(_currentTimeStep);
    final maxTemp = results.getMaxTemperature(_currentTimeStep);
    final minTemp = results.getMinTemperature(_currentTimeStep);

    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildHeatmap(temperatureData, minTemp, maxTemp),
          ),
        ),
        if (_showColorScale) _buildColorScale(minTemp, maxTemp),
      ],
    );
  }

  Widget _buildHeatmap(List<List<double>> data, double minTemp, double maxTemp) {
    if (data.isEmpty || data[0].isEmpty) {
      return const Center(child: Text('Sem dados para visualização'));
    }

    final nr = data.length;
    final nz = data[0].length;

    // Criar uma representação visual da malha cilíndrica
    return AspectRatio(
      aspectRatio: 0.5, // Proporção altura/largura do cilindro
      child: CustomPaint(
        painter: HeatmapPainter(
          data: data,
          minValue: minTemp,
          maxValue: maxTemp,
        ),
      ),
    );
  }

  Widget _buildColorScale(double minTemp, double maxTemp) {
    return Container(
      width: 60,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${maxTemp.toStringAsFixed(1)}°C',
            style: const TextStyle(fontSize: 12),
          ),
          Expanded(
            child: Container(
              width: 20,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.red,
                    Colors.orange,
                    Colors.yellow,
                    Colors.green,
                    Colors.blue,
                  ],
                ),
              ),
            ),
          ),
          Text(
            '${minTemp.toStringAsFixed(1)}°C',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeControls(SimulationState state) {
    final results = state.results;
    if (results == null) return const SizedBox.shrink();

    final maxTimeStep = results.timeSteps - 1;

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous),
                onPressed: _currentTimeStep > 0
                    ? () {
                        setState(() {
                          _currentTimeStep = 0;
                        });
                      }
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.fast_rewind),
                onPressed: _currentTimeStep > 0
                    ? () {
                        setState(() {
                          _currentTimeStep = (_currentTimeStep - 10).clamp(0, maxTimeStep);
                        });
                      }
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.arrow_left),
                onPressed: _currentTimeStep > 0
                    ? () {
                        setState(() {
                          _currentTimeStep--;
                        });
                      }
                    : null,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Passo $_currentTimeStep / $maxTimeStep',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_right),
                onPressed: _currentTimeStep < maxTimeStep
                    ? () {
                        setState(() {
                          _currentTimeStep++;
                        });
                      }
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.fast_forward),
                onPressed: _currentTimeStep < maxTimeStep
                    ? () {
                        setState(() {
                          _currentTimeStep = (_currentTimeStep + 10).clamp(0, maxTimeStep);
                        });
                      }
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.skip_next),
                onPressed: _currentTimeStep < maxTimeStep
                    ? () {
                        setState(() {
                          _currentTimeStep = maxTimeStep;
                        });
                      }
                    : null,
              ),
            ],
          ),
          Slider(
            value: _currentTimeStep.toDouble(),
            min: 0,
            max: maxTimeStep.toDouble(),
            divisions: maxTimeStep,
            label: _currentTimeStep.toString(),
            onChanged: (value) {
              setState(() {
                _currentTimeStep = value.round();
              });
            },
          ),
        ],
      ),
    );
  }
}

// Painter personalizado para desenhar o mapa de calor
class HeatmapPainter extends CustomPainter {
  final List<List<double>> data;
  final double minValue;
  final double maxValue;

  HeatmapPainter({
    required this.data,
    required this.minValue,
    required this.maxValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || data[0].isEmpty) return;

    final nr = data.length;
    final nz = data[0].length;

    final cellWidth = size.width / nr;
    final cellHeight = size.height / nz;

    for (int i = 0; i < nr; i++) {
      for (int j = 0; j < nz; j++) {
        final value = data[i][j];
        final normalizedValue = (value - minValue) / (maxValue - minValue);
        
        // Mapear valor para cor (azul -> verde -> amarelo -> vermelho)
        final color = _getColorForValue(normalizedValue);
        
        final rect = Rect.fromLTWH(
          i * cellWidth,
          (nz - j - 1) * cellHeight, // Inverter eixo y para que a base do cilindro fique embaixo
          cellWidth,
          cellHeight,
        );
        
        final paint = Paint()..color = color;
        canvas.drawRect(rect, paint);
      }
    }

    // Desenhar contorno
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      borderPaint,
    );
  }

  Color _getColorForValue(double normalizedValue) {
    if (normalizedValue <= 0) return Colors.blue;
    if (normalizedValue >= 1) return Colors.red;
    
    if (normalizedValue < 0.25) {
      // Azul para ciano
      return Color.lerp(Colors.blue, Colors.cyan, normalizedValue * 4)!;
    } else if (normalizedValue < 0.5) {
      // Ciano para verde
      return Color.lerp(Colors.cyan, Colors.green, (normalizedValue - 0.25) * 4)!;
    } else if (normalizedValue < 0.75) {
      // Verde para amarelo
      return Color.lerp(Colors.green, Colors.yellow, (normalizedValue - 0.5) * 4)!;
    } else {
      // Amarelo para vermelho
      return Color.lerp(Colors.yellow, Colors.red, (normalizedValue - 0.75) * 4)!;
    }
  }

  @override
  bool shouldRepaint(covariant HeatmapPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.minValue != minValue ||
        oldDelegate.maxValue != maxValue;
  }
}
