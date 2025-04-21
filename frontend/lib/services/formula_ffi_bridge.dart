import 'dart:convert';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../models/formula.dart';
import 'ffi_bridge.dart'; // Import base bridge

// --- FFI Function Typedefs for Formulas (JSON based) ---

typedef GetAllFormulasJsonNative = Pointer<Utf8> Function();
typedef GetAllFormulasJsonDart = Pointer<Utf8> Function();

typedef GetFormulasByCategoryJsonNative = Pointer<Utf8> Function(Pointer<Utf8>);
typedef GetFormulasByCategoryJsonDart = Pointer<Utf8> Function(Pointer<Utf8>);

typedef GetFormulaJsonNative = Pointer<Utf8> Function(Pointer<Utf8>);
typedef GetFormulaJsonDart = Pointer<Utf8> Function(Pointer<Utf8>);

typedef SaveFormulaJsonNative = Int32 Function(Pointer<Utf8>);
typedef SaveFormulaJsonDart = int Function(Pointer<Utf8>);

typedef DeleteFormulaJsonNative = Int32 Function(Pointer<Utf8>);
typedef DeleteFormulaJsonDart = int Function(Pointer<Utf8>);

typedef ValidateFormulaJsonNative = Pointer<Utf8> Function(
    Pointer<Utf8>, Pointer<Utf8>);
typedef ValidateFormulaJsonDart = Pointer<Utf8> Function(
    Pointer<Utf8>, Pointer<Utf8>);

typedef EvaluateFormulaJsonNative = Pointer<Utf8> Function(
    Pointer<Utf8>, Pointer<Utf8>);
typedef EvaluateFormulaJsonDart = Pointer<Utf8> Function(
    Pointer<Utf8>, Pointer<Utf8>);

typedef SetFormulaForFunctionJsonNative = Int32 Function(
    Pointer<Utf8>, Pointer<Utf8>);
typedef SetFormulaForFunctionJsonDart = int Function(
    Pointer<Utf8>, Pointer<Utf8>);

typedef GetFormulaForFunctionJsonNative = Pointer<Utf8> Function(Pointer<Utf8>);
typedef GetFormulaForFunctionJsonDart = Pointer<Utf8> Function(Pointer<Utf8>);

// --- FFI Function Pointers Storage (using extension) ---
// We need a way to store the loaded functions. Since extensions can't have
// instance fields, we'll store them globally or manage them via the main FFIBridge.
// For simplicity, let's load them on demand within each method for now,
// though loading once in FFIBridge.initialize() would be more efficient.

