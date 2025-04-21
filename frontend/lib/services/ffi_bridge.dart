import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as path;

// Classe para gerenciar a ponte FFI com a biblioteca Rust
class FFIBridge {
  // Singleton
  static final FFIBridge _instance = FFIBridge._internal();
  factory FFIBridge() => _instance;
  FFIBridge._internal();

  // Biblioteca dinâmica
  late DynamicLibrary _dylib;
  bool _initialized = false;

  // Inicializa a biblioteca
  void initialize() {
    if (_initialized) return;

    final libraryPath = _getLibraryPath();
    try {
      _dylib = DynamicLibrary.open(libraryPath);
      _initialized = true;
      print('Biblioteca Rust carregada com sucesso: $libraryPath');
    } catch (e) {
      print('Erro ao carregar a biblioteca Rust: $e');
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
      throw UnsupportedError('Plataforma não suportada: ${Platform.operatingSystem}');
    }
  }

  // Verifica se a biblioteca foi inicializada
  void _checkInitialized() {
    if (!_initialized) {
      throw StateError('FFIBridge não foi inicializado. Chame initialize() primeiro.');
    }
  }

  // Estruturas FFI

  // Parâmetros de simulação
  class SimulationParameters extends Struct {
    @Double()
    external double height;
    
    @Double()
    external double radius;
    
    @Int32()
    external int nr;
    
    @Int32()
    external int nz;
    
    @Double()
    external double initialTemperature;
    
    @Double()
    external double ambientTemperature;
    
    @Double()
    external double convectionCoefficient;
    
    @Bool()
    external bool enableConvection;
    
    @Bool()
    external bool enableRadiation;
    
    @Double()
    external double totalTime;
    
    @Double()
    external double timeStep;
    
    @Int32()
    external int timeSteps;
  }

  // Tocha de plasma
  class PlasmaTorch extends Struct {
    @Double()
    external double rPosition;
    
    @Double()
    external double zPosition;
    
    @Double()
    external double pitch;
    
    @Double()
    external double yaw;
    
    @Double()
    external double power;
    
    @Double()
    external double gasFlow;
    
    @Double()
    external double gasTemperature;
  }

  // Propriedades do material
  class MaterialProperties extends Struct {
    external Pointer<Utf8> name;
    
    @Double()
    external double density;
    
    @Double()
    external double moistureContent;
    
    @Double()
    external double specificHeat;
    
    @Double()
    external double thermalConductivity;
    
    @Double()
    external double emissivity;
    
    @Double()
    external double meltingPoint;
    
    @Double()
    external double latentHeatFusion;
    
    @Double()
    external double vaporizationPoint;
    
    @Double()
    external double latentHeatVaporization;
  }

  // Estado da simulação
  class SimulationState extends Struct {
    @Int32()
    external int status;
    
    @Float()
    external double progress;
    
    external Pointer<Utf8> errorMessage;
    
    @Double()
    external double executionTime;
  }

  // Funções FFI

  // Inicializa a simulação
  int initializeSimulation(SimulationParameters params) {
    _checkInitialized();
    
    final function = _dylib.lookupFunction<
      Int32 Function(Pointer<SimulationParameters>),
      int Function(Pointer<SimulationParameters>)
    >('initialize_simulation');
    
    return function(params.addressOf);
  }

  // Adiciona uma tocha de plasma
  int addPlasmaTorch(PlasmaTorch torch) {
    _checkInitialized();
    
    final function = _dylib.lookupFunction<
      Int32 Function(Pointer<PlasmaTorch>),
      int Function(Pointer<PlasmaTorch>)
    >('add_plasma_torch');
    
    return function(torch.addressOf);
  }

  // Define as propriedades do material
  int setMaterialProperties(MaterialProperties material) {
    _checkInitialized();
    
    final function = _dylib.lookupFunction<
      Int32 Function(Pointer<MaterialProperties>),
      int Function(Pointer<MaterialProperties>)
    >('set_material_properties');
    
    return function(material.addressOf);
  }

  // Executa a simulação
  int runSimulation() {
    _checkInitialized();
    
    final function = _dylib.lookupFunction<
      Int32 Function(),
      int Function()
    >('run_simulation');
    
    return function();
  }

  // Pausa a simulação
  int pauseSimulation() {
    _checkInitialized();
    
    final function = _dylib.lookupFunction<
      Int32 Function(),
      int Function()
    >('pause_simulation');
    
    return function();
  }

  // Retoma a simulação
  int resumeSimulation() {
    _checkInitialized();
    
    final function = _dylib.lookupFunction<
      Int32 Function(),
      int Function()
    >('resume_simulation');
    
    return function();
  }

  // Obtém o estado atual da simulação
  int getSimulationState(SimulationState state) {
    _checkInitialized();
    
    final function = _dylib.lookupFunction<
      Int32 Function(Pointer<SimulationState>),
      int Function(Pointer<SimulationState>)
    >('get_simulation_state');
    
    return function(state.addressOf);
  }

  // Obtém os dados de temperatura para um passo de tempo específico
  int getTemperatureData(int timeStep, Pointer<Float> buffer, int bufferSize) {
    _checkInitialized();
    
    final function = _dylib.lookupFunction<
      Int32 Function(Int32, Pointer<Float>, Uint64),
      int Function(int, Pointer<Float>, int)
    >('get_temperature_data');
    
    return function(timeStep, buffer, bufferSize);
  }

  // Libera os recursos da simulação
  int destroySimulation() {
    _checkInitialized();
    
    final function = _dylib.lookupFunction<
      Int32 Function(),
      int Function()
    >('destroy_simulation');
    
    return function();
  }

  // Obtém a última mensagem de erro
  String getLastError() {
    _checkInitialized();
    
    final function = _dylib.lookupFunction<
      Pointer<Utf8> Function(),
      Pointer<Utf8> Function()
    >('get_last_error');
    
    final errorPtr = function();
    final error = errorPtr.toDartString();
    
    // Liberar a memória
    final freeFunction = _dylib.lookupFunction<
      Void Function(Pointer<Utf8>),
      void Function(Pointer<Utf8>)
    >('free_error_message');
    
    freeFunction(errorPtr);
    
    return error;
  }
}
