import 'package:flutter/material.dart';

class SimulationMetrics {
  final double minTemperature;
  final double maxTemperature;
  final double avgTemperature;
  final double stdTemperature;
  final double maxGradient;
  final double maxHeatFlux;
  final double totalEnergy;
  final double avgHeatingRate;
  final List<RegionMetrics> regionMetrics;
  final TemporalMetrics temporalMetrics;

  SimulationMetrics({
    required this.minTemperature,
    required this.maxTemperature,
    required this.avgTemperature,
    required this.stdTemperature,
    required this.maxGradient,
    required this.maxHeatFlux,
    required this.totalEnergy,
    required this.avgHeatingRate,
    required this.regionMetrics,
    required this.temporalMetrics,
  });

  factory SimulationMetrics.fromJson(Map<String, dynamic> json) {
    return SimulationMetrics(
      minTemperature: json['min_temperature'],
      maxTemperature: json['max_temperature'],
      avgTemperature: json['avg_temperature'],
      stdTemperature: json['std_temperature'],
      maxGradient: json['max_gradient'],
      maxHeatFlux: json['max_heat_flux'],
      totalEnergy: json['total_energy'],
      avgHeatingRate: json['avg_heating_rate'],
      regionMetrics: (json['region_metrics'] as List)
          .map((region) => RegionMetrics.fromJson(region))
          .toList(),
      temporalMetrics: TemporalMetrics.fromJson(json['temporal_metrics']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'min_temperature': minTemperature,
      'max_temperature': maxTemperature,
      'avg_temperature': avgTemperature,
      'std_temperature': stdTemperature,
      'max_gradient': maxGradient,
      'max_heat_flux': maxHeatFlux,
      'total_energy': totalEnergy,
      'avg_heating_rate': avgHeatingRate,
      'region_metrics': regionMetrics.map((region) => region.toJson()).toList(),
      'temporal_metrics': temporalMetrics.toJson(),
    };
  }
}

class RegionMetrics {
  final String name;
  final double minTemperature;
  final double maxTemperature;
  final double avgTemperature;
  final double volume;
  final double energy;

  RegionMetrics({
    required this.name,
    required this.minTemperature,
    required this.maxTemperature,
    required this.avgTemperature,
    required this.volume,
    required this.energy,
  });

  factory RegionMetrics.fromJson(Map<String, dynamic> json) {
    return RegionMetrics(
      name: json['name'],
      minTemperature: json['min_temperature'],
      maxTemperature: json['max_temperature'],
      avgTemperature: json['avg_temperature'],
      volume: json['volume'],
      energy: json['energy'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'min_temperature': minTemperature,
      'max_temperature': maxTemperature,
      'avg_temperature': avgTemperature,
      'volume': volume,
      'energy': energy,
    };
  }
}

class TemporalMetrics {
  final double timeToHalfMax;
  final double timeTo90PercentMax;
  final double maxHeatingRate;
  final double stabilizationTime;

  TemporalMetrics({
    required this.timeToHalfMax,
    required this.timeTo90PercentMax,
    required this.maxHeatingRate,
    required this.stabilizationTime,
  });

  factory TemporalMetrics.fromJson(Map<String, dynamic> json) {
    return TemporalMetrics(
      timeToHalfMax: json['time_to_half_max'],
      timeTo90PercentMax: json['time_to_90_percent_max'],
      maxHeatingRate: json['max_heating_rate'],
      stabilizationTime: json['stabilization_time'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time_to_half_max': timeToHalfMax,
      'time_to_90_percent_max': timeTo90PercentMax,
      'max_heating_rate': maxHeatingRate,
      'stabilization_time': stabilizationTime,
    };
  }
}

class ExportOptions {
  final String format;
  final String outputPath;
  final bool includeMetrics;
  final bool includeTemperature;
  final bool includeGradient;
  final bool includeHeatFlux;
  final bool includeMetadata;
  final List<int>? timeSteps;

  ExportOptions({
    required this.format,
    required this.outputPath,
    required this.includeMetrics,
    required this.includeTemperature,
    required this.includeGradient,
    required this.includeHeatFlux,
    required this.includeMetadata,
    this.timeSteps,
  });

  Map<String, dynamic> toJson() {
    return {
      'format': format,
      'output_path': outputPath,
      'include_metrics': includeMetrics,
      'include_temperature': includeTemperature,
      'include_gradient': includeGradient,
      'include_heat_flux': includeHeatFlux,
      'include_metadata': includeMetadata,
      'time_steps': timeSteps,
    };
  }
}
