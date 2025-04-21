import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'dart:io';

import '../models/simulation_results.dart';
import '../models/metrics.dart';
import '../state/simulation_state.dart';
import '../services/ffi_bridge.dart';
import '../widgets/metrics/metric_card.dart';
import '../widgets/metrics/temperature_chart.dart';
import '../widgets/metrics/region_metrics_table.dart';

class MetricsScreen extends ConsumerStatefulWidget {
  const MetricsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MetricsScreen> createState() => _MetricsScreenState();
}

class _MetricsScreenState extends ConsumerState<MetricsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  SimulationMetrics? _metrics;
  bool _isLoading = false;
  String? _error;
  
  // Estado para exportação
  bool _isExporting = false;
  String _exportFormat = 'CSV';
  bool _includeMetrics = true;
  bool _includeTemperature = true;
  bool _includeGradient = false;
  bool _includeHeatFlux = false;
  bool _includeMetadata = true;
  String _exportPath = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMetrics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMetrics() async {
    final simulationState = ref.read(simulationStateProvider);
    
    if (simulationState.results == null) {
      setState(() {
        _error = 'Nenhum resultado de simulação disponível';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final ffiBridge = FFIBridge();
      final metrics = await ffiBridge.calculateMetrics();
      
      setState(() {
        _metrics = metrics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erro ao calcular métricas: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _exportResults() async {
    final simulationState = ref.read(simulationStateProvider);
    
    if (simulationState.results == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum resultado de simulação disponível para exportar')),
      );
      return;
    }
    
    setState(() {
      _isExporting = true;
    });
    
    try {
      final ffiBridge = FFIBridge();
      
      // Determinar formato de exportação
      final format = _exportFormat;
      
      // Determinar caminho de exportação
      final path = _exportPath.isNotEmpty 
          ? _exportPath 
          : '/tmp/simulation_results.${format.toLowerCase()}';
      
      // Configurar opções de exportação
      final options = ExportOptions(
        format: format,
        outputPath: path,
        includeMetrics: _includeMetrics,
        includeTemperature: _includeTemperature,
        includeGradient: _includeGradient,
        includeHeatFlux: _includeHeatFlux,
        includeMetadata: _includeMetadata,
      );
      
      // Exportar resultados
      await ffiBridge.exportResults(options);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Resultados exportados com sucesso para $path')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao exportar resultados: $e')),
        );
      }
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  Future<void> _generateReport() async {
    final simulationState = ref.read(simulationStateProvider);
    
    if (simulationState.results == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum resultado de simulação disponível para gerar relatório')),
      );
      return;
    }
    
    setState(() {
      _isExporting = true;
    });
    
    try {
      final ffiBridge = FFIBridge();
      
      // Determinar caminho do relatório
      const path = '/tmp/simulation_report.md';
      
      // Gerar relatório
      await ffiBridge.generateReport(path);
      
      if (mounted) {
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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao gerar relatório: $e')),
        );
      }
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final simulationState = ref.watch(simulationStateProvider);
    final results = simulationState.results;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Métricas e Exportação'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Visão Geral'),
            Tab(text: 'Análise Detalhada'),
            Tab(text: 'Exportação'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recalcular Métricas',
            onPressed: _isLoading ? null : _loadMetrics,
          ),
          IconButton(
            icon: const Icon(Icons.description),
            tooltip: 'Gerar Relatório',
            onPressed: _isLoading || _metrics == null ? null : _generateReport,
          ),
        ],
      ),
      body: results == null
          ? const Center(child: Text('Nenhum resultado de simulação disponível'))
          : _error != null
              ? Center(child: Text(_error!))
              : _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverviewTab(),
                        _buildDetailedAnalysisTab(),
                        _buildExportTab(),
                      ],
                    ),
    );
  }

  Widget _buildOverviewTab() {
    if (_metrics == null) {
      return const Center(child: Text('Métricas não disponíveis'));
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Métricas Globais',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          // Cartões de métricas principais
          GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              MetricCard(
                title: 'Temperatura Mínima',
                value: '${_metrics!.minTemperature.toStringAsFixed(1)} °C',
                icon: Icons.arrow_downward,
                color: Colors.blue,
              ),
              MetricCard(
                title: 'Temperatura Máxima',
                value: '${_metrics!.maxTemperature.toStringAsFixed(1)} °C',
                icon: Icons.arrow_upward,
                color: Colors.red,
              ),
              MetricCard(
                title: 'Temperatura Média',
                value: '${_metrics!.avgTemperature.toStringAsFixed(1)} °C',
                icon: Icons.equalizer,
                color: Colors.orange,
              ),
              MetricCard(
                title: 'Desvio Padrão',
                value: '${_metrics!.stdTemperature.toStringAsFixed(1)} °C',
                icon: Icons.show_chart,
                color: Colors.purple,
              ),
              MetricCard(
                title: 'Gradiente Máximo',
                value: '${_metrics!.maxGradient.toStringAsFixed(1)} °C/m',
                icon: Icons.trending_up,
                color: Colors.green,
              ),
              MetricCard(
                title: 'Fluxo de Calor Máximo',
                value: '${_metrics!.maxHeatFlux.toStringAsFixed(1)} W/m²',
                icon: Icons.waves,
                color: Colors.amber,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          Text(
            'Métricas Temporais',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          // Cartões de métricas temporais
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              MetricCard(
                title: 'Tempo para 50% da Temperatura Máxima',
                value: '${_metrics!.temporalMetrics.timeToHalfMax.toStringAsFixed(1)} s',
                icon: Icons.hourglass_half,
                color: Colors.teal,
              ),
              MetricCard(
                title: 'Tempo para 90% da Temperatura Máxima',
                value: '${_metrics!.temporalMetrics.timeTo90PercentMax.toStringAsFixed(1)} s',
                icon: Icons.hourglass_full,
                color: Colors.teal.shade700,
              ),
              MetricCard(
                title: 'Taxa de Aquecimento Máxima',
                value: '${_metrics!.temporalMetrics.maxHeatingRate.toStringAsFixed(1)} °C/s',
                icon: Icons.local_fire_department,
                color: Colors.deepOrange,
              ),
              MetricCard(
                title: 'Tempo de Estabilização',
                value: '${_metrics!.temporalMetrics.stabilizationTime.toStringAsFixed(1)} s',
                icon: Icons.access_time,
                color: Colors.indigo,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          Text(
            'Métricas por Região',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          // Tabela de métricas por região
          RegionMetricsTable(regionMetrics: _metrics!.regionMetrics),
          
          const SizedBox(height: 24),
          Text(
            'Evolução da Temperatura',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          // Gráfico de evolução da temperatura
          SizedBox(
            height: 300,
            child: TemperatureChart(
              simulationResults: ref.read(simulationStateProvider).results!,
              metrics: _metrics!,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedAnalysisTab() {
    if (_metrics == null) {
      return const Center(child: Text('Métricas não disponíveis'));
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Análise de Distribuição de Temperatura',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          // Histograma de temperatura (simplificado)
          SizedBox(
            height: 300,
            child: _buildTemperatureHistogram(),
          ),
          
          const SizedBox(height: 24),
          Text(
            'Análise de Energia',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          // Cartões de energia
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              MetricCard(
                title: 'Energia Total',
                value: '${(_metrics!.totalEnergy / 1000).toStringAsFixed(1)} kJ',
                icon: Icons.bolt,
                color: Colors.amber,
              ),
              MetricCard(
                title: 'Taxa de Aquecimento Média',
                value: '${_metrics!.avgHeatingRate.toStringAsFixed(1)} °C/s',
                icon: Icons.trending_up,
                color: Colors.red,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          Text(
            'Análise de Eficiência',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          // Análise de eficiência (simplificada)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Uniformidade de Temperatura',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: 1.0 - (_metrics!.stdTemperature / _metrics!.avgTemperature).clamp(0.0, 1.0),
                    backgroundColor: Colors.red.shade100,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _metrics!.stdTemperature / _metrics!.avgTemperature < 0.1
                          ? Colors.green
                          : _metrics!.stdTemperature / _metrics!.avgTemperature < 0.2
                              ? Colors.amber
                              : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _metrics!.stdTemperature / _metrics!.avgTemperature < 0.1
                        ? 'Excelente uniformidade (desvio < 10% da média)'
                        : _metrics!.stdTemperature / _metrics!.avgTemperature < 0.2
                            ? 'Boa uniformidade (desvio < 20% da média)'
                            : 'Baixa uniformidade (desvio > 20% da média)',
                  ),
                  
                  const SizedBox(height: 16),
                  const Text(
                    'Tempo de Aquecimento',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: 1.0 - (_metrics!.temporalMetrics.timeTo90PercentMax / 100.0).clamp(0.0, 1.0),
                    backgroundColor: Colors.red.shade100,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _metrics!.temporalMetrics.timeTo90PercentMax < 30.0
                          ? Colors.green
                          : _metrics!.temporalMetrics.timeTo90PercentMax < 60.0
                              ? Colors.amber
                              : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _metrics!.temporalMetrics.timeTo90PercentMax < 30.0
                        ? 'Aquecimento rápido (< 30s para 90% da temperatura máxima)'
                        : _metrics!.temporalMetrics.timeTo90PercentMax < 60.0
                            ? 'Aquecimento moderado (< 60s para 90% da temperatura máxima)'
                            : 'Aquecimento lento (> 60s para 90% da temperatura máxima)',
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          Text(
            'Conclusões',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          // Conclusões
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'A simulação atingiu uma temperatura máxima de ${_metrics!.maxTemperature.toStringAsFixed(1)} °C. '
                    'A temperatura média final foi de ${_metrics!.avgTemperature.toStringAsFixed(1)} °C, com um desvio padrão de ${_metrics!.stdTemperature.toStringAsFixed(1)} °C, '
                    'indicando uma distribuição de temperatura ${_metrics!.stdTemperature / _metrics!.avgTemperature < 0.1 ? "relativamente uniforme" : "não uniforme"}. '
                    'O sistema atingiu 90% da temperatura máxima em ${_metrics!.temporalMetrics.timeTo90PercentMax.toStringAsFixed(1)} segundos e estabilizou após ${_metrics!.temporalMetrics.stabilizationTime.toStringAsFixed(1)} segundos.',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'O fluxo de calor máximo foi de ${_metrics!.maxHeatFlux.toStringAsFixed(1)} W/m², localizado na região de maior gradiente de temperatura (${_metrics!.maxGradient.toStringAsFixed(1)} °C/m). '
                    'A energia total armazenada no sistema foi de ${(_metrics!.totalEnergy / 1000).toStringAsFixed(1)} kJ.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Exportação de Resultados',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          // Formato de exportação
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Formato de Exportação',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment<String>(
                        value: 'CSV',
                        label: Text('CSV'),
                        icon: Icon(Icons.table_chart),
                      ),
                      ButtonSegment<String>(
                        value: 'JSON',
                        label: Text('JSON'),
                        icon: Icon(Icons.code),
                      ),
                      ButtonSegment<String>(
                        value: 'VTK',
                        label: Text('VTK'),
                        icon: Icon(Icons.view_in_ar),
                      ),
                    ],
                    selected: {_exportFormat},
                    onSelectionChanged: (Set<String> selection) {
                      if (selection.isNotEmpty) {
                        setState(() {
                          _exportFormat = selection.first;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Caminho de Exportação',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    decoration: InputDecoration(
                      hintText: '/tmp/simulation_results.${_exportFormat.toLowerCase()}',
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(Icons.folder_open),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _exportPath = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Opções de exportação
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Opções de Exportação',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: const Text('Incluir Métricas'),
                    value: _includeMetrics,
                    onChanged: (value) {
                      setState(() {
                        _includeMetrics = value ?? true;
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Incluir Dados de Temperatura'),
                    value: _includeTemperature,
                    onChanged: (value) {
                      setState(() {
                        _includeTemperature = value ?? true;
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Incluir Dados de Gradiente'),
                    value: _includeGradient,
                    onChanged: (value) {
                      setState(() {
                        _includeGradient = value ?? false;
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Incluir Dados de Fluxo de Calor'),
                    value: _includeHeatFlux,
                    onChanged: (value) {
                      setState(() {
                        _includeHeatFlux = value ?? false;
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Incluir Metadados'),
                    value: _includeMetadata,
                    onChanged: (value) {
                      setState(() {
                        _includeMetadata = value ?? true;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Botão de exportação
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: Text(_isExporting ? 'Exportando...' : 'Exportar Resultados'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              onPressed: _isExporting ? null : _exportResults,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Geração de relatório
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Geração de Relatório',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Gere um relatório completo com análise detalhada dos resultados da simulação. '
                    'O relatório inclui métricas, gráficos e conclusões em formato Markdown.',
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.description),
                      label: Text(_isExporting ? 'Gerando...' : 'Gerar Relatório'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      onPressed: _isExporting || _metrics == null ? null : _generateReport,
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

  Widget _buildTemperatureHistogram() {
    // Dados simplificados para o histograma
    final simulationState = ref.read(simulationStateProvider);
    if (simulationState.results == null) {
      return const Center(child: Text('Dados não disponíveis'));
    }
    
    // Criar dados do histograma (simplificado)
    final minTemp = _metrics!.minTemperature;
    final maxTemp = _metrics!.maxTemperature;
    final range = maxTemp - minTemp;
    final binSize = range / 10;
    
    final bins = List.generate(10, (i) => 0.0);
    
    // Preencher bins com dados sintéticos
    // Em uma implementação real, usaríamos os dados reais da simulação
    bins[0] = 5.0;
    bins[1] = 8.0;
    bins[2] = 12.0;
    bins[3] = 18.0;
    bins[4] = 25.0;
    bins[5] = 20.0;
    bins[6] = 15.0;
    bins[7] = 10.0;
    bins[8] = 7.0;
    bins[9] = 3.0;
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: bins.reduce((a, b) => a > b ? a : b) * 1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueGrey,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final binStart = minTemp + groupIndex * binSize;
              final binEnd = binStart + binSize;
              return BarTooltipItem(
                '${binStart.toStringAsFixed(1)} - ${binEnd.toStringAsFixed(1)} °C\n${rod.toY.toInt()} células',
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value % 2 == 0) {
                  final temp = minTemp + value * binSize;
                  return Text(
                    temp.toStringAsFixed(0),
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value % 5 == 0) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 30,
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300),
        ),
        barGroups: bins.asMap().entries.map((entry) {
          final index = entry.key;
          final value = entry.value;
          
          // Cor baseada na temperatura
          final temp = minTemp + index * binSize + binSize / 2;
          final ratio = (temp - minTemp) / range;
          final color = ColorTween(
            begin: Colors.blue,
            end: Colors.red,
          ).lerp(ratio)!;
          
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: value,
                color: color,
                width: 15,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
