// Implementação dos bindings FFI para comunicação com o frontend Flutter

use std::ffi::{c_void, CStr, CString};
use std::os::raw::{c_char, c_int, c_float, c_double};
use std::ptr;
use std::slice;
use std::sync::{Arc, Mutex};
use std::sync::atomic::Ordering;
use std::collections::HashMap;
use std::mem;
use std::cell::RefCell; // Added for thread-local

use crate::simulation::{
    SimulationParameters, SimulationResults, HeatSolver, 
    MaterialProperties, PlasmaTorch, SimulationState, SharedSimulationState
};
use crate::models::validation::{self, ImportOptions, ReferenceData, ValidationResult, ValidationMetrics};
use crate::formulas; // Assuming this module exists
use crate::metrics; // Assuming this module exists
use crate::export;  // Assuming this module exists
use crate::reporting; // Assuming this module exists
use crate::parametric; // Assuming this module exists

// Estrutura para passar parâmetros de simulação através da FFI
#[repr(C)]
pub struct FFISimulationParameters {
    pub height: f64,
    pub radius: f64,
    pub nr: i32,
    pub nz: i32,
    pub initial_temperature: f64,
    pub ambient_temperature: f64,
    pub convection_coefficient: f64,
    pub enable_convection: bool,
    pub enable_radiation: bool,
    pub total_time: f64,
    pub time_step: f64,
    pub time_steps: i32,
}

// Estrutura para passar informações de tocha através da FFI
#[repr(C)]
pub struct FFIPlasmaTorch {
    pub r_position: f64,
    pub z_position: f64,
    pub pitch: f64,
    pub yaw: f64,
    pub power: f64,
    pub gas_flow: f64,
    pub gas_temperature: f64,
}

// Estrutura para passar informações de material através da FFI
#[repr(C)]
pub struct FFIMaterialProperties {
    pub name: *const c_char,
    pub density: f64,
    pub moisture_content: f64,
    pub specific_heat: f64,
    pub thermal_conductivity: f64,
    pub emissivity: f64,
    pub melting_point: f64,
    pub latent_heat_fusion: f64,
    pub vaporization_point: f64,
    pub latent_heat_vaporization: f64,
}

// Estrutura para passar informações de estado da simulação através da FFI
#[repr(C)]
pub struct FFISimulationState {
    pub status: i32,  // 0: NotStarted, 1: Running, 2: Paused, 3: Completed, 4: Failed
    pub progress: f32,
    pub error_message: *const c_char,
    pub execution_time: f64,
}

// Armazenamento global para o estado da simulação
static mut SIMULATION_STATE: Option<SharedSimulationState> = None;

// Armazenamento thread-local para a última mensagem de erro específica da FFI
thread_local! {
    static LAST_ERROR: RefCell<Option<String>> = RefCell::new(None);
}

/// Helper function to set the thread-local FFI error message.
fn set_last_ffi_error(err_msg: String) {
    LAST_ERROR.with(|cell| {
        *cell.borrow_mut() = Some(err_msg);
    });
}

// Função auxiliar para converter FFISimulationParameters para SimulationParameters
fn convert_ffi_parameters(ffi_params: &FFISimulationParameters) -> SimulationParameters {
    let mut params = SimulationParameters::new(
        ffi_params.height,
        ffi_params.radius,
        ffi_params.nr as usize,
        ffi_params.nz as usize,
    );
    
    params.initial_temperature = ffi_params.initial_temperature;
    params.ambient_temperature = ffi_params.ambient_temperature;
    params.convection_coefficient = ffi_params.convection_coefficient;
    params.enable_convection = ffi_params.enable_convection;
    params.enable_radiation = ffi_params.enable_radiation;
    params.total_time = ffi_params.total_time;
    params.time_step = ffi_params.time_step;
    params.time_steps = ffi_params.time_steps as usize;
    
    params
}

// Função auxiliar para converter FFIPlasmaTorch para PlasmaTorch
fn convert_ffi_torch(ffi_torch: &FFIPlasmaTorch) -> PlasmaTorch {
    PlasmaTorch::new(
        ffi_torch.r_position,
        ffi_torch.z_position,
        ffi_torch.pitch,
        ffi_torch.yaw,
        ffi_torch.power,
        ffi_torch.gas_flow,
        ffi_torch.gas_temperature,
    )
}

// Função auxiliar para converter FFIMaterialProperties para MaterialProperties
fn convert_ffi_material(ffi_material: &FFIMaterialProperties) -> MaterialProperties {
    let name = unsafe {
        CStr::from_ptr(ffi_material.name)
            .to_string_lossy()
            .into_owned()
    };
    
    let mut material = MaterialProperties::new(
        &name,
        ffi_material.density,
        ffi_material.specific_heat,
        ffi_material.thermal_conductivity,
    );
    
    material.moisture_content = ffi_material.moisture_content;
    material.emissivity = ffi_material.emissivity;
    
    if ffi_material.melting_point > 0.0 {
        material.melting_point = Some(ffi_material.melting_point);
    }
    
    if ffi_material.latent_heat_fusion > 0.0 {
        material.latent_heat_fusion = Some(ffi_material.latent_heat_fusion);
    }
    
    if ffi_material.vaporization_point > 0.0 {
        material.vaporization_point = Some(ffi_material.vaporization_point);
    }
    
    if ffi_material.latent_heat_vaporization > 0.0 {
        material.latent_heat_vaporization = Some(ffi_material.latent_heat_vaporization);
    }
    
    material
}

// Função auxiliar para converter SimulationState para FFISimulationState
fn convert_simulation_state(state: &SimulationState) -> FFISimulationState {
    let status = match state.status {
        crate::simulation::SimulationStatus::NotStarted => 0,
        crate::simulation::SimulationStatus::Running => 1,
        crate::simulation::SimulationStatus::Paused => 2,
        crate::simulation::SimulationStatus::Completed => 3,
        crate::simulation::SimulationStatus::Failed => 4,
    };
    
    let error_message = match &state.error_message {
        Some(msg) => CString::new(msg.clone()).unwrap().into_raw(),
        None => ptr::null(),
    };
    
    FFISimulationState {
        status,
        progress: state.progress,
        error_message,
        execution_time: state.execution_time,
    }
}

// --- FFI Structs for Validation ---

#[repr(C)]
pub struct FFIImportOptions {
    pub input_path: *const c_char,
    pub format: *const c_char, // e.g., "CSV", "JSON"
}

// Represents a vector of f64
#[repr(C)]
pub struct FFIVector_f64 {
    pub ptr: *const f64,
    pub len: usize,
}

// Represents a coordinate (example, adjust as needed)
#[repr(C)]
pub struct FFICoordinate {
   pub x: f64,
   pub y: f64,
   pub z: f64,
}

// Represents a vector of coordinates
#[repr(C)]
pub struct FFIVector_Coordinate {
   pub ptr: *const FFICoordinate,
   pub len: usize,
}


// Represents a key-value pair for maps (simplistic example)
#[repr(C)]
pub struct FFIStringPair {
    pub key: *const c_char,
    pub value: *const c_char,
}

