import 'dart:async';
import 'dart:ffi';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ffi/ffi.dart';

import '../models/simulation_parameters.dart';
import '../models/simulation_results.dart';
import '../services/ffi_bridge.dart';

// Provider para o serviço de simulação
final simulationServiceProvider = Provider<SimulationService>((ref) {
  return SimulationService();
});

// Provider para o estado da simulação
final simulationStateProvider = StateNotifierProvider<SimulationStateNotifier, SimulationState>((ref) {
  return SimulationStateNotifier(ref.watch(simulationServiceProvider));
});

// Notificador de estado para a simulação
class SimulationStateNotifier extends StateNotifier<SimulationState> {
  final SimulationService _simulationService;
  Timer? _pollingTimer;

  SimulationStateNotifier(this._simulationService) : super(SimulationState.initial()) {
    // Inicializar o serviço de simulação
    try {
      _simulationService.initialize();
    } catch (e) {
      state = state.copyWith(
        status: SimulationStatus.failed,
        errorMessage: 'Falha ao inicializar o serviço de simulação: $e',
      );
    }
  }

  // Configura os parâmetros da simulação
  Future<void> setParameters(SimulationParameters parameters) async {
    try {
      await _simulationService.setParameters(parameters);
    } catch (e) {
      state = state.copyWith(
        status: SimulationStatus.failed,
        errorMessage: 'Falha ao configurar parâmetros: $e',
      );
    }
  }

  // Inicia a simulação
  Future<void> startSimulation() async {
    if (state.isRunning) return;

    try {
      await _simulationService.runSimulation();
      
      // Atualizar o estado para "em execução"
      state = state.copyWith(
        status: SimulationStatus.running,
        progress: 0.0,
      );
      
      // Iniciar polling para atualizar o progresso
      _startPolling();
    } catch (e) {
      state = state.copyWith(
        status: SimulationStatus.failed,
        errorMessage: 'Falha ao iniciar simulação: $e',
      );
    }
  }

  // Pausa a simulação
  Future<void> pauseSimulation() async {
    if (!state.isRunning) return;

    try {
      await _simulationService.pauseSimulation();
      
      // Atualizar o estado para "pausado"
      state = state.copyWith(
        status: SimulationStatus.paused,
      );
      
      // Parar polling
      _stopPolling();
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Falha ao pausar simulação: $e',
      );
    }
  }

  // Retoma a simulação
  Future<void> resumeSimulation() async {
    if (!state.isPaused) return;

    try {
      await _simulationService.resumeSimulation();
      
      // Atualizar o estado para "em execução"
      state = state.copyWith(
        status: SimulationStatus.running,
      );
      
      // Reiniciar polling
      _startPolling();
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Falha ao retomar simulação: $e',
      );
    }
  }

  // Inicia o polling para atualizar o progresso
  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(Duration(milliseconds: 500), (_) => _updateState());
  }

  // Para o polling
  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  // Atualiza o estado da simulação
  Future<void> _updateState() async {
    try {
      final simulationState = await _simulationService.getSimulationState();
      
      // Atualizar o estado
      state = state.copyWith(
        status: simulationState.status,
        progress: simulationState.progress,
        errorMessage: simulationState.errorMessage,
        executionTime: simulationState.executionTime,
      );
      
      // Se a simulação foi concluída ou falhou, parar polling
      if (state.isCompleted || state.isFailed) {
        _stopPolling();
        
        // Se foi concluída, obter resultados
        if (state.isCompleted) {
          final results = await _simulationService.getResults();
          state = state.copyWith(results: results);
        }
      }
    } catch (e) {
      print('Erro ao atualizar estado: $e');
    }
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}

// Serviço de simulação
class SimulationService {
  final FFIBridge _ffiBridge = FFIBridge();
  bool _initialized = false;
  SimulationParameters? _currentParameters;

  // Inicializa o serviço
  void initialize() {
    if (_initialized) return;
    
    _ffiBridge.initialize();
    _initialized = true;
  }

