import 'package:flutter/material.dart';

enum ScaleType {
  linear,
  logarithmic,
}

enum OptimizationGoal {
  maximize,
  minimize,
}

class ParametricParameter {
  final String name;
  final String description;
  final String unit;
  final double minValue;
  final double maxValue;
  final int numPoints;
  final ScaleType scaleType;
  final List<double>? specificValues;

  ParametricParameter({
    required this.name,
    required this.description,
    required this.unit,
    required this.minValue,
    required this.maxValue,
    required this.numPoints,
    required this.scaleType,
    this.specificValues,
  });

  factory ParametricParameter.fromJson(Map<String, dynamic> json) {
    return ParametricParameter(
      name: json['name'] as String,
      description: json['description'] as String,
      unit: json['unit'] as String,
      minValue: json['min_value'] as double,
      maxValue: json['max_value'] as double,
      numPoints: json['num_points'] as int,
      scaleType: ScaleType.values.firstWhere(
        (e) => e.toString() == 'ScaleType.${json['scale_type']}',
        orElse: () => ScaleType.linear,
      ),
      specificValues: json['specific_values'] != null
          ? (json['specific_values'] as List).cast<double>()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'unit': unit,
      'min_value': minValue,
      'max_value': maxValue,
      'num_points': numPoints,
      'scale_type': scaleType.toString().split('.').last,
      'specific_values': specificValues,
    };
  }
}

class ParametricStudyConfig {
  final String name;
  final String description;
  final List<ParametricParameter> parameters;
  final String targetMetric;
  final OptimizationGoal optimizationGoal;
  final int maxSimulations;
  final double maxExecutionTime;
  final bool useParallel;
  final Map<String, String> metadata;

  ParametricStudyConfig({
    required this.name,
    required this.description,
    required this.parameters,
    required this.targetMetric,
    required this.optimizationGoal,
    required this.maxSimulations,
    required this.maxExecutionTime,
    required this.useParallel,
    required this.metadata,
  });

  factory ParametricStudyConfig.fromJson(Map<String, dynamic> json) {
    return ParametricStudyConfig(
      name: json['name'] as String,
      description: json['description'] as String,
      parameters: (json['parameters'] as List)
          .map((e) => ParametricParameter.fromJson(e as Map<String, dynamic>))
          .toList(),
      targetMetric: json['target_metric'] as String,
      optimizationGoal: OptimizationGoal.values.firstWhere(
        (e) => e.toString() == 'OptimizationGoal.${json['optimization_goal']}',
        orElse: () => OptimizationGoal.maximize,
      ),
      maxSimulations: json['max_simulations'] as int,
      maxExecutionTime: json['max_execution_time'] as double,
      useParallel: json['use_parallel'] as bool,
      metadata: Map<String, String>.from(json['metadata'] as Map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'parameters': parameters.map((e) => e.toJson()).toList(),
      'target_metric': targetMetric,
      'optimization_goal': optimizationGoal.toString().split('.').last,
      'max_simulations': maxSimulations,
      'max_execution_time': maxExecutionTime,
      'use_parallel': useParallel,
      'metadata': metadata,
    };
  }
}

class ParametricSimulationResult {
  final Map<String, double> parameterValues;
  final double targetMetricValue;
  final Map<String, double> additionalMetrics;
  final double executionTime;
  final int simulationId;

  ParametricSimulationResult({
    required this.parameterValues,
    required this.targetMetricValue,
    required this.additionalMetrics,
    required this.executionTime,
    required this.simulationId,
  });

  factory ParametricSimulationResult.fromJson(Map<String, dynamic> json) {
    return ParametricSimulationResult(
      parameterValues: Map<String, double>.from(json['parameter_values'] as Map),
      targetMetricValue: json['target_metric_value'] as double,
      additionalMetrics: Map<String, double>.from(json['additional_metrics'] as Map),
      executionTime: json['execution_time'] as double,
      simulationId: json['simulation_id'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'parameter_values': parameterValues,
      'target_metric_value': targetMetricValue,
      'additional_metrics': additionalMetrics,
      'execution_time': executionTime,
      'simulation_id': simulationId,
    };
  }
}

class ParametricStudyResult {
  final ParametricStudyConfig config;
  final List<ParametricSimulationResult> simulationResults;
  final ParametricSimulationResult bestConfiguration;
  final Map<String, double> sensitivityAnalysis;
  final double totalExecutionTime;
  final int totalSimulations;
  final Map<String, String> metadata;

  ParametricStudyResult({
    required this.config,
    required this.simulationResults,
    required this.bestConfiguration,
    required this.sensitivityAnalysis,
    required this.totalExecutionTime,
    required this.totalSimulations,
    required this.metadata,
  });

  factory ParametricStudyResult.fromJson(Map<String, dynamic> json) {
    return ParametricStudyResult(
      config: ParametricStudyConfig.fromJson(json['config'] as Map<String, dynamic>),
      simulationResults: (json['simulation_results'] as List)
          .map((e) => ParametricSimulationResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      bestConfiguration: ParametricSimulationResult.fromJson(
          json['best_configuration'] as Map<String, dynamic>),
      sensitivityAnalysis: Map<String, double>.from(json['sensitivity_analysis'] as Map),
      totalExecutionTime: json['total_execution_time'] as double,
      totalSimulations: json['total_simulations'] as int,
      metadata: Map<String, String>.from(json['metadata'] as Map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'config': config.toJson(),
      'simulation_results': simulationResults.map((e) => e.toJson()).toList(),
      'best_configuration': bestConfiguration.toJson(),
      'sensitivity_analysis': sensitivityAnalysis,
      'total_execution_time': totalExecutionTime,
      'total_simulations': totalSimulations,
      'metadata': metadata,
    };
  }
}
