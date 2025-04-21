import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart'; // Import for Float32List

// Estruturas FFI (Top-level)

// Parâmetros de simulação
final class SimulationParameters extends Struct {
  @Double()
  external double height;

  @Double()
  external double radius;

  @Int32()
  external int nr;

  @Int32()
  external int nz;

  @Double()
  external double initial_temperature;

  @Double()
  external double ambient_temperature;

  @Double()
  external double convection_coefficient;

  @Bool()
  external bool enable_convection;

  @Bool()
  external bool enable_radiation;

  @Double()
  external double total_time;

  @Double()
  external double time_step;

  @Int32()
  external int time_steps;
}

// Tocha de plasma
final class PlasmaTorch extends Struct {
  @Double()
  external double r_position;

  @Double()
  external double z_position;

  @Double()
  external double pitch;

  @Double()
  external double yaw;

  @Double()
  external double power;

  @Double()
  external double gas_flow;

  @Double()
  external double gas_temperature;
}

// Propriedades do material
final class MaterialProperties extends Struct {
  external Pointer<Utf8> name;

  @Double()
  external double density;

  @Double()
  external double moisture_content;

  @Double()
  external double specific_heat;

  @Double()
  external double thermal_conductivity;

  @Double()
  external double emissivity;

  @Double()
  external double melting_point;

  @Double()
  external double latent_heat_fusion;

  @Double()
  external double vaporization_point;

  @Double()
  external double latent_heat_vaporization;
}

// Estado da simulação
final class SimulationState extends Struct {
  @Int32()
  external int status;

  @Float()
  external double progress;

  external Pointer<Utf8> error_message;

  @Double()
  external double execution_time;
}

// Funções FFI Typedefs (Top-level)
typedef InitializeSimulationNative = Int32 Function(
    Pointer<SimulationParameters>);
typedef InitializeSimulationDart = int Function(Pointer<SimulationParameters>);

typedef AddPlasmaTorchNative = Int32 Function(Pointer<PlasmaTorch>);
typedef AddPlasmaTorchDart = int Function(Pointer<PlasmaTorch>);

typedef SetMaterialPropertiesNative = Int32 Function(
    Pointer<MaterialProperties>);
typedef SetMaterialPropertiesDart = int Function(Pointer<MaterialProperties>);

typedef RunSimulationNative = Int32 Function();
typedef RunSimulationDart = int Function();

typedef PauseSimulationNative = Int32 Function();
typedef PauseSimulationDart = int Function();

typedef ResumeSimulationNative = Int32 Function();
typedef ResumeSimulationDart = int Function();

typedef GetSimulationStateNative = Int32 Function(Pointer<SimulationState>);
typedef GetSimulationStateDart = int Function(Pointer<SimulationState>);

typedef GetTemperatureDataNative = Int32 Function(
    Int32, Pointer<Float>, IntPtr);
typedef GetTemperatureDataDart = int Function(int, Pointer<Float>, int);

typedef DestroySimulationNative = Int32 Function();
typedef DestroySimulationDart = int Function();

typedef GetLastErrorNative = Pointer<Utf8> Function();
typedef GetLastErrorDart = Pointer<Utf8> Function();

typedef FreeErrorMessageNative = Void Function(Pointer<Utf8>);
typedef FreeRustStringNative = Void Function(Pointer<Utf8>);
typedef FreeRustStringDart = void Function(Pointer<Utf8>);

// Classe para gerenciar a ponte FFI com a biblioteca Rust
class FFIBridge {
  // Singleton
  static final FFIBridge _instance = FFIBridge._internal();
  factory FFIBridge() => _instance;
  FFIBridge._internal();

  // Biblioteca dinâmica - Made public
  late DynamicLibrary dylib;
  bool _initialized = false;

  // Store simulation dimensions
  int _nr = 0;
  int _nz = 0;