  // Configura os parâmetros da simulação
  Future<void> setParameters(SimulationParameters parameters) async {
    _checkInitialized();
    
    // Validar parâmetros
    final errors = parameters.validate();
    if (errors.isNotEmpty) {
      throw Exception('Parâmetros inválidos: ${errors.join(', ')}');
    }
    
    // Armazenar parâmetros atuais
    _currentParameters = parameters;
    
    // Inicializar simulação
    final ffiParams = _createFFIParameters(parameters);
    final result = _ffiBridge.initializeSimulation(ffiParams);
    
    if (result != 0) {
      throw Exception('Falha ao inicializar simulação: ${_ffiBridge.getLastError()}');
    }
    
    // Adicionar tochas
    for (var torch in parameters.torches) {
      final ffiTorch = _createFFITorch(torch);
      final result = _ffiBridge.addPlasmaTorch(ffiTorch);
      
      if (result != 0) {
        throw Exception('Falha ao adicionar tocha: ${_ffiBridge.getLastError()}');
      }
    }
    
    // Configurar material
    final ffiMaterial = _createFFIMaterial(parameters.material);
    final materialResult = _ffiBridge.setMaterialProperties(ffiMaterial);
    
    if (materialResult != 0) {
      throw Exception('Falha ao configurar material: ${_ffiBridge.getLastError()}');
    }
  }

  // Executa a simulação
  Future<void> runSimulation() async {
    _checkInitialized();
    
    final result = _ffiBridge.runSimulation();
    
    if (result != 0) {
      throw Exception('Falha ao executar simulação: ${_ffiBridge.getLastError()}');
    }
  }

  // Pausa a simulação
  Future<void> pauseSimulation() async {
    _checkInitialized();
    
    final result = _ffiBridge.pauseSimulation();
    
    if (result != 0) {
      throw Exception('Falha ao pausar simulação: ${_ffiBridge.getLastError()}');
    }
  }

  // Retoma a simulação
  Future<void> resumeSimulation() async {
    _checkInitialized();
    
    final result = _ffiBridge.resumeSimulation();
    
    if (result != 0) {
      throw Exception('Falha ao retomar simulação: ${_ffiBridge.getLastError()}');
    }
  }

  // Obtém o estado atual da simulação
  Future<SimulationState> getSimulationState() async {
    _checkInitialized();
    
    final ffiState = calloc<FFIBridge.SimulationState>();
    final result = _ffiBridge.getSimulationState(ffiState.ref);
    
    if (result != 0) {
      calloc.free(ffiState);
      throw Exception('Falha ao obter estado da simulação: ${_ffiBridge.getLastError()}');
    }
    
    // Converter status
    final status = _convertStatus(ffiState.ref.status);
    
    // Obter mensagem de erro
    String? errorMessage;
    if (ffiState.ref.errorMessage != nullptr) {
      errorMessage = ffiState.ref.errorMessage.toDartString();
    }
    
    // Criar estado
    final state = SimulationState(
      status: status,
      progress: ffiState.ref.progress,
      errorMessage: errorMessage,
      executionTime: ffiState.ref.executionTime,
    );
    
    calloc.free(ffiState);
    
    return state;
  }

  // Obtém os resultados da simulação
  Future<SimulationResults> getResults() async {
    _checkInitialized();
    
    if (_currentParameters == null) {
      throw Exception('Parâmetros de simulação não configurados');
    }
    
    final nr = _currentParameters!.nr;
    final nz = _currentParameters!.nz;
    final timeSteps = _currentParameters!.timeSteps;
    
    // Criar array 3D para armazenar os dados de temperatura
    final temperatureData = List.generate(
      nr,
      (_) => List.generate(
        nz,
        (_) => List.filled(timeSteps + 1, 0.0),
      ),
    );
    
    // Obter dados de temperatura para cada passo de tempo
    for (var step = 0; step <= timeSteps; step++) {
      final bufferSize = nr * nz;
      final buffer = calloc<Float>(bufferSize);
      
      final result = _ffiBridge.getTemperatureData(step, buffer, bufferSize);
      
      if (result != 0) {
        calloc.free(buffer);
        throw Exception('Falha ao obter dados de temperatura: ${_ffiBridge.getLastError()}');
      }
      
      // Copiar dados para o array 3D
      for (var i = 0; i < nr; i++) {
        for (var j = 0; j < nz; j++) {
          temperatureData[i][j][step] = buffer[i * nz + j];
        }
      }
      
      calloc.free(buffer);
    }
    
    // Obter estado para o tempo de execução
    final state = await getSimulationState();
    
    return SimulationResults(
      nr: nr,
      nz: nz,
      timeSteps: timeSteps + 1,
      temperatureData: temperatureData,
      executionTime: state.executionTime,
    );
  }

