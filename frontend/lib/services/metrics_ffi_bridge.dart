import 'dart:convert';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../models/metrics.dart';

// Extensão da ponte FFI para suportar métricas e exportação
extension MetricsFFIBridge on FFIBridge {
  // Calcula métricas a partir dos resultados da simulação
  Future<SimulationMetrics> calculateMetrics() async {
    try {
      final jsonString = _callNativeFunction('calculate_metrics', []);
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      return SimulationMetrics.fromJson(jsonMap);
    } catch (e) {
      throw Exception('Erro ao calcular métricas: $e');
    }
  }

  // Exporta resultados da simulação
  Future<void> exportResults(ExportOptions options) async {
    try {
      final optionsJson = json.encode(options.toJson());
      _callNativeFunction('export_results', [optionsJson]);
    } catch (e) {
      throw Exception('Erro ao exportar resultados: $e');
    }
  }

  // Gera um relatório com os resultados da simulação
  Future<void> generateReport(String outputPath) async {
    try {
      _callNativeFunction('generate_report', [outputPath]);
    } catch (e) {
      throw Exception('Erro ao gerar relatório: $e');
    }
  }

  // Método auxiliar para chamar funções nativas
  String _callNativeFunction(String functionName, List<String> args) {
    // Implementação simplificada - em um ambiente real, isso chamaria
    // as funções FFI reais definidas no backend Rust
    
    // Simulação para desenvolvimento
    if (functionName == 'calculate_metrics') {
      // Retornar dados de métricas simulados
      return '''
      {
        "min_temperature": 25.0,
        "max_temperature": 500.0,
        "avg_temperature": 250.0,
        "std_temperature": 75.0,
        "max_gradient": 100.0,
        "max_heat_flux": 5000.0,
        "total_energy": 1000000.0,
        "avg_heating_rate": 10.0,
        "region_metrics": [
          {
            "name": "Centro",
            "min_temperature": 400.0,
            "max_temperature": 500.0,
            "avg_temperature": 450.0,
            "volume": 0.01,
            "energy": 500000.0
          },
          {
            "name": "Meio",
            "min_temperature": 200.0,
            "max_temperature": 400.0,
            "avg_temperature": 300.0,
            "volume": 0.02,
            "energy": 350000.0
          },
          {
            "name": "Periferia",
            "min_temperature": 25.0,
            "max_temperature": 200.0,
            "avg_temperature": 100.0,
            "volume": 0.03,
            "energy": 150000.0
          }
        ],
        "temporal_metrics": {
          "time_to_half_max": 5.0,
          "time_to_90_percent_max": 15.0,
          "max_heating_rate": 20.0,
          "stabilization_time": 30.0
        }
      }
      ''';
    }
    
    return '';
  }
}
