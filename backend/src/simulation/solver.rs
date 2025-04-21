// Integração do módulo de materiais com o solucionador

use ndarray::{Array2, Array3, Axis};
use rayon::prelude::*;
use serde::{Deserialize, Serialize};
use std::time::Instant;
use log::{info, warn, error};

use super::mesh::CylindricalMesh;
use super::physics::{PlasmaTorch, HeatSources, calculate_radiation_source, calculate_convection_source};
use super::materials::{MaterialProperties, MaterialLibrary};

/// Estrutura que representa os parâmetros da simulação com suporte a materiais avançados
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SimulationParameters {
    /// Altura do cilindro (m)
    pub height: f64,
    /// Raio do cilindro (m)
    pub radius: f64,
    /// Número de nós na direção radial
    pub nr: usize,
    /// Número de nós na direção axial
    pub nz: usize,
    /// Número de nós na direção angular (para visualização 3D)
    pub ntheta: usize,
    /// Tochas de plasma
    pub torches: Vec<PlasmaTorch>,
    /// Propriedades do material
    pub material: MaterialProperties,
    /// Mapa de materiais para diferentes zonas (opcional)
    pub material_zones: Option<Vec<(String, MaterialProperties)>>,
    /// Temperatura inicial (°C)
    pub initial_temperature: f64,
    /// Temperatura ambiente (°C)
    pub ambient_temperature: f64,
    /// Coeficiente de convecção (W/(m²·K))
    pub convection_coefficient: f64,
    /// Habilitar convecção
    pub enable_convection: bool,
    /// Habilitar radiação
    pub enable_radiation: bool,
    /// Habilitar mudanças de fase
    pub enable_phase_changes: bool,
    /// Tempo total de simulação (s)
    pub total_time: f64,
    /// Passo de tempo (s)
    pub time_step: f64,
    /// Número de passos de tempo
    pub time_steps: usize,
    /// Mapa de zonas (opcional)
    pub zone_map: Option<Array2<usize>>,
}

impl SimulationParameters {
    /// Cria uma nova instância de parâmetros de simulação com valores padrão
    pub fn new(height: f64, radius: f64, nr: usize, nz: usize) -> Self {
        // Criar biblioteca de materiais
        let library = MaterialLibrary::new();
        
        // Usar aço como material padrão
        let default_material = library.get_material_clone("steel")
            .unwrap_or_else(|| MaterialProperties::new("Default Material", 7850.0, 490.0, 45.0));
        
        Self {
            height,
            radius,
            nr,
            nz,
            ntheta: 12, // Valor padrão para visualização 3D
            torches: Vec::new(),
            material: default_material,
            material_zones: None,
            initial_temperature: 25.0,
            ambient_temperature: 25.0,
            convection_coefficient: 10.0,
            enable_convection: true,
            enable_radiation: true,
            enable_phase_changes: true,
            total_time: 100.0,
            time_step: 1.0,
            time_steps: 100,
            zone_map: None,
        }
    }

    /// Adiciona uma tocha de plasma à simulação
    pub fn add_torch(&mut self, torch: PlasmaTorch) {
        self.torches.push(torch);
    }

    /// Remove uma tocha de plasma da simulação pelo ID
    pub fn remove_torch(&mut self, torch_id: &str) -> bool {
        let initial_len = self.torches.len();
        self.torches.retain(|t| t.id != torch_id);
        self.torches.len() < initial_len
    }

    /// Define o material principal
    pub fn set_material(&mut self, material: MaterialProperties) {
        self.material = material;
    }

    /// Adiciona uma zona de material
    pub fn add_material_zone(&mut self, zone_id: String, material: MaterialProperties) {
        if self.material_zones.is_none() {
            self.material_zones = Some(Vec::new());
        }
        
        if let Some(zones) = &mut self.material_zones {
            // Verificar se a zona já existe
            for (i, (id, _)) in zones.iter().enumerate() {
                if id == &zone_id {
                    // Atualizar material existente
                    zones[i] = (zone_id, material);
                    return;
                }
            }
            
            // Adicionar nova zona
            zones.push((zone_id, material));
        }
    }

    /// Remove uma zona de material
    pub fn remove_material_zone(&mut self, zone_id: &str) -> bool {
        if let Some(zones) = &mut self.material_zones {
            let initial_len = zones.len();
            zones.retain(|(id, _)| id != zone_id);
            return zones.len() < initial_len;
        }
        false
    }

