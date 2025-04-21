# Guia de Referência - Simulador de Fornalha de Plasma

Este guia de referência fornece informações detalhadas sobre as funcionalidades, parâmetros e APIs do Simulador de Fornalha de Plasma.

## Parâmetros de Simulação

### Geometria e Malha

| Parâmetro | Descrição | Unidade | Intervalo Típico |
|-----------|-----------|---------|-----------------|
| `meshRadialCells` | Número de células na direção radial | - | 10-100 |
| `meshAngularCells` | Número de células na direção angular | - | 8-64 |
| `meshAxialCells` | Número de células na direção axial | - | 10-100 |
| `meshCellSize` | Tamanho da célula | m | 0.01-0.1 |
| `furnaceRadius` | Raio da fornalha | m | 0.5-5.0 |
| `furnaceHeight` | Altura da fornalha | m | 1.0-10.0 |

### Condições de Simulação

| Parâmetro | Descrição | Unidade | Intervalo Típico |
|-----------|-----------|---------|-----------------|
| `initialTemperature` | Temperatura inicial | K | 273-1273 |
| `ambientTemperature` | Temperatura ambiente | K | 273-323 |
| `simulationTimeStep` | Passo de tempo | s | 0.001-1.0 |
| `simulationDuration` | Duração total da simulação | s | 1-3600 |
| `maxIterations` | Número máximo de iterações por passo | - | 10-1000 |
| `convergenceTolerance` | Tolerância para convergência | - | 1e-6-1e-3 |

### Propriedades da Tocha de Plasma

| Parâmetro | Descrição | Unidade | Intervalo Típico |
|-----------|-----------|---------|-----------------|
| `torchPower` | Potência da tocha | kW | 10-500 |
| `torchEfficiency` | Eficiência da tocha | - | 0.5-0.95 |
| `torchPosition` | Posição da tocha (x, y, z) | m | - |
| `torchDirection` | Direção da tocha (vetor) | - | - |
| `torchDiameter` | Diâmetro da tocha | m | 0.01-0.1 |
| `torchTemperature` | Temperatura do plasma | K | 5000-20000 |

### Propriedades dos Materiais

| Parâmetro | Descrição | Unidade | Intervalo Típico |
|-----------|-----------|---------|-----------------|
| `materialThermalConductivity` | Condutividade térmica | W/(m·K) | 0.1-500 |
| `materialSpecificHeat` | Calor específico | J/(kg·K) | 100-5000 |
| `materialDensity` | Densidade | kg/m³ | 100-20000 |
| `materialEmissivity` | Emissividade | - | 0.1-1.0 |
| `materialMeltingPoint` | Ponto de fusão | K | 500-3000 |
| `materialLatentHeat` | Calor latente de fusão | J/kg | 1e4-5e5 |

## Materiais Pré-definidos

| Material | Condutividade Térmica (W/(m·K)) | Calor Específico (J/(kg·K)) | Densidade (kg/m³) | Emissividade | Ponto de Fusão (K) |
|----------|--------------------------------|----------------------------|-----------------|--------------|-------------------|
| Aço Carbono | 45 | 490 | 7850 | 0.8 | 1723 |
| Aço Inoxidável | 15 | 500 | 8000 | 0.85 | 1673 |
| Alumínio | 237 | 900 | 2700 | 0.2 | 933 |
| Cobre | 400 | 385 | 8960 | 0.3 | 1358 |
| Ferro | 80 | 450 | 7870 | 0.7 | 1808 |
| Grafite | 120 | 710 | 2250 | 0.95 | 3800 |
| Concreto | 1.7 | 880 | 2300 | 0.9 | 1773 |
| Vidro | 1.0 | 840 | 2600 | 0.95 | 1473 |
| Madeira | 0.15 | 1700 | 700 | 0.9 | 573 |
| Cerâmica | 2.5 | 800 | 3000 | 0.85 | 2073 |

## Fórmulas Físicas

### Equação de Transferência de Calor

A equação fundamental que governa a transferência de calor na fornalha é:

$$\rho c_p \frac{\partial T}{\partial t} = \nabla \cdot (k \nabla T) + Q$$

Onde:
- $\rho$ é a densidade do material (kg/m³)
- $c_p$ é o calor específico (J/(kg·K))
- $T$ é a temperatura (K)
- $t$ é o tempo (s)
- $k$ é a condutividade térmica (W/(m·K))
- $Q$ é o termo fonte de calor (W/m³)

### Fonte de Calor do Plasma

A fonte de calor do plasma é modelada como:

$$Q(r) = \frac{P \eta}{2\pi\sigma^2} \exp\left(-\frac{r^2}{2\sigma^2}\right)$$

Onde:
- $P$ é a potência da tocha (W)
- $\eta$ é a eficiência da tocha
- $r$ é a distância do centro da tocha (m)
- $\sigma$ é o parâmetro de dispersão (m)

### Radiação Térmica

A transferência de calor por radiação é modelada pela lei de Stefan-Boltzmann:

$$q_r = \varepsilon \sigma (T^4 - T_{amb}^4)$$

Onde:
- $q_r$ é o fluxo de calor radiativo (W/m²)
- $\varepsilon$ é a emissividade da superfície
- $\sigma$ é a constante de Stefan-Boltzmann (5.67×10⁻⁸ W/(m²·K⁴))
- $T$ é a temperatura da superfície (K)
- $T_{amb}$ é a temperatura ambiente (K)

## Métricas de Simulação

| Métrica | Descrição | Unidade |
|---------|-----------|---------|
| `maxTemperature` | Temperatura máxima | K |
| `minTemperature` | Temperatura mínima | K |
| `avgTemperature` | Temperatura média | K |
| `maxGradient` | Gradiente máximo de temperatura | K/m |
| `avgGradient` | Gradiente médio de temperatura | K/m |
| `maxHeatFlux` | Fluxo de calor máximo | W/m² |
| `avgHeatFlux` | Fluxo de calor médio | W/m² |
| `totalEnergy` | Energia total no sistema | J |
| `heatingRate` | Taxa de aquecimento | K/s |
| `energyEfficiency` | Eficiência energética | % |

## Métricas de Validação

| Métrica | Descrição | Fórmula |
|---------|-----------|---------|
| `meanAbsoluteError` (MAE) | Erro médio absoluto | $\frac{1}{n}\sum_{i=1}^{n}\|y_i-\hat{y}_i\|$ |
| `meanSquaredError` (MSE) | Erro quadrático médio | $\frac{1}{n}\sum_{i=1}^{n}(y_i-\hat{y}_i)^2$ |
| `rootMeanSquaredError` (RMSE) | Raiz do erro quadrático médio | $\sqrt{\frac{1}{n}\sum_{i=1}^{n}(y_i-\hat{y}_i)^2}$ |
| `meanAbsolutePercentageError` (MAPE) | Erro percentual médio absoluto | $\frac{100\%}{n}\sum_{i=1}^{n}\left\|\frac{y_i-\hat{y}_i}{y_i}\right\|$ |
| `rSquared` (R²) | Coeficiente de determinação | $1-\frac{\sum_{i=1}^{n}(y_i-\hat{y}_i)^2}{\sum_{i=1}^{n}(y_i-\bar{y})^2}$ |

## Formatos de Exportação

### CSV (Comma-Separated Values)

Formato de texto simples para dados tabulares:

```
x,y,z,temperature
0.1,0.0,0.1,350.5
0.2,0.0,0.1,375.2
...
```

### JSON (JavaScript Object Notation)

Formato estruturado para dados hierárquicos:

```json
{
  "metadata": {
    "simulationTime": 10.0,
    "meshSize": [20, 16, 20]
  },
  "results": [
    {"position": [0.1, 0.0, 0.1], "temperature": 350.5},
    {"position": [0.2, 0.0, 0.1], "temperature": 375.2},
    ...
  ]
}
```

### VTK (Visualization Toolkit)

Formato para visualização científica 3D:

```
# vtk DataFile Version 3.0
Plasma Furnace Simulation Results
ASCII
DATASET STRUCTURED_GRID
DIMENSIONS 20 16 20
POINTS 6400 float
...
POINT_DATA 6400
SCALARS temperature float 1
LOOKUP_TABLE default
...
```

## API de Plugins

### Interface de Plugin

```rust
pub trait SimulationPlugin {
    fn name(&self) -> &str;
    fn description(&self) -> &str;
    fn initialize(&mut self, state: &mut SimulationState);
    fn pre_step(&mut self, state: &mut SimulationState, physics: &PlasmaPhysics);
    fn post_step(&mut self, state: &mut SimulationState, physics: &PlasmaPhysics);
    fn finalize(&mut self, state: &mut SimulationState);
}
```

### Criando um Plugin Personalizado

1. Implemente a trait `SimulationPlugin`
2. Compile como uma biblioteca dinâmica (.dll/.so/.dylib)
3. Coloque o arquivo na pasta de plugins
4. Ative o plugin nas configurações do aplicativo