// Represents a map of String -> String (simplistic example)
#[repr(C)]
pub struct FFIMap_String_String {
    pub pairs: *const FFIStringPair,
    pub len: usize,
}


// Represents ReferenceData for FFI
#[repr(C)]
pub struct FFIReferenceData {
    pub name: *const c_char,
    pub description: *const c_char,
    pub source: *const c_char,
    pub data_type: *const c_char,
    pub coordinates: FFIVector_Coordinate, // Needs careful handling
    pub values: FFIVector_f64,        // Needs careful handling
    pub uncertainties: FFIVector_f64, // Needs careful handling
    pub metadata: FFIMap_String_String, // Needs careful handling
}


// Represents ValidationMetrics for FFI (simplified example)
#[repr(C)]
pub struct FFIValidationMetrics {
    pub mean_absolute_error: f64,
    pub mean_squared_error: f64,
    pub root_mean_squared_error: f64,
    pub mean_absolute_percentage_error: f64,
    pub r_squared: f64,
    pub max_absolute_error: f64,
    pub mean_error: f64,
    pub normalized_rmse: f64,
    // pub region_metrics: FFIMap_String_FFIValidationMetrics, // Too complex for simple FFI, skip for now
}

// Represents ValidationResult for FFI
#[repr(C)]
pub struct FFIValidationResult {
    pub name: *const c_char,
    pub description: *const c_char,
    pub reference_data: *mut FFIReferenceData, // Pointer to nested struct
    pub metrics: FFIValidationMetrics,
    pub simulated_values: FFIVector_f64,    // Needs careful handling
    pub metadata: FFIMap_String_String,     // Needs careful handling
}

// --- Helper functions for memory management ---

// Helper to convert Vec<f64> to FFIVector_f64 (allocates memory!)
fn vec_to_ffi_vector_f64(vec: Vec<f64>) -> FFIVector_f64 {
    let ptr = vec.as_ptr();
    let len = vec.len();
    mem::forget(vec); // Prevent Rust from freeing the memory
    FFIVector_f64 { ptr, len }
}

// Helper to free memory allocated for FFIVector_f64
#[no_mangle]
pub extern "C" fn free_ffi_vector_f64(vec: FFIVector_f64) {
    unsafe {
        if !vec.ptr.is_null() { // Add null check
            let _ = Vec::from_raw_parts(vec.ptr as *mut f64, vec.len, vec.len);
        }
    }
}

// Similar helpers needed for FFIVector_Coordinate, FFIStringPair, FFIMap_String_String
// ... these are non-trivial to implement correctly for FFI ...


// --- FFI Functions for Validation ---

/// Converts FFIImportOptions to validation::ImportOptions
fn convert_ffi_import_options(ffi_options: *const FFIImportOptions) -> Result<validation::ImportOptions, String> {
    if ffi_options.is_null() {
        return Err("FFIImportOptions pointer was null".to_string());
    }
    let options = unsafe { &*ffi_options };

    let input_path = if options.input_path.is_null() {
        return Err("input_path was null".to_string());
    } else {
        unsafe { CStr::from_ptr(options.input_path) }.to_str()
            .map_err(|e| format!("Invalid UTF-8 in input_path: {}", e))?
            .to_string()
    };

    let format = if options.format.is_null() {
        return Err("format was null".to_string());
    } else {
         unsafe { CStr::from_ptr(options.format) }.to_str()
            .map_err(|e| format!("Invalid UTF-8 in format: {}", e))?
            .to_string()
    };

    Ok(validation::ImportOptions { input_path, format })
}


#[no_mangle]
pub extern "C" fn import_reference_data(options: *const FFIImportOptions) -> *mut FFIReferenceData {
    let import_options = match convert_ffi_import_options(options) {
        Ok(opts) => opts,
        Err(e) => {
            set_last_ffi_error(format!("Invalid import options: {}", e));
            return ptr::null_mut();
        }
    };

    match validation::import_data(import_options) {
        Ok(ref_data) => {
            // TODO: Convert ref_data (Rust ReferenceData) to FFIReferenceData
            // This requires allocating memory for strings, vectors, etc.
            // and returning a Box::into_raw pointer.
             println!("RUST: import_reference_data succeeded, but FFI conversion TODO.");
             set_last_ffi_error("FFI conversion for ReferenceData not implemented".to_string());
             ptr::null_mut() // Return null until conversion is implemented
        }
        Err(e) => {
            set_last_ffi_error(format!("Failed to import reference data: {}", e));
            ptr::null_mut()
        }
    }
}

#[no_mangle]
pub extern "C" fn free_reference_data(data: *mut FFIReferenceData) {
    if !data.is_null() {
        unsafe {
             // TODO: Free all allocated memory within FFIReferenceData
             // - Free strings (CString::from_raw)
             // - Free vectors (using helpers like free_ffi_vector_f64)
             // - Free maps
             println!("RUST: free_reference_data called (STUB - Potential memory leaks!)");
            // Placeholder: Free only the top-level struct for now
            // Proper implementation MUST free nested allocated data (strings, vectors, maps)
            // For example, if name was allocated with CString::into_raw:
            // if !(*data).name.is_null() { let _ = CString::from_raw((*data).name as *mut c_char); }
            // free_ffi_vector_f64((*data).values); // Assuming a helper exists and was used

            let _ = Box::from_raw(data); // Free the main struct allocated with Box::into_raw
        }
    }
}

#[no_mangle]
pub extern "C" fn create_synthetic_reference_data(num_points: c_int, error_level: c_double) -> *mut FFIReferenceData {
    if num_points <= 0 {
         set_last_ffi_error("Number of points must be positive".to_string());
         return ptr::null_mut();
    }

     match validation::create_synthetic(num_points as usize, error_level) {
        Ok(ref_data) => {
            // TODO: Convert ref_data (Rust ReferenceData) to FFIReferenceData
             println!("RUST: create_synthetic_reference_data succeeded, but FFI conversion TODO.");
             set_last_ffi_error("FFI conversion for ReferenceData not implemented".to_string());
             ptr::null_mut()
        }
        Err(e) => {
            set_last_ffi_error(format!("Failed to create synthetic reference data: {}", e));
            ptr::null_mut()
        }
     }
}