    /// Define o mapa de zonas para diferentes materiais ou condições
    pub fn set_zone_map(&mut self, zone_map: Array2<usize>) {
        assert_eq!(zone_map.shape(), &[self.nr, self.nz], "Dimensões do mapa de zonas devem corresponder à malha");
        self.zone_map = Some(zone_map);
    }

    /// Valida os parâmetros da simulação
    pub fn validate(&self) -> Result<(), String> {
        if self.height <= 0.0 {
            return Err("Altura deve ser positiva".to_string());
        }
        if self.radius <= 0.0 {
            return Err("Raio deve ser positivo".to_string());
        }
        if self.nr < 2 {
            return Err("Número de nós radiais deve ser pelo menos 2".to_string());
        }
        if self.nz < 2 {
            return Err("Número de nós axiais deve ser pelo menos 2".to_string());
        }
        if self.ntheta < 4 {
            return Err("Número de nós angulares deve ser pelo menos 4".to_string());
        }
        if self.torches.is_empty() {
            return Err("Pelo menos uma tocha deve ser definida".to_string());
        }
        if self.time_step <= 0.0 {
            return Err("Passo de tempo deve ser positivo".to_string());
        }
        if self.total_time <= 0.0 {
            return Err("Tempo total deve ser positivo".to_string());
        }
        
        // Validar posição das tochas
        for torch in &self.torches {
            if torch.r_position < 0.0 || torch.r_position > self.radius {
                return Err(format!("Posição radial da tocha {} ({}) fora dos limites [0, {}]", 
                                  torch.id, torch.r_position, self.radius));
            }
            if torch.z_position < 0.0 || torch.z_position > self.height {
                return Err(format!("Posição axial da tocha {} ({}) fora dos limites [0, {}]", 
                                  torch.id, torch.z_position, self.height));
            }
        }
        
        // Verificar IDs duplicados de tochas
        let mut torch_ids = Vec::new();
        for torch in &self.torches {
            if torch_ids.contains(&torch.id) {
                return Err(format!("ID de tocha duplicado: {}", torch.id));
            }
            torch_ids.push(torch.id.clone());
        }
        
        // Verificar zonas de material
        if let Some(zone_map) = &self.zone_map {
            if let Some(material_zones) = &self.material_zones {
                // Verificar se todas as zonas no mapa têm um material correspondente
                let max_zone = zone_map.iter().max().unwrap_or(&0);
                if *max_zone >= material_zones.len() {
                    return Err(format!("Zona de material {} não definida", max_zone));
                }
            } else if zone_map.iter().any(|&z| z > 0) {
                return Err("Mapa de zonas definido, mas nenhuma zona de material configurada".to_string());
            }
        }
        
        Ok(())
    }
}

/// Estrutura que representa os resultados da simulação com suporte a materiais avançados
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SimulationResults {
    /// Parâmetros da simulação
    pub parameters: SimulationParameters,
    /// Malha cilíndrica
    pub mesh: CylindricalMesh,
    /// Campo de temperatura (nr, nz, time_steps)
    pub temperature: Array3<f64>,
    /// Tempo de execução (s)
    pub execution_time: f64,
    /// Informações sobre mudanças de fase (opcional)
    pub phase_change_info: Option<PhaseChangeInfo>,
}

/// Estrutura que armazena informações sobre mudanças de fase
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PhaseChangeInfo {
    /// Fração de material fundido em cada célula (nr, nz, time_steps)
    pub melt_fraction: Option<Array3<f64>>,
    /// Fração de material vaporizado em cada célula (nr, nz, time_steps)
    pub vapor_fraction: Option<Array3<f64>>,
    /// Energia total absorvida por mudanças de fase (J)
    pub total_phase_change_energy: f64,
}

impl SimulationResults {
    /// Gera dados de temperatura 3D para um passo de tempo específico
    pub fn generate_3d_temperature(&self, time_step: usize) -> Result<Array3<f64>, String> {
        if time_step >= self.parameters.time_steps {
            return Err(format!("Passo de tempo {} fora dos limites [0, {}]", 
                              time_step, self.parameters.time_steps - 1));
        }
        
        let nr = self.parameters.nr;
        let nz = self.parameters.nz;
        let ntheta = self.parameters.ntheta;
        
        let mut temp_3d = Array3::<f64>::zeros((nr, ntheta, nz));
        
        // Preencher o array 3D replicando os dados 2D em torno do eixo
        for i in 0..nr {
            for k in 0..ntheta {
                for j in 0..nz {
                    temp_3d[[i, k, j]] = self.temperature[[i, j, time_step]];
                }
            }
        }
        
        Ok(temp_3d)
    }
}

