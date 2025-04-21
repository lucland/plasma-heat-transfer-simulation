// Módulo de fórmulas para o simulador de fornalha de plasma

pub mod engine;
pub mod integration;

// Re-exportar tipos principais
pub use engine::{
    FormulaEngine, 
    Formula, 
    FormulaParameter, 
    ParameterType, 
    ParameterValue, 
    FormulaCategory,
    FormulaResult
};

pub use integration::{
    FormulaManager,
    FunctionType
};
