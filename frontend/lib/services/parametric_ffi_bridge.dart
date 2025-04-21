import 'dart:async';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../models/parametric_study.dart';
import 'dart:convert';
import 'ffi_bridge.dart';

// --- FFI Function Typedefs for Parametric Studies (JSON based) ---

typedef GetPredefinedStudiesJsonNative = Pointer<Utf8> Function();
typedef GetPredefinedStudiesJsonDart = Pointer<Utf8> Function();

typedef GetPredefinedStudyJsonNative = Pointer<Utf8> Function(Pointer<Utf8>);
typedef GetPredefinedStudyJsonDart = Pointer<Utf8> Function(Pointer<Utf8>);

typedef RunParametricStudyJsonNative = Pointer<Utf8> Function(Pointer<Utf8>);
typedef RunParametricStudyJsonDart = Pointer<Utf8> Function(Pointer<Utf8>);

typedef GenerateParametricStudyReportJsonNative = Int32 Function(
    Pointer<Utf8>, Pointer<Utf8>);
typedef GenerateParametricStudyReportJsonDart = int Function(
    Pointer<Utf8>, Pointer<Utf8>);

// Ponte FFI para estudos paramétricos - Changed to Extension
extension ParametricFFIBridgeExtension on FFIBridge {
  // Obtém estudos paramétricos predefinidos
  Future<List<ParametricStudyConfig>> getPredefinedStudies() async {
    try {
      // Load func directly
      final func = dylib
          .lookup<NativeFunction<GetPredefinedStudiesJsonNative>>(
              'get_predefined_studies_json')
          .asFunction<GetPredefinedStudiesJsonDart>();
      final jsonString = callJsonReturningFunction(func);
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((json) => ParametricStudyConfig.fromJson(json))
          .toList();
    } catch (e) {
      print("Error in getPredefinedStudies: $e");
      throw Exception('Erro ao obter estudos predefinidos: $e');
    }
  }

  // Obtém um estudo paramétrico predefinido específico
  Future<ParametricStudyConfig> getPredefinedStudy(String studyType) async {
    try {
      // Load func directly
      final func = dylib
          .lookup<NativeFunction<GetPredefinedStudyJsonNative>>(
              'get_predefined_study_json')
          .asFunction<GetPredefinedStudyJsonDart>();
      final jsonString = callJsonReturningFunction1Arg(func, studyType);
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      if (jsonMap.isEmpty) {
        // Assuming empty means not found
        throw Exception("Estudo predefinido '$studyType' não encontrado.");
      }
      return ParametricStudyConfig.fromJson(jsonMap);
    } catch (e) {
      print("Error in getPredefinedStudy: $e");
      throw Exception('Erro ao obter estudo predefinido: $e');
    }
  }

  // Executa um estudo paramétrico
  Future<ParametricStudyResult> runParametricStudy(
      ParametricStudyConfig config) async {
    try {
      // Load func directly
      final func = dylib
          .lookup<NativeFunction<RunParametricStudyJsonNative>>(
              'run_parametric_study_json')
          .asFunction<RunParametricStudyJsonDart>();
      final configJson = json.encode(config.toJson());
      final jsonString = callJsonReturningFunction1Arg(func, configJson);
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      // Need to ensure ParametricStudyResult.fromJson handles potentially nested data
      return ParametricStudyResult.fromJson(jsonMap);
    } catch (e) {
      print("Error in runParametricStudy: $e");
      throw Exception('Erro ao executar estudo paramétrico: $e');
    }
  }

  // Gera um relatório do estudo paramétrico
  Future<void> generateParametricStudyReport(
      ParametricStudyResult result, String outputPath) async {
    try {
      // Load func directly
      final func = dylib
          .lookup<NativeFunction<GenerateParametricStudyReportJsonNative>>(
              'generate_parametric_study_report_json')
          .asFunction<GenerateParametricStudyReportJsonDart>();
      final resultJson = json.encode(result.toJson());
      callVoidReturningFunction2Args(func, resultJson, outputPath);
    } catch (e) {
      print("Error in generateParametricStudyReport: $e");
      throw Exception('Erro ao gerar relatório: $e');
    }
  }
}
