import 'package:flutter/foundation.dart';

// Modelo para os parâmetros de simulação
class SimulationParameters {
  // Geometria
  final double height;
  final double radius;
  final int nr;
  final int nz;
  
  // Temperatura
  final double initialTemperature;
  final double ambientTemperature;
  
  // Convecção
  final double convectionCoefficient;
  final bool enableConvection;
  
  // Radiação
  final bool enableRadiation;
  
  // Tempo
  final double totalTime;
  final double timeStep;
  final int timeSteps;
  
  // Tochas
  final List<PlasmaTorch> torches;
  
  // Material
  final MaterialProperties material;
  
  SimulationParameters({
    required this.height,
    required this.radius,
    required this.nr,
    required this.nz,
    this.initialTemperature = 25.0,
    this.ambientTemperature = 25.0,
    this.convectionCoefficient = 10.0,
    this.enableConvection = true,
    this.enableRadiation = true,
    this.totalTime = 100.0,
    this.timeStep = 1.0,
    int? timeSteps,
    List<PlasmaTorch>? torches,
    MaterialProperties? material,
  }) : 
    this.timeSteps = timeSteps ?? (totalTime / timeStep).round(),
    this.torches = torches ?? [],
    this.material = material ?? MaterialProperties();
  
  // Cria uma cópia com alguns parâmetros alterados
  SimulationParameters copyWith({
    double? height,
    double? radius,
    int? nr,
    int? nz,
    double? initialTemperature,
    double? ambientTemperature,
    double? convectionCoefficient,
    bool? enableConvection,
    bool? enableRadiation,
    double? totalTime,
    double? timeStep,
    int? timeSteps,
    List<PlasmaTorch>? torches,
    MaterialProperties? material,
  }) {
    return SimulationParameters(
      height: height ?? this.height,
      radius: radius ?? this.radius,
      nr: nr ?? this.nr,
      nz: nz ?? this.nz,
      initialTemperature: initialTemperature ?? this.initialTemperature,
      ambientTemperature: ambientTemperature ?? this.ambientTemperature,
      convectionCoefficient: convectionCoefficient ?? this.convectionCoefficient,
      enableConvection: enableConvection ?? this.enableConvection,
      enableRadiation: enableRadiation ?? this.enableRadiation,
      totalTime: totalTime ?? this.totalTime,
      timeStep: timeStep ?? this.timeStep,
      timeSteps: timeSteps ?? this.timeSteps,
      torches: torches ?? List.from(this.torches),
      material: material ?? this.material,
    );
  }
  
  // Cria uma instância com valores padrão
  factory SimulationParameters.defaultParams() {
    return SimulationParameters(
      height: 1.0,
      radius: 0.5,
      nr: 50,
      nz: 100,
      initialTemperature: 25.0,
      ambientTemperature: 25.0,
      convectionCoefficient: 10.0,
      enableConvection: true,
      enableRadiation: true,
      totalTime: 100.0,
      timeStep: 1.0,
      torches: [
        PlasmaTorch(
          rPosition: 0.0,
          zPosition: 0.5,
          pitch: 90.0,
          yaw: 0.0,
          power: 100.0,
          gasFlow: 0.01,
          gasTemperature: 5000.0,
        ),
      ],
      material: MaterialProperties(
        name: 'Material Padrão',
        density: 1000.0,
        specificHeat: 1500.0,
        thermalConductivity: 0.5,
      ),
    );
  }
  
  // Valida os parâmetros
  List<String> validate() {
    final errors = <String>[];
    
    if (height <= 0.0) {
      errors.add('Altura deve ser positiva');
    }
    
    if (radius <= 0.0) {
      errors.add('Raio deve ser positivo');
    }
    
    if (nr < 2) {
      errors.add('Número de nós radiais deve ser pelo menos 2');
    }
    
    if (nz < 2) {
      errors.add('Número de nós axiais deve ser pelo menos 2');
    }
    
    if (torches.isEmpty) {
      errors.add('Pelo menos uma tocha deve ser definida');
    }
    
    if (timeStep <= 0.0) {
      errors.add('Passo de tempo deve ser positivo');
    }
    
    if (totalTime <= 0.0) {
      errors.add('Tempo total deve ser positivo');
    }
    
    // Validar posição das tochas
    for (var torch in torches) {
      if (torch.rPosition < 0.0 || torch.rPosition > radius) {
        errors.add('Posição radial da tocha (${torch.rPosition}) fora dos limites [0, $radius]');
      }
      
      if (torch.zPosition < 0.0 || torch.zPosition > height) {
        errors.add('Posição axial da tocha (${torch.zPosition}) fora dos limites [0, $height]');
      }
    }
    
    return errors;
  }
}

// Modelo para tocha de plasma
class PlasmaTorch {
  final double rPosition;
  final double zPosition;
  final double pitch;
  final double yaw;
  final double power;
  final double gasFlow;
  final double gasTemperature;
  
  PlasmaTorch({
    required this.rPosition,
    required this.zPosition,
    required this.pitch,
    required this.yaw,
    required this.power,
    required this.gasFlow,
    required this.gasTemperature,
  });
  
  // Cria uma cópia com alguns parâmetros alterados
  PlasmaTorch copyWith({
    double? rPosition,
    double? zPosition,
    double? pitch,
    double? yaw,
    double? power,
    double? gasFlow,
    double? gasTemperature,
  }) {
    return PlasmaTorch(
      rPosition: rPosition ?? this.rPosition,
      zPosition: zPosition ?? this.zPosition,
      pitch: pitch ?? this.pitch,
      yaw: yaw ?? this.yaw,
      power: power ?? this.power,
      gasFlow: gasFlow ?? this.gasFlow,
      gasTemperature: gasTemperature ?? this.gasTemperature,
    );
  }
}

// Modelo para propriedades do material
class MaterialProperties {
  final String name;
  final double density;
  final double moistureContent;
  final double specificHeat;
  final double thermalConductivity;
  final double emissivity;
  final double? meltingPoint;
  final double? latentHeatFusion;
  final double? vaporizationPoint;
  final double? latentHeatVaporization;
  
  MaterialProperties({
    this.name = 'Material Padrão',
    this.density = 1000.0,
    this.moistureContent = 0.0,
    this.specificHeat = 1500.0,
    this.thermalConductivity = 0.5,
    this.emissivity = 0.9,
    this.meltingPoint,
    this.latentHeatFusion,
    this.vaporizationPoint,
    this.latentHeatVaporization,
  });
  
  // Cria uma cópia com alguns parâmetros alterados
  MaterialProperties copyWith({
    String? name,
    double? density,
    double? moistureContent,
    double? specificHeat,
    double? thermalConductivity,
    double? emissivity,
    double? meltingPoint,
    double? latentHeatFusion,
    double? vaporizationPoint,
    double? latentHeatVaporization,
  }) {
    return MaterialProperties(
      name: name ?? this.name,
      density: density ?? this.density,
      moistureContent: moistureContent ?? this.moistureContent,
      specificHeat: specificHeat ?? this.specificHeat,
      thermalConductivity: thermalConductivity ?? this.thermalConductivity,
      emissivity: emissivity ?? this.emissivity,
      meltingPoint: meltingPoint ?? this.meltingPoint,
      latentHeatFusion: latentHeatFusion ?? this.latentHeatFusion,
      vaporizationPoint: vaporizationPoint ?? this.vaporizationPoint,
      latentHeatVaporization: latentHeatVaporization ?? this.latentHeatVaporization,
    );
  }
}