/// Estrutura que representa o solucionador da equação de calor com suporte a materiais avançados
pub struct HeatSolver {
    /// Parâmetros da simulação
    params: SimulationParameters,
    /// Malha cilíndrica
    mesh: CylindricalMesh,
    /// Campo de temperatura atual
    temperature: Array2<f64>,
    /// Histórico de temperatura
    temperature_history: Array3<f64>,
    /// Fração de material fundido em cada célula
    melt_fraction: Option<Array2<f64>>,
    /// Histórico de fração fundida
    melt_fraction_history: Option<Array3<f64>>,
    /// Fração de material vaporizado em cada célula
    vapor_fraction: Option<Array2<f64>>,
    /// Histórico de fração vaporizada
    vapor_fraction_history: Option<Array3<f64>>,
    /// Energia total absorvida por mudanças de fase
    total_phase_change_energy: f64,
    /// Passo de tempo atual
    current_step: usize,
}

impl HeatSolver {
    /// Cria um novo solucionador com os parâmetros especificados
    pub fn new(params: SimulationParameters) -> Result<Self, String> {
        // Validar parâmetros
        params.validate()?;
        
        // Criar malha
        let mesh = CylindricalMesh::new(
            params.height, 
            params.radius, 
            params.nr, 
            params.nz, 
            params.ntheta
        );
        
        // Inicializar campo de temperatura
        let temperature = Array2::<f64>::from_elem((params.nr, params.nz), params.initial_temperature);
        
        // Inicializar histórico de temperatura
        let temperature_history = Array3::<f64>::zeros((params.nr, params.nz, params.time_steps + 1));
        
        // Armazenar temperatura inicial no histórico
        let mut temperature_history_view = temperature_history.slice_mut(s![.., .., 0]);
        temperature_history_view.assign(&temperature);
        
        // Inicializar arrays de mudança de fase se necessário
        let (melt_fraction, melt_fraction_history, vapor_fraction, vapor_fraction_history) = 
            if params.enable_phase_changes && 
               (params.material.melting_point.is_some() || params.material.vaporization_point.is_some()) {
                
                let melt_fraction = Array2::<f64>::zeros((params.nr, params.nz));
                let melt_fraction_history = Array3::<f64>::zeros((params.nr, params.nz, params.time_steps + 1));
                
                let vapor_fraction = Array2::<f64>::zeros((params.nr, params.nz));
                let vapor_fraction_history = Array3::<f64>::zeros((params.nr, params.nz, params.time_steps + 1));
                
                (Some(melt_fraction), Some(melt_fraction_history), 
                 Some(vapor_fraction), Some(vapor_fraction_history))
            } else {
                (None, None, None, None)
            };
        
        // Configurar mapa de zonas, se fornecido
        let mut solver = Self {
            params,
            mesh,
            temperature,
            temperature_history,
            melt_fraction,
            melt_fraction_history,
            vapor_fraction,
            vapor_fraction_history,
            total_phase_change_energy: 0.0,
            current_step: 0,
        };
        
        if let Some(zone_map) = &solver.params.zone_map {
            solver.mesh.set_zones(zone_map.clone());
        }
        
        Ok(solver)
    }
    
