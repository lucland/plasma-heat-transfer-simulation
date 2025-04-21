import 'dart:convert';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../models/validation.dart';
import 'ffi_bridge.dart'; // Import the main FFI bridge
import 'dart:typed_data'; // For Float64List etc.

// --- FFI Struct Definitions (Matching Rust side) ---

final class FFIImportOptions extends Struct {
  external Pointer<Utf8> input_path;
  external Pointer<Utf8> format;
}

final class FFIVector_f64 extends Struct {
  external Pointer<Double> ptr;
  @IntPtr()
  external int len;
}

final class FFICoordinate extends Struct {
  @Double()
  external double x;
  @Double()
  external double y;
  @Double()
  external double z;
}

final class FFIVector_Coordinate extends Struct {
  external Pointer<FFICoordinate> ptr;
  @IntPtr()
  external int len;
}

final class FFIStringPair extends Struct {
  external Pointer<Utf8> key;
  external Pointer<Utf8> value;
}

final class FFIMap_String_String extends Struct {
  external Pointer<FFIStringPair> pairs;
  @IntPtr()
  external int len;
}

final class FFIReferenceData extends Struct {
  external Pointer<Utf8> name;
  external Pointer<Utf8> description;
  external Pointer<Utf8> source;
  external Pointer<Utf8> data_type;
  external FFIVector_Coordinate coordinates;
  external FFIVector_f64 values;
  external FFIVector_f64 uncertainties;
  external FFIMap_String_String metadata;
}

final class FFIValidationMetrics extends Struct {
  @Double()
  external double mean_absolute_error;
  @Double()
  external double mean_squared_error;
  @Double()
  external double root_mean_squared_error;
  @Double()
  external double mean_absolute_percentage_error;
  @Double()
  external double r_squared;
  @Double()
  external double max_absolute_error;
  @Double()
  external double mean_error;
  @Double()
  external double normalized_rmse;
}

final class FFIValidationResult extends Struct {
  external Pointer<Utf8> name;
  external Pointer<Utf8> description;
  external Pointer<FFIReferenceData> reference_data; // Pointer!
  external FFIValidationMetrics metrics;
  external FFIVector_f64 simulated_values;
  external FFIMap_String_String metadata;
}

// --- FFI Function Typedefs ---

typedef ImportReferenceDataNative = Pointer<FFIReferenceData> Function(
    Pointer<FFIImportOptions>);
typedef ImportReferenceDataDart = Pointer<FFIReferenceData> Function(
    Pointer<FFIImportOptions>);

typedef FreeReferenceDataNative = Void Function(Pointer<FFIReferenceData>);
typedef FreeReferenceDataDart = void Function(Pointer<FFIReferenceData>);

typedef CreateSyntheticReferenceDataNative = Pointer<FFIReferenceData> Function(
    Int32, Double);
typedef CreateSyntheticReferenceDataDart = Pointer<FFIReferenceData> Function(
    int, double);

typedef ValidateModelNative = Pointer<FFIValidationResult> Function(
    Pointer<Utf8>, Pointer<Utf8>);
typedef ValidateModelDart = Pointer<FFIValidationResult> Function(
    Pointer<Utf8>, Pointer<Utf8>);

typedef FreeValidationResultNative = Void Function(
    Pointer<FFIValidationResult>);
typedef FreeValidationResultDart = void Function(Pointer<FFIValidationResult>);

typedef GenerateValidationReportNative = Int32 Function(Pointer<Utf8>);
typedef GenerateValidationReportDart = int Function(Pointer<Utf8>);

// Ponte FFI para validação de modelos
class ValidationFFIBridge {
  // Get singleton instance of the main bridge
  final FFIBridge _mainBridge = FFIBridge();
  late final DynamicLibrary _dylib;

  // Function pointers
  late ImportReferenceDataDart _importReferenceData;
  late FreeReferenceDataDart _freeReferenceData;
  late CreateSyntheticReferenceDataDart _createSyntheticReferenceData;
  late ValidateModelDart _validateModel;
  late FreeValidationResultDart _freeValidationResult;
  late GenerateValidationReportDart _generateValidationReport;