#[no_mangle]
pub extern "C" fn validate_model(name: *const c_char, description: *const c_char) -> *mut FFIValidationResult {
     let name_str = if name.is_null() {
         "DefaultValidation".to_string()
     } else {
         match unsafe { CStr::from_ptr(name).to_str() } {
             Ok(s) => s.to_string(),
             Err(e) => {
                 set_last_ffi_error(format!("Invalid UTF-8 in name string: {}", e));
                 return ptr::null_mut();
             }
         }
     };
     let description_str = if description.is_null() {
         String::new()
     } else {
         match unsafe { CStr::from_ptr(description).to_str() } {
             Ok(s) => s.to_string(),
             Err(e) => {
                 set_last_ffi_error(format!("Invalid UTF-8 in description string: {}", e));
                 return ptr::null_mut();
             }
         }
     };

    // TODO: Need a way to get the required ReferenceData.
    // This might involve loading it based on the `name_str` or having it
    // passed differently. For now, we assume it's unavailable.
    let reference_data: Option<ReferenceData> = None; // Placeholder
    if reference_data.is_none() {
         set_last_ffi_error("Reference data for validation not available or loaded.".to_string());
         return ptr::null_mut();
    }
    let ref_data = reference_data.unwrap();

     // Access simulation results
     unsafe {
        if SIMULATION_STATE.is_none() {
            set_last_ffi_error("Simulation not initialized.".to_string());
            return ptr::null_mut();
        }
        match SIMULATION_STATE.as_ref().unwrap().state.lock() {
            Ok(state) => {
                if let Some(results) = &state.results {
                    // Call backend validation logic
                     match validation::validate(results, &ref_data, name_str, description_str) {
                         Ok(val_result) => {
                            // TODO: Convert val_result (Rust ValidationResult) to FFIValidationResult
                             println!("RUST: validate_model succeeded, but FFI conversion TODO.");
                             set_last_ffi_error("FFI conversion for ValidationResult not implemented".to_string());
                             ptr::null_mut()
                         }
                         Err(e) => {
                             set_last_ffi_error(format!("Validation failed: {}", e));
                             ptr::null_mut()
                         }
                     }
                } else {
                    set_last_ffi_error("Simulation results not available for validation.".to_string());
                    ptr::null_mut()
                }
            }
            Err(poison_err) => {
                set_last_ffi_error(format!("Mutex poisoned while validating model: {}", poison_err));
                ptr::null_mut()
            }
        }
     }
}


#[no_mangle]
pub extern "C" fn free_validation_result(result: *mut FFIValidationResult) {
    if !result.is_null() {
        unsafe {
             // TODO: Free all allocated memory within FFIValidationResult
             // - Free strings
             // - Free nested FFIReferenceData (call free_reference_data)
             // - Free vectors/maps in result and metrics
             println!("RUST: free_validation_result called (STUB - Potential memory leaks!)");
             // Placeholder: Free only the top-level struct for now
             // Proper implementation MUST free nested allocated data
              if !(*result).reference_data.is_null() {
                 // This assumes reference_data was allocated via Box::into_raw
                 // AND that free_reference_data correctly frees its internals.
                 free_reference_data((*result).reference_data);
             }
             // Free other fields like strings, vectors, maps...

             let _ = Box::from_raw(result);
        }
    }
}


#[no_mangle]
pub extern "C" fn generate_validation_report(output_path: *const c_char) -> c_int {
    if output_path.is_null() {
        set_last_ffi_error("generate_validation_report: output_path pointer was null".to_string());
        return -1;
    }

    let path_str = match unsafe { CStr::from_ptr(output_path).to_str() } {
        Ok(s) => s.to_string(),
        Err(e) => {
            set_last_ffi_error(format!("Invalid UTF-8 in output_path string: {}", e));
            return -2; // Invalid input error
        }
     };

    // TODO: Need a way to access the ValidationResult to generate report from.
    // Assume it's stored globally/statefully for now.
    let validation_result: Option<ValidationResult> = None; // Placeholder

    if let Some(val_res) = validation_result {
         match reporting::generate_validation_report(&val_res, path_str) {
             Ok(_) => 0, // Success
             Err(e) => {
                 set_last_ffi_error(format!("Failed to generate validation report: {}", e));
                 -3 // Report generation error
             }
         }
    } else {
        set_last_ffi_error("Validation result not available for report generation.".to_string());
        -4 // Result not ready
    }
}

// --- FFI Functions for Formulas (JSON based) ---

/// Returns all formulas as a JSON string (list of Formula objects).
/// Caller must free the returned string using `free_rust_string`.
#[no_mangle]
pub extern "C" fn get_all_formulas_json() -> *mut c_char {
    match formulas::get_all_formulas() {
        Ok(formulas) => {
            match serde_json::to_string(&formulas) {
                Ok(json_string) => {
                    // Convert to CString and return raw pointer
                    CString::new(json_string).map_or_else(|e| {
                        set_last_ffi_error(format!("Failed to create CString for JSON: {}", e));
                        ptr::null_mut()
                    }, |c_str| c_str.into_raw())
                }
                Err(e) => {
                    // Failed to serialize
                    set_last_ffi_error(format!("Failed to serialize formulas to JSON: {}", e));
                    ptr::null_mut()
                }
            }
        }
        Err(e) => {
            // Failed to get formulas from the backend
            set_last_ffi_error(format!("Failed to get formulas: {}", e));
            ptr::null_mut()
        }
    }
}

/// Returns formulas for a given category as a JSON string.
/// Caller must free the returned string using `free_rust_string`.
#[no_mangle]
pub extern "C" fn get_formulas_by_category_json(category: *const c_char) -> *mut c_char {
    if category.is_null() {
        // Set error? Might be unnecessary if Dart checks.
        return ptr::null_mut();
    }
    let category_str = match unsafe { CStr::from_ptr(category).to_str() } {
        Ok(s) => s.to_string(),
        Err(e) => {
            set_last_ffi_error(format!("Invalid UTF-8 in category string: {}", e));
            return ptr::null_mut();
        }
    };

    match formulas::get_by_category(category_str) {
        Ok(formulas) => {
            match serde_json::to_string(&formulas) {
                Ok(json_string) => {
                    CString::new(json_string).map_or_else(|e| {
                        set_last_ffi_error(format!("Failed to create CString for JSON: {}", e));
                        ptr::null_mut()
                    }, |c_str| c_str.into_raw())
                }
                Err(e) => {
                    set_last_ffi_error(format!("Failed to serialize formulas to JSON: {}", e));
                    ptr::null_mut()
                }
            }
        }
        Err(e) => {
            set_last_ffi_error(format!("Failed to get formulas by category: {}", e));
            ptr::null_mut()
        }
    }
}

/// Returns a single formula by ID as a JSON string.
/// Caller must free the returned string using `free_rust_string`.
#[no_mangle]
pub extern "C" fn get_formula_json(id: *const c_char) -> *mut c_char {
     if id.is_null() {
        return ptr::null_mut();
     }
     let id_str = match unsafe { CStr::from_ptr(id).to_str() } {
        Ok(s) => s.to_string(),
        Err(e) => {
            set_last_ffi_error(format!("Invalid UTF-8 in id string: {}", e));
            return ptr::null_mut();
        }
    };

    match formulas::get_by_id(id_str) {
        Ok(Some(formula)) => { // Handle Option<Formula>
             match serde_json::to_string(&formula) {
                Ok(json_string) => {
                    CString::new(json_string).map_or_else(|e| {
                        set_last_ffi_error(format!("Failed to create CString for JSON: {}", e));
                        ptr::null_mut()
                    }, |c_str| c_str.into_raw())
                }
                Err(e) => {
                    set_last_ffi_error(format!("Failed to serialize formula to JSON: {}", e));
                    ptr::null_mut()
                }
            }
        }
        Ok(None) => { // Formula not found
            // Return null, maybe set a specific error or let Dart handle null?
            // set_last_ffi_error("Formula not found".to_string()); // Optional
            ptr::null_mut()
        }
        Err(e) => {
            set_last_ffi_error(format!("Failed to get formula by ID: {}", e));
            ptr::null_mut()
        }
    }
}