  // Inicializa a biblioteca
  void initialize() {
    if (_initialized) return;

    final libraryPath = _getLibraryPath();
    try {
      dylib = DynamicLibrary.open(libraryPath);

      // Carrega as funções
      _initializeSimulation = dylib
          .lookup<NativeFunction<InitializeSimulationNative>>(
              'initialize_simulation')
          .asFunction<InitializeSimulationDart>();

      _addPlasmaTorch = dylib
          .lookup<NativeFunction<AddPlasmaTorchNative>>('add_plasma_torch')
          .asFunction<AddPlasmaTorchDart>();

      _setMaterialProperties = dylib
          .lookup<NativeFunction<SetMaterialPropertiesNative>>(
              'set_material_properties')
          .asFunction<SetMaterialPropertiesDart>();

      _runSimulation = dylib
          .lookup<NativeFunction<RunSimulationNative>>('run_simulation')
          .asFunction<RunSimulationDart>();

      _pauseSimulation = dylib
          .lookup<NativeFunction<PauseSimulationNative>>('pause_simulation')
          .asFunction<PauseSimulationDart>();

      _resumeSimulation = dylib
          .lookup<NativeFunction<ResumeSimulationNative>>('resume_simulation')
          .asFunction<ResumeSimulationDart>();

      _getSimulationState = dylib
          .lookup<NativeFunction<GetSimulationStateNative>>(
              'get_simulation_state')
          .asFunction<GetSimulationStateDart>();

      _getTemperatureData = dylib
          .lookup<NativeFunction<GetTemperatureDataNative>>(
              'get_temperature_data')
          .asFunction<GetTemperatureDataDart>();

      _destroySimulation = dylib
          .lookup<NativeFunction<DestroySimulationNative>>('destroy_simulation')
          .asFunction<DestroySimulationDart>();

      _getLastError = dylib
          .lookup<NativeFunction<GetLastErrorNative>>('get_last_error')
          .asFunction<GetLastErrorDart>();

      _freeRustString = dylib
          .lookup<NativeFunction<FreeRustStringNative>>('free_rust_string')
          .asFunction<FreeRustStringDart>();

      _initialized = true;
      print(
          'Biblioteca Rust carregada com sucesso e funções FFI mapeadas: $libraryPath');
    } catch (e) {
      print('Erro ao carregar a biblioteca Rust ou mapear funções FFI: $e');
      rethrow;
    }
  }

  // Obtém o caminho da biblioteca de acordo com a plataforma
  String _getLibraryPath() {
    final String basePath = path.dirname(Platform.resolvedExecutable);

    if (Platform.isMacOS) {
      return path.join(basePath, 'libplasma_simulation.dylib');
    } else if (Platform.isWindows) {
      return path.join(basePath, 'plasma_simulation.dll');
    } else if (Platform.isLinux) {
      return path.join(basePath, 'libplasma_simulation.so');
    } else {
      throw UnsupportedError(
          'Plataforma não suportada: ${Platform.operatingSystem}');
    }
  }

  // Verifica se a biblioteca foi inicializada
  void _checkInitialized() {
    if (!_initialized) {
      throw StateError(
          'FFIBridge não foi inicializado. Chame initialize() primeiro.');
    }
  }

  // Funções FFI carregadas
  late InitializeSimulationDart _initializeSimulation;
  late AddPlasmaTorchDart _addPlasmaTorch;
  late SetMaterialPropertiesDart _setMaterialProperties;
  late RunSimulationDart _runSimulation;
  late PauseSimulationDart _pauseSimulation;
  late ResumeSimulationDart _resumeSimulation;
  late GetSimulationStateDart _getSimulationState;
  late GetTemperatureDataDart _getTemperatureData;
  late DestroySimulationDart _destroySimulation;
  late GetLastErrorDart _getLastError;
  late FreeRustStringDart _freeRustString;

  // Funções da API Pública

  // Inicializa a simulação
  int initializeSimulation(Pointer<SimulationParameters> params) {
    _checkInitialized();
    final result = _initializeSimulation(params);
    if (result == 0) {
      // Store nr and nz on successful initialization
      _nr = params.ref.nr;
      _nz = params.ref.nz;
    } else {
      _nr = 0; // Reset on failure
      _nz = 0;
    }
    return result;
  }

  // Adiciona uma tocha de plasma
  int addPlasmaTorch(Pointer<PlasmaTorch> torch) {
    _checkInitialized();
    return _addPlasmaTorch(torch);
  }

  // Define as propriedades do material
  int setMaterialProperties(Pointer<MaterialProperties> material) {
    _checkInitialized();
    return _setMaterialProperties(material);
  }

  // Executa a simulação
  int runSimulation() {
    _checkInitialized();
    return _runSimulation();
  }

  // Pausa a simulação
  int pauseSimulation() {
    _checkInitialized();
    return _pauseSimulation();
  }