  ValidationFFIBridge() {
    // Ensure main bridge is initialized and get the library
    _mainBridge.initialize(); // Ensure library is loaded
    _dylib = _mainBridge.dylib; // Access the PUBLIC dylib

    // Load validation functions
    _loadFunctions();
  }

  void _loadFunctions() {
    _importReferenceData = _dylib
        .lookup<NativeFunction<ImportReferenceDataNative>>(
            'import_reference_data')
        .asFunction<ImportReferenceDataDart>();
    _freeReferenceData = _dylib
        .lookup<NativeFunction<FreeReferenceDataNative>>('free_reference_data')
        .asFunction<FreeReferenceDataDart>();
    _createSyntheticReferenceData = _dylib
        .lookup<NativeFunction<CreateSyntheticReferenceDataNative>>(
            'create_synthetic_reference_data')
        .asFunction<CreateSyntheticReferenceDataDart>();
    _validateModel = _dylib
        .lookup<NativeFunction<ValidateModelNative>>('validate_model')
        .asFunction<ValidateModelDart>();
    _freeValidationResult = _dylib
        .lookup<NativeFunction<FreeValidationResultNative>>(
            'free_validation_result')
        .asFunction<FreeValidationResultDart>();
    _generateValidationReport = _dylib
        .lookup<NativeFunction<GenerateValidationReportNative>>(
            'generate_validation_report')
        .asFunction<GenerateValidationReportDart>();
  }

  // --- Helper Functions (Dart side conversions) ---

  // Convert FFIReferenceData pointer to Dart ReferenceData model
  // NOTE: This is a simplified conversion and needs proper handling for vectors/maps
  ReferenceData _convertFFIReferenceData(Pointer<FFIReferenceData> ffiPtr) {
    if (ffiPtr == nullptr) {
      throw Exception("Received null pointer from FFI for ReferenceData");
    }
    final ffiData = ffiPtr.ref;

    // TODO: Implement proper conversion for vectors and maps
    // This requires reading data from ffiData.values.ptr, ffiData.coordinates.ptr etc.
    // and freeing the corresponding Rust vectors if necessary (depends on Rust impl)
    List<List<double>> coords = []; // Placeholder
    List<double> values = ffiData.values.ptr
        .asTypedList(ffiData.values.len)
        .toList(); // Example for values
    List<double> uncertainties = []; // Placeholder
    Map<String, String> metadata = {}; // Placeholder

    return ReferenceData(
      name: ffiData.name.toDartString(),
      description: ffiData.description.toDartString(),
      source: ffiData.source.toDartString(),
      dataType: ffiData.data_type.toDartString(),
      coordinates: coords,
      values: values,
      uncertainties: uncertainties,
      metadata: metadata,
    );
  }

  // Convert FFIValidationResult pointer to Dart ValidationResult model
  // NOTE: Simplified conversion
  ValidationResult _convertFFIValidationResult(
      Pointer<FFIValidationResult> ffiPtr) {
    if (ffiPtr == nullptr) {
      throw Exception("Received null pointer from FFI for ValidationResult");
    }
    final ffiResult = ffiPtr.ref;

    // Convert nested reference data (potential ownership issues if not copied)
    final referenceData = _convertFFIReferenceData(ffiResult.reference_data);

    // Convert metrics
    final metrics = ValidationMetrics(
      meanAbsoluteError: ffiResult.metrics.mean_absolute_error,
      meanSquaredError: ffiResult.metrics.mean_squared_error,
      rootMeanSquaredError: ffiResult.metrics.root_mean_squared_error,
      meanAbsolutePercentageError:
          ffiResult.metrics.mean_absolute_percentage_error,
      rSquared: ffiResult.metrics.r_squared,
      maxAbsoluteError: ffiResult.metrics.max_absolute_error,
      meanError: ffiResult.metrics.mean_error,
      normalizedRmse: ffiResult.metrics.normalized_rmse,
      regionMetrics: {}, // Placeholder
    );

    // TODO: Convert simulated_values and metadata
    List<double> simulatedValues = []; // Placeholder
    Map<String, String> metadata = {}; // Placeholder

    return ValidationResult(
      name: ffiResult.name.toDartString(),
      description: ffiResult.description.toDartString(),
      referenceData: referenceData,
      metrics: metrics,
      simulatedValues: simulatedValues,
      metadata: metadata,
    );
  }

