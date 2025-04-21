import 'package:flutter/foundation.dart';

// Modelo para os resultados da simulação
class SimulationResults {
  // Dimensões da malha
  final int nr;
  final int nz;
  final int timeSteps;
  
  // Dados de temperatura (nr x nz x timeSteps)
  final List<List<List<double>>> temperatureData;
  
  // Tempo de execução
  final double executionTime;
  
  SimulationResults({
    required this.nr,
    required this.nz,
    required this.timeSteps,
    required this.temperatureData,
    required this.executionTime,
  });
  
  // Obtém os dados de temperatura para um passo de tempo específico
  List<List<double>> getTemperatureAtStep(int timeStep) {
    if (timeStep < 0 || timeStep >= timeSteps) {
      throw ArgumentError('Passo de tempo inválido: $timeStep');
    }
    
    return temperatureData.map((row) => 
      row.map((col) => col[timeStep]).toList()
    ).toList();
  }
  
  // Obtém a temperatura máxima para um passo de tempo específico
  double getMaxTemperature(int timeStep) {
    final data = getTemperatureAtStep(timeStep);
    double max = double.negativeInfinity;
    
    for (var row in data) {
      for (var value in row) {
        if (value > max) {
          max = value;
        }
      }
    }
    
    return max;
  }
  
  // Obtém a temperatura mínima para um passo de tempo específico
  double getMinTemperature(int timeStep) {
    final data = getTemperatureAtStep(timeStep);
    double min = double.infinity;
    
    for (var row in data) {
      for (var value in row) {
        if (value < min) {
          min = value;
        }
      }
    }
    
    return min;
  }
  
  // Cria uma instância vazia para testes
  factory SimulationResults.empty() {
    return SimulationResults(
      nr: 0,
      nz: 0,
      timeSteps: 0,
      temperatureData: [],
      executionTime: 0.0,
    );
  }
}

// Enumeração para o status da simulação
enum SimulationStatus {
  notStarted,
  running,
  paused,
  completed,
  failed,
}

// Modelo para o estado da simulação
class SimulationState {
  final SimulationStatus status;
  final double progress;
  final String? errorMessage;
  final double executionTime;
  final SimulationResults? results;
  
  SimulationState({
    required this.status,
    required this.progress,
    this.errorMessage,
    required this.executionTime,
    this.results,
  });
  
  // Cria uma instância inicial
  factory SimulationState.initial() {
    return SimulationState(
      status: SimulationStatus.notStarted,
      progress: 0.0,
      executionTime: 0.0,
    );
  }
  
  // Cria uma cópia com alguns parâmetros alterados
  SimulationState copyWith({
    SimulationStatus? status,
    double? progress,
    String? errorMessage,
    double? executionTime,
    SimulationResults? results,
  }) {
    return SimulationState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
      executionTime: executionTime ?? this.executionTime,
      results: results ?? this.results,
    );
  }
  
  // Verifica se a simulação está em execução
  bool get isRunning => status == SimulationStatus.running;
  
  // Verifica se a simulação está pausada
  bool get isPaused => status == SimulationStatus.paused;
  
  // Verifica se a simulação está concluída
  bool get isCompleted => status == SimulationStatus.completed;
  
  // Verifica se a simulação falhou
  bool get isFailed => status == SimulationStatus.failed;
}