  // Retoma a simulação
  int resumeSimulation() {
    _checkInitialized();
    return _resumeSimulation();
  }

  // Obtém o estado atual da simulação
  // Retorna o estado e a mensagem de erro (se houver)
  (SimulationState, String?) getSimulationState() {
    _checkInitialized();
    // Aloca memória para a struct de estado no lado do Dart
    final statePtr = calloc<SimulationState>();
    try {
      final result = _getSimulationState(statePtr);
      if (result != 0) {
        // Tenta obter a última mensagem de erro se a chamada falhar
        final errorMsgPtr = _getLastError();
        String? errorMsg;
        if (errorMsgPtr != nullptr) {
          errorMsg = errorMsgPtr.toDartString();
          _freeRustString(errorMsgPtr);
        }
        throw Exception(
            'Falha ao obter o estado da simulação. Código: $result. Erro: ${errorMsg ?? "N/A"}');
      }

      // Lê a struct preenchida pelo Rust
      final state = statePtr.ref;
      String? errorMessage;
      if (state.error_message != nullptr) {
        errorMessage = state.error_message.toDartString();
        _freeRustString(state.error_message);
      }

      // Retorna uma cópia dos dados e a string de erro convertida
      // Precisamos criar uma cópia ou garantir que statePtr não seja liberado
      // se a struct SimulationState for usada fora deste escopo imediato.
      // Para simplificar, vamos assumir que o chamador usará os dados imediatamente.
      // Se a struct precisar viver mais, uma cópia profunda seria necessária.
      // No entanto, o ponteiro error_message já foi tratado.
      return (state, errorMessage);
    } finally {
      calloc.free(statePtr); // Libera a memória alocada para a struct
    }
  }

  // Obtém os dados de temperatura para um passo de tempo específico
  Float32List? getTemperatureData(int timeStep) {
    _checkInitialized();

    // Primeiro, precisamos saber o tamanho do buffer necessário.
    if (_nr <= 0 || _nz <= 0) {
      print(
          "Erro: Dimensões da simulação (nr, nz) não inicializadas ou inválidas.");
      // Talvez obter o último erro aqui? Ou lançar uma exceção?
      final errorMsg = getLastError();
      print("Último erro FFI (se houver): $errorMsg");
      throw StateError(
          "A simulação não foi inicializada corretamente com nr e nz válidos.");
    }
    final int expectedSize = _nr * _nz;

    // *** SOLUÇÃO TEMPORÁRIA: Obter o estado para pegar nr/nz implicitamente *** - REMOVED
    // Vamos usar um tamanho fixo grande como placeholder, mas isso é RUIM. - REMOVED
    // const int placeholderSize = 100 * 100; // ESTIMATIVA - PRECISA SER CORRIGIDO - REMOVED

    final bufferPtr = calloc<Float>(expectedSize); // Use expectedSize
    try {
      // Pass IntPtr.from(expectedSize) if the C side expects size_t/uintptr_t
      // Assuming the Dart typedef `int` for size matches the C side `IntPtr` usage.
      // Let's stick to int for now as per the typedef.
      final result = _getTemperatureData(
          timeStep, bufferPtr, expectedSize); // Use expectedSize

      if (result < 0) {
        // Erro
        final errorMsgPtr = _getLastError();
        String? errorMsg;
        if (errorMsgPtr != nullptr) {
          errorMsg = errorMsgPtr.toDartString();
          _freeRustString(errorMsgPtr);
        }
        print(
            'Erro ao obter dados de temperatura: ${errorMsg ?? "Código $result"}');
        return null;
      }

      // result contém o número real de elementos escritos ou 0 se timeStep inválido
      final actualSize = result;
      if (actualSize == 0) {
        print(
            "Nenhum dado de temperatura retornado para o timestep $timeStep (pode ser inválido ou não calculado ainda).");
        return Float32List(0);
      }
      if (actualSize > expectedSize) {
        // Check against expectedSize
        print(
            "WARN: Buffer para temperatura era muito pequeno! Dados truncados. Esperado: $expectedSize, Recebido: $actualSize");
        // Não podemos confiavelmente criar a lista se o buffer foi pequeno demais.
        // A API Rust idealmente retornaria o tamanho necessário se o buffer for pequeno.
        return null; // Ou lançar um erro
      }

      // Copia os dados do ponteiro para uma lista Dart
      final dataList = Float32List(actualSize);
      for (int i = 0; i < actualSize; i++) {
        dataList[i] = bufferPtr[i];
      }
      return dataList;
    } finally {
      calloc.free(bufferPtr);
    }
  }

