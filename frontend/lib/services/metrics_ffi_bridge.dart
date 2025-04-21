import 'dart:convert';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../models/metrics.dart';
import 'ffi_bridge.dart'; // Import base bridge
import 'formula_ffi_bridge.dart'; // Import for helpers (temporary)

// --- FFI Function Typedefs for Metrics/Export (JSON based) ---

typedef CalculateMetricsJsonNative = Pointer<Utf8> Function();
typedef CalculateMetricsJsonDart = Pointer<Utf8> Function();

typedef ExportResultsJsonNative = Int32 Function(Pointer<Utf8>);
typedef ExportResultsJsonDart = int Function(Pointer<Utf8>);

typedef GenerateReportJsonNative = Int32 Function(Pointer<Utf8>);
typedef GenerateReportJsonDart = int Function(Pointer<Utf8>);

// Extensão da ponte FFI para suportar métricas e exportação
extension MetricsFFIBridge on FFIBridge {
  // REMOVED: Note about using helpers from FormulaFFIBridgeExtension
  // The helpers are now public on FFIBridge itself.

  // Calcula métricas a partir dos resultados da simulação
  Future<SimulationMetrics> calculateMetrics() async {
    try {
      // Load func directly
      final func = dylib
          .lookup<NativeFunction<CalculateMetricsJsonNative>>(
              'calculate_metrics_json')
          .asFunction<CalculateMetricsJsonDart>();
      final jsonString =
          callJsonReturningFunction(func); // Use public helper from FFIBridge
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      return SimulationMetrics.fromJson(jsonMap);
    } catch (e) {
      print("Error in calculateMetrics: $e");
      throw Exception('Erro ao calcular métricas: $e');
    }
  }

  // Exporta resultados da simulação
  Future<void> exportResults(ExportOptions options) async {
    try {
      // Load func directly
      final func = dylib
          .lookup<NativeFunction<ExportResultsJsonNative>>(
              'export_results_json')
          .asFunction<ExportResultsJsonDart>();
      final optionsJson = json.encode(options.toJson());
      callVoidReturningFunction1Arg(
          func, optionsJson); // Use public helper from FFIBridge
    } catch (e) {
      print("Error in exportResults: $e");
      throw Exception('Erro ao exportar resultados: $e');
    }
  }

  // Gera um relatório com os resultados da simulação
  Future<void> generateReport(String outputPath) async {
    try {
      // Load func directly
      final func = dylib
          .lookup<NativeFunction<GenerateReportJsonNative>>(
              'generate_report_json')
          .asFunction<GenerateReportJsonDart>();
      callVoidReturningFunction1Arg(
          func, outputPath); // Use public helper from FFIBridge
    } catch (e) {
      print("Error in generateReport: $e");
      throw Exception('Erro ao gerar relatório: $e');
    }
  }

  // REMOVED: _callNativeFunction simulation
}
