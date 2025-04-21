import 'dart:convert';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../models/formula.dart';

// Extensão da ponte FFI para suportar o editor de fórmulas
extension FormulaFFIBridge on FFIBridge {
  // Obtém todas as fórmulas disponíveis
  Future<List<Formula>> getAllFormulas() async {
    try {
      final jsonString = _callNativeFunction('get_all_formulas', []);
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => Formula.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erro ao obter fórmulas: $e');
    }
  }

  // Obtém fórmulas por categoria
  Future<List<Formula>> getFormulasByCategory(String category) async {
    try {
      final jsonString = _callNativeFunction('get_formulas_by_category', [category]);
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => Formula.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erro ao obter fórmulas por categoria: $e');
    }
  }

  // Obtém uma fórmula pelo ID
  Future<Formula> getFormula(String id) async {
    try {
      final jsonString = _callNativeFunction('get_formula', [id]);
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      return Formula.fromJson(jsonMap);
    } catch (e) {
      throw Exception('Erro ao obter fórmula: $e');
    }
  }

  // Salva uma fórmula
  Future<void> saveFormula(Formula formula) async {
    try {
      final jsonString = json.encode(formula.toJson());
      _callNativeFunction('save_formula', [jsonString]);
    } catch (e) {
      throw Exception('Erro ao salvar fórmula: $e');
    }
  }

  // Exclui uma fórmula
  Future<void> deleteFormula(String id) async {
    try {
      _callNativeFunction('delete_formula', [id]);
    } catch (e) {
      throw Exception('Erro ao excluir fórmula: $e');
    }
  }

  // Valida uma fórmula
  Future<FormulaValidationResult> validateFormula(
    String source,
    List<FormulaParameter> parameters,
  ) async {
    try {
      final parametersJson = json.encode(parameters.map((p) => p.toJson()).toList());
      final jsonString = _callNativeFunction('validate_formula', [source, parametersJson]);
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      return FormulaValidationResult.fromJson(jsonMap);
    } catch (e) {
      throw Exception('Erro ao validar fórmula: $e');
    }
  }

  // Avalia uma fórmula com parâmetros específicos
  Future<FormulaEvaluationResult> evaluateFormula(
    String id,
    Map<String, dynamic> parameters,
  ) async {
    try {
      final parametersJson = json.encode(parameters);
      final jsonString = _callNativeFunction('evaluate_formula', [id, parametersJson]);
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      return FormulaEvaluationResult.fromJson(jsonMap);
    } catch (e) {
      throw Exception('Erro ao avaliar fórmula: $e');
    }
  }

  // Define uma fórmula para uma função específica
  Future<void> setFormulaForFunction(String functionType, String formulaId) async {
    try {
      _callNativeFunction('set_formula_for_function', [functionType, formulaId]);
    } catch (e) {
      throw Exception('Erro ao definir fórmula para função: $e');
    }
  }

  // Obtém o ID da fórmula definida para uma função
  Future<String?> getFormulaForFunction(String functionType) async {
    try {
      final result = _callNativeFunction('get_formula_for_function', [functionType]);
      if (result.isEmpty) {
        return null;
      }
      return result;
    } catch (e) {
      throw Exception('Erro ao obter fórmula para função: $e');
    }
  }

  // Método auxiliar para chamar funções nativas
  String _callNativeFunction(String functionName, List<String> args) {
    // Implementação simplificada - em um ambiente real, isso chamaria
    // as funções FFI reais definidas no backend Rust
    
    // Simulação para desenvolvimento
    if (functionName == 'get_all_formulas') {
      return '[]'; // Lista vazia de fórmulas
    } else if (functionName == 'validate_formula') {
      return '{"isValid": true, "logs": ["Fórmula validada com sucesso"]}';
    }
    
    return '';
  }
}
