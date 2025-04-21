import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';

import '../models/validation.dart';
import '../models/simulation_results.dart';
import '../state/simulation_state.dart';
import '../services/validation_ffi_bridge.dart';
import '../widgets/validation/error_metrics_card.dart';
import '../widgets/validation/scatter_plot.dart';
import '../widgets/validation/region_validation_table.dart';

class ModelValidationScreen extends ConsumerStatefulWidget {
  const ModelValidationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ModelValidationScreen> createState() => _ModelValidationScreenState();
}

class _ModelValidationScreenState extends ConsumerState<ModelValidationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ReferenceData? _referenceData;
  ValidationResult? _validationResult;
  bool _isLoading = false;
  String? _error;
  
  // Estado para importação
  bool _isImporting = false;
  String _importFormat = 'CSV';
  bool _hasHeader = true;
  String _delimiter = ',';
  String _rColumn = '0';
  String _thetaColumn = '1';
  String _zColumn = '2';
  String _valueColumn = '3';
  String _uncertaintyColumn = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _importReferenceData() async {
    final simulationState = ref.read(simulationStateProvider);
    
    if (simulationState.results == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum resultado de simulação disponível para validação')),
      );
      return;
    }
    
    setState(() {
      _isImporting = true;
      _error = null;
    });
    
    try {
      // Abrir seletor de arquivo
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'json'],
      );
      
      if (result == null || result.files.isEmpty) {
        setState(() {
          _isImporting = false;
        });
        return;
      }
      
      final file = result.files.first;
      final path = file.path;
      
      if (path == null) {
        throw Exception('Caminho do arquivo inválido');
      }
      
      // Determinar formato de importação
      final format = _importFormat;
      
      // Configurar opções de importação
      final options = ImportOptions(
        format: format,
        inputPath: path,
        delimiter: _delimiter,
        hasHeader: _hasHeader,
        coordinateColumns: format == 'CSV' 
            ? [int.parse(_rColumn), int.parse(_thetaColumn), int.parse(_zColumn)]
            : null,
        valueColumn: format == 'CSV' ? int.parse(_valueColumn) : null,
        uncertaintyColumn: _uncertaintyColumn.isNotEmpty ? int.parse(_uncertaintyColumn) : null,
      );
      
      // Importar dados de referência
      final ffiBridge = ValidationFFIBridge();
      final referenceData = await ffiBridge.importReferenceData(options);
      
      setState(() {
        _referenceData = referenceData;
        _isImporting = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dados de referência importados com sucesso: ${referenceData.name}')),
      );
    } catch (e) {
      setState(() {
        _error = 'Erro ao importar dados de referência: $e';
        _isImporting = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao importar dados de referência: $e')),
      );
    }
  }

  Future<void> _createSyntheticData() async {
    final simulationState = ref.read(simulationStateProvider);
    
    if (simulationState.results == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum resultado de simulação disponível para validação')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // Criar dados sintéticos
      final ffiBridge = ValidationFFIBridge();
      final referenceData = await ffiBridge.createSyntheticReferenceData(100, 0.05);
      
      setState(() {
        _referenceData = referenceData;
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dados sintéticos criados com sucesso: ${referenceData.name}')),
      );
    } catch (e) {
      setState(() {
        _error = 'Erro ao criar dados sintéticos: $e';
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar dados sintéticos: $e')),
      );
    }
  }

  Future<void> _validateModel() async {
    if (_referenceData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum dado de referência disponível para validação')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // Validar modelo
      final ffiBridge = ValidationFFIBridge();
      final validationResult = await ffiBridge.validateModel(
        'Validação do Modelo',
        'Validação do modelo de simulação de fornalha de plasma',
      );
      
      setState(() {
        _validationResult = validationResult;
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Modelo validado com sucesso')),
      );
    } catch (e) {
      setState(() {
        _error = 'Erro ao validar modelo: $e';
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao validar modelo: $e')),
      );
    }
  }

  Future<void> _generateReport() async {
    if (_validationResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum resultado de validação disponível para gerar relatório')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Gerar relatório
      final ffiBridge = ValidationFFIBridge();
      const path = '/tmp/validation_report.md';
      await ffiBridge.generateValidationReport(path);
      
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
    final simulationState = ref.watch(simulationStateProvider);
    final results = simulationState.results;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validação de Modelos'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Dados de Referência'),
            Tab(text: 'Resultados da Validação'),
            Tab(text: 'Análise Detalhada'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.description),
            tooltip: 'Gerar Relatório',
            onPressed: _isLoading || _validationResult == null ? null : _generateReport,
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
                        _buildReferenceDataTab(),
                        _buildValidationResultsTab(),
                        _buildDetailedAnalysisTab(),
                      ],
                    ),
      floatingActionButton: _tabController.index == 0
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'importData',
                  onPressed: _isImporting ? null : _importReferenceData,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Importar Dados'),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.extended(
                  heroTag: 'createSynthetic',
                  onPressed: _isLoading ? null : _createSyntheticData,
                  icon: const Icon(Icons.science),
                  label: const Text('Dados Sintéticos'),
                ),
              ],
            )
          : _tabController.index == 1 && _referenceData != null && _validationResult == null
              ? FloatingActionButton.extended(
                  onPressed: _isLoading ? null : _validateModel,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Validar Modelo'),
                )
              : null,
    );
  }

  Widget _buildReferenceDataTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dados de Referência',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          // Configurações de importação
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Configurações de Importação',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  
                  // Formato de importação
                  const Text(
                    'Formato de Arquivo',
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
                    ],
                    selected: {_importFormat},
                    onSelectionChanged: (Set<String> selection) {
                      if (selection.isNotEmpty) {
                        setState(() {
                          _importFormat = selection.first;
                        });
                      }
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Opções específicas para CSV
                  if (_importFormat == 'CSV') ...[
                    Row(
                      children: [
                        Expanded(
                          child: CheckboxListTile(
                            title: const Text('Tem Cabeçalho'),
                            value: _hasHeader,
                            onChanged: (value) {
                              setState(() {
                                _hasHeader = value ?? true;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            title: const Text('Delimitador'),
                            trailing: SizedBox(
                              width: 50,
                              child: TextField(
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                ),
                                initialValue: _delimiter,
                                onChanged: (value) {
                                  if (value.isNotEmpty) {
                                    setState(() {
                                      _delimiter = value[0];
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    const Text(
                      'Índices de Colunas (começando em 0)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Coluna R',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            initialValue: _rColumn,
                            onChanged: (value) {
                              setState(() {
                                _rColumn = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Coluna Theta',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            initialValue: _thetaColumn,
                            onChanged: (value) {
                              setState(() {
                                _thetaColumn = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Coluna Z',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            initialValue: _zColumn,
                            onChanged: (value) {
                              setState(() {
                                _zColumn = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Coluna Valor',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            initialValue: _valueColumn,
                            onChanged: (value) {
                              setState(() {
                                _valueColumn = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              labelText: 'Coluna Incerteza (opcional)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            initialValue: _uncertaintyColumn,
                            onChanged: (value) {
                              setState(() {
                                _uncertaintyColumn = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Dados de referência carregados
          if (_referenceData != null) ...[
            Text(
              'Dados Carregados',
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
                      title: const Text('Nome'),
                      subtitle: Text(_referenceData!.name),
                    ),
                    ListTile(
                      title: const Text('Descrição'),
                      subtitle: Text(_referenceData!.description),
                    ),
                    ListTile(
                      title: const Text('Fonte'),
                      subtitle: Text(_referenceData!.source),
                    ),
                    ListTile(
                      title: const Text('Tipo de Dados'),
                      subtitle: Text(_referenceData!.dataType),
                    ),
                    ListTile(
                      title: const Text('Número de Pontos'),
                      subtitle: Text(_referenceData!.coordinates.length.toString()),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Visualização dos dados
            Text(
              'Visualização dos Dados',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            
            SizedBox(
              height: 300,
              child: _buildReferenceDataVisualization(),
            ),
            
            const SizedBox(height: 16),
            
            // Tabela de dados (primeiros 10 pontos)
            Text(
              'Amostra de Dados (primeiros 10 pontos)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('R (m)')),
                  DataColumn(label: Text('Theta (rad)')),
                  DataColumn(label: Text('Z (m)')),
                  DataColumn(label: Text('Valor (°C)')),
                  DataColumn(label: Text('Incerteza')),
                ],
                rows: List.generate(
                  _referenceData!.coordinates.length > 10 ? 10 : _referenceData!.coordinates.length,
                  (index) {
                    final coord = _referenceData!.coordinates[index];
                    final value = _referenceData!.values[index];
                    final uncertainty = _referenceData!.uncertainties != null && index < _referenceData!.uncertainties!.length
                        ? _referenceData!.uncertainties![index]
                        : null;
                    
                    return DataRow(
                      cells: [
                        DataCell(Text(coord[0].toStringAsFixed(3))),
                        DataCell(Text(coord[1].toStringAsFixed(3))),
                        DataCell(Text(coord[2].toStringAsFixed(3))),
                        DataCell(Text(value.toStringAsFixed(2))),
                        DataCell(uncertainty != null ? Text(uncertainty.toStringAsFixed(2)) : const Text('-')),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildValidationResultsTab() {
    if (_referenceData == null) {
      return const Center(
        child: Text('Nenhum dado de referência disponível. Importe dados na aba "Dados de Referência".'),
      );
    }
    
    if (_validationResult == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Clique no botão "Validar Modelo" para iniciar a validação.'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _validateModel,
              icon: const Icon(Icons.check_circle),
              label: const Text('Validar Modelo'),
            ),
          ],
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resultados da Validação',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          // Informações da validação
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: const Text('Nome da Validação'),
                    subtitle: Text(_validationResult!.name),
                  ),
                  ListTile(
                    title: const Text('Descrição'),
                    subtitle: Text(_validationResult!.description),
                  ),
                  ListTile(
                    title: const Text('Conjunto de Dados'),
                    subtitle: Text(_validationResult!.referenceData.name),
                  ),
                  ListTile(
                    title: const Text('Número de Pontos'),
                    subtitle: Text(_validationResult!.referenceData.coordinates.length.toString()),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Métricas de erro
          Text(
            'Métricas de Erro',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          // Cartões de métricas de erro
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              ErrorMetricsCard(
                title: 'Erro Médio Absoluto (MAE)',
                value: '${_validationResult!.metrics.meanAbsoluteError.toStringAsFixed(2)} °C',
                description: 'Média dos valores absolutos dos erros',
                quality: _getErrorQuality(_validationResult!.metrics.meanAbsoluteError, 10.0, 30.0),
              ),
              ErrorMetricsCard(
                title: 'Raiz do Erro Quadrático Médio (RMSE)',
                value: '${_validationResult!.metrics.rootMeanSquaredError.toStringAsFixed(2)} °C',
                description: 'Raiz quadrada da média dos erros ao quadrado',
                quality: _getErrorQuality(_validationResult!.metrics.rootMeanSquaredError, 15.0, 40.0),
              ),
              ErrorMetricsCard(
                title: 'Erro Percentual Absoluto Médio (MAPE)',
                value: '${_validationResult!.metrics.meanAbsolutePercentageError.toStringAsFixed(2)}%',
                description: 'Média dos erros percentuais absolutos',
                quality: _getErrorQuality(_validationResult!.metrics.meanAbsolutePercentageError, 5.0, 15.0),
              ),
              ErrorMetricsCard(
                title: 'Coeficiente de Determinação (R²)',
                value: _validationResult!.metrics.rSquared.toStringAsFixed(3),
                description: 'Proporção da variância explicada pelo modelo',
                quality: _getRSquaredQuality(_validationResult!.metrics.rSquared),
                isHigherBetter: true,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Gráfico de dispersão
          Text(
            'Comparação de Valores',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          SizedBox(
            height: 400,
            child: ScatterPlot(
              referenceValues: _validationResult!.referenceData.values,
              simulatedValues: _validationResult!.simulatedValues,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Métricas por região
          Text(
            'Métricas por Região',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          RegionValidationTable(regionMetrics: _validationResult!.metrics.regionMetrics),
          
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
                    _getConclusionText(),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getRecommendationText(),
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

  Widget _buildDetailedAnalysisTab() {
    if (_validationResult == null) {
      return const Center(
        child: Text('Nenhum resultado de validação disponível. Valide o modelo na aba "Resultados da Validação".'),
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
          
          // Análise de erro por região
          Text(
            'Distribuição de Erro por Região',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          SizedBox(
            height: 300,
            child: _buildRegionErrorChart(),
          ),
          
          const SizedBox(height: 24),
          
          // Análise de correlação
          Text(
            'Análise de Correlação',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: const Text('Coeficiente de Correlação'),
                    subtitle: Text(_validationResult!.metrics.rSquared.sqrt().toStringAsFixed(3)),
                    trailing: Icon(
                      _validationResult!.metrics.rSquared > 0.8
                          ? Icons.check_circle
                          : _validationResult!.metrics.rSquared > 0.5
                              ? Icons.info
                              : Icons.error,
                      color: _validationResult!.metrics.rSquared > 0.8
                          ? Colors.green
                          : _validationResult!.metrics.rSquared > 0.5
                              ? Colors.orange
                              : Colors.red,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  const Text(
                    'Interpretação:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getCorrelationInterpretation(),
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Análise de erro por valor
          Text(
            'Análise de Erro por Valor',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          SizedBox(
            height: 300,
            child: _buildErrorByValueChart(),
          ),
          
          const SizedBox(height: 24),
          
          // Recomendações detalhadas
          Text(
            'Recomendações Detalhadas',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Com base na análise detalhada, recomenda-se:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  // Lista de recomendações
                  ...(_getDetailedRecommendations().map((recommendation) => 
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.arrow_right, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(recommendation)),
                        ],
                      ),
                    )
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceDataVisualization() {
    if (_referenceData == null) {
      return const Center(child: Text('Nenhum dado de referência disponível'));
    }
    
    // Criar dados para visualização 3D simplificada
    // Em uma implementação real, usaríamos uma biblioteca de visualização 3D
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.view_in_ar, size: 64, color: Colors.blue),
              const SizedBox(height: 16),
              Text(
                '${_referenceData!.coordinates.length} pontos de dados',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Faixa de valores: ${_getMinValue().toStringAsFixed(1)} - ${_getMaxValue().toStringAsFixed(1)} °C',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                'Visualização 3D não disponível nesta versão',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegionErrorChart() {
    if (_validationResult == null) {
      return const Center(child: Text('Nenhum resultado de validação disponível'));
    }
    
    final regionNames = _validationResult!.metrics.regionMetrics.keys.toList();
    final rmseValues = regionNames.map((name) => 
      _validationResult!.metrics.regionMetrics[name]!.rootMeanSquaredError
    ).toList();
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: rmseValues.reduce((a, b) => a > b ? a : b) * 1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueGrey,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${regionNames[group.x.toInt()]}\nRMSE: ${rod.toY.toStringAsFixed(2)} °C',
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
                if (value >= 0 && value < regionNames.length) {
                  return Text(
                    regionNames[value.toInt()],
                    style: const TextStyle(fontSize: 12),
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
                if (value % 10 == 0) {
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
        barGroups: List.generate(
          regionNames.length,
          (index) => BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: rmseValues[index],
                color: _getErrorColor(rmseValues[index], 15.0, 40.0),
                width: 20,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorByValueChart() {
    if (_validationResult == null) {
      return const Center(child: Text('Nenhum resultado de validação disponível'));
    }
    
    final referenceValues = _validationResult!.referenceData.values;
    final simulatedValues = _validationResult!.simulatedValues;
    
    // Calcular erros
    final errors = List.generate(
      referenceValues.length,
      (index) => simulatedValues[index] - referenceValues[index],
    );
    
    // Criar pontos para o gráfico
    final spots = List.generate(
      referenceValues.length,
      (index) => FlSpot(referenceValues[index], errors[index]),
    );
    
    // Encontrar limites
    final maxX = referenceValues.reduce((a, b) => a > b ? a : b);
    final minX = referenceValues.reduce((a, b) => a < b ? a : b);
    final maxY = errors.reduce((a, b) => a > b ? a : b);
    final minY = errors.reduce((a, b) => a < b ? a : b);
    final rangeY = (maxY - minY).abs();
    
    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.blueGrey,
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  'Valor: ${spot.x.toStringAsFixed(1)} °C\nErro: ${spot.y.toStringAsFixed(1)} °C',
                  const TextStyle(color: Colors.white),
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 10,
          verticalInterval: 50,
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
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value % 100 == 0) {
                  return Text(
                    '${value.toInt()}°C',
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
                if (value % 10 == 0) {
                  return Text(
                    '${value.toInt()}°C',
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 30,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300),
        ),
        minX: minX - 10,
        maxX: maxX + 10,
        minY: minY - rangeY * 0.1,
        maxY: maxY + rangeY * 0.1,
        lineBarsData: [
          // Linha de erro zero
          LineChartBarData(
            spots: [
              FlSpot(minX - 10, 0),
              FlSpot(maxX + 10, 0),
            ],
            isCurved: false,
            color: Colors.grey,
            barWidth: 1,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: AreaData(show: false),
          ),
          // Pontos de erro
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: Colors.transparent,
            barWidth: 0,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: _getErrorColor(spot.y.abs(), 10.0, 30.0),
                  strokeWidth: 1,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: AreaData(show: false),
          ),
        ],
      ),
    );
  }

  double _getMinValue() {
    if (_referenceData == null || _referenceData!.values.isEmpty) {
      return 0.0;
    }
    
    return _referenceData!.values.reduce((a, b) => a < b ? a : b);
  }

  double _getMaxValue() {
    if (_referenceData == null || _referenceData!.values.isEmpty) {
      return 0.0;
    }
    
    return _referenceData!.values.reduce((a, b) => a > b ? a : b);
  }

  ErrorQuality _getErrorQuality(double error, double goodThreshold, double badThreshold) {
    if (error <= goodThreshold) {
      return ErrorQuality.good;
    } else if (error <= badThreshold) {
      return ErrorQuality.moderate;
    } else {
      return ErrorQuality.poor;
    }
  }

  ErrorQuality _getRSquaredQuality(double rSquared) {
    if (rSquared >= 0.9) {
      return ErrorQuality.good;
    } else if (rSquared >= 0.7) {
      return ErrorQuality.moderate;
    } else {
      return ErrorQuality.poor;
    }
  }

  Color _getErrorColor(double error, double goodThreshold, double badThreshold) {
    if (error <= goodThreshold) {
      return Colors.green;
    } else if (error <= badThreshold) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _getConclusionText() {
    if (_validationResult == null) {
      return '';
    }
    
    final metrics = _validationResult!.metrics;
    
    if (metrics.rSquared > 0.9 && metrics.normalizedRmse < 0.1) {
      return 'O modelo apresenta excelente concordância com os dados de referência. '
             'O erro médio absoluto de ${metrics.meanAbsoluteError.toStringAsFixed(2)} °C e o erro percentual médio de '
             '${metrics.meanAbsolutePercentageError.toStringAsFixed(2)}% indicam que o modelo é adequado para aplicações de alta precisão.';
    } else if (metrics.rSquared > 0.7 && metrics.normalizedRmse < 0.2) {
      return 'O modelo apresenta boa concordância com os dados de referência. '
             'O erro médio absoluto de ${metrics.meanAbsoluteError.toStringAsFixed(2)} °C e o erro percentual médio de '
             '${metrics.meanAbsolutePercentageError.toStringAsFixed(2)}% indicam que o modelo é adequado para a maioria das aplicações práticas.';
    } else {
      return 'O modelo apresenta concordância limitada com os dados de referência. '
             'O erro médio absoluto de ${metrics.meanAbsoluteError.toStringAsFixed(2)} °C e o erro percentual médio de '
             '${metrics.meanAbsolutePercentageError.toStringAsFixed(2)}% indicam que o modelo pode ser inadequado para aplicações que exigem alta precisão.';
    }
  }

  String _getRecommendationText() {
    if (_validationResult == null) {
      return '';
    }
    
    final metrics = _validationResult!.metrics;
    
    if (metrics.rSquared < 0.7) {
      return 'Recomenda-se revisar os parâmetros físicos e refinar a malha de discretização para melhorar a precisão do modelo.';
    } else if (metrics.meanError.abs() > 0.1 * metrics.rootMeanSquaredError) {
      return 'Recomenda-se ajustar os parâmetros do modelo para reduzir o viés sistemático observado.';
    } else {
      return 'Recomenda-se realizar validações adicionais com outros conjuntos de dados para confirmar a robustez do modelo.';
    }
  }

  String _getCorrelationInterpretation() {
    if (_validationResult == null) {
      return '';
    }
    
    final rSquared = _validationResult!.metrics.rSquared;
    final correlation = rSquared.sqrt();
    
    if (correlation > 0.95) {
      return 'Existe uma correlação muito forte entre os valores simulados e os valores de referência, '
             'indicando que o modelo captura com excelência o comportamento do sistema real.';
    } else if (correlation > 0.8) {
      return 'Existe uma correlação forte entre os valores simulados e os valores de referência, '
             'indicando que o modelo captura bem o comportamento do sistema real.';
    } else if (correlation > 0.6) {
      return 'Existe uma correlação moderada entre os valores simulados e os valores de referência, '
             'indicando que o modelo captura razoavelmente o comportamento do sistema real, mas há espaço para melhorias.';
    } else {
      return 'Existe uma correlação fraca entre os valores simulados e os valores de referência, '
             'indicando que o modelo não captura adequadamente o comportamento do sistema real e requer revisão.';
    }
  }

  List<String> _getDetailedRecommendations() {
    if (_validationResult == null) {
      return [];
    }
    
    final metrics = _validationResult!.metrics;
    final recommendations = <String>[];
    
    // Encontrar região com pior desempenho
    String worstRegion = '';
    double worstRmse = 0.0;
    
    for (final entry in metrics.regionMetrics.entries) {
      if (entry.value.rootMeanSquaredError > worstRmse) {
        worstRmse = entry.value.rootMeanSquaredError;
        worstRegion = entry.key;
      }
    }
    
    if (metrics.rSquared < 0.7) {
      recommendations.add('Revisar os parâmetros físicos do modelo, especialmente a condutividade térmica e as propriedades dos materiais.');
      recommendations.add('Refinar a malha de discretização para capturar melhor os gradientes de temperatura.');
    }
    
    if (metrics.meanError.abs() > 0.1 * metrics.rootMeanSquaredError) {
      if (metrics.meanError > 0) {
        recommendations.add('Ajustar os parâmetros do modelo para reduzir a tendência de subestimação dos valores reais.');
      } else {
        recommendations.add('Ajustar os parâmetros do modelo para reduzir a tendência de superestimação dos valores reais.');
      }
    }
    
    if (worstRegion.isNotEmpty) {
      recommendations.add('Focar na melhoria do modelo na região "$worstRegion", que apresenta o maior erro (RMSE de ${worstRmse.toStringAsFixed(2)} °C).');
    }
    
    if (metrics.meanAbsolutePercentageError > 10.0) {
      recommendations.add('Considerar a inclusão de fenômenos físicos adicionais no modelo para melhorar a precisão.');
    }
    
    recommendations.add('Realizar validações adicionais com outros conjuntos de dados para confirmar a robustez do modelo.');
    
    return recommendations;
  }
}
