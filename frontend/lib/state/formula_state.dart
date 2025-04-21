import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/formula.dart';
import '../services/ffi_bridge.dart';
import '../services/formula_ffi_bridge.dart'; // Import the extension

// --- Service Layer ---

class FormulaService {
  final FFIBridge _ffiBridge = FFIBridge(); // Get singleton instance

  Future<List<Formula>> getAllFormulas() {
    return _ffiBridge.getAllFormulas();
  }

  Future<void> saveFormula(Formula formula) {
    return _ffiBridge.saveFormula(formula);
  }

  Future<void> deleteFormula(String id) {
    return _ffiBridge.deleteFormula(id);
  }

  Future<void> setFormulaForFunction(String functionType, String formulaId) {
    return _ffiBridge.setFormulaForFunction(functionType, formulaId);
  }

  Future<String?> getFormulaForFunction(String functionType) {
    return _ffiBridge.getFormulaForFunction(functionType);
  }

  // Add other methods like validate, evaluate, getById etc. if needed
  // Future<FormulaValidationResult> validateFormula(...) => _ffiBridge.validateFormula(...);
  // Future<FormulaEvaluationResult> evaluateFormula(...) => _ffiBridge.evaluateFormula(...);
  // Future<Formula> getFormula(String id) => _ffiBridge.getFormula(id);
}

// --- Riverpod Providers ---

// Provider for the service
final formulaServiceProvider = Provider<FormulaService>((ref) {
  return FormulaService();
});

// Provider para o estado das fórmulas
final formulaStateProvider =
    StateNotifierProvider<FormulaStateNotifier, FormulaState>((ref) {
  // Provide the service to the notifier
  return FormulaStateNotifier(ref.watch(formulaServiceProvider));
});

// Classe que representa o estado das fórmulas
class FormulaState {
  final List<Formula> formulas;
  final bool isLoading;
  final String? error;

  FormulaState({
    required this.formulas,
    this.isLoading = false,
    this.error,
  });

  FormulaState copyWith({
    List<Formula>? formulas,
    bool? isLoading,
    String? error,
  }) {
    return FormulaState(
      formulas: formulas ?? this.formulas,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Notificador de estado para as fórmulas
class FormulaStateNotifier extends StateNotifier<FormulaState> {
  // Inject the service
  final FormulaService _formulaService;

  // Constructor receives the service
  FormulaStateNotifier(this._formulaService)
      : super(FormulaState(formulas: [], isLoading: false));

  // REMOVED: Direct FFI Bridge instance
  // final FFIBridge _ffiBridge = FFIBridge();

  // Carrega todas as fórmulas
  Future<void> loadFormulas() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Use the service
      final formulas = await _formulaService.getAllFormulas();
      state = state.copyWith(formulas: formulas, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      print('Falha ao carregar fórmulas: $e'); // Log error
      // Avoid re-throwing if state handles error display
      // throw Exception('Falha ao carregar fórmulas: $e');
    }
  }

  // Salva uma fórmula
  Future<void> saveFormula(Formula formula) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Use the service
      await _formulaService.saveFormula(formula);

      // Atualizar a lista de fórmulas (reload is simpler for now)
      await loadFormulas();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      print('Falha ao salvar fórmula: $e'); // Log error
      // throw Exception('Falha ao salvar fórmula: $e');
    }
  }

  // Exclui uma fórmula
  Future<void> deleteFormula(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Use the service
      await _formulaService.deleteFormula(id);

      // Atualizar a lista de fórmulas (reload)
      await loadFormulas();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      print('Falha ao excluir fórmula: $e'); // Log error
      // throw Exception('Falha ao excluir fórmula: $e');
    }
  }

  // Define uma fórmula para uma função
  Future<void> setFormulaForFunction(
      String functionType, String formulaId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Use the service
      await _formulaService.setFormulaForFunction(functionType, formulaId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      print('Falha ao definir fórmula para função: $e'); // Log error
      // throw Exception('Falha ao definir fórmula para função: $e');
    }
  }

  // Obtém a fórmula definida para uma função
  Future<String?> getFormulaForFunction(String functionType) async {
    // Setting isLoading might not be needed if result is used immediately
    // state = state.copyWith(isLoading: true, error: null);

    try {
      // Use the service
      final formulaId =
          await _formulaService.getFormulaForFunction(functionType);
      // state = state.copyWith(isLoading: false); // Clear loading if set
      return formulaId;
    } catch (e) {
      // state = state.copyWith(error: e.toString(), isLoading: false); // Update state on error?
      print('Falha ao obter fórmula para função: $e'); // Log error
      throw Exception(
          'Falha ao obter fórmula para função: $e'); // Re-throw might be needed here
    }
  }
}