  // Destrói a simulação e libera recursos no lado Rust
  int destroySimulation() {
    _checkInitialized();
    return _destroySimulation();
  }

  // Obtém a última mensagem de erro (se houver)
  String? getLastError() {
    _checkInitialized();
    final errorMsgPtr = _getLastError();
    if (errorMsgPtr == nullptr) {
      return null;
    }
    final errorMsg = errorMsgPtr.toDartString();
    _freeRustString(errorMsgPtr);
    return errorMsg;
  }

  // Libera manualmente uma string C alocada pelo Rust
  void freeRustString(Pointer<Utf8> messagePtr) {
    _checkInitialized();
    if (messagePtr != nullptr) {
      _freeRustString(messagePtr);
    }
  }

  // --- FFI Helper Methods ---

  // Helper to call functions returning JSON string (handles pointer free)
  String callJsonReturningFunction(Pointer<Utf8> Function() func) {
    Pointer<Utf8> resultPtr = nullptr;
    try {
      resultPtr = func();
      if (resultPtr == nullptr) {
        final errorMsg = getLastError() ?? "FFI function returned null pointer";
        throw Exception(errorMsg);
      }
      final jsonString = resultPtr.toDartString();
      return jsonString;
    } finally {
      if (resultPtr != nullptr) {
        freeRustString(resultPtr);
      }
    }
  }

  String callJsonReturningFunction1Arg(
      Pointer<Utf8> Function(Pointer<Utf8>) func, String arg1) {
    Pointer<Utf8> resultPtr = nullptr;
    final arg1Ptr = arg1.toNativeUtf8();
    try {
      resultPtr = func(arg1Ptr);
      if (resultPtr == nullptr) {
        final errorMsg = getLastError() ?? "FFI function returned null pointer";
        // Handle case where null means "not found" vs error
        // For now, assume null is error unless specifically handled
        throw Exception(errorMsg);
      }
      final jsonString = resultPtr.toDartString();
      return jsonString;
    } finally {
      calloc.free(arg1Ptr);
      if (resultPtr != nullptr) {
        freeRustString(resultPtr);
      }
    }
  }

  String callJsonReturningFunction2Args(
      Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>) func,
      String arg1,
      String arg2) {
    Pointer<Utf8> resultPtr = nullptr;
    final arg1Ptr = arg1.toNativeUtf8();
    final arg2Ptr = arg2.toNativeUtf8();
    try {
      resultPtr = func(arg1Ptr, arg2Ptr);
      if (resultPtr == nullptr) {
        final errorMsg = getLastError() ?? "FFI function returned null pointer";
        throw Exception(errorMsg);
      }
      final jsonString = resultPtr.toDartString();
      return jsonString;
    } finally {
      calloc.free(arg1Ptr);
      calloc.free(arg2Ptr);
      if (resultPtr != nullptr) {
        freeRustString(resultPtr);
      }
    }
  }

  // Helper for functions returning Int (status code)
  void callVoidReturningFunction1Arg(
      int Function(Pointer<Utf8>) func, String arg1) {
    final arg1Ptr = arg1.toNativeUtf8();
    try {
      final result = func(arg1Ptr);
      if (result != 0) {
        // Assuming 0 is success
        final errorMsg =
            getLastError() ?? "FFI function returned error code $result";
        throw Exception(errorMsg);
      }
    } finally {
      calloc.free(arg1Ptr);
    }
  }

  void callVoidReturningFunction2Args(
      int Function(Pointer<Utf8>, Pointer<Utf8>) func,
      String arg1,
      String arg2) {
    final arg1Ptr = arg1.toNativeUtf8();
    final arg2Ptr = arg2.toNativeUtf8();
    try {
      final result = func(arg1Ptr, arg2Ptr);
      if (result != 0) {
        // Assuming 0 is success
        final errorMsg =
            getLastError() ?? "FFI function returned error code $result";
        throw Exception(errorMsg);
      }
    } finally {
      calloc.free(arg1Ptr);
      calloc.free(arg2Ptr);
    }
  }

  // --- End FFI Helper Methods ---
}