/// Saves a formula provided as a JSON string. Returns 0 on success, negative on error.
#[no_mangle]
pub extern "C" fn save_formula_json(formula_json: *const c_char) -> c_int {
    if formula_json.is_null() {
        set_last_ffi_error("save_formula_json: formula_json pointer was null".to_string());
        return -1;
    }

    let json_str = match unsafe { CStr::from_ptr(formula_json).to_str() } {
        Ok(s) => s,
        Err(e) => {
            set_last_ffi_error(format!("Invalid UTF-8 in formula JSON string: {}", e));
            return -2; // Different error code for invalid input
        }
    };

    // Deserialize JSON string to Formula object
    match serde_json::from_str::<formulas::Formula>(json_str) { // Assuming Formula struct path
        Ok(formula) => {
            // Call Rust function to save the formula
            match formulas::save_formula(formula) {
                Ok(_) => 0, // Success
                Err(e) => {
                    set_last_ffi_error(format!("Failed to save formula: {}", e));
                    -3 // Error during save operation
                }
            }
        }
        Err(e) => {
            set_last_ffi_error(format!("Failed to deserialize formula JSON: {}", e));
            -4 // Error during JSON deserialization
        }
    }
}

/// Deletes a formula by ID. Returns 0 on success, negative on error.
#[no_mangle]
pub extern "C" fn delete_formula_json(id: *const c_char) -> c_int {
    if id.is_null() {
        set_last_ffi_error("delete_formula_json: id pointer was null".to_string());
        return -1;
    }

    let id_str = match unsafe { CStr::from_ptr(id).to_str() } {
        Ok(s) => s.to_string(),
        Err(e) => {
            set_last_ffi_error(format!("Invalid UTF-8 in id string: {}", e));
            return -2;
        }
    };

    match formulas::delete_formula(id_str) {
        Ok(_) => 0, // Success
        Err(e) => {
            set_last_ffi_error(format!("Failed to delete formula: {}", e));
            -3 // Error during delete operation
        }
    }
}

/// Validates a formula source string with given parameters (as JSON).
/// Returns validation result as a JSON string.
/// Caller must free the returned string using `free_rust_string`.
#[no_mangle]
pub extern "C" fn validate_formula_json(source_json: *const c_char, params_json: *const c_char) -> *mut c_char {
     if source_json.is_null() {
         set_last_ffi_error("validate_formula_json: source_json pointer was null".to_string());
         return ptr::null_mut();
     }
     if params_json.is_null() {
         set_last_ffi_error("validate_formula_json: params_json pointer was null".to_string());
         return ptr::null_mut();
     }

     let source_str = match unsafe { CStr::from_ptr(source_json).to_str() } {
        Ok(s) => s.to_string(),
        Err(e) => {
            set_last_ffi_error(format!("Invalid UTF-8 in source_json string: {}", e));
            return ptr::null_mut();
        }
     };
     let params_str = match unsafe { CStr::from_ptr(params_json).to_str() } {
         Ok(s) => s.to_string(),
         Err(e) => {
             set_last_ffi_error(format!("Invalid UTF-8 in params_json string: {}", e));
             return ptr::null_mut();
         }
     };

    // Call backend validation logic
    match formulas::validate_formula(source_str, params_str) {
        Ok(result_json) => {
            CString::new(result_json).map_or_else(|e| {
                set_last_ffi_error(format!("Failed to create CString for validation result JSON: {}", e));
                ptr::null_mut()
            }, |c_str| c_str.into_raw())
        }
        Err(e) => {
            set_last_ffi_error(format!("Failed to validate formula: {}", e));
            ptr::null_mut()
        }
    }
}

/// Evaluates a formula by ID with given parameters (as JSON).
/// Returns evaluation result as a JSON string.
/// Caller must free the returned string using `free_rust_string`.
#[no_mangle]
pub extern "C" fn evaluate_formula_json(id: *const c_char, params_json: *const c_char) -> *mut c_char {
     if id.is_null() {
         set_last_ffi_error("evaluate_formula_json: id pointer was null".to_string());
         return ptr::null_mut();
     }
      if params_json.is_null() {
         set_last_ffi_error("evaluate_formula_json: params_json pointer was null".to_string());
         return ptr::null_mut();
     }

     let id_str = match unsafe { CStr::from_ptr(id).to_str() } {
        Ok(s) => s.to_string(),
        Err(e) => {
            set_last_ffi_error(format!("Invalid UTF-8 in id string: {}", e));
            return ptr::null_mut();
        }
     };
     let params_str = match unsafe { CStr::from_ptr(params_json).to_str() } {
         Ok(s) => s.to_string(),
         Err(e) => {
             set_last_ffi_error(format!("Invalid UTF-8 in params_json string: {}", e));
             return ptr::null_mut();
         }
     };

    // Call backend evaluation logic
     match formulas::evaluate_formula(id_str, params_str) {
        Ok(result_json) => {
            CString::new(result_json).map_or_else(|e| {
                set_last_ffi_error(format!("Failed to create CString for evaluation result JSON: {}", e));
                ptr::null_mut()
            }, |c_str| c_str.into_raw())
        }
        Err(e) => {
            set_last_ffi_error(format!("Failed to evaluate formula: {}", e));
            ptr::null_mut()
        }
    }
}

/// Sets the formula (by ID) to be used for a specific function type (e.g., "conductivity").
/// Returns 0 on success, negative on error.
#[no_mangle]
pub extern "C" fn set_formula_for_function_json(function_type: *const c_char, formula_id: *const c_char) -> c_int {
    if function_type.is_null() {
        set_last_ffi_error("set_formula_for_function_json: function_type pointer was null".to_string());
        return -1;
    }
    if formula_id.is_null() {
        set_last_ffi_error("set_formula_for_function_json: formula_id pointer was null".to_string());
        return -2;
    }

    let type_str = match unsafe { CStr::from_ptr(function_type).to_str() } {
        Ok(s) => s.to_string(),
        Err(e) => {
            set_last_ffi_error(format!("Invalid UTF-8 in function_type string: {}", e));
            return -3;
        }
     };
    let id_str = match unsafe { CStr::from_ptr(formula_id).to_str() } {
        Ok(s) => s.to_string(),
        Err(e) => {
            set_last_ffi_error(format!("Invalid UTF-8 in formula_id string: {}", e));
            return -4;
        }
     };

     // Call backend association logic
     match formulas::set_association(type_str, id_str) {
         Ok(_) => 0, // Success
         Err(e) => {
             set_last_ffi_error(format!("Failed to set formula association: {}", e));
             -5 // Error during association
         }
     }
}

