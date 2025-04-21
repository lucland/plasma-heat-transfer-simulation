import 'dart:async';
import 'dart:ffi';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ffi/ffi.dart';

import '../models/simulation_parameters.dart' as models;
import '../models/simulation_results.dart';
import '../services/ffi_bridge.dart' as ffi;

// Provider para o serviço de simulação
final simulationServiceProvider = Provider<SimulationService>((ref) {
  return SimulationService();
});

// Provider para o estado da simulação
final simulationStateProvider =
    StateNotifierProvider<SimulationStateNotifier, SimulationState>((ref) {
  return SimulationStateNotifier(ref.watch(simulationServiceProvider));
});

// Notificador de estado para a simulação
class SimulationStateNotifier extends StateNotifier<SimulationState> {
  final SimulationService _simulationService;
  Timer? _pollingTimer;

  SimulationStateNotifier(this._simulationService)
      : super(SimulationState.initial()) {
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
  Future<void> setParameters(models.SimulationParameters parameters) async {
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
    _pollingTimer =
        Timer.periodic(Duration(milliseconds: 500), (_) => _updateState());
  }

  // Para o polling
  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  // Atualiza o estado da simulação
  Future<void> _updateState() async {
    try {
      final currentSimState = await _simulationService.getSimulationState();

      // Update notifier state (ensure SimulationState has copyWith)
      state = state.copyWith(
        status: currentSimState.status,
        progress: currentSimState.progress,
        errorMessage: currentSimState.errorMessage,
        executionTime: currentSimState.executionTime,
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
  final ffi.FFIBridge _ffiBridge = ffi.FFIBridge();
  bool _initialized = false;
  models.SimulationParameters? _currentParameters;

  // Inicializa o serviço
  void initialize() {
    if (_initialized) return;

    _ffiBridge.initialize();
    _initialized = true;
  }

  // Configura os parâmetros da simulação
  Future<void> setParameters(models.SimulationParameters parameters) async {
    _checkInitialized();

    // Validar parâmetros
    // Assuming validation is on the model type
    // final errors = parameters.validate();
    // if (errors.isNotEmpty) {
    //   throw Exception('Parâmetros inválidos: ${errors.join(', ')}');
    // }

    // Armazenar parâmetros atuais
    _currentParameters = parameters;

    // Inicializar simulação
    final ffiParamsPtr = _createFFIParameters(parameters);
    try {
      final result = _ffiBridge.initializeSimulation(ffiParamsPtr);
      if (result != 0) {
        // getLastError() implicitly frees the error string
        throw Exception(
            'Falha ao inicializar simulação: ${_ffiBridge.getLastError()}');
      }
    } finally {
      // Free the allocated FFI parameters struct
      _freeFFIParameters(ffiParamsPtr);
    }

    // Adicionar tochas
    for (var torch in parameters.torches) {
      final ffiTorchPtr = _createFFITorch(torch);
      try {
        final result = _ffiBridge.addPlasmaTorch(ffiTorchPtr);
        if (result != 0) {
          throw Exception(
              'Falha ao adicionar tocha: ${_ffiBridge.getLastError()}');
        }
      } finally {
        // Free the allocated FFI torch struct
        _freeFFITorch(ffiTorchPtr);
      }
    }

    // Configurar material
    final ffiMaterialPtr = _createFFIMaterial(parameters.material);
    try {
      final materialResult = _ffiBridge.setMaterialProperties(ffiMaterialPtr);
      if (materialResult != 0) {
        throw Exception(
            'Falha ao configurar material: ${_ffiBridge.getLastError()}');
      }
    } finally {
      // Free the allocated FFI material struct
      _freeFFIMaterial(ffiMaterialPtr);
    }
  }

  // Executa a simulação
  Future<void> runSimulation() async {
    _checkInitialized();

    final result = _ffiBridge.runSimulation();

    if (result != 0) {
      throw Exception(
          'Falha ao executar simulação: ${_ffiBridge.getLastError()}');
    }
  }

  // Pausa a simulação
  Future<void> pauseSimulation() async {
    _checkInitialized();

    final result = _ffiBridge.pauseSimulation();

    if (result != 0) {
      throw Exception(
          'Falha ao pausar simulação: ${_ffiBridge.getLastError()}');
    }
  }

  // Retoma a simulação
  Future<void> resumeSimulation() async {
    _checkInitialized();

    final result = _ffiBridge.resumeSimulation();

    if (result != 0) {
      throw Exception(
          'Falha ao retomar simulação: ${_ffiBridge.getLastError()}');
    }
  }

  // Obtém o estado atual da simulação
  Future<SimulationState> getSimulationState() async {
    _checkInitialized();

    // Call the updated FFI bridge method
    final (ffiState, errorMessage) = _ffiBridge.getSimulationState();

    // Handle potential error message from the tuple
    if (errorMessage != null) {
      print(
          "Error message returned from getSimulationState FFI: $errorMessage");
      // Return an error state matching the model structure
      return SimulationState(
        // Assuming SimulationState is MODEL type
        status: SimulationStatus.failed,
        progress: 0.0, // Use default value
        errorMessage: "Erro FFI: $errorMessage",
        executionTime: 0.0, // Use default value
      );
    }

    // Convert FFI state struct to the application's SimulationState model
    // This assumes the SimulationState model has a simple constructor
    // Adjust if it uses copyWith or factory constructors
    return SimulationState(
      status: _mapFFIStatus(ffiState.status),
      progress: ffiState.progress,
      errorMessage: null, // Error handled above
      executionTime: ffiState.execution_time,
      // results: null // Results are fetched separately
    );
  }

  // Helper to map FFI status int to Dart enum
  SimulationStatus _mapFFIStatus(int ffiStatus) {
    // Ensure this mapping matches the one defined in Rust FFI comments
    // 0: NotStarted, 1: Running, 2: Paused, 3: Completed, 4: Failed
    switch (ffiStatus) {
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
        print("Aviso: Status FFI desconhecido recebido: $ffiStatus");
        return SimulationStatus.failed; // Default to failed for unknown status
    }
  }

  // Obtém os resultados da simulação (exemplo: temperatura no último passo)
  Future<SimulationResults?> getResults() async {
    // Return nullable type
    _checkInitialized();
    if (_currentParameters == null) {
      print("Parâmetros não configurados para obter resultados.");
      return null; // Return null if parameters not set
    }

    // Decide which timestep? Maybe the last one?
    final lastTimeStep = _currentParameters!.timeSteps - 1;
    if (lastTimeStep < 0) {
      print("Nenhum passo de tempo válido para obter resultados.");
      return null; // No steps to get results from
    }

    try {
      final temperatureDataList = _ffiBridge.getTemperatureData(lastTimeStep);

      if (temperatureDataList == null) {
        print(
            "Falha ao obter dados de temperatura para o passo $lastTimeStep (FFI retornou null).");
        return null; // Return null if FFI failed
      }

      // --- TODO: Implement proper conversion from Float32List to List<List<double>> ---
      // This requires knowing nr and nz. Assuming _currentParameters is not null here.
      final nr = _currentParameters!.nr;
      final nz = _currentParameters!.nz;
      List<List<double>> formattedTemperatureData = [];
      if (temperatureDataList.length == nr * nz) {
        formattedTemperatureData = List.generate(
            nr,
            (i) => List.generate(
                nz, (j) => temperatureDataList[i * nz + j].toDouble()));
      } else {
        print(
            "Erro: Tamanho dos dados de temperatura (${temperatureDataList.length}) não corresponde a nr*nz (${nr * nz})");
        // Return null or throw? Let's return null for now.
        return null;
      }
      // --- End TODO ---

      // Fetch execution time separately if needed, maybe from last known state?
      // Getting state again might be slightly outdated, but better than nothing.
      final currentState = await getSimulationState();
      final lastExecutionTime = currentState.executionTime;

      return SimulationResults(
        // Adapt as needed for the actual SimulationResults model definition
        nr: nr,
        nz: nz,
        timeSteps: 1, // We only fetched one step
        temperatureData: [
          formattedTemperatureData
        ], // Wrap the single step data in a list
        executionTime: lastExecutionTime,
      );
    } catch (e) {
      print("Erro ao obter resultados da simulação: $e");
      // Consider calling getLastError here if appropriate
      // final errorMsg = _ffiBridge.getLastError();
      // print("FFI Error: $errorMsg");
      throw Exception("Erro ao processar resultados da simulação: $e");
    }
  }

  // Verifica se o serviço foi inicializado
  void _checkInitialized() {
    if (!_initialized) {
      throw StateError(
          'SimulationService não foi inicializado. Chame initialize() primeiro.');
    }
  }

  // Cria ponteiro FFI para SimulationParameters
  Pointer<ffi.SimulationParameters> _createFFIParameters(
      models.SimulationParameters params) {
    final ptr = calloc<ffi.SimulationParameters>();
    ptr.ref
      ..height = params.height
      ..radius = params.radius
      ..nr = params.nr
      ..nz = params.nz
      ..initial_temperature = params.initialTemperature
      ..ambient_temperature = params.ambientTemperature
      ..convection_coefficient = params.convectionCoefficient
      ..enable_convection = params.enableConvection
      ..enable_radiation = params.enableRadiation
      ..total_time = params.totalTime
      ..time_step = params.timeStep
      ..time_steps = params.timeSteps;
    return ptr;
  }

  // Libera memória alocada para SimulationParameters
  void _freeFFIParameters(Pointer<ffi.SimulationParameters> ptr) {
    calloc.free(ptr);
  }

  // Cria ponteiro FFI para PlasmaTorch
  Pointer<ffi.PlasmaTorch> _createFFITorch(models.PlasmaTorch torch) {
    final ptr = calloc<ffi.PlasmaTorch>();
    ptr.ref
      ..r_position = torch.rPosition
      ..z_position = torch.zPosition
      ..pitch = torch.pitch
      ..yaw = torch.yaw
      ..power = torch.power
      ..gas_flow = torch.gasFlow
      ..gas_temperature = torch.gasTemperature;
    return ptr;
  }

  // Libera memória alocada para PlasmaTorch
  void _freeFFITorch(Pointer<ffi.PlasmaTorch> ptr) {
    calloc.free(ptr);
  }

  // Cria ponteiro FFI para MaterialProperties
  Pointer<ffi.MaterialProperties> _createFFIMaterial(
      models.MaterialProperties material) {
    final ptr = calloc<ffi.MaterialProperties>();
    final namePtr = material.name.toNativeUtf8(); // Allocate string separately
    ptr.ref
      ..name = namePtr
      ..density = material.density
      ..moisture_content = material.moistureContent
      ..specific_heat = material.specificHeat
      ..thermal_conductivity = material.thermalConductivity
      ..emissivity = material.emissivity
      ..melting_point = material.meltingPoint ?? 0.0 // Handle nullable
      ..latent_heat_fusion = material.latentHeatFusion ?? 0.0
      ..vaporization_point = material.vaporizationPoint ?? 0.0
      ..latent_heat_vaporization = material.latentHeatVaporization ?? 0.0;
    // IMPORTANT: namePtr needs to be freed separately AFTER the FFI call
    // This approach is flawed. We need to free namePtr in the caller (_setParameters)
    // Let's adjust _freeFFIMaterial to handle this.
    return ptr;
  }

  // Libera memória alocada para MaterialProperties (incluindo string)
  void _freeFFIMaterial(Pointer<ffi.MaterialProperties> ptr) {
    // Free the string pointer stored inside the struct first
    if (ptr.ref.name != nullptr) {
      calloc.free(ptr.ref.name);
    }
    // Then free the struct itself
    calloc.free(ptr);
  }
}