  // --- Public API Methods ---

  // Importa dados de referência a partir de um arquivo
  Future<ReferenceData> importReferenceData(ImportOptions options) async {
    // _mainBridge._checkInitialized(); // REMOVED - Initialization checked in constructor

    // Allocate FFI options struct
    final optionsPtr = calloc<FFIImportOptions>();
    final pathPtr = options.inputPath.toNativeUtf8();
    final formatPtr = options.format.toNativeUtf8();

    try {
      optionsPtr.ref.input_path = pathPtr;
      optionsPtr.ref.format = formatPtr;

      // Call FFI function
      final resultPtr = _importReferenceData(optionsPtr);

      if (resultPtr == nullptr) {
        final errorMsg = _mainBridge.getLastError() ??
            "Erro desconhecido ao importar dados de referência";
        throw Exception(errorMsg);
      }

      // Convert the result (pointer) to Dart object
      // This conversion needs to be deep if the object is used after freeing the FFI pointer
      final referenceData = _convertFFIReferenceData(resultPtr);

      // IMPORTANT: Free the memory allocated by Rust for the ReferenceData struct itself
      // (and its contents, which should be handled by the Rust free_reference_data func)
      _freeReferenceData(resultPtr);

      return referenceData;
    } finally {
      // Free memory allocated in Dart
      calloc.free(optionsPtr);
      calloc.free(pathPtr);
      calloc.free(formatPtr);
    }
  }

  // Cria dados de referência sintéticos para testes
  Future<ReferenceData> createSyntheticReferenceData(
      int numPoints, double errorLevel) async {
    // _mainBridge._checkInitialized(); // REMOVED
    Pointer<FFIReferenceData> resultPtr = nullptr;
    try {
      resultPtr = _createSyntheticReferenceData(numPoints, errorLevel);

      if (resultPtr == nullptr) {
        final errorMsg = _mainBridge.getLastError() ??
            "Erro desconhecido ao criar dados sintéticos";
        throw Exception(errorMsg);
      }

      final referenceData = _convertFFIReferenceData(resultPtr);
      _freeReferenceData(resultPtr); // Free Rust memory
      return referenceData;
    } catch (e) {
      // Ensure memory is freed even on conversion errors, if ptr is valid
      if (resultPtr != nullptr) _freeReferenceData(resultPtr);
      print("Error in createSyntheticReferenceData: $e");
      rethrow;
    }
  }

  // Valida o modelo com os dados de referência
  Future<ValidationResult> validateModel(
      String name, String description) async {
    // _mainBridge._checkInitialized(); // REMOVED

    final namePtr = name.toNativeUtf8();
    final descPtr = description.toNativeUtf8();
    Pointer<FFIValidationResult> resultPtr = nullptr;

    try {
      resultPtr = _validateModel(namePtr, descPtr);

      if (resultPtr == nullptr) {
        final errorMsg =
            _mainBridge.getLastError() ?? "Erro desconhecido ao validar modelo";
        throw Exception(errorMsg);
      }

      final validationResult = _convertFFIValidationResult(resultPtr);
      _freeValidationResult(resultPtr); // Free Rust memory
      return validationResult;
    } catch (e) {
      if (resultPtr != nullptr) _freeValidationResult(resultPtr);
      print("Error in validateModel: $e");
      rethrow;
    } finally {
      calloc.free(namePtr);
      calloc.free(descPtr);
    }
  }

  // Gera um relatório de validação
  Future<void> generateValidationReport(String outputPath) async {
    // _mainBridge._checkInitialized(); // REMOVED
    final pathPtr = outputPath.toNativeUtf8();
    try {
      final result = _generateValidationReport(pathPtr);
      if (result != 0) {
        // Assuming 0 is success
        final errorMsg = _mainBridge.getLastError() ??
            "Erro desconhecido ao gerar relatório";
        throw Exception(errorMsg);
      }
      // Success, no return value needed
    } finally {
      calloc.free(pathPtr);
    }
  }

  // REMOVED: _calculateMetrics - This should now be done in Rust
}