/// Gets the ID of the formula associated with a function type.
/// Returns the formula ID as a string, or null if none is set or on error.
/// Caller must free the returned string using `free_rust_string`.
#[no_mangle]
pub extern "C" fn get_formula_for_function_json(function_type: *const c_char) -> *mut c_char {
     if function_type.is_null() {
         // set_last_ffi_error("get_formula_for_function_json: function_type pointer was null".to_string()); // Optional error
         return ptr::null_mut();
     }

     let type_str = match unsafe { CStr::from_ptr(function_type).to_str() } {
        Ok(s) => s.to_string(),
        Err(e) => {
            set_last_ffi_error(format!("Invalid UTF-8 in function_type string: {}", e));
            return ptr::null_mut();
        }
     };

    // Call backend logic
    match formulas::get_association(type_str) {
        Ok(Some(formula_id)) => { // Association found
            CString::new(formula_id).map_or_else(|e| {
                set_last_ffi_error(format!("Failed to create CString for formula ID: {}", e));
                ptr::null_mut()
            }, |c_str| c_str.into_raw())
        }
        Ok(None) => { // No association found
            ptr::null_mut()
        }
        Err(e) => {
            set_last_ffi_error(format!("Failed to get formula association: {}", e));
            ptr::null_mut()
        }
    }
}

// --- FFI Functions for Metrics & Export (JSON based) ---

/// Calculates simulation metrics based on the current simulation state/results.
/// Returns metrics as a JSON string.
/// Caller must free the returned string using `free_rust_string`.
#[no_mangle]
pub extern "C" fn calculate_metrics_json() -> *mut c_char {
    unsafe {
        if SIMULATION_STATE.is_none() {
            set_last_ffi_error("Simulation not initialized.".to_string());
            return ptr::null_mut();
        }

        // Lock state to access results
        match SIMULATION_STATE.as_ref().unwrap().state.lock() {
            Ok(state) => {
                if let Some(results) = &state.results {
                    // Call backend metrics calculation
                    match metrics::calculate(results) {
                        Ok(metrics_json) => {
                            CString::new(metrics_json).map_or_else(|e| {
                                set_last_ffi_error(format!("Failed to create CString for metrics JSON: {}", e));
                                ptr::null_mut()
                            }, |c_str| c_str.into_raw())
                        }
                        Err(e) => {
                            set_last_ffi_error(format!("Failed to calculate metrics: {}", e));
                            ptr::null_mut()
                        }
                    }
                } else {
                    set_last_ffi_error("Simulation results not available (simulation not completed or results missing).".to_string());
                    ptr::null_mut()
                }
            }
            Err(poison_err) => {
                set_last_ffi_error(format!("Mutex poisoned while calculating metrics: {}", poison_err));
                ptr::null_mut()
            }
        }
    }
}

/// Exports simulation results based on options provided as a JSON string.
/// Returns 0 on success, negative on error.
#[no_mangle]
pub extern "C" fn export_results_json(options_json: *const c_char) -> c_int {
     if options_json.is_null() {
         set_last_ffi_error("export_results_json: options_json pointer was null".to_string());
         return -1;
     }

     let options_str = match unsafe { CStr::from_ptr(options_json).to_str() } {
        Ok(s) => s,
        Err(e) => {
            set_last_ffi_error(format!("Invalid UTF-8 in options_json string: {}", e));
            return -2; // Invalid input error
        }
     };

     // Deserialize options (assuming an ExportOptions struct exists in crate::export)
     let options: export::ExportOptions = match serde_json::from_str(options_str) {
         Ok(opts) => opts,
         Err(e) => {
             set_last_ffi_error(format!("Failed to deserialize export options JSON: {}", e));
             return -3; // Deserialization error
         }
     };

     // Access simulation results
     unsafe {
        if SIMULATION_STATE.is_none() {
            set_last_ffi_error("Simulation not initialized.".to_string());
            return -4; // Not initialized
        }

        match SIMULATION_STATE.as_ref().unwrap().state.lock() {
             Ok(state) => {
                 if let Some(results) = &state.results {
                    // Call backend export function
                    match export::export_results(results, options) {
                        Ok(_) => 0, // Success
                        Err(e) => {
                            set_last_ffi_error(format!("Failed to export results: {}", e));
                            -5 // Export error
                        }
                    }
                 } else {
                     set_last_ffi_error("Simulation results not available for export.".to_string());
                     -6 // Results not ready
                 }
             }
             Err(poison_err) => {
                 set_last_ffi_error(format!("Mutex poisoned while exporting results: {}", poison_err));
                 -7 // Mutex error
             }
         }
     }
}

/// Generates a report (e.g., PDF, HTML) at the specified output path.
/// Requires calculated metrics and results.
/// Returns 0 on success, negative on error.
#[no_mangle]
pub extern "C" fn generate_report_json(output_path: *const c_char) -> c_int {
     if output_path.is_null() {
         set_last_ffi_error("generate_report_json: output_path pointer was null".to_string());
         return -1;
     }

     let path_str = match unsafe { CStr::from_ptr(output_path).to_str() } {
        Ok(s) => s.to_string(),
        Err(e) => {
            set_last_ffi_error(format!("Invalid UTF-8 in output_path string: {}", e));
            return -2; // Invalid input error
        }
     };

    // Access simulation results and potentially calculate metrics first
     unsafe {
        if SIMULATION_STATE.is_none() {
            set_last_ffi_error("Simulation not initialized.".to_string());
            return -3; // Not initialized
        }

        match SIMULATION_STATE.as_ref().unwrap().state.lock() {
            Ok(state) => {
                 if let Some(results) = &state.results {
                    // TODO: Decide if metrics should be calculated here or passed in.
                    // For simplicity, let's assume report generation uses results directly
                    // or calls metrics::calculate internally if needed.

                    // Call backend report generation function
                    match reporting::generate_report(results, path_str) { // Assuming generate_report takes results and path
                        Ok(_) => 0, // Success
                        Err(e) => {
                            set_last_ffi_error(format!("Failed to generate report: {}", e));
                            -4 // Report generation error
                        }
                    }
                 } else {
                     set_last_ffi_error("Simulation results not available for report generation.".to_string());
                     -5 // Results not ready
                 }
            }
             Err(poison_err) => {
                 set_last_ffi_error(format!("Mutex poisoned while generating report: {}", poison_err));
                 -6 // Mutex error
             }
        }
     }
}

// --- FFI Functions for Parametric Studies (JSON based) ---

/// Gets predefined parametric study configurations as a JSON string (list).
/// Caller must free the returned string using `free_rust_string`.
#[no_mangle]
pub extern "C" fn get_predefined_studies_json() -> *mut c_char {
    match parametric::get_predefined_studies() {
        Ok(configs) => {
             match serde_json::to_string(&configs) {
                Ok(json_string) => {
                    CString::new(json_string).map_or_else(|e| {
                        set_last_ffi_error(format!("Failed to create CString for JSON: {}", e));
                        ptr::null_mut()
                    }, |c_str| c_str.into_raw())
                }
                Err(e) => {
                    set_last_ffi_error(format!("Failed to serialize predefined studies to JSON: {}", e));
                    ptr::null_mut()
                }
            }
        }
        Err(e) => {
            set_last_ffi_error(format!("Failed to get predefined studies: {}", e));
            ptr::null_mut()
        }
    }
}