    /// Executa a simulação completa
    pub fn run(&mut self, progress_callback: Option<&dyn Fn(f32)>) -> Result<SimulationResults, String> {
        let start_time = Instant::now();
        
        info!("Iniciando simulação com {} passos de tempo, {} tochas e material: {}", 
              self.params.time_steps, self.params.torches.len(), self.params.material.name);
        
        // Loop principal de simulação
        for step in 0..self.params.time_steps {
            self.current_step = step;
            
            // Calcular termos fonte
            let sources = self.calculate_sources();
            
            // Resolver um passo de tempo
            self.solve_time_step(&sources)?;
            
            // Atualizar frações de mudança de fase, se necessário
            if self.params.enable_phase_changes {
                self.update_phase_change_fractions()?;
            }
            
            // Armazenar resultado no histórico
            let mut temperature_history_view = self.temperature_history.slice_mut(s![.., .., step + 1]);
            temperature_history_view.assign(&self.temperature);
            
            // Armazenar frações de mudança de fase no histórico, se necessário
            if let Some(melt_fraction) = &self.melt_fraction {
                if let Some(melt_history) = &mut self.melt_fraction_history {
                    let mut melt_history_view = melt_history.slice_mut(s![.., .., step + 1]);
                    melt_history_view.assign(melt_fraction);
                }
            }
            
            if let Some(vapor_fraction) = &self.vapor_fraction {
                if let Some(vapor_history) = &mut self.vapor_fraction_history {
                    let mut vapor_history_view = vapor_history.slice_mut(s![.., .., step + 1]);
                    vapor_history_view.assign(vapor_fraction);
                }
            }
            
            // Reportar progresso
            if let Some(callback) = progress_callback {
                let progress = (step + 1) as f32 / self.params.time_steps as f32;
                callback(progress);
            }
            
            if (step + 1) % 10 == 0 || step + 1 == self.params.time_steps {
                info!("Passo de tempo {}/{} concluído", step + 1, self.params.time_steps);
            }
        }
        
        let execution_time = start_time.elapsed().as_secs_f64();
        info!("Simulação concluída em {:.2} segundos", execution_time);
        
        // Criar informações de mudança de fase, se necessário
        let phase_change_info = if self.params.enable_phase_changes && 
                                  (self.melt_fraction_history.is_some() || self.vapor_fraction_history.is_some()) {
            Some(PhaseChangeInfo {
                melt_fraction: self.melt_fraction_history.clone(),
                vapor_fraction: self.vapor_fraction_history.clone(),
                total_phase_change_energy: self.total_phase_change_energy,
            })
        } else {
            None
        };
        
        // Criar resultados
        let results = SimulationResults {
            parameters: self.params.clone(),
            mesh: self.mesh.clone(),
            temperature: self.temperature_history.clone(),
            execution_time,
            phase_change_info,
        };
        
        Ok(results)
    }
    
    /// Calcula os termos fonte para a equação de calor
    fn calculate_sources(&self) -> HeatSources {
        let mut sources = HeatSources::new(self.params.nr, self.params.nz);
        
        // Calcular termo fonte de radiação
        if self.params.enable_radiation {
            sources.radiation = calculate_radiation_source(
                &self.mesh,
                &self.params.torches,
                &self.temperature,
                &self.params.material,
            );
        }
        
        // Calcular termo fonte de convecção
        if self.params.enable_convection {
            sources.convection = calculate_convection_source(
                &self.mesh,
                &self.params.torches,
                &self.temperature,
                self.params.convection_coefficient,
            );
        }
        
        // Termo fonte de mudança de fase será calculado durante a solução
        
        sources
    }
    
