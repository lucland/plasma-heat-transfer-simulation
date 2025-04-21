import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plasma_furnace_ui/models/simulation_parameters.dart';
import 'package:plasma_furnace_ui/models/simulation_results.dart';
import 'package:plasma_furnace_ui/models/parametric_study.dart';
import 'package:plasma_furnace_ui/models/validation.dart';
import 'package:plasma_furnace_ui/models/formula.dart';
import 'package:plasma_furnace_ui/models/metrics.dart';

void main() {
  group('Simulation Parameters Tests', () {
    test('SimulationParameters creation and serialization', () {
      final params = SimulationParameters(
        meshRadialCells: 20,
        meshAngularCells: 16,
        meshAxialCells: 20,
        meshCellSize: 0.05,
        furnaceRadius: 1.5,
        initialTemperature: 300.0,
        ambientTemperature: 25.0,
        simulationTimeStep: 0.1,
        simulationDuration: 10.0,
        torchPower: 100.0,
        torchEfficiency: 0.8,
        materialThermalConductivity: 50.0,
        materialSpecificHeat: 1000.0,
        materialDensity: 5000.0,
        materialEmissivity: 0.8,
      );
      
      // Verificar valores
      expect(params.meshRadialCells, 20);
      expect(params.meshAngularCells, 16);
      expect(params.meshAxialCells, 20);
      expect(params.meshCellSize, 0.05);
      expect(params.furnaceRadius, 1.5);
      expect(params.initialTemperature, 300.0);
      expect(params.ambientTemperature, 25.0);
      expect(params.simulationTimeStep, 0.1);
      expect(params.simulationDuration, 10.0);
      expect(params.torchPower, 100.0);
      expect(params.torchEfficiency, 0.8);
      expect(params.materialThermalConductivity, 50.0);
      expect(params.materialSpecificHeat, 1000.0);
      expect(params.materialDensity, 5000.0);
      expect(params.materialEmissivity, 0.8);
      
      // Testar serialização
      final json = params.toJson();
      final deserializedParams = SimulationParameters.fromJson(json);
      
      // Verificar se os valores são preservados após serialização/deserialização
      expect(deserializedParams.meshRadialCells, params.meshRadialCells);
      expect(deserializedParams.meshAngularCells, params.meshAngularCells);
      expect(deserializedParams.meshAxialCells, params.meshAxialCells);
      expect(deserializedParams.meshCellSize, params.meshCellSize);
      expect(deserializedParams.furnaceRadius, params.furnaceRadius);
      expect(deserializedParams.initialTemperature, params.initialTemperature);
      expect(deserializedParams.ambientTemperature, params.ambientTemperature);
      expect(deserializedParams.simulationTimeStep, params.simulationTimeStep);
      expect(deserializedParams.simulationDuration, params.simulationDuration);
      expect(deserializedParams.torchPower, params.torchPower);
      expect(deserializedParams.torchEfficiency, params.torchEfficiency);
      expect(deserializedParams.materialThermalConductivity, params.materialThermalConductivity);
      expect(deserializedParams.materialSpecificHeat, params.materialSpecificHeat);
      expect(deserializedParams.materialDensity, params.materialDensity);
      expect(deserializedParams.materialEmissivity, params.materialEmissivity);
    });
    
    test('SimulationParameters validation', () {
      // Parâmetros válidos
      final validParams = SimulationParameters(
        meshRadialCells: 20,
        meshAngularCells: 16,
        meshAxialCells: 20,
        meshCellSize: 0.05,
        furnaceRadius: 1.5,
        initialTemperature: 300.0,
        ambientTemperature: 25.0,
        simulationTimeStep: 0.1,
        simulationDuration: 10.0,
        torchPower: 100.0,
        torchEfficiency: 0.8,
        materialThermalConductivity: 50.0,
        materialSpecificHeat: 1000.0,
        materialDensity: 5000.0,
        materialEmissivity: 0.8,
      );
      
      expect(validParams.isValid(), true);
      
      // Parâmetros inválidos
      final invalidParams1 = SimulationParameters(
        meshRadialCells: 0, // Inválido: deve ser > 0
        meshAngularCells: 16,
        meshAxialCells: 20,
        meshCellSize: 0.05,
        furnaceRadius: 1.5,
        initialTemperature: 300.0,
        ambientTemperature: 25.0,
        simulationTimeStep: 0.1,
        simulationDuration: 10.0,
        torchPower: 100.0,
        torchEfficiency: 0.8,
        materialThermalConductivity: 50.0,
        materialSpecificHeat: 1000.0,
        materialDensity: 5000.0,
        materialEmissivity: 0.8,
      );
      
      expect(invalidParams1.isValid(), false);
      
      final invalidParams2 = SimulationParameters(
        meshRadialCells: 20,
        meshAngularCells: 16,
        meshAxialCells: 20,
        meshCellSize: 0.05,
        furnaceRadius: 1.5,
        initialTemperature: 300.0,
        ambientTemperature: 25.0,
        simulationTimeStep: 0.1,
        simulationDuration: 10.0,
        torchPower: 100.0,
        torchEfficiency: 1.2, // Inválido: deve ser <= 1.0
        materialThermalConductivity: 50.0,
        materialSpecificHeat: 1000.0,
        materialDensity: 5000.0,
        materialEmissivity: 0.8,
      );
      
      expect(invalidParams2.isValid(), false);
    });
  });
  
  group('Simulation Results Tests', () {
    test('SimulationResults creation and serialization', () {
      // Criar dados de temperatura simulados
      final temperatureData = List.generate(
        5 * 4 * 5,
        (index) => 300.0 + index % 100,
      );
      
      final results = SimulationResults(
        temperatureData: temperatureData,
        meshRadialCells: 5,
        meshAngularCells: 4,
        meshAxialCells: 5,
        timeStep: 0.1,
        currentTime: 1.0,
        maxTemperature: 399.0,
        minTemperature: 300.0,
        avgTemperature: 349.5,
      );
      
      // Verificar valores
      expect(results.temperatureData.length, 5 * 4 * 5);
      expect(results.meshRadialCells, 5);
      expect(results.meshAngularCells, 4);
      expect(results.meshAxialCells, 5);
      expect(results.timeStep, 0.1);
      expect(results.currentTime, 1.0);
      expect(results.maxTemperature, 399.0);
      expect(results.minTemperature, 300.0);
      expect(results.avgTemperature, 349.5);
      
      // Testar serialização
      final json = results.toJson();
      final deserializedResults = SimulationResults.fromJson(json);
      
      // Verificar se os valores são preservados após serialização/deserialização
      expect(deserializedResults.temperatureData.length, results.temperatureData.length);
      expect(deserializedResults.meshRadialCells, results.meshRadialCells);
      expect(deserializedResults.meshAngularCells, results.meshAngularCells);
      expect(deserializedResults.meshAxialCells, results.meshAxialCells);
      expect(deserializedResults.timeStep, results.timeStep);
      expect(deserializedResults.currentTime, results.currentTime);
      expect(deserializedResults.maxTemperature, results.maxTemperature);
      expect(deserializedResults.minTemperature, results.minTemperature);
      expect(deserializedResults.avgTemperature, results.avgTemperature);
    });
    
    test('SimulationResults getTemperature', () {
      // Criar dados de temperatura simulados
      final temperatureData = List.generate(
        5 * 4 * 5,
        (index) => 300.0 + index,
      );
      
      final results = SimulationResults(
        temperatureData: temperatureData,
        meshRadialCells: 5,
        meshAngularCells: 4,
        meshAxialCells: 5,
        timeStep: 0.1,
        currentTime: 1.0,
        maxTemperature: 399.0,
        minTemperature: 300.0,
        avgTemperature: 349.5,
      );
      
      // Verificar acesso a temperaturas específicas
      expect(results.getTemperature(0, 0, 0), 300.0);
      expect(results.getTemperature(1, 0, 0), 301.0);
      expect(results.getTemperature(0, 1, 0), 305.0);
      expect(results.getTemperature(0, 0, 1), 320.0);
      
      // Verificar índice fora dos limites
      expect(() => results.getTemperature(5, 0, 0), throwsRangeError);
      expect(() => results.getTemperature(0, 4, 0), throwsRangeError);
      expect(() => results.getTemperature(0, 0, 5), throwsRangeError);
    });
  });
  
  group('Parametric Study Tests', () {
    test('ParametricParameter creation and serialization', () {
      final param = ParametricParameter(
        name: 'torch_power',
        description: 'Potência da tocha de plasma',
        unit: 'kW',
        minValue: 50.0,
        maxValue: 200.0,
        numPoints: 6,
        scaleType: ScaleType.linear,
        specificValues: null,
      );
      
      // Verificar valores
      expect(param.name, 'torch_power');
      expect(param.description, 'Potência da tocha de plasma');
      expect(param.unit, 'kW');
      expect(param.minValue, 50.0);
      expect(param.maxValue, 200.0);
      expect(param.numPoints, 6);
      expect(param.scaleType, ScaleType.linear);
      expect(param.specificValues, null);
      
      // Testar serialização
      final json = param.toJson();
      final deserializedParam = ParametricParameter.fromJson(json);
      
      // Verificar se os valores são preservados após serialização/deserialização
      expect(deserializedParam.name, param.name);
      expect(deserializedParam.description, param.description);
      expect(deserializedParam.unit, param.unit);
      expect(deserializedParam.minValue, param.minValue);
      expect(deserializedParam.maxValue, param.maxValue);
      expect(deserializedParam.numPoints, param.numPoints);
      expect(deserializedParam.scaleType, param.scaleType);
      expect(deserializedParam.specificValues, param.specificValues);
    });
    
    test('ParametricStudyConfig creation and serialization', () {
      final parameters = [
        ParametricParameter(
          name: 'torch_power',
          description: 'Potência da tocha de plasma',
          unit: 'kW',
          minValue: 50.0,
          maxValue: 200.0,
          numPoints: 6,
          scaleType: ScaleType.linear,
          specificValues: null,
        ),
        ParametricParameter(
          name: 'thermal_conductivity',
          description: 'Condutividade térmica do material',
          unit: 'W/(m·K)',
          minValue: 10.0,
          maxValue: 100.0,
          numPoints: 5,
          scaleType: ScaleType.logarithmic,
          specificValues: null,
        ),
      ];
      
      final config = ParametricStudyConfig(
        name: 'Otimização de Eficiência Energética',
        description: 'Estudo paramétrico para maximizar a eficiência energética da fornalha de plasma',
        parameters: parameters,
        targetMetric: 'energy_efficiency',
        optimizationGoal: OptimizationGoal.maximize,
        maxSimulations: 120,
        maxExecutionTime: 3600.0,
        useParallel: true,
        metadata: {},
      );
      
      // Verificar valores
      expect(config.name, 'Otimização de Eficiência Energética');
      expect(config.description, 'Estudo paramétrico para maximizar a eficiência energética da fornalha de plasma');
      expect(config.parameters.length, 2);
      expect(config.targetMetric, 'energy_efficiency');
      expect(config.optimizationGoal, OptimizationGoal.maximize);
      expect(config.maxSimulations, 120);
      expect(config.maxExecutionTime, 3600.0);
      expect(config.useParallel, true);
      
      // Testar serialização
      final json = config.toJson();
      final deserializedConfig = ParametricStudyConfig.fromJson(json);
      
      // Verificar se os valores são preservados após serialização/deserialização
      expect(deserializedConfig.name, config.name);
      expect(deserializedConfig.description, config.description);
      expect(deserializedConfig.parameters.length, config.parameters.length);
      expect(deserializedConfig.targetMetric, config.targetMetric);
      expect(deserializedConfig.optimizationGoal, config.optimizationGoal);
      expect(deserializedConfig.maxSimulations, config.maxSimulations);
      expect(deserializedConfig.maxExecutionTime, config.maxExecutionTime);
      expect(deserializedConfig.useParallel, config.useParallel);
    });
    
    test('ParametricStudyResult creation and serialization', () {
      final parameters = [
        ParametricParameter(
          name: 'torch_power',
          description: 'Potência da tocha de plasma',
          unit: 'kW',
          minValue: 50.0,
          maxValue: 200.0,
          numPoints: 6,
          scaleType: ScaleType.linear,
          specificValues: null,
        ),
      ];
      
      final config = ParametricStudyConfig(
        name: 'Teste',
        description: 'Teste',
        parameters: parameters,
        targetMetric: 'max_temperature',
        optimizationGoal: OptimizationGoal.maximize,
        maxSimulations: 10,
        maxExecutionTime: 60.0,
        useParallel: false,
        metadata: {},
      );
      
      final simulationResults = [
        ParametricSimulationResult(
          parameterValues: {'torch_power': 50.0},
          targetMetricValue: 500.0,
          additionalMetrics: {'avg_temperature': 400.0},
          executionTime: 1.0,
          simulationId: 0,
        ),
        ParametricSimulationResult(
          parameterValues: {'torch_power': 100.0},
          targetMetricValue: 600.0,
          additionalMetrics: {'avg_temperature': 450.0},
          executionTime: 1.0,
          simulationId: 1,
        ),
      ];
      
      final result = ParametricStudyResult(
        config: config,
        simulationResults: simulationResults,
        bestConfiguration: simulationResults[1],
        sensitivityAnalysis: {'torch_power': 1.0},
        totalExecutionTime: 2.0,
        totalSimulations: 2,
        metadata: {},
      );
      
      // Verificar valores
      expect(result.config.name, 'Teste');
      expect(result.simulationResults.length, 2);
      expect(result.bestConfiguration.targetMetricValue, 600.0);
      expect(result.sensitivityAnalysis['torch_power'], 1.0);
      expect(result.totalExecutionTime, 2.0);
      expect(result.totalSimulations, 2);
      
      // Testar serialização
      final json = result.toJson();
      final deserializedResult = ParametricStudyResult.fromJson(json);
      
      // Verificar se os valores são preservados após serialização/deserialização
      expect(deserializedResult.config.name, result.config.name);
      expect(deserializedResult.simulationResults.length, result.simulationResults.length);
      expect(deserializedResult.bestConfiguration.targetMetricValue, result.bestConfiguration.targetMetricValue);
      expect(deserializedResult.sensitivityAnalysis['torch_power'], result.sensitivityAnalysis['torch_power']);
      expect(deserializedResult.totalExecutionTime, result.totalExecutionTime);
      expect(deserializedResult.totalSimulations, result.totalSimulations);
    });
  });
  
  group('Validation Tests', () {
    test('ReferenceData creation and serialization', () {
      final referenceData = ReferenceData(
        name: 'Dados de Teste',
        description: 'Dados de teste para validação',
        source: 'Simulação',
        dataType: 'Temperatura',
        coordinates: [
          [0.1, 0.0, 0.1],
          [0.2, 0.0, 0.1],
          [0.3, 0.0, 0.1],
        ],
        values: [300.0, 350.0, 400.0],
        uncertainties: [5.0, 5.0, 5.0],
        metadata: {'date': '2025-04-21'},
      );
      
      // Verificar valores
      expect(referenceData.name, 'Dados de Teste');
      expect(referenceData.description, 'Dados de teste para validação');
      expect(referenceData.source, 'Simulação');
      expect(referenceData.dataType, 'Temperatura');
      expect(referenceData.coordinates.length, 3);
      expect(referenceData.values.length, 3);
      expect(referenceData.uncertainties!.length, 3);
      expect(referenceData.metadata['date'], '2025-04-21');
      
      // Testar serialização
      final json = referenceData.toJson();
      final deserializedData = ReferenceData.fromJson(json);
      
      // Verificar se os valores são preservados após serialização/deserialização
      expect(deserializedData.name, referenceData.name);
      expect(deserializedData.description, referenceData.description);
      expect(deserializedData.source, referenceData.source);
      expect(deserializedData.dataType, referenceData.dataType);
      expect(deserializedData.coordinates.length, referenceData.coordinates.length);
      expect(deserializedData.values.length, referenceData.values.length);
      expect(deserializedData.uncertainties!.length, referenceData.uncertainties!.length);
      expect(deserializedData.metadata['date'], referenceData.metadata['date']);
    });
    
    test('ValidationMetrics creation and serialization', () {
      final regionMetrics = {
        'Centro': ValidationMetrics(
          meanAbsoluteError: 5.0,
          meanSquaredError: 30.0,
          rootMeanSquaredError: 5.477,
          meanAbsolutePercentageError: 1.5,
          rSquared: 0.95,
          maxAbsoluteError: 10.0,
          meanError: 2.0,
          normalizedRmse: 0.1,
          regionMetrics: {},
        ),
      };
      
      final metrics = ValidationMetrics(
        meanAbsoluteError: 10.0,
        meanSquaredError: 150.0,
        rootMeanSquaredError: 12.247,
        meanAbsolutePercentageError: 3.0,
        rSquared: 0.9,
        maxAbsoluteError: 20.0,
        meanError: 5.0,
        normalizedRmse: 0.2,
        regionMetrics: regionMetrics,
      );
      
      // Verificar valores
      expect(metrics.meanAbsoluteError, 10.0);
      expect(metrics.meanSquaredError, 150.0);
      expect(metrics.rootMeanSquaredError, closeTo(12.247, 0.001));
      expect(metrics.meanAbsolutePercentageError, 3.0);
      expect(metrics.rSquared, 0.9);
      expect(metrics.maxAbsoluteError, 20.0);
      expect(metrics.meanError, 5.0);
      expect(metrics.normalizedRmse, 0.2);
      expect(metrics.regionMetrics.length, 1);
      expect(metrics.regionMetrics['Centro']!.meanAbsoluteError, 5.0);
      
      // Testar serialização
      final json = metrics.toJson();
      final deserializedMetrics = ValidationMetrics.fromJson(json);
      
      // Verificar se os valores são preservados após serialização/deserialização
      expect(deserializedMetrics.meanAbsoluteError, metrics.meanAbsoluteError);
      expect(deserializedMetrics.meanSquaredError, metrics.meanSquaredError);
      expect(deserializedMetrics.rootMeanSquaredError, closeTo(metrics.rootMeanSquaredError, 0.001));
      expect(deserializedMetrics.meanAbsolutePercentageError, metrics.meanAbsolutePercentageError);
      expect(deserializedMetrics.rSquared, metrics.rSquared);
      expect(deserializedMetrics.maxAbsoluteError, metrics.maxAbsoluteError);
      expect(deserializedMetrics.meanError, metrics.meanError);
      expect(deserializedMetrics.normalizedRmse, metrics.normalizedRmse);
      expect(deserializedMetrics.regionMetrics.length, metrics.regionMetrics.length);
      expect(deserializedMetrics.regionMetrics['Centro']!.meanAbsoluteError, metrics.regionMetrics['Centro']!.meanAbsoluteError);
    });
  });
  
  group('Formula Tests', () {
    test('Formula creation and serialization', () {
      final formula = Formula(
        id: 'heat_source',
        name: 'Fonte de Calor',
        description: 'Fórmula para calcular a fonte de calor',
        category: 'Física',
        expression: 'power * efficiency / (4 * pi * r^2)',
        parameters: {
          'power': FormulaParameter(
            name: 'power',
            description: 'Potência da tocha',
            type: 'double',
            defaultValue: '100.0',
            unit: 'kW',
          ),
          'efficiency': FormulaParameter(
            name: 'efficiency',
            description: 'Eficiência da tocha',
            type: 'double',
            defaultValue: '0.8',
            unit: '',
          ),
          'r': FormulaParameter(
            name: 'r',
            description: 'Distância do centro',
            type: 'double',
            defaultValue: '0.1',
            unit: 'm',
          ),
        },
        variables: ['pi'],
        isBuiltIn: true,
        metadata: {'author': 'Sistema'},
      );
      
      // Verificar valores
      expect(formula.id, 'heat_source');
      expect(formula.name, 'Fonte de Calor');
      expect(formula.description, 'Fórmula para calcular a fonte de calor');
      expect(formula.category, 'Física');
      expect(formula.expression, 'power * efficiency / (4 * pi * r^2)');
      expect(formula.parameters.length, 3);
      expect(formula.variables.length, 1);
      expect(formula.isBuiltIn, true);
      expect(formula.metadata['author'], 'Sistema');
      
      // Testar serialização
      final json = formula.toJson();
      final deserializedFormula = Formula.fromJson(json);
      
      // Verificar se os valores são preservados após serialização/deserialização
      expect(deserializedFormula.id, formula.id);
      expect(deserializedFormula.name, formula.name);
      expect(deserializedFormula.description, formula.description);
      expect(deserializedFormula.category, formula.category);
      expect(deserializedFormula.expression, formula.expression);
      expect(deserializedFormula.parameters.length, formula.parameters.length);
      expect(deserializedFormula.variables.length, formula.variables.length);
      expect(deserializedFormula.isBuiltIn, formula.isBuiltIn);
      expect(deserializedFormula.metadata['author'], formula.metadata['author']);
    });
    
    test('FormulaParameter creation and serialization', () {
      final param = FormulaParameter(
        name: 'power',
        description: 'Potência da tocha',
        type: 'double',
        defaultValue: '100.0',
        unit: 'kW',
      );
      
      // Verificar valores
      expect(param.name, 'power');
      expect(param.description, 'Potência da tocha');
      expect(param.type, 'double');
      expect(param.defaultValue, '100.0');
      expect(param.unit, 'kW');
      
      // Testar serialização
      final json = param.toJson();
      final deserializedParam = FormulaParameter.fromJson(json);
      
      // Verificar se os valores são preservados após serialização/deserialização
      expect(deserializedParam.name, param.name);
      expect(deserializedParam.description, param.description);
      expect(deserializedParam.type, param.type);
      expect(deserializedParam.defaultValue, param.defaultValue);
      expect(deserializedParam.unit, param.unit);
    });
  });
  
  group('Metrics Tests', () {
    test('SimulationMetrics creation and serialization', () {
      final metrics = SimulationMetrics(
        maxTemperature: 500.0,
        minTemperature: 300.0,
        avgTemperature: 400.0,
        maxGradient: 50.0,
        avgGradient: 20.0,
        maxHeatFlux: 2000.0,
        avgHeatFlux: 1000.0,
        totalEnergy: 5000.0,
        heatingRate: 10.0,
        energyEfficiency: 80.0,
        regionMetrics: {
          'Centro': RegionMetrics(
            name: 'Centro',
            maxTemperature: 500.0,
            minTemperature: 400.0,
            avgTemperature: 450.0,
            volume: 0.1,
          ),
          'Periferia': RegionMetrics(
            name: 'Periferia',
            maxTemperature: 400.0,
            minTemperature: 300.0,
            avgTemperature: 350.0,
            volume: 0.2,
          ),
        },
      );
      
      // Verificar valores
      expect(metrics.maxTemperature, 500.0);
      expect(metrics.minTemperature, 300.0);
      expect(metrics.avgTemperature, 400.0);
      expect(metrics.maxGradient, 50.0);
      expect(metrics.avgGradient, 20.0);
      expect(metrics.maxHeatFlux, 2000.0);
      expect(metrics.avgHeatFlux, 1000.0);
      expect(metrics.totalEnergy, 5000.0);
      expect(metrics.heatingRate, 10.0);
      expect(metrics.energyEfficiency, 80.0);
      expect(metrics.regionMetrics.length, 2);
      expect(metrics.regionMetrics['Centro']!.maxTemperature, 500.0);
      expect(metrics.regionMetrics['Periferia']!.avgTemperature, 350.0);
      
      // Testar serialização
      final json = metrics.toJson();
      final deserializedMetrics = SimulationMetrics.fromJson(json);
      
      // Verificar se os valores são preservados após serialização/deserialização
      expect(deserializedMetrics.maxTemperature, metrics.maxTemperature);
      expect(deserializedMetrics.minTemperature, metrics.minTemperature);
      expect(deserializedMetrics.avgTemperature, metrics.avgTemperature);
      expect(deserializedMetrics.maxGradient, metrics.maxGradient);
      expect(deserializedMetrics.avgGradient, metrics.avgGradient);
      expect(deserializedMetrics.maxHeatFlux, metrics.maxHeatFlux);
      expect(deserializedMetrics.avgHeatFlux, metrics.avgHeatFlux);
      expect(deserializedMetrics.totalEnergy, metrics.totalEnergy);
      expect(deserializedMetrics.heatingRate, metrics.heatingRate);
      expect(deserializedMetrics.energyEfficiency, metrics.energyEfficiency);
      expect(deserializedMetrics.regionMetrics.length, metrics.regionMetrics.length);
      expect(deserializedMetrics.regionMetrics['Centro']!.maxTemperature, metrics.regionMetrics['Centro']!.maxTemperature);
      expect(deserializedMetrics.regionMetrics['Periferia']!.avgTemperature, metrics.regionMetrics['Periferia']!.avgTemperature);
    });
    
    test('RegionMetrics creation and serialization', () {
      final regionMetrics = RegionMetrics(
        name: 'Centro',
        maxTemperature: 500.0,
        minTemperature: 400.0,
        avgTemperature: 450.0,
        volume: 0.1,
      );
      
      // Verificar valores
      expect(regionMetrics.name, 'Centro');
      expect(regionMetrics.maxTemperature, 500.0);
      expect(regionMetrics.minTemperature, 400.0);
      expect(regionMetrics.avgTemperature, 450.0);
      expect(regionMetrics.volume, 0.1);
      
      // Testar serialização
      final json = regionMetrics.toJson();
      final deserializedMetrics = RegionMetrics.fromJson(json);
      
      // Verificar se os valores são preservados após serialização/deserialização
      expect(deserializedMetrics.name, regionMetrics.name);
      expect(deserializedMetrics.maxTemperature, regionMetrics.maxTemperature);
      expect(deserializedMetrics.minTemperature, regionMetrics.minTemperature);
      expect(deserializedMetrics.avgTemperature, regionMetrics.avgTemperature);
      expect(deserializedMetrics.volume, regionMetrics.volume);
    });
  });
}