/// Gets a specific predefined study configuration by type name as a JSON string.
/// Caller must free the returned string using `free_rust_string`.
#[no_mangle]
pub extern "C" fn get_predefined_study_json(study_type: *const c_char) -> *mut c_char {
    if study_type.is_null() {
        return ptr::null_mut();
    }
    let type_str = match unsafe { CStr::from_ptr(study_type).to_str() } {
        Ok(s) => s.to_string(),
        Err(e) => {
            set_last_ffi_error(format!("Invalid UTF-8 in study_type string: {}", e));
            return ptr::null_mut();
        }
    };

    match parametric::get_predefined_study(type_str) {
        Ok(Some(config)) => { // Config found
            match serde_json::to_string(&config) {
                Ok(json_string) => {
                    CString::new(json_string).map_or_else(|e| {
                        set_last_ffi_error(format!("Failed to create CString for JSON: {}", e));
                        ptr::null_mut()
                    }, |c_str| c_str.into_raw())
                }
                Err(e) => {
                    set_last_ffi_error(format!("Failed to serialize predefined study to JSON: {}", e));
                    ptr::null_mut()
                }
            }
        }
        Ok(None) => { // Config not found
            // set_last_ffi_error("Predefined study not found".to_string()); // Optional
            ptr::null_mut()
        }
        Err(e) => {
            set_last_ffi_error(format!("Failed to get predefined study: {}", e));
            ptr::null_mut()
        }
    }
}

/// Runs a parametric study based on the configuration provided as a JSON string.
/// Returns the results as a JSON string.
/// Caller must free the returned string using `free_rust_string`.
#[no_mangle]
pub extern "C" fn run_parametric_study_json(config_json: *const c_char) -> *mut c_char {
     if config_json.is_null() {
         set_last_ffi_error("run_parametric_study_json: config_json pointer was null".to_string());
         return ptr::null_mut();
     }

     let config_str = match unsafe { CStr::from_ptr(config_json).to_str() } {
        Ok(s) => s,
        Err(e) => {
            set_last_ffi_error(format!("Invalid UTF-8 in config_json string: {}", e));
            return ptr::null_mut();
        }
     };

     // Deserialize config (assuming StudyConfig struct in crate::parametric)
     let config: parametric::StudyConfig = match serde_json::from_str(config_str) {
         Ok(cfg) => cfg,
         Err(e) => {
             set_last_ffi_error(format!("Failed to deserialize study config JSON: {}", e));
             return ptr::null_mut();
         }
     };

     // Call backend run study function (this might be long-running)
     // TODO: Consider running this in a separate thread similar to run_simulation?
     match parametric::run_study(config) {
        Ok(study_result) => {
             match serde_json::to_string(&study_result) {
                Ok(json_string) => {
                    CString::new(json_string).map_or_else(|e| {
                        set_last_ffi_error(format!("Failed to create CString for study result JSON: {}", e));
                        ptr::null_mut()
                    }, |c_str| c_str.into_raw())
                }
                Err(e) => {
                    set_last_ffi_error(format!("Failed to serialize study result to JSON: {}", e));
                    ptr::null_mut()
                }
            }
        }
        Err(e) => {
            set_last_ffi_error(format!("Parametric study failed: {}", e));
            ptr::null_mut()
        }
     }
}

/// Generates a report for a parametric study result provided as a JSON string.
/// Returns 0 on success, negative on error.
#[no_mangle]
pub extern "C" fn generate_parametric_study_report_json(result_json: *const c_char, output_path: *const c_char) -> c_int {
     if result_json.is_null() {
         set_last_ffi_error("generate_parametric_study_report_json: result_json pointer was null".to_string());
         return -1;
     }
     if output_path.is_null() {
         set_last_ffi_error("generate_parametric_study_report_json: output_path pointer was null".to_string());
         return -2;
     }

     let result_str = match unsafe { CStr::from_ptr(result_json).to_str() } {
        Ok(s) => s,
        Err(e) => {
            set_last_ffi_error(format!("Invalid UTF-8 in result_json string: {}", e));
            return -3;
        }
     };
     let path_str = match unsafe { CStr::from_ptr(output_path).to_str() } {
        Ok(s) => s.to_string(),
        Err(e) => {
            set_last_ffi_error(format!("Invalid UTF-8 in output_path string: {}", e));
            return -4;
        }
     };

    // Deserialize result (assuming StudyResult struct in crate::parametric)
     let result: parametric::StudyResult = match serde_json::from_str(result_str) {
         Ok(res) => res,
         Err(e) => {
             set_last_ffi_error(format!("Failed to deserialize study result JSON: {}", e));
             return -5;
         }
     };

    // Call backend report generation
     match reporting::generate_parametric_report(&result, path_str) {
         Ok(_) => 0, // Success
         Err(e) => {
             set_last_ffi_error(format!("Failed to generate parametric study report: {}", e));
             -6 // Report generation error
         }
     }
}

// API FFI

/// Inicializa a simulação com os parâmetros especificados
#[no_mangle]
pub extern "C" fn initialize_simulation(ffi_params: *const FFISimulationParameters) -> c_int {
    // Check for null pointer
    if ffi_params.is_null() {
        set_last_ffi_error("initialize_simulation: ffi_params pointer was null".to_string());
        return -1; // Null pointer error
    }
    
    // Ensure simulation is not already initialized
    unsafe {
        if SIMULATION_STATE.is_some() {
            set_last_ffi_error("Simulation already initialized. Call destroy_simulation first.".to_string());
            return -2; // Already initialized error
        }
    }

    // Convert FFI parameters to Rust SimulationParameters
    let params = convert_ffi_parameters(unsafe { &*ffi_params });
    
    // Validate parameters before creating state
    if let Err(validation_err) = params.validate() {
        set_last_ffi_error(format!("Invalid simulation parameters: {}", validation_err));
        return -3; // Invalid parameters
    }
    
    // Create and store the shared state
    unsafe {
        SIMULATION_STATE = Some(SharedSimulationState::new(params));
    }
    
    0 // Success
}

/// Adiciona uma tocha de plasma à simulação
#[no_mangle]
pub extern "C" fn add_plasma_torch(ffi_torch: *const FFIPlasmaTorch) -> c_int {
    if ffi_torch.is_null() {
        set_last_ffi_error("add_plasma_torch: ffi_torch pointer was null".to_string());
        return -1; // Null pointer error
    }
    
    let torch = convert_ffi_torch(unsafe { &*ffi_torch });
    
    unsafe {
        // Check if state exists
        if SIMULATION_STATE.is_none() {
            set_last_ffi_error("Simulation not initialized. Call initialize_simulation first.".to_string());
            return -2; // Not initialized error
        }
        
        // Lock the state mutex
        match SIMULATION_STATE.as_ref().unwrap().state.lock() {
            Ok(mut state) => {
                // Check if simulation is already running/completed (cannot add torch then)
                if state.status != crate::simulation::SimulationStatus::NotStarted {
                    set_last_ffi_error("Cannot add torch to a running or completed simulation.".to_string());
                    return -3; // Cannot modify running/completed simulation
                }
                state.parameters.add_torch(torch);
                0 // Success
            }
            Err(poison_err) => {
                set_last_ffi_error(format!("Mutex poisoned while adding torch: {}", poison_err));
                -4 // Mutex poisoned error
            }
        }
    }
}