  // Verifica se o serviço foi inicializado
  void _checkInitialized() {
    if (!_initialized) {
      throw StateError('SimulationService não foi inicializado. Chame initialize() primeiro.');
    }
  }

  // Cria uma estrutura FFI para os parâmetros de simulação
  FFIBridge.SimulationParameters _createFFIParameters(SimulationParameters params) {
    final ffiParams = calloc<FFIBridge.SimulationParameters>().ref;
    
    ffiParams.height = params.height;
    ffiParams.radius = params.radius;
    ffiParams.nr = params.nr;
    ffiParams.nz = params.nz;
    ffiParams.initialTemperature = params.initialTemperature;
    ffiParams.ambientTemperature = params.ambientTemperature;
    ffiParams.convectionCoefficient = params.convectionCoefficient;
    ffiParams.enableConvection = params.enableConvection;
    ffiParams.enableRadiation = params.enableRadiation;
    ffiParams.totalTime = params.totalTime;
    ffiParams.timeStep = params.timeStep;
    ffiParams.timeSteps = params.timeSteps;
    
    return ffiParams;
  }

  // Cria uma estrutura FFI para uma tocha de plasma
  FFIBridge.PlasmaTorch _createFFITorch(PlasmaTorch torch) {
    final ffiTorch = calloc<FFIBridge.PlasmaTorch>().ref;
    
    ffiTorch.rPosition = torch.rPosition;
    ffiTorch.zPosition = torch.zPosition;
    ffiTorch.pitch = torch.pitch;
    ffiTorch.yaw = torch.yaw;
    ffiTorch.power = torch.power;
    ffiTorch.gasFlow = torch.gasFlow;
    ffiTorch.gasTemperature = torch.gasTemperature;
    
    return ffiTorch;
  }

  // Cria uma estrutura FFI para as propriedades do material
  FFIBridge.MaterialProperties _createFFIMaterial(MaterialProperties material) {
    final ffiMaterial = calloc<FFIBridge.MaterialProperties>().ref;
    
    ffiMaterial.name = material.name.toNativeUtf8();
    ffiMaterial.density = material.density;
    ffiMaterial.moistureContent = material.moistureContent;
    ffiMaterial.specificHeat = material.specificHeat;
    ffiMaterial.thermalConductivity = material.thermalConductivity;
    ffiMaterial.emissivity = material.emissivity;
    ffiMaterial.meltingPoint = material.meltingPoint ?? 0.0;
    ffiMaterial.latentHeatFusion = material.latentHeatFusion ?? 0.0;
    ffiMaterial.vaporizationPoint = material.vaporizationPoint ?? 0.0;
    ffiMaterial.latentHeatVaporization = material.latentHeatVaporization ?? 0.0;
    
    return ffiMaterial;
  }

  // Converte o status da simulação
  SimulationStatus _convertStatus(int status) {
    switch (status) {
      case 0:
        return SimulationStatus.notStarted;
      case 1:
        return SimulationStatus.running;
      case 2:
        return SimulationStatus.paused;
      case 3:
        return SimulationStatus.completed;
      case 4:
        return SimulationStatus.failed;
      default:
        return SimulationStatus.notStarted;
    }
  }
}
