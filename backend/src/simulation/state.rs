// Implementação do estado da simulação

use serde::{Deserialize, Serialize};
use std::sync::{Arc, Mutex};
use std::time::Instant;

use super::solver::{SimulationParameters, SimulationResults, HeatSolver};

/// Enumeração que representa o status da simulação
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum SimulationStatus {
    /// Simulação não iniciada
    NotStarted,
    /// Simulação em execução
    Running,
    /// Simulação pausada
    Paused,
    /// Simulação concluída
    Completed,
    /// Simulação falhou
    Failed,
}

/// Estrutura que representa o estado da simulação
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SimulationState {
    /// Parâmetros da simulação
    pub parameters: SimulationParameters,
    /// Status da simulação
    pub status: SimulationStatus,
    /// Progresso da simulação (0.0 - 1.0)
    pub progress: f32,
    /// Mensagem de erro (se houver)
    pub error_message: Option<String>,
    /// Resultados da simulação (se concluída)
    #[serde(skip)]
    pub results: Option<SimulationResults>,
    /// Tempo de início da simulação
    #[serde(skip)]
    pub start_time: Option<Instant>,
    /// Tempo de execução da simulação (s)
    pub execution_time: f64,
}

impl SimulationState {
    /// Cria um novo estado de simulação com os parâmetros especificados
    pub fn new(parameters: SimulationParameters) -> Self {
        Self {
            parameters,
            status: SimulationStatus::NotStarted,
            progress: 0.0,
            error_message: None,
            results: None,
            start_time: None,
            execution_time: 0.0,
        }
    }

    /// Inicia a simulação
    pub fn start(&mut self) -> Result<(), String> {
        if self.status == SimulationStatus::Running {
            return Err("Simulação já está em execução".to_string());
        }

        self.status = SimulationStatus::Running;
        self.progress = 0.0;
        self.error_message = None;
        self.start_time = Some(Instant::now());

        Ok(())
    }

    /// Pausa a simulação
    pub fn pause(&mut self) -> Result<(), String> {
        if self.status != SimulationStatus::Running {
            return Err("Simulação não está em execução".to_string());
        }

        self.status = SimulationStatus::Paused;

        Ok(())
    }

    /// Retoma a simulação
    pub fn resume(&mut self) -> Result<(), String> {
        if self.status != SimulationStatus::Paused {
            return Err("Simulação não está pausada".to_string());
        }

        self.status = SimulationStatus::Running;

        Ok(())
    }

    /// Atualiza o progresso da simulação
    pub fn update_progress(&mut self, progress: f32) {
        self.progress = progress;
    }

    /// Conclui a simulação com sucesso
    pub fn complete(&mut self, results: SimulationResults) {
        self.status = SimulationStatus::Completed;
        self.progress = 1.0;
        self.results = Some(results);
        
        if let Some(start_time) = self.start_time {
            self.execution_time = start_time.elapsed().as_secs_f64();
        }
    }

    /// Marca a simulação como falha
    pub fn fail(&mut self, error_message: String) {
        self.status = SimulationStatus::Failed;
        self.error_message = Some(error_message);
        
        if let Some(start_time) = self.start_time {
            self.execution_time = start_time.elapsed().as_secs_f64();
        }
    }

    /// Verifica se a simulação está concluída
    pub fn is_completed(&self) -> bool {
        self.status == SimulationStatus::Completed
    }

    /// Verifica se a simulação falhou
    pub fn is_failed(&self) -> bool {
        self.status == SimulationStatus::Failed
    }

    /// Retorna os resultados da simulação, se disponíveis
    pub fn get_results(&self) -> Option<&SimulationResults> {
        self.results.as_ref()
    }
}

/// Estrutura thread-safe para compartilhar o estado da simulação
pub struct SharedSimulationState {
    /// Estado da simulação
    state: Arc<Mutex<SimulationState>>,
}

impl SharedSimulationState {
    /// Cria um novo estado compartilhado com os parâmetros especificados
    pub fn new(parameters: SimulationParameters) -> Self {
        Self {
            state: Arc::new(Mutex::new(SimulationState::new(parameters))),
        }
    }

    /// Obtém uma cópia do estado atual
    pub fn get_state(&self) -> Result<SimulationState, String> {
        match self.state.lock() {
            Ok(state) => Ok(state.clone()),
            Err(_) => Err("Falha ao obter o estado da simulação".to_string()),
        }
    }

    /// Executa a simulação em uma thread separada
    pub fn run_simulation(&self) -> Result<(), String> {
        // Obter parâmetros da simulação
        let parameters = {
            let state = self.state.lock().map_err(|_| "Falha ao obter o estado da simulação".to_string())?;
            state.parameters.clone()
        };

        // Iniciar simulação
        {
            let mut state = self.state.lock().map_err(|_| "Falha ao obter o estado da simulação".to_string())?;
            state.start()?;
        }

        // Criar clone do Arc para usar na thread
        let state_clone = self.state.clone();

        // Executar simulação em uma thread separada
        std::thread::spawn(move || {
            // Criar solucionador
            let solver_result = HeatSolver::new(parameters);
            
            if let Err(err) = solver_result {
                // Marcar simulação como falha
                if let Ok(mut state) = state_clone.lock() {
                    state.fail(err);
                }
                return;
            }
            
            let mut solver = solver_result.unwrap();
            
            // Definir callback de progresso
            let progress_callback = |progress: f32| {
                if let Ok(mut state) = state_clone.lock() {
                    state.update_progress(progress);
                    
                    // Verificar se a simulação foi pausada
                    if state.status == SimulationStatus::Paused {
                        // Esperar até que a simulação seja retomada
                        while let Ok(state) = state_clone.lock() {
                            if state.status != SimulationStatus::Paused {
                                break;
                            }
                            std::thread::sleep(std::time::Duration::from_millis(100));
                        }
                    }
                }
            };
            
            // Executar simulação
            let result = solver.run(Some(&progress_callback));
            
            // Atualizar estado
            if let Ok(mut state) = state_clone.lock() {
                match result {
                    Ok(results) => state.complete(results),
                    Err(err) => state.fail(err),
                }
            }
        });

        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use super::super::physics::PlasmaTorch;
    
    #[test]
    fn test_simulation_state() {
        let mut params = SimulationParameters::new(1.0, 0.5, 10, 20);
        params.add_torch(PlasmaTorch::new(0.0, 0.0, 90.0, 0.0, 100.0, 0.01, 5000.0));
        
        let mut state = SimulationState::new(params);
        
        // Estado inicial
        assert_eq!(state.status, SimulationStatus::NotStarted);
        assert_eq!(state.progress, 0.0);
        assert!(state.error_message.is_none());
        assert!(state.results.is_none());
        
        // Iniciar simulação
        assert!(state.start().is_ok());
        assert_eq!(state.status, SimulationStatus::Running);
        
        // Atualizar progresso
        state.update_progress(0.5);
        assert_eq!(state.progress, 0.5);
        
        // Pausar simulação
        assert!(state.pause().is_ok());
        assert_eq!(state.status, SimulationStatus::Paused);
        
        // Retomar simulação
        assert!(state.resume().is_ok());
        assert_eq!(state.status, SimulationStatus::Running);
        
        // Falhar simulação
        state.fail("Erro de teste".to_string());
        assert_eq!(state.status, SimulationStatus::Failed);
        assert_eq!(state.error_message, Some("Erro de teste".to_string()));
        assert!(state.is_failed());
    }
}