    /// Resolve um passo de tempo usando o método de Crank-Nicolson
    fn solve_time_step(&mut self, sources: &HeatSources) -> Result<(), String> {
        // Implementação simplificada usando o método explícito para a primeira versão
        // O método de Crank-Nicolson será implementado posteriormente
        
        let dt = self.params.time_step;
        let nr = self.params.nr;
        let nz = self.params.nz;
        
        // Criar uma cópia da temperatura atual
        let mut new_temperature = self.temperature.clone();
        
        // Calcular novo campo de temperatura
        for i in 0..nr {
            for j in 0..nz {
                let r = self.mesh.r_coords[i];
                let dr = self.mesh.dr;
                let dz = self.mesh.dz;
                
                // Obter temperatura atual
                let temp = self.temperature[[i, j]];
                
                // Obter propriedades do material para a temperatura atual
                // Usar propriedades dependentes da temperatura
                let rho = self.params.material.get_density(temp);
                let cp = self.params.material.get_specific_heat(temp);
                let k = self.params.material.get_thermal_conductivity(temp);
                
                // Capacidade térmica efetiva (considerando mudanças de fase)
                let cp_eff = if self.params.enable_phase_changes {
                    self.params.material.effective_specific_heat(temp, dt)
                } else {
                    cp
                };
                
                // Termo fonte total
                let source = sources.total()[[i, j]];
                
                // Termos de condução
                let mut conduction_term = 0.0;
                
                // Condução radial
                if i == 0 {
                    // Condição de simetria no eixo central
                    let t_right = self.temperature[[i+1, j]];
                    conduction_term += 2.0 * k * (t_right - temp) / (dr * dr);
                } else if i == nr - 1 {
                    // Condição de contorno na parede externa
                    let t_left = self.temperature[[i-1, j]];
                    let t_wall = self.params.ambient_temperature;
                    conduction_term += k * (t_left - temp) / (dr * dr);
                    conduction_term += 2.0 * k * (t_wall - temp) / (dr * dr);
                } else {
                    // Nós internos
                    let t_left = self.temperature[[i-1, j]];
                    let t_right = self.temperature[[i+1, j]];
                    conduction_term += k * (t_left - 2.0 * temp + t_right) / (dr * dr);
                    conduction_term += k * (t_right - t_left) / (2.0 * r * dr);
                }
                
                // Condução axial
                if j == 0 {
                    // Condição de contorno na base
                    let t_up = self.temperature[[i, j+1]];
                    let t_bottom = self.params.ambient_temperature;
                    conduction_term += k * (t_up - temp) / (dz * dz);
                    conduction_term += k * (t_bottom - temp) / (dz * dz);
                } else if j == nz - 1 {
                    // Condição de contorno no topo
                    let t_down = self.temperature[[i, j-1]];
                    let t_top = self.params.ambient_temperature;
                    conduction_term += k * (t_down - temp) / (dz * dz);
                    conduction_term += k * (t_top - temp) / (dz * dz);
                } else {
                    // Nós internos
                    let t_down = self.temperature[[i, j-1]];
                    let t_up = self.temperature[[i, j+1]];
                    conduction_term += k * (t_down - 2.0 * temp + t_up) / (dz * dz);
                }
                
                // Atualizar temperatura
                new_temperature[[i, j]] = temp + dt * (conduction_term + source) / (rho * cp_eff);
            }
        }
        
        // Atualizar campo de temperatura
        self.temperature = new_temperature;
        
        Ok(())
    }
    
    /// Atualiza as frações de mudança de fase
    fn update_phase_change_fractions(&mut self) -> Result<(), String> {
        if !self.params.enable_phase_changes {
            return Ok(());
        }
        
        let nr = self.params.nr;
        let nz = self.params.nz;
        let dt = self.params.time_step;
        
        // Atualizar fração de fusão, se aplicável
        if let (Some(melting_point), Some(latent_heat)) = (self.params.material.melting_point, self.params.material.latent_heat_fusion) {
            if self.melt_fraction.is_none() {
                self.melt_fraction = Some(Array2::<f64>::zeros((nr, nz)));
            }
            
            if let Some(melt_fraction) = &mut self.melt_fraction {
                for i in 0..nr {
                    for j in 0..nz {
                        let temp = self.temperature[[i, j]];
                        
                        // Atualizar fração de fusão
                        if temp > melting_point && melt_fraction[[i, j]] < 1.0 {
                            // Calcular energia disponível para fusão
                            let rho = self.params.material.get_density(temp);
                            let volume = self.mesh.cell_volumes[[i, j]];
                            let mass = rho * volume;
                            
                            // Energia necessária para fusão completa
                            let energy_for_complete_melt = mass * latent_heat * (1.0 - melt_fraction[[i, j]]);
                            
                            // Energia disponível neste passo de tempo (simplificada)
                            let cp = self.params.material.get_specific_heat(temp);
                            let available_energy = mass * cp * (temp - melting_point);
                            
                            // Limitar a energia disponível
                            let used_energy = available_energy.min(energy_for_complete_melt);
                            
                            // Atualizar fração de fusão
                            let delta_fraction = used_energy / (mass * latent_heat);
                            melt_fraction[[i, j]] += delta_fraction;
                            melt_fraction[[i, j]] = melt_fraction[[i, j]].min(1.0);
                            
                            // Contabilizar energia usada para mudança de fase
                            self.total_phase_change_energy += used_energy;
                        }
                    }
                }
            }
        }
        
        // Atualizar fração de vaporização, se aplicável
        if let (Some(vaporization_point), Some(latent_heat)) = (self.params.material.vaporization_point, self.params.material.latent_heat_vaporization) {
            if self.vapor_fraction.is_none() {
                self.vapor_fraction = Some(Array2::<f64>::zeros((nr, nz)));
            }
            
            if let Some(vapor_fraction) = &mut self.vapor_fraction {
                for i in 0..nr {
                    for j in 0..nz {
                        let temp = self.temperature[[i, j]];
                        
                        // Atualizar fração de vaporização
                        if temp > vaporization_point && vapor_fraction[[i, j]] < 1.0 {
                            // Verificar se o material está completamente fundido
                            let is_fully_melted = if let Some(melt_fraction) = &self.melt_fraction {
                                melt_fraction[[i, j]] >= 1.0
                            } else {
                                true
                            };
                            
                            if is_fully_melted {
                                // Calcular energia disponível para vaporização
                                let rho = self.params.material.get_density(temp);
                                let volume = self.mesh.cell_volumes[[i, j]];
                                let mass = rho * volume;
                                
                                // Energia necessária para vaporização completa
                                let energy_for_complete_vapor = mass * latent_heat * (1.0 - vapor_fraction[[i, j]]);
                                
                                // Energia disponível neste passo de tempo (simplificada)
                                let cp = self.params.material.get_specific_heat(temp);
                                let available_energy = mass * cp * (temp - vaporization_point);
                                
                                // Limitar a energia disponível
                                let used_energy = available_energy.min(energy_for_complete_vapor);
                                
                                // Atualizar fração de vaporização
                                let delta_fraction = used_energy / (mass * latent_heat);
                                vapor_fraction[[i, j]] += delta_fraction;
                                vapor_fraction[[i, j]] = vapor_fraction[[i, j]].min(1.0);
                                
                                // Contabilizar energia usada para mudança de fase
                                self.total_phase_change_energy += used_energy;
                            }
                        }
                    }
                }
            }
        }
        
        Ok(())
    }
    
