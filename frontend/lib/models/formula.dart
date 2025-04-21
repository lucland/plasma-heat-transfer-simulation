import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Formula {
  final String id;
  final String name;
  final String description;
  final String source;
  final String category;
  final String resultUnit;
  final List<FormulaParameter> parameters;

  Formula({
    required this.id,
    required this.name,
    required this.description,
    required this.source,
    required this.category,
    required this.resultUnit,
    required this.parameters,
  });

  Formula copyWith({
    String? id,
    String? name,
    String? description,
    String? source,
    String? category,
    String? resultUnit,
    List<FormulaParameter>? parameters,
  }) {
    return Formula(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      source: source ?? this.source,
      category: category ?? this.category,
      resultUnit: resultUnit ?? this.resultUnit,
      parameters: parameters ?? this.parameters,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'source': source,
      'category': category,
      'resultUnit': resultUnit,
      'parameters': parameters.map((p) => p.toJson()).toList(),
    };
  }

  factory Formula.fromJson(Map<String, dynamic> json) {
    return Formula(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      source: json['source'],
      category: json['category'],
      resultUnit: json['resultUnit'],
      parameters: (json['parameters'] as List)
          .map((p) => FormulaParameter.fromJson(p))
          .toList(),
    );
  }
}

class FormulaParameter {
  final String name;
  final String description;
  final String type;
  final String defaultValue;
  final String unit;
  final String? minValue;
  final String? maxValue;

  FormulaParameter({
    required this.name,
    required this.description,
    required this.type,
    required this.defaultValue,
    required this.unit,
    this.minValue,
    this.maxValue,
  });

  FormulaParameter copyWith({
    String? name,
    String? description,
    String? type,
    String? defaultValue,
    String? unit,
    String? minValue,
    String? maxValue,
  }) {
    return FormulaParameter(
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      defaultValue: defaultValue ?? this.defaultValue,
      unit: unit ?? this.unit,
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'type': type,
      'defaultValue': defaultValue,
      'unit': unit,
      'minValue': minValue,
      'maxValue': maxValue,
    };
  }

  factory FormulaParameter.fromJson(Map<String, dynamic> json) {
    return FormulaParameter(
      name: json['name'],
      description: json['description'],
      type: json['type'],
      defaultValue: json['defaultValue'],
      unit: json['unit'],
      minValue: json['minValue'],
      maxValue: json['maxValue'],
    );
  }
}

class FormulaValidationResult {
  final bool isValid;
  final String? error;
  final List<String> logs;

  FormulaValidationResult({
    required this.isValid,
    this.error,
    required this.logs,
  });

  factory FormulaValidationResult.fromJson(Map<String, dynamic> json) {
    return FormulaValidationResult(
      isValid: json['isValid'],
      error: json['error'],
      logs: List<String>.from(json['logs']),
    );
  }
}

class FormulaEvaluationResult {
  final dynamic value;
  final int executionTimeUs;
  final List<String> logs;

  FormulaEvaluationResult({
    required this.value,
    required this.executionTimeUs,
    required this.logs,
  });

  factory FormulaEvaluationResult.fromJson(Map<String, dynamic> json) {
    return FormulaEvaluationResult(
      value: json['value'],
      executionTimeUs: json['executionTimeUs'],
      logs: List<String>.from(json['logs']),
    );
  }
}
