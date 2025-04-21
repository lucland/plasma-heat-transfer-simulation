// Módulo FFI para comunicação com o backend Rust

pub mod bindings;
pub mod conversions;

// Re-exportar estruturas principais
pub use bindings::{
    FFISimulationParameters,
    FFIPlasmaTorch,
    FFIMaterialProperties,
    FFISimulationState,
};