// Extensão da ponte FFI para suportar o editor de fórmulas
extension FormulaFFIBridgeExtension on FFIBridge {
  // Obtém todas as fórmulas disponíveis
  Future<List<Formula>> getAllFormulas() async {
    try {
      // Load func directly
      final func = dylib
          .lookup<NativeFunction<GetAllFormulasJsonNative>>(
              'get_all_formulas_json')
          .asFunction<GetAllFormulasJsonDart>();
      final jsonString = callJsonReturningFunction(func);
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => Formula.fromJson(json)).toList();
    } catch (e) {
      print("Error in getAllFormulas: $e");
      throw Exception('Erro ao obter fórmulas: $e');
    }
  }

  // Obtém fórmulas por categoria
  Future<List<Formula>> getFormulasByCategory(String category) async {
    try {
      // Load func directly
      final func = dylib
          .lookup<NativeFunction<GetFormulasByCategoryJsonNative>>(
              'get_formulas_by_category_json')
          .asFunction<GetFormulasByCategoryJsonDart>();
      final jsonString = callJsonReturningFunction1Arg(func, category);
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => Formula.fromJson(json)).toList();
    } catch (e) {
      print("Error in getFormulasByCategory: $e");
      throw Exception('Erro ao obter fórmulas por categoria: $e');
    }
  }

  // Obtém uma fórmula pelo ID
  Future<Formula> getFormula(String id) async {
    try {
      // Load func directly
      final func = dylib
          .lookup<NativeFunction<GetFormulaJsonNative>>('get_formula_json')
          .asFunction<GetFormulaJsonDart>();
      final jsonString = callJsonReturningFunction1Arg(func, id);
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      // Handle case where Rust returns empty JSON `{}` for not found?
      if (jsonMap.isEmpty) {
        throw Exception("Fórmula com ID '$id' não encontrada.");
      }
      return Formula.fromJson(jsonMap);
    } catch (e) {
      print("Error in getFormula: $e");
      throw Exception('Erro ao obter fórmula: $e');
    }
  }

  // Salva uma fórmula
  Future<void> saveFormula(Formula formula) async {
    try {
      // Load func directly
      final func = dylib
          .lookup<NativeFunction<SaveFormulaJsonNative>>('save_formula_json')
          .asFunction<SaveFormulaJsonDart>();
      final jsonString = json.encode(formula.toJson());
      callVoidReturningFunction1Arg(func, jsonString);
    } catch (e) {
      print("Error in saveFormula: $e");
      throw Exception('Erro ao salvar fórmula: $e');
    }
  }

  // Exclui uma fórmula
  Future<void> deleteFormula(String id) async {
    try {
      // Load func directly
      final func = dylib
          .lookup<NativeFunction<DeleteFormulaJsonNative>>(
              'delete_formula_json')
          .asFunction<DeleteFormulaJsonDart>();
      callVoidReturningFunction1Arg(func, id);
    } catch (e) {
      print("Error in deleteFormula: $e");
      throw Exception('Erro ao excluir fórmula: $e');
    }
  }

  // Valida uma fórmula
  Future<FormulaValidationResult> validateFormula(
    String source,
    List<FormulaParameter> parameters, // Assuming FormulaParameter has toJson
  ) async {
    try {
      // Load func directly
      final func = dylib
          .lookup<NativeFunction<ValidateFormulaJsonNative>>(
              'validate_formula_json')
          .asFunction<ValidateFormulaJsonDart>();
      // Pass source directly if it's the formula string itself
      final parametersJson =
          json.encode(parameters.map((p) => p.toJson()).toList());
      final jsonString =
          callJsonReturningFunction2Args(func, source, parametersJson);
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      return FormulaValidationResult.fromJson(jsonMap);
    } catch (e) {
      print("Error in validateFormula: $e");
      throw Exception('Erro ao validar fórmula: $e');
    }
  }

  // Avalia uma fórmula com parâmetros específicos
  Future<FormulaEvaluationResult> evaluateFormula(
    String id, // ID of the formula to evaluate
    Map<String, dynamic> parameters, // Parameters for evaluation
  ) async {
    try {
      // Load func directly
      final func = dylib
          .lookup<NativeFunction<EvaluateFormulaJsonNative>>(
              'evaluate_formula_json')
          .asFunction<EvaluateFormulaJsonDart>();
      final parametersJson = json.encode(parameters);
      final jsonString =
          callJsonReturningFunction2Args(func, id, parametersJson);
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      return FormulaEvaluationResult.fromJson(jsonMap);
    } catch (e) {
      print("Error in evaluateFormula: $e");
      throw Exception('Erro ao avaliar fórmula: $e');
    }
  }

  // Define uma fórmula para uma função específica
  Future<void> setFormulaForFunction(
      String functionType, String formulaId) async {
    try {
      // Load func directly
      final func = dylib
          .lookup<NativeFunction<SetFormulaForFunctionJsonNative>>(
              'set_formula_for_function_json')
          .asFunction<SetFormulaForFunctionJsonDart>();
      callVoidReturningFunction2Args(func, functionType, formulaId);
    } catch (e) {
      print("Error in setFormulaForFunction: $e");
      throw Exception('Erro ao definir fórmula para função: $e');
    }
  }

  // Obtém o ID da fórmula definida para uma função
  Future<String?> getFormulaForFunction(String functionType) async {
    Pointer<Utf8> resultPtr = nullptr;
    final arg1Ptr = functionType.toNativeUtf8();
    try {
      // Load func directly
      final func = dylib
          .lookup<NativeFunction<GetFormulaForFunctionJsonNative>>(
              'get_formula_for_function_json')
          .asFunction<GetFormulaForFunctionJsonDart>();
      resultPtr = func(arg1Ptr);
      if (resultPtr == nullptr) {
        // Null pointer here likely means "not found", not necessarily an error
        // Check getLastError just in case Rust set one?
        final errorMsg = getLastError(); // Freeing is handled by getLastError
        if (errorMsg != null &&
            errorMsg.isNotEmpty &&
            errorMsg != "Nenhum erro") {
          print(
              "Warning: getFormulaForFunction returned null, but Rust error was: $errorMsg");
        }
        return null; // Return null if no formula ID is set
      }
      final result = resultPtr.toDartString();
      return result.isEmpty ? null : result; // Return null if empty string
    } catch (e) {
      print("Error in getFormulaForFunction: $e");
      throw Exception('Erro ao obter fórmula para função: $e');
    } finally {
      calloc.free(arg1Ptr);
      if (resultPtr != nullptr) {
        freeRustString(resultPtr); // Free Rust memory
      }
    }
  }
}
