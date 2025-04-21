import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'dart:math' as math;

import '../models/parametric_study.dart';
import '../state/simulation_state.dart';
import '../services/parametric_ffi_bridge.dart';
import '../widgets/parametric/parameter_config_card.dart';
import '../widgets/parametric/result_heatmap.dart';
import '../widgets/parametric/sensitivity_chart.dart';

class ParametricStudyScreen extends ConsumerStatefulWidget {
  const ParametricStudyScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ParametricStudyScreen> createState() => _ParametricStudyScreenState();
}

class _ParametricStudyScreenState extends ConsumerState<ParametricStudyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String? _error;
  
  // Estado para configuração do estudo
  ParametricStudyConfig? _studyConfig;
  ParametricStudyResult? _studyResult;
  
  // Lista de parâmetros para o estudo
  List<ParametricParameter> _parameters = [];
  
  // Métricas disponíveis
  final List<String> _availableMetrics = [
    'max_temperature',
    'min_temperature',
    'avg_temperature',
    'max_gradient',
    'avg_gradient',
    'max_heat_flux',
    'avg_heat_flux',
    'total_energy',
    'heating_rate',
    'energy_efficiency',
  ];
  
  // Métrica selecionada
  String _selectedMetric = 'max_temperature';
  
  // Objetivo da otimização
  OptimizationGoal _optimizationGoal = OptimizationGoal.maximize;
  
  // Configurações avançadas
  int _maxSimulations = 100;
  bool _useParallel = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPredefinedStudies();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPredefinedStudies() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final ffiBridge = ParametricFFIBridge();
      final predefinedStudies = await ffiBridge.getPredefinedStudies();
      
      if (predefinedStudies.isNotEmpty) {
        setState(() {
          _studyConfig = predefinedStudies.first;
          _parameters = _studyConfig!.parameters;
          _selectedMetric = _studyConfig!.targetMetric;
          _optimizationGoal = _studyConfig!.optimizationGoal;
          _maxSimulations = _studyConfig!.maxSimulations;
          _useParallel = _studyConfig!.useParallel;
        });
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar estudos predefinidos: $e';
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar estudos predefinidos: $e')),
      );
    }
  }

  Future<void> _loadPredefinedStudy(String studyType) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final ffiBridge = ParametricFFIBridge();
      final studyConfig = await ffiBridge.getPredefinedStudy(studyType);
      
      setState(() {
        _studyConfig = studyConfig;
        _parameters = _studyConfig!.parameters;
        _selectedMetric = _studyConfig!.targetMetric;
        _optimizationGoal = _studyConfig!.optimizationGoal;
        _maxSimulations = _studyConfig!.maxSimulations;
        _useParallel = _studyConfig!.useParallel;
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Estudo predefinido carregado: ${_studyConfig!.name}')),
      );
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar estudo predefinido: $e';
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar estudo predefinido: $e')),
      );
    }
  }

  Future<void> _addParameter() async {
    final newParameter = ParametricParameter(
      name: 'novo_parametro',
      description: 'Novo parâmetro',
      unit: '-',
      minValue: 0.0,
      maxValue: 100.0,
      numPoints: 5,
      scaleType: ScaleType.linear,
      specificValues: null,
    );
    
    setState(() {
      _parameters.add(newParameter);
    });
  }

  void _removeParameter(int index) {
    setState(() {
      _parameters.removeAt(index);
    });
  }

  void _updateParameter(int index, ParametricParameter parameter) {
    setState(() {
      _parameters[index] = parameter;
    });
  }

  Future<void> _runParametricStudy() async {
    if (_parameters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicione pelo menos um parâmetro para o estudo')),
      );
      return;
    }
    
    final simulationState = ref.read(simulationStateProvider);
    
    if (simulationState.results == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Execute uma simulação básica antes de iniciar um estudo paramétrico')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // Criar configuração do estudo
      final studyConfig = ParametricStudyConfig(
        name: 'Estudo Paramétrico Personalizado',
        description: 'Estudo paramétrico configurado pelo usuário',
        parameters: _parameters,
        targetMetric: _selectedMetric,
        optimizationGoal: _optimizationGoal,
        maxSimulations: _maxSimulations,
        maxExecutionTime: 3600.0,
        useParallel: _useParallel,
        metadata: {},
      );
      
      // Executar estudo paramétrico
      final ffiBridge = ParametricFFIBridge();
      final result = await ffiBridge.runParametricStudy(studyConfig);
      
      setState(() {
        _studyResult = result;
        _studyConfig = studyConfig;
        _isLoading = false;
        _tabController.animateTo(1); // Mudar para a aba de resultados
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Estudo paramétrico concluído com ${result.totalSimulations} simulações')),
      );
    } catch (e) {
      setState(() {
        _error = 'Erro ao executar estudo paramétrico: $e';
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao executar estudo paramétrico: $e')),
      );
    }
  }

  Future<void> _generateReport() async {
    if (_studyResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum resultado de estudo paramétrico disponível')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Gerar relatório
      final ffiBridge = ParametricFFIBridge();
      const path = '/tmp/parametric_study_report.md';
      await ffiBridge.generateParametricStudyReport(_studyResult!, path);
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Relatório gerado com sucesso em $path'),
          action: SnackBarAction(
            label: 'Abrir',
            onPressed: () {
              // Abrir o relatório (implementação simplificada)
              // Em uma implementação real, usaríamos um visualizador de Markdown
              // ou converteríamos para HTML e abriríamos no navegador
            },
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _error = 'Erro ao gerar relatório: $e';
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gerar relatório: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estudos Paramétricos'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Configuração'),
            Tab(text: 'Resultados'),
            Tab(text: 'Análise'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Carregar estudo predefinido',
            icon: const Icon(Icons.auto_awesome),
            onSelected: _loadPredefinedStudy,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'energy_efficiency',
                child: Text('Otimização de Eficiência Energética'),
              ),
              const PopupMenuItem(
                value: 'max_temperature',
                child: Text('Otimização de Temperatura Máxima'),
              ),
              const PopupMenuItem(
                value: 'temperature_uniformity',
                child: Text('Otimização de Uniformidade de Temperatura'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.description),
            tooltip: 'Gerar Relatório',
            onPressed: _studyResult == null || _isLoading ? null : _generateReport,
          ),
        ],
      ),
      body: _error != null
          ? Center(child: Text(_error!))
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildConfigurationTab(),
                    _buildResultsTab(),
                    _buildAnalysisTab(),
                  ],
                ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: _isLoading ? null : _runParametricStudy,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Executar Estudo'),
            )
          : null,
    );
  }

  Widget _buildConfigurationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configuração do Estudo Paramétrico',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          // Configuração de parâmetros
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Parâmetros',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      ElevatedButton.icon(
                        onPressed: _addParameter,
                        icon: const Icon(Icons.add),
                        label: const Text('Adicionar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  if (_parameters.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Nenhum parâmetro configurado. Adicione parâmetros para o estudo.'),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _parameters.length,
                      itemBuilder: (context, index) {
                        return ParameterConfigCard(
                          parameter: _parameters[index],
                          onUpdate: (parameter) => _updateParameter(index, parameter),
                          onRemove: () => _removeParameter(index),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Configuração de métrica e objetivo
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Métrica e Objetivo',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  
                  // Seleção de métrica
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Métrica Alvo',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedMetric,
                    items: _availableMetrics.map((metric) {
                      return DropdownMenuItem<String>(
                        value: metric,
                        child: Text(_formatMetricName(metric)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedMetric = value;
                        });
                      }
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Seleção de objetivo
                  const Text(
                    'Objetivo da Otimização',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<OptimizationGoal>(
                    segments: const [
                      ButtonSegment<OptimizationGoal>(
                        value: OptimizationGoal.maximize,
                        label: Text('Maximizar'),
                        icon: Icon(Icons.arrow_upward),
                      ),
                      ButtonSegment<OptimizationGoal>(
                        value: OptimizationGoal.minimize,
                        label: Text('Minimizar'),
                        icon: Icon(Icons.arrow_downward),
                      ),
                    ],
                    selected: {_optimizationGoal},
                    onSelectionChanged: (Set<OptimizationGoal> selection) {
                      if (selection.isNotEmpty) {
                        setState(() {
                          _optimizationGoal = selection.first;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Configurações avançadas
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Configurações Avançadas',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  
                  // Número máximo de simulações
                  Slider(
                    value: _maxSimulations.toDouble(),
                    min: 10,
                    max: 500,
                    divisions: 49,
                    label: _maxSimulations.toString(),
                    onChanged: (value) {
                      setState(() {
                        _maxSimulations = value.round();
                      });
                    },
                  ),
                  Text(
                    'Número máximo de simulações: $_maxSimulations',
                    style: const TextStyle(fontSize: 14),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Usar processamento paralelo
                  SwitchListTile(
                    title: const Text('Usar processamento paralelo'),
                    subtitle: const Text('Acelera a execução em sistemas com múltiplos núcleos'),
                    value: _useParallel,
                    onChanged: (value) {
                      setState(() {
                        _useParallel = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsTab() {
    if (_studyResult == null) {
      return const Center(
        child: Text('Nenhum resultado de estudo paramétrico disponível. Configure e execute um estudo na aba "Configuração".'),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resultados do Estudo Paramétrico',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          // Informações do estudo
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: const Text('Nome do Estudo'),
                    subtitle: Text(_studyResult!.config.name),
                  ),
                  ListTile(
                    title: const Text('Métrica Alvo'),
                    subtitle: Text(_formatMetricName(_studyResult!.config.targetMetric)),
                  ),
                  ListTile(
                    title: const Text('Objetivo'),
                    subtitle: Text(_studyResult!.config.optimizationGoal == OptimizationGoal.maximize
                        ? 'Maximizar'
                        : 'Minimizar'),
                  ),
                  ListTile(
                    title: const Text('Número de Simulações'),
                    subtitle: Text(_studyResult!.totalSimulations.toString()),
                  ),
                  ListTile(
                    title: const Text('Tempo Total de Execução'),
                    subtitle: Text('${_studyResult!.totalExecutionTime.toStringAsFixed(2)} segundos'),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Melhor configuração
          Text(
            'Melhor Configuração',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: Text('Valor da Métrica (${_formatMetricName(_studyResult!.config.targetMetric)})'),
                    subtitle: Text(_studyResult!.bestConfiguration.targetMetricValue.toStringAsFixed(4)),
                    trailing: Icon(
                      _studyResult!.config.optimizationGoal == OptimizationGoal.maximize
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      color: Colors.blue,
                    ),
                  ),
                  
                  const Divider(),
                  const Text(
                    'Valores dos Parâmetros',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _studyResult!.bestConfiguration.parameterValues.length,
                    itemBuilder: (context, index) {
                      final entry = _studyResult!.bestConfiguration.parameterValues.entries.elementAt(index);
                      final paramName = entry.key;
                      final paramValue = entry.value;
                      
                      // Encontrar unidade do parâmetro
                      final param = _studyResult!.config.parameters.firstWhere(
                        (p) => p.name == paramName,
                        orElse: () => ParametricParameter(
                          name: paramName,
                          description: '',
                          unit: '',
                          minValue: 0,
                          maxValue: 0,
                          numPoints: 0,
                          scaleType: ScaleType.linear,
                          specificValues: null,
                        ),
                      );
                      
                      return ListTile(
                        title: Text(_formatParameterName(paramName)),
                        subtitle: Text('${paramValue.toStringAsFixed(4)} ${param.unit}'),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Visualização de resultados
          Text(
            'Visualização de Resultados',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          // Mapa de calor para 2 parâmetros
          if (_studyResult!.config.parameters.length >= 2)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mapa de Calor',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    
                    SizedBox(
                      height: 400,
                      child: ResultHeatmap(
                        studyResult: _studyResult!,
                        xParameter: _studyResult!.config.parameters[0].name,
                        yParameter: _studyResult!.config.parameters[1].name,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: 24),
          
          // Análise de sensibilidade
          Text(
            'Análise de Sensibilidade',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sensibilidade dos Parâmetros',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    height: 300,
                    child: SensitivityChart(
                      sensitivityAnalysis: _studyResult!.sensitivityAnalysis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisTab() {
    if (_studyResult == null) {
      return const Center(
        child: Text('Nenhum resultado de estudo paramétrico disponível. Configure e execute um estudo na aba "Configuração".'),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Análise Detalhada',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          // Análise de parâmetros individuais
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Análise de Parâmetros Individuais',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _studyResult!.config.parameters.length,
                    itemBuilder: (context, index) {
                      final param = _studyResult!.config.parameters[index];
                      final sensitivity = _studyResult!.sensitivityAnalysis[param.name] ?? 0.0;
                      
                      return ExpansionTile(
                        title: Text(_formatParameterName(param.name)),
                        subtitle: Text('Sensibilidade: ${(sensitivity * 100).toStringAsFixed(1)}%'),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: SizedBox(
                              height: 200,
                              child: _buildParameterAnalysisChart(param.name),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Comparação de configurações
          Text(
            'Comparação de Configurações',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Melhores Configurações',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: [
                        const DataColumn(label: Text('Rank')),
                        const DataColumn(label: Text('Métrica')),
                        ..._studyResult!.config.parameters.map((param) => 
                          DataColumn(label: Text(_formatParameterName(param.name))),
                        ),
                      ],
                      rows: _getTopConfigurations(5).map((config) {
                        final rank = _getTopConfigurations(100).indexOf(config) + 1;
                        
                        return DataRow(
                          cells: [
                            DataCell(Text('#$rank')),
                            DataCell(Text(config.targetMetricValue.toStringAsFixed(2))),
                            ..._studyResult!.config.parameters.map((param) => 
                              DataCell(Text(config.parameterValues[param.name]?.toStringAsFixed(2) ?? '-')),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Conclusões
          Text(
            'Conclusões',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getStudyConclusions(),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getStudyRecommendations(),
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParameterAnalysisChart(String paramName) {
    // Agrupar resultados por valor do parâmetro
    final Map<double, List<double>> valueGroups = {};
    
    for (final result in _studyResult!.simulationResults) {
      if (result.parameterValues.containsKey(paramName)) {
        final paramValue = result.parameterValues[paramName]!;
        final metricValue = result.targetMetricValue;
        
        if (!valueGroups.containsKey(paramValue)) {
          valueGroups[paramValue] = [];
        }
        
        valueGroups[paramValue]!.add(metricValue);
      }
    }
    
    // Calcular média para cada valor do parâmetro
    final List<FlSpot> spots = [];
    
    valueGroups.forEach((paramValue, metricValues) {
      final avgMetric = metricValues.reduce((a, b) => a + b) / metricValues.length;
      spots.add(FlSpot(paramValue, avgMetric));
    });
    
    // Ordenar pontos por valor do parâmetro
    spots.sort((a, b) => a.x.compareTo(b.x));
    
    // Encontrar limites
    double minX = spots.isEmpty ? 0 : spots.map((spot) => spot.x).reduce(math.min);
    double maxX = spots.isEmpty ? 100 : spots.map((spot) => spot.x).reduce(math.max);
    double minY = spots.isEmpty ? 0 : spots.map((spot) => spot.y).reduce(math.min);
    double maxY = spots.isEmpty ? 100 : spots.map((spot) => spot.y).reduce(math.max);
    
    // Adicionar margem
    final rangeX = maxX - minX;
    final rangeY = maxY - minY;
    minX -= rangeX * 0.05;
    maxX += rangeX * 0.05;
    minY -= rangeY * 0.1;
    maxY += rangeY * 0.1;
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: rangeY / 5,
          verticalInterval: rangeX / 5,
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            axisNameWidget: Text(_formatParameterName(paramName)),
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 10),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            axisNameWidget: Text(_formatMetricName(_studyResult!.config.targetMetric)),
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 10),
                );
              },
              reservedSize: 40,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300),
        ),
        minX: minX,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.blue,
                  strokeWidth: 1,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: AreaData(
              show: true,
              color: Colors.blue.withOpacity(0.2),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.blueGrey,
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '${_formatParameterName(paramName)}: ${spot.x.toStringAsFixed(2)}\n'
                  '${_formatMetricName(_studyResult!.config.targetMetric)}: ${spot.y.toStringAsFixed(2)}',
                  const TextStyle(color: Colors.white),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  List<ParametricSimulationResult> _getTopConfigurations(int count) {
    if (_studyResult == null || _studyResult!.simulationResults.isEmpty) {
      return [];
    }
    
    // Ordenar resultados com base no objetivo
    final sortedResults = List<ParametricSimulationResult>.from(_studyResult!.simulationResults);
    
    if (_studyResult!.config.optimizationGoal == OptimizationGoal.maximize) {
      sortedResults.sort((a, b) => b.targetMetricValue.compareTo(a.targetMetricValue));
    } else {
      sortedResults.sort((a, b) => a.targetMetricValue.compareTo(b.targetMetricValue));
    }
    
    // Retornar os N melhores resultados
    return sortedResults.take(count).toList();
  }

  String _formatMetricName(String metric) {
    switch (metric) {
      case 'max_temperature':
        return 'Temperatura Máxima';
      case 'min_temperature':
        return 'Temperatura Mínima';
      case 'avg_temperature':
        return 'Temperatura Média';
      case 'max_gradient':
        return 'Gradiente Máximo';
      case 'avg_gradient':
        return 'Gradiente Médio';
      case 'max_heat_flux':
        return 'Fluxo de Calor Máximo';
      case 'avg_heat_flux':
        return 'Fluxo de Calor Médio';
      case 'total_energy':
        return 'Energia Total';
      case 'heating_rate':
        return 'Taxa de Aquecimento';
      case 'energy_efficiency':
        return 'Eficiência Energética';
      default:
        return metric;
    }
  }

  String _formatParameterName(String paramName) {
    switch (paramName) {
      case 'torch_power':
        return 'Potência da Tocha';
      case 'torch_efficiency':
        return 'Eficiência da Tocha';
      case 'thermal_conductivity':
        return 'Condutividade Térmica';
      case 'specific_heat':
        return 'Calor Específico';
      case 'density':
        return 'Densidade';
      case 'emissivity':
        return 'Emissividade';
      case 'time_step':
        return 'Passo de Tempo';
      case 'max_iterations':
        return 'Máximo de Iterações';
      case 'convergence_tolerance':
        return 'Tolerância de Convergência';
      case 'ambient_temperature':
        return 'Temperatura Ambiente';
      default:
        return paramName;
    }
  }

  String _getStudyConclusions() {
    if (_studyResult == null) {
      return '';
    }
    
    // Identificar parâmetros mais sensíveis
    final sensitivePairs = _studyResult!.sensitivityAnalysis.entries.toList();
    sensitivePairs.sort((a, b) => b.value.abs().compareTo(a.value.abs()));
    
    final mostSensitiveParams = sensitivePairs
        .where((entry) => entry.value.abs() > 0.5)
        .map((entry) => _formatParameterName(entry.key))
        .toList();
    
    if (mostSensitiveParams.isNotEmpty) {
      return 'O estudo paramétrico identificou que os parâmetros mais influentes na '
             '${_studyResult!.config.optimizationGoal == OptimizationGoal.maximize ? "maximização" : "minimização"} '
             'da métrica alvo (${_formatMetricName(_studyResult!.config.targetMetric)}) são: '
             '${mostSensitiveParams.join(", ")}. '
             'Estes parâmetros devem ser controlados com maior precisão para obter resultados consistentes.';
    } else {
      return 'O estudo paramétrico não identificou parâmetros com alta sensibilidade em relação à métrica alvo '
             '(${_formatMetricName(_studyResult!.config.targetMetric)}). '
             'Isso sugere que a métrica é robusta em relação às variações dos parâmetros testados, '
             'ou que as faixas de variação utilizadas foram insuficientes para capturar a sensibilidade.';
    }
  }

  String _getStudyRecommendations() {
    if (_studyResult == null) {
      return '';
    }
    
    // Calcular melhoria em relação à média
    final avgMetric = _studyResult!.simulationResults
        .map((r) => r.targetMetricValue)
        .reduce((a, b) => a + b) / _studyResult!.simulationResults.length;
    
    final bestMetric = _studyResult!.bestConfiguration.targetMetricValue;
    
    double improvementPercent;
    if (_studyResult!.config.optimizationGoal == OptimizationGoal.maximize) {
      improvementPercent = avgMetric > 0 ? (bestMetric - avgMetric) / avgMetric * 100 : 0;
    } else {
      improvementPercent = avgMetric > 0 ? (avgMetric - bestMetric) / avgMetric * 100 : 0;
    }
    
    return 'A melhor configuração encontrada resultou em um valor de ${bestMetric.toStringAsFixed(2)} '
           'para a métrica alvo, o que representa um '
           '${_studyResult!.config.optimizationGoal == OptimizationGoal.maximize ? "aumento" : "redução"} '
           'de ${improvementPercent.toStringAsFixed(1)}% em relação à média das configurações testadas. '
           'Recomenda-se realizar estudos adicionais com faixas mais estreitas em torno dos valores ótimos '
           'para refinar ainda mais a configuração.';
  }
}