    /// Retorna o campo de temperatura atual
    pub fn get_temperature(&self) -> &Array2<f64> {
        &self.temperature
    }
    
    /// Retorna o histórico de temperatura
    pub fn get_temperature_history(&self) -> &Array3<f64> {
        &self.temperature_history
    }
    
    /// Retorna a temperatura para um passo de tempo específico
    pub fn get_temperature_at_step(&self, step: usize) -> Result<Array2<f64>, String> {
        if step > self.current_step {
            return Err(format!("Passo de tempo {} não disponível (atual: {})", step, self.current_step));
        }
        
        Ok(self.temperature_history.slice(s![.., .., step]).to_owned())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use approx::assert_relative_eq;
    
    #[test]
    fn test_simulation_with_material_properties() {
        // Criar biblioteca de materiais
        let library = MaterialLibrary::new();
        
        // Obter material pré-definido
        let aluminum = library.get_material_clone("aluminum").unwrap();
        
        // Criar parâmetros de simulação com o material
        let mut params = SimulationParameters::new(0.1, 0.05, 5, 5);
        params.material = aluminum;
        params.time_steps = 2;
        params.add_torch(PlasmaTorch::new(
            "torch1",
            0.0, 0.0, 0.05, 90.0, 0.0, 10.0, 0.001, 1000.0
        ));
        
        // Criar e executar o solucionador
        let mut solver = HeatSolver::new(params).unwrap();
        let results = solver.run(None).unwrap();
        
        // Verificar se os resultados contêm as propriedades do material
        assert_eq!(results.parameters.material.name, "Alumínio");
    }
    
    #[test]
    fn test_phase_change_tracking() {
        // Criar material com ponto de fusão
        let mut material = MaterialProperties::new("Test Material", 1000.0, 1500.0, 0.5);
        material.melting_point = Some(100.0);
        material.latent_heat_fusion = Some(200000.0);
        
        // Criar parâmetros de simulação com o material
        let mut params = SimulationParameters::new(0.1, 0.05, 5, 5);
        params.material = material;
        params.time_steps = 5;
        params.enable_phase_changes = true;
        params.initial_temperature = 90.0; // Próximo ao ponto de fusão
        
        // Adicionar tocha de alta potência para garantir fusão
        params.add_torch(PlasmaTorch::new(
            "torch1",
            0.0, 0.0, 0.05, 90.0, 0.0, 1000.0, 0.001, 5000.0
        ));
        
        // Criar e executar o solucionador
        let mut solver = HeatSolver::new(params).unwrap();
        let results = solver.run(None).unwrap();
        
        // Verificar se as informações de mudança de fase estão presentes
        assert!(results.phase_change_info.is_some());
        
        if let Some(phase_info) = results.phase_change_info {
            assert!(phase_info.melt_fraction.is_some());
        }
    }
}
