class ReferenceData {
  final String name;
  final String description;
  final String source;
  final String dataType;
  final List<List<double>> coordinates;
  final List<double> values;
  final List<double>? uncertainties;
  final Map<String, String> metadata;

  ReferenceData({
    required this.name,
    required this.description,
    required this.source,
    required this.dataType,
    required this.coordinates,
    required this.values,
    this.uncertainties,
    required this.metadata,
  });

  factory ReferenceData.fromJson(Map<String, dynamic> json) {
    return ReferenceData(
      name: json['name'] as String,
      description: json['description'] as String,
      source: json['source'] as String,
      dataType: json['data_type'] as String,
      coordinates: (json['coordinates'] as List)
          .map((coord) => (coord as List).map((c) => c as double).toList())
          .toList(),
      values: (json['values'] as List).map((v) => v as double).toList(),
      uncertainties: json['uncertainties'] != null
          ? (json['uncertainties'] as List).map((u) => u as double).toList()
          : null,
      metadata: Map<String, String>.from(json['metadata'] as Map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'source': source,
      'data_type': dataType,
      'coordinates': coordinates,
      'values': values,
      'uncertainties': uncertainties,
      'metadata': metadata,
    };
  }
}

class ValidationMetrics {
  final double meanAbsoluteError;
  final double meanSquaredError;
  final double rootMeanSquaredError;
  final double meanAbsolutePercentageError;
  final double rSquared;
  final double maxAbsoluteError;
  final double meanError;
  final double normalizedRmse;
  Map<String, ValidationMetrics> regionMetrics;

  ValidationMetrics({
    required this.meanAbsoluteError,
    required this.meanSquaredError,
    required this.rootMeanSquaredError,
    required this.meanAbsolutePercentageError,
    required this.rSquared,
    required this.maxAbsoluteError,
    required this.meanError,
    required this.normalizedRmse,
    required this.regionMetrics,
  });

  factory ValidationMetrics.fromJson(Map<String, dynamic> json) {
    final regionMetricsJson = json['region_metrics'] as Map<String, dynamic>;
    final regionMetrics = <String, ValidationMetrics>{};
    
    regionMetricsJson.forEach((key, value) {
      regionMetrics[key] = ValidationMetrics.fromJson(value as Map<String, dynamic>);
    });
    
    return ValidationMetrics(
      meanAbsoluteError: json['mean_absolute_error'] as double,
      meanSquaredError: json['mean_squared_error'] as double,
      rootMeanSquaredError: json['root_mean_squared_error'] as double,
      meanAbsolutePercentageError: json['mean_absolute_percentage_error'] as double,
      rSquared: json['r_squared'] as double,
      maxAbsoluteError: json['max_absolute_error'] as double,
      meanError: json['mean_error'] as double,
      normalizedRmse: json['normalized_rmse'] as double,
      regionMetrics: regionMetrics,
    );
  }

  Map<String, dynamic> toJson() {
    final regionMetricsJson = <String, dynamic>{};
    
    regionMetrics.forEach((key, value) {
      regionMetricsJson[key] = value.toJson();
    });
    
    return {
      'mean_absolute_error': meanAbsoluteError,
      'mean_squared_error': meanSquaredError,
      'root_mean_squared_error': rootMeanSquaredError,
      'mean_absolute_percentage_error': meanAbsolutePercentageError,
      'r_squared': rSquared,
      'max_absolute_error': maxAbsoluteError,
      'mean_error': meanError,
      'normalized_rmse': normalizedRmse,
      'region_metrics': regionMetricsJson,
    };
  }
}

class ValidationResult {
  final String name;
  final String description;
  final ReferenceData referenceData;
  final ValidationMetrics metrics;
  final List<double> simulatedValues;
  final Map<String, String> metadata;

  ValidationResult({
    required this.name,
    required this.description,
    required this.referenceData,
    required this.metrics,
    required this.simulatedValues,
    required this.metadata,
  });

  factory ValidationResult.fromJson(Map<String, dynamic> json) {
    return ValidationResult(
      name: json['name'] as String,
      description: json['description'] as String,
      referenceData: ReferenceData.fromJson(json['reference_data'] as Map<String, dynamic>),
      metrics: ValidationMetrics.fromJson(json['metrics'] as Map<String, dynamic>),
      simulatedValues: (json['simulated_values'] as List).map((v) => v as double).toList(),
      metadata: Map<String, String>.from(json['metadata'] as Map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'reference_data': referenceData.toJson(),
      'metrics': metrics.toJson(),
      'simulated_values': simulatedValues,
      'metadata': metadata,
    };
  }
}

class ImportOptions {
  final String format;
  final String inputPath;
  final String? delimiter;
  final bool hasHeader;
  final List<int>? coordinateColumns;
  final int? valueColumn;
  final int? uncertaintyColumn;

  ImportOptions({
    required this.format,
    required this.inputPath,
    this.delimiter,
    required this.hasHeader,
    this.coordinateColumns,
    this.valueColumn,
    this.uncertaintyColumn,
  });

  Map<String, dynamic> toJson() {
    return {
      'format': format,
      'input_path': inputPath,
      'delimiter': delimiter,
      'has_header': hasHeader,
      'coordinate_columns': coordinateColumns,
      'value_column': valueColumn,
      'uncertainty_column': uncertaintyColumn,
    };
  }
}