## Linguagem de Fórmulas

### Sintaxe Básica

A linguagem de fórmulas suporta:

- Operadores aritméticos: `+`, `-`, `*`, `/`, `^` (potência)
- Funções matemáticas: `sin`, `cos`, `tan`, `exp`, `log`, `sqrt`
- Constantes: `pi`, `e`
- Variáveis definidas pelo usuário
- Condicionais: `if(condição, valor_verdadeiro, valor_falso)`

### Exemplos

Fonte de calor gaussiana:
```
power * efficiency / (2 * pi * sigma^2) * exp(-r^2 / (2 * sigma^2))
```

Condutividade térmica dependente da temperatura:
```
k_0 * (1 + alpha * (T - T_ref))
```

Emissividade variável:
```
if(T < T_transition, emissivity_low, emissivity_high)
```

## Formato de Arquivo de Projeto

Os projetos são salvos no formato `.pfp` (Plasma Furnace Project), que é um arquivo ZIP contendo:

- `project.json`: Metadados do projeto
- `simulation_parameters.json`: Parâmetros da simulação
- `materials/`: Definições de materiais personalizados
- `formulas/`: Fórmulas personalizadas
- `results/`: Resultados da simulação
- `validation/`: Dados de validação
- `parametric_studies/`: Configurações e resultados de estudos paramétricos

## Requisitos de Hardware para Simulações Complexas

| Complexidade | Células da Malha | RAM Recomendada | CPU Recomendada | Tempo Estimado* |
|--------------|------------------|-----------------|-----------------|-----------------|
| Baixa | < 50.000 | 8 GB | 4 núcleos | Minutos |
| Média | 50.000 - 500.000 | 16 GB | 8 núcleos | Dezenas de minutos |
| Alta | 500.000 - 5.000.000 | 32 GB | 16+ núcleos | Horas |
| Muito Alta | > 5.000.000 | 64+ GB | 32+ núcleos | Dias |

*Tempo estimado para uma simulação de 1 hora de tempo real

## Códigos de Erro

| Código | Descrição | Solução |
|--------|-----------|---------|
| E001 | Parâmetros de simulação inválidos | Verifique os valores dos parâmetros |
| E002 | Falha na inicialização da malha | Reduza o tamanho da malha ou aumente a memória disponível |
| E003 | Instabilidade numérica detectada | Reduza o passo de tempo ou use o solucionador implícito |
| E004 | Erro de convergência | Aumente o número máximo de iterações ou a tolerância |
| E005 | Arquivo de projeto corrompido | Use um backup ou crie um novo projeto |
| E006 | Erro na importação de dados | Verifique o formato do arquivo de dados |
| E007 | Erro na exportação de resultados | Verifique as permissões de escrita no diretório de destino |
| E008 | Erro na avaliação de fórmula | Verifique a sintaxe da fórmula |
| E009 | Erro na inicialização do plugin | Verifique a compatibilidade do plugin |
| E010 | Erro na renderização 3D | Atualize os drivers da placa de vídeo ou reduza a qualidade da visualização |

## Glossário Técnico

| Termo | Definição |
|-------|-----------|
| **Advecção** | Transporte de uma substância ou propriedade por um fluido devido ao movimento do fluido |
| **Condução** | Transferência de calor através de um material sem movimento macroscópico do material |
| **Convecção** | Transferência de calor devido ao movimento de fluidos |
| **Difusividade Térmica** | Propriedade que caracteriza a taxa de difusão de calor através de um material (k/ρcp) |
| **Discretização** | Processo de converter equações diferenciais contínuas em equações algébricas discretas |
| **Equação de Navier-Stokes** | Equações que descrevem o movimento de fluidos |
| **Isosuperfície** | Superfície tridimensional que representa pontos de valor constante |
| **Método dos Volumes Finitos** | Técnica numérica para resolver equações diferenciais parciais |
| **Número de Courant** | Parâmetro que relaciona o passo de tempo com o tamanho da malha e a velocidade do fenômeno |
| **Plasma** | Estado da matéria composto de gás ionizado |
| **Radiação Térmica** | Transferência de calor por ondas eletromagnéticas |
| **Regime Transiente** | Estado em que as propriedades do sistema variam com o tempo |
| **Regime Estacionário** | Estado em que as propriedades do sistema não variam com o tempo |
| **Tensor de Condutividade Térmica** | Representação da condutividade térmica em materiais anisotrópicos |
| **Tocha de Plasma** | Dispositivo que gera um jato de plasma de alta temperatura |