/// Define as propriedades do material
#[no_mangle]
pub extern "C" fn set_material_properties(ffi_material: *const FFIMaterialProperties) -> c_int {
    if ffi_material.is_null() {
        set_last_ffi_error("set_material_properties: ffi_material pointer was null".to_string());
        return -1; // Null pointer error
    }
    
    // Check if name pointer is valid before converting
    // Note: This doesn't guarantee valid UTF-8 yet, conversion handles that.
    if unsafe { (*ffi_material).name.is_null() } {
        set_last_ffi_error("set_material_properties: material name pointer was null".to_string());
        return -5; // Null name pointer
    }

    // Note: Conversion might fail if `name` is not valid UTF-8.
    // We rely on `to_string_lossy` inside `convert_ffi_material` for now.
    // A more robust solution might check CStr::from_ptr().to_str() first.
    let material = convert_ffi_material(unsafe { &*ffi_material });
    
    unsafe {
        // Check if state exists
        if SIMULATION_STATE.is_none() {
            set_last_ffi_error("Simulation not initialized. Call initialize_simulation first.".to_string());
            return -2; // Not initialized error
        }
        
        // Lock the state mutex
        match SIMULATION_STATE.as_ref().unwrap().state.lock() {
            Ok(mut state) => {
                // Check if simulation is already running/completed
                 if state.status != crate::simulation::SimulationStatus::NotStarted {
                    set_last_ffi_error("Cannot set material properties for a running or completed simulation.".to_string());
                    return -3; // Cannot modify running/completed simulation
                }
                state.parameters.material = material;
                0 // Success
            }
            Err(poison_err) => {
                 set_last_ffi_error(format!("Mutex poisoned while setting material: {}", poison_err));
                -4 // Mutex poisoned error
            }
        }
    }
}

/// Executa a simulação
#[no_mangle]
pub extern "C" fn run_simulation() -> c_int {
    unsafe {
        // Check if state exists
        if SIMULATION_STATE.is_none() {
            set_last_ffi_error("Simulation not initialized. Call initialize_simulation first.".to_string());
            return -1; // Not initialized error
        }

        // Call the run_simulation method on the shared state
        // This method handles spawning the thread internally
        match SIMULATION_STATE.as_ref().unwrap().run_simulation() {
            Ok(_) => 0, // Success (simulation started)
            Err(err_msg) => {
                // TODO: Store err_msg using get_last_error mechanism? // DONE
                set_last_ffi_error(format!("Failed to start simulation: {}", err_msg));
                eprintln!("Failed to start simulation: {}", err_msg); // Keep log for server-side debugging
                -2 // Failed to start (e.g., couldn't lock mutex, already running)
            }
        }
    }
}

/// Pausa a simulação
#[no_mangle]
pub extern "C" fn pause_simulation() -> c_int {
    unsafe {
        if SIMULATION_STATE.is_none() {
            set_last_ffi_error("Simulation not initialized.".to_string());
            return -1; // Not initialized
        }

        match SIMULATION_STATE.as_ref().unwrap().state.lock() {
            Ok(mut state) => {
                match state.pause() { // Call pause() on the inner state
                    Ok(_) => 0, // Success
                    Err(err_msg) => {
                         // TODO: Store err_msg? // DONE
                         set_last_ffi_error(format!("Failed to pause simulation: {}", err_msg));
                         eprintln!("Failed to pause simulation: {}", err_msg); // Keep log
                        -3 // e.g., Not running
                    }
                }
            }
            Err(poison_err) => {
                set_last_ffi_error(format!("Mutex poisoned while pausing simulation: {}", poison_err));
                -2 // Mutex poisoned
            }
        }
    }
}

/// Retoma a simulação
#[no_mangle]
pub extern "C" fn resume_simulation() -> c_int {
     unsafe {
        if SIMULATION_STATE.is_none() {
            set_last_ffi_error("Simulation not initialized.".to_string());
            return -1; // Not initialized
        }

        match SIMULATION_STATE.as_ref().unwrap().state.lock() {
            Ok(mut state) => {
                match state.resume() { // Call resume() on the inner state
                    Ok(_) => 0, // Success
                    Err(err_msg) => {
                         // TODO: Store err_msg? // DONE
                         set_last_ffi_error(format!("Failed to resume simulation: {}", err_msg));
                         eprintln!("Failed to resume simulation: {}", err_msg); // Keep log
                         -3 // e.g., Not paused
                    }
                }
            }
            Err(poison_err) => {
                 set_last_ffi_error(format!("Mutex poisoned while resuming simulation: {}", poison_err));
                -2 // Mutex poisoned
            }
        }
    }
}

/// Obtém o estado atual da simulação
#[no_mangle]
pub extern "C" fn get_simulation_state(ffi_state: *mut FFISimulationState) -> c_int {
    if ffi_state.is_null() {
        set_last_ffi_error("get_simulation_state: ffi_state pointer was null".to_string());
        return -1; // Null pointer provided by caller
    }
    
    unsafe {
        if SIMULATION_STATE.is_none() {
             set_last_ffi_error("Simulation not initialized.".to_string());
            return -2; // Not initialized
        }

        // Use the get_state method which handles locking and cloning
        match SIMULATION_STATE.as_ref().unwrap().get_state() {
            Ok(current_state) => {
                // Convert the cloned Rust state to the FFI struct
                // This allocates memory for error_message if it exists.
                let converted_state = convert_simulation_state(&current_state);
                
                // Write the converted state to the pointer provided by Dart
                // The caller (Dart) is responsible for reading this struct
                // and freeing the error_message pointer via free_rust_string.
                *ffi_state = converted_state;
                0 // Success
            }
            Err(err_msg) => {
                set_last_ffi_error(format!("Failed to get simulation state: {}", err_msg));
                -3 // Mutex lock failed or other internal error from get_state
            }
        }
    }
}

