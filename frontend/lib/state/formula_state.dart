import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/formula.dart';
import '../services/ffi_bridge.dart';

// Provider para o estado das fórmulas
final formulaStateProvider = StateNotifierProvider<FormulaStateNotifier, FormulaState>((ref) {
  return FormulaStateNotifier();
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
  FormulaStateNotifier() : super(FormulaState(formulas: [], isLoading: false));

  final FFIBridge _ffiBridge = FFIBridge();

  // Carrega todas as fórmulas
  Future<void> loadFormulas() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final formulas = await _ffiBridge.getAllFormulas();
      state = state.copyWith(formulas: formulas, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      throw Exception('Falha ao carregar fórmulas: $e');
    }
  }

  // Salva uma fórmula
  Future<void> saveFormula(Formula formula) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _ffiBridge.saveFormula(formula);
      
      // Atualizar a lista de fórmulas
      await loadFormulas();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      throw Exception('Falha ao salvar fórmula: $e');
    }
  }

  // Exclui uma fórmula
  Future<void> deleteFormula(String id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _ffiBridge.deleteFormula(id);
      
      // Atualizar a lista de fórmulas
      await loadFormulas();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      throw Exception('Falha ao excluir fórmula: $e');
    }
  }

  // Define uma fórmula para uma função
  Future<void> setFormulaForFunction(String functionType, String formulaId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _ffiBridge.setFormulaForFunction(functionType, formulaId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      throw Exception('Falha ao definir fórmula para função: $e');
    }
  }

  // Obtém a fórmula definida para uma função
  Future<String?> getFormulaForFunction(String functionType) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final formulaId = await _ffiBridge.getFormulaForFunction(functionType);
      state = state.copyWith(isLoading: false);
      return formulaId;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      throw Exception('Falha ao obter fórmula para função: $e');
    }
  }
}
