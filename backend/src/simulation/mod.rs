// Módulo de estudos paramétricos para o simulador de fornalha de plasma

pub mod parametric;

// Re-exportar tipos principais
pub use parametric::{
    ParametricParameter,
    ScaleType,
    ParametricStudyConfig,
    OptimizationGoal,
    ParametricSimulationResult,
    ParametricStudyResult,
    ParametricStudyManager
};