/// Obtém os dados de temperatura para um passo de tempo específico
#[no_mangle]
pub extern "C" fn get_temperature_data(
    time_step: c_int,
    buffer: *mut c_float,
    buffer_size: usize,
) -> c_int {
    // Check for null buffer from caller
    if buffer.is_null() {
        set_last_ffi_error("get_temperature_data: buffer pointer was null".to_string());
        return -1; // Null buffer pointer
    }
    
    unsafe {
        // Check if simulation state exists
        if SIMULATION_STATE.is_none() {
            set_last_ffi_error("Simulation not initialized.".to_string());
            return -2; // Not initialized
        }
        
        // Lock the state mutex
        match SIMULATION_STATE.as_ref().unwrap().state.lock() {
            Ok(state) => {
                // Check if simulation is complete and results are available
                if !state.is_completed() || state.results.is_none() {
                     // Consider different codes? -4 = Not completed, -5 = No results (shouldn't happen if completed)
                     set_last_ffi_error("Simulation results not available (simulation not completed or no results stored).".to_string());
                    return -4; // Results not available or simulation not completed
                }
                
                let results = state.results.as_ref().unwrap();
                let params = &state.parameters;
                let nr = params.nr;
                let nz = params.nz;
                let total_steps = params.time_steps; // Assuming this matches the size of the last dimension in temperature array
                // Or does the ndarray include the initial state at step 0?
                // Let's assume the ndarray has shape (nr, nz, time_steps) or similar
                // and valid indices are 0 to time_steps - 1.
                
                // Validate time_step index (assuming 0-based index)
                // Check against the actual dimension of the temperature array if possible
                let temp_shape = results.temperature.shape();
                if temp_shape.len() != 3 || total_steps != temp_shape[2] {
                     set_last_ffi_error(format!("Internal error: Mismatch between params.time_steps ({}) and results.temperature shape ({:?})", total_steps, temp_shape));
                     return -9; // Internal dimension mismatch
                }
                if time_step < 0 || time_step as usize >= total_steps {
                     set_last_ffi_error(format!("Invalid time step index: {}. Must be between 0 and {}.", time_step, total_steps - 1));
                    return -3; // Invalid time step index
                }

                let required_size = nr * nz;
                if buffer_size < required_size {
                     set_last_ffi_error(format!("Buffer too small: provided size {}, required size {}.", buffer_size, required_size));
                    return -6; // Buffer too small
                }

                // Access the temperature data (assuming ndarray)
                // Use slice method s! macro requires ndarray import
                use ndarray::s;
                let temp_slice_view = match results.temperature.slice(s![.., .., time_step as usize]) {
                     Ok(slice) => slice,
                     Err(e) => {
                         set_last_ffi_error(format!("Error slicing temperature data: {}", e));
                         return -7; // Error slicing ndarray
                     }
                };
                // Ensure the view is contiguous or copy if necessary for safe access.
                // Using `.as_slice()` requires the slice to be contiguous C-order.
                // If it might not be, iterate and copy element-wise.
                // Let's assume standard layout for now or that iteration below handles it.

                // Get a mutable slice from the FFI buffer pointer
                let buffer_slice = slice::from_raw_parts_mut(buffer, required_size);

                // Copy data, handling potential dimension order (assuming C order [row-major] in ndarray)
                let mut count = 0;
                for i in 0..nr {
                    for j in 0..nz {
                         // Use the view directly
                         if let Some(val) = temp_slice_view.get([i, j]) {
                             buffer_slice[count] = *val as c_float;
                         } else {
                             // Should not happen if slice dimensions are correct and loops are right
                             set_last_ffi_error(format!("Internal error: Indexing failed at [{}, {}] during temperature copy.", i, j));
                             return -8; // Indexing error during copy
                         }
                        count += 1;
                    }
                }

                // Return the number of elements written (nr * nz)
                // Dart side expects this to handle the Float32List size.
                 required_size as c_int // Success, return number of elements written
            }
            Err(poison_err) => {
                set_last_ffi_error(format!("Mutex poisoned while getting temperature data: {}", poison_err));
                -5 // Mutex poisoned error
            }
        }
    }
}

/// Libera os recursos da simulação, solicitando cancelamento e aguardando a thread.
#[no_mangle]
pub extern "C" fn destroy_simulation() -> c_int {
    let shared_state_option = unsafe {
        // Take the state out of the static variable to ensure it's dropped
        // at the end of this function, after the thread join.
        SIMULATION_STATE.take()
    };

    if let Some(shared_state) = shared_state_option {
        println!("RUST: destroy_simulation called. Requesting cancellation...");
        // 1. Request cancellation
        shared_state.request_cancellation();

        // 2. Wait for the simulation thread to finish
        match shared_state.join_simulation_thread() {
            Ok(true) => {
                println!("RUST: Simulation thread joined successfully.");
                // State will be dropped automatically here
                0 // Success
            }
            Ok(false) => {
                println!("RUST: No simulation thread was running to join.");
                // State will be dropped automatically here
                0 // Success (already stopped or never started)
            }
            Err(err) => {
                eprintln!("RUST: Error joining simulation thread: {}", err);
                set_last_ffi_error(format!("Error during simulation cleanup: {}", err));
                // Even if join fails, the state is dropped here.
                // Return specific error code for join failure?
                -3 // Error joining thread
            }
        }
        // `shared_state` is dropped here, releasing the Arc/Mutex/thread handle resources.

    } else {
        println!("RUST: destroy_simulation called, but state was already None.");
        set_last_ffi_error("Simulation already destroyed or never initialized.".to_string());
        -1 // Already destroyed or never initialized
    }
}

/// Obtém a última mensagem de erro.
/// Checks thread-local FFI errors first, then simulation state errors.
/// Returns a pointer to a C string allocated by Rust.
/// The caller (Dart) MUST call free_rust_string on the returned pointer.
/// Returns null if no error is pending.
#[no_mangle]
pub extern "C" fn get_last_error() -> *mut c_char {
    // 1. Check thread-local FFI error first
    let ffi_error = LAST_ERROR.with(|cell| cell.borrow_mut().take()); // take() gets the value and leaves None

    if let Some(err_msg) = ffi_error {
        return CString::new(err_msg).map_or_else(|_| {
            // Should not happen if we set valid strings, but handle allocation error
             eprintln!("Error: Failed to create CString for FFI error message.");
             ptr::null_mut()
        }, |c_str| c_str.into_raw());
    }

    // 2. If no FFI error, check the simulation state error
    unsafe {
        // Try to get the error message stored in the current simulation state
        if let Some(shared_state) = &SIMULATION_STATE {
            // Use get_state to handle locking safely
            match shared_state.get_state() {
                 Ok(state) => {
                     // Check the specific error message field within the simulation state
                    if let Some(sim_error_msg) = &state.error_message {
                         // Allocate a CString and return the raw pointer.
                        // The caller (Dart) MUST call free_rust_string on this pointer.
                         return CString::new(sim_error_msg.clone()).map_or_else(|_| {
                             eprintln!("Error: Failed to create CString for simulation error message.");
                             ptr::null_mut()
                         }, |c_str| c_str.into_raw());
                    }
                 }
                 Err(_) => {
                     // Mutex poisoned or other error getting state.
                     // Avoid setting a new error here, just report none found for now.
                     eprintln!("Warning: Could not access simulation state to check for error (mutex likely poisoned).");
                 }
             }
        }
    }

    // No thread-local FFI error and no simulation state error found (or state inaccessible)
    ptr::null_mut() // Return null pointer if no specific error is found
}

/// Libera a memória de uma string C alocada pelo Rust (e.g., JSON, erro)
#[no_mangle]
pub extern "C" fn free_rust_string(message: *mut c_char) {
    if !message.is_null() {
        unsafe {
            // Safety: This assumes `message` was allocated by `CString::into_raw`.
            // This is true for strings returned by `get_last_error` and the JSON functions.
            let _ = CString::from_raw(message);
        }
    }
}
