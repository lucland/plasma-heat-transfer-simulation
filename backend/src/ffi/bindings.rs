// Implementação dos bindings FFI para comunicação com o frontend Flutter

use std::ffi::{c_void, CStr, CString};
use std::os::raw::{c_char, c_int, c_float};
use std::ptr;
use std::slice;
use std::sync::{Arc, Mutex};

use crate::simulation::{
    SimulationParameters, SimulationResults, HeatSolver, 
    MaterialProperties, PlasmaTorch, SimulationState, SharedSimulationState
};

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

// API FFI

/// Inicializa a simulação com os parâmetros especificados
#[no_mangle]
pub extern "C" fn initialize_simulation(ffi_params: *const FFISimulationParameters) -> c_int {
    if ffi_params.is_null() {
        return -1;
    }
    
    let ffi_params = unsafe { &*ffi_params };
    let params = convert_ffi_parameters(ffi_params);
    
    unsafe {
        SIMULATION_STATE = Some(SharedSimulationState::new(params));
    }
    
    0 // Sucesso
}

/// Adiciona uma tocha de plasma à simulação
#[no_mangle]
pub extern "C" fn add_plasma_torch(ffi_torch: *const FFIPlasmaTorch) -> c_int {
    if ffi_torch.is_null() {
        return -1;
    }
    
    let ffi_torch = unsafe { &*ffi_torch };
    let torch = convert_ffi_torch(ffi_torch);
    
    unsafe {
        if let Some(shared_state) = &SIMULATION_STATE {
            if let Ok(mut state) = shared_state.get_state() {
                state.parameters.add_torch(torch);
                return 0; // Sucesso
            }
        }
    }
    
    -1 // Falha
}

/// Define as propriedades do material
#[no_mangle]
pub extern "C" fn set_material_properties(ffi_material: *const FFIMaterialProperties) -> c_int {
    if ffi_material.is_null() {
        return -1;
    }
    
    let ffi_material = unsafe { &*ffi_material };
    let material = convert_ffi_material(ffi_material);
    
    unsafe {
        if let Some(shared_state) = &SIMULATION_STATE {
            if let Ok(mut state) = shared_state.get_state() {
                state.parameters.material = material;
                return 0; // Sucesso
            }
        }
    }
    
    -1 // Falha
}

/// Executa a simulação
#[no_mangle]
pub extern "C" fn run_simulation() -> c_int {
    unsafe {
        if let Some(shared_state) = &SIMULATION_STATE {
            match shared_state.run_simulation() {
                Ok(_) => 0, // Sucesso
                Err(_) => -1, // Falha
            }
        } else {
            -1 // Falha
        }
    }
}

/// Pausa a simulação
#[no_mangle]
pub extern "C" fn pause_simulation() -> c_int {
    unsafe {
        if let Some(shared_state) = &SIMULATION_STATE {
            if let Ok(mut state) = shared_state.get_state() {
                match state.pause() {
                    Ok(_) => 0, // Sucesso
                    Err(_) => -1, // Falha
                }
            } else {
                -1 // Falha
            }
        } else {
            -1 // Falha
        }
    }
}

/// Retoma a simulação
#[no_mangle]
pub extern "C" fn resume_simulation() -> c_int {
    unsafe {
        if let Some(shared_state) = &SIMULATION_STATE {
            if let Ok(mut state) = shared_state.get_state() {
                match state.resume() {
                    Ok(_) => 0, // Sucesso
                    Err(_) => -1, // Falha
                }
            } else {
                -1 // Falha
            }
        } else {
            -1 // Falha
        }
    }
}

/// Obtém o estado atual da simulação
#[no_mangle]
pub extern "C" fn get_simulation_state(ffi_state: *mut FFISimulationState) -> c_int {
    if ffi_state.is_null() {
        return -1;
    }
    
    unsafe {
        if let Some(shared_state) = &SIMULATION_STATE {
            if let Ok(state) = shared_state.get_state() {
                let converted_state = convert_simulation_state(&state);
                *ffi_state = converted_state;
                return 0; // Sucesso
            }
        }
    }
    
    -1 // Falha
}

/// Obtém os dados de temperatura para um passo de tempo específico
#[no_mangle]
pub extern "C" fn get_temperature_data(
    time_step: c_int,
    buffer: *mut c_float,
    buffer_size: usize,
) -> c_int {
    if buffer.is_null() {
        return -1;
    }
    
    unsafe {
        if let Some(shared_state) = &SIMULATION_STATE {
            if let Ok(state) = shared_state.get_state() {
                if let Some(results) = state.get_results() {
                    let nr = results.parameters.nr;
                    let nz = results.parameters.nz;
                    
                    if buffer_size < nr * nz {
                        return -2; // Buffer muito pequeno
                    }
                    
                    if time_step < 0 || time_step as usize > results.parameters.time_steps {
                        return -3; // Passo de tempo inválido
                    }
                    
                    let temp_slice = results.temperature.slice(s![.., .., time_step as usize]);
                    let buffer_slice = slice::from_raw_parts_mut(buffer, nr * nz);
                    
                    for i in 0..nr {
                        for j in 0..nz {
                            buffer_slice[i * nz + j] = temp_slice[[i, j]] as c_float;
                        }
                    }
                    
                    return 0; // Sucesso
                }
            }
        }
    }
    
    -1 // Falha
}

/// Libera os recursos da simulação
#[no_mangle]
pub extern "C" fn destroy_simulation() -> c_int {
    unsafe {
        SIMULATION_STATE = None;
    }
    
    0 // Sucesso
}

/// Obtém a última mensagem de erro
#[no_mangle]
pub extern "C" fn get_last_error() -> *const c_char {
    unsafe {
        if let Some(shared_state) = &SIMULATION_STATE {
            if let Ok(state) = shared_state.get_state() {
                if let Some(error) = &state.error_message {
                    return CString::new(error.clone()).unwrap().into_raw();
                }
            }
        }
    }
    
    CString::new("Nenhum erro").unwrap().into_raw()
}

/// Libera a memória de uma string retornada por get_last_error
#[no_mangle]
pub extern "C" fn free_error_message(message: *mut c_char) {
    if !message.is_null() {
        unsafe {
            let _ = CString::from_raw(message);
        }
    }
}
