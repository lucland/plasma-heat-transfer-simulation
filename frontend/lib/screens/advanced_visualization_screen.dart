import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_gl/flutter_gl.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:convert';

import '../models/simulation_results.dart';
import '../state/simulation_state.dart';
import '../services/ffi_bridge.dart';
import '../widgets/visualization/color_scale_widget.dart';
import '../widgets/visualization/visualization_controls.dart';

class AdvancedVisualizationScreen extends ConsumerStatefulWidget {
  const AdvancedVisualizationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdvancedVisualizationScreen> createState() => _AdvancedVisualizationScreenState();
}

class _AdvancedVisualizationScreenState extends ConsumerState<AdvancedVisualizationScreen> {
  // Controladores para visualização 3D
  FlutterGlPlugin? _flutterGlPlugin;
  int _viewportWidth = 0;
  int _viewportHeight = 0;
  
  // Estado da visualização
  String _visualizationMode = '3D';
  String _sliceType = 'Axial';
  double _slicePosition = 0.5;
  int _currentTimeStep = 0;
  bool _showGrid = true;
  bool _showTorches = true;
  bool _showHeatFlux = false;
  bool _showIsosurfaces = false;
  String _colorScale = 'BlueToRed';
  double _opacity = 1.0;
  double _rotationX = 0.0;
  double _rotationY = 0.0;
  double _rotationZ = 0.0;
  double _zoom = 1.0;
  
  // Dados de visualização
  Map<String, dynamic>? _visualizationData;
  
  @override
  void initState() {
    super.initState();
    _initializeVisualization();
  }
  
  @override
  void dispose() {
    _flutterGlPlugin?.dispose();
    super.dispose();
  }
  
  Future<void> _initializeVisualization() async {
    // Inicializar FlutterGL
    _flutterGlPlugin = FlutterGlPlugin();
    
    // Carregar dados de visualização iniciais
    await _loadVisualizationData();
  }
  
  Future<void> _loadVisualizationData() async {
    final simulationState = ref.read(simulationStateProvider);
    
    if (simulationState.results == null) {
      return;
    }
    
    // Obter dados de visualização do backend via FFI
    final ffiBridge = FFIBridge();
    
    try {
      String jsonData;
      
      if (_visualizationMode == '3D') {
        jsonData = await ffiBridge.getVisualizationData3D(
          _currentTimeStep,
          _showGrid,
          _showTorches,
          _colorScale,
        );
      } else if (_visualizationMode == 'Slice') {
        jsonData = await ffiBridge.getSliceVisualizationData(
          _sliceType,
          _slicePosition,
          _currentTimeStep,
          _showGrid,
          _colorScale,
        );
      } else if (_visualizationMode == 'HeatFlux') {
        jsonData = await ffiBridge.getHeatFluxVisualizationData(
          _currentTimeStep,
          _colorScale,
        );
      } else {
        return;
      }
      
      setState(() {
        _visualizationData = json.decode(jsonData);
      });
      
      // Renderizar visualização
      _renderVisualization();
    } catch (e) {
      print('Erro ao carregar dados de visualização: $e');
    }
  }
  
  void _renderVisualization() {
    if (_visualizationData == null || _flutterGlPlugin == null) {
      return;
    }
    
    // Implementação da renderização 3D usando FlutterGL
    // Esta é uma implementação simplificada para demonstração
    
    if (_visualizationMode == '3D') {
      _render3DVisualization();
    } else if (_visualizationMode == 'Slice') {
      _renderSliceVisualization();
    } else if (_visualizationMode == 'HeatFlux') {
      _renderHeatFluxVisualization();
    }
  }
  
  void _render3DVisualization() {
    // Implementação da renderização 3D
    // Em uma implementação real, usaríamos WebGL via FlutterGL
  }
  
  void _renderSliceVisualization() {
    // Implementação da renderização de corte
  }
  
  void _renderHeatFluxVisualization() {
    // Implementação da renderização de fluxo de calor
  }
  
  void _updateVisualizationMode(String mode) {
    setState(() {
      _visualizationMode = mode;
    });
    _loadVisualizationData();
  }
  
  void _updateSliceType(String type) {
    setState(() {
      _sliceType = type;
    });
    if (_visualizationMode == 'Slice') {
      _loadVisualizationData();
    }
  }
  
  void _updateSlicePosition(double position) {
    setState(() {
      _slicePosition = position;
    });
    if (_visualizationMode == 'Slice') {
      _loadVisualizationData();
    }
  }
  
  void _updateTimeStep(int step) {
    setState(() {
      _currentTimeStep = step;
    });
    _loadVisualizationData();
  }
  
  void _updateColorScale(String scale) {
    setState(() {
      _colorScale = scale;
    });
    _loadVisualizationData();
  }
  
  void _updateShowGrid(bool show) {
    setState(() {
      _showGrid = show;
    });
    _loadVisualizationData();
  }
  
  void _updateShowTorches(bool show) {
    setState(() {
      _showTorches = show;
    });
    _loadVisualizationData();
  }
  
  void _updateShowHeatFlux(bool show) {
    setState(() {
      _showHeatFlux = show;
    });
    _loadVisualizationData();
  }
  
  void _updateShowIsosurfaces(bool show) {
    setState(() {
      _showIsosurfaces = show;
    });
    _loadVisualizationData();
  }
  
  void _updateOpacity(double opacity) {
    setState(() {
      _opacity = opacity;
    });
    _renderVisualization();
  }
  
  void _updateRotation(double x, double y, double z) {
    setState(() {
      _rotationX = x;
      _rotationY = y;
      _rotationZ = z;
    });
    _renderVisualization();
  }
  
  void _updateZoom(double zoom) {
    setState(() {
      _zoom = zoom;
    });
    _renderVisualization();
  }
  
  @override
  Widget build(BuildContext context) {
    final simulationState = ref.watch(simulationStateProvider);
    final results = simulationState.results;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visualização Avançada'),
      ),
      body: results == null
          ? const Center(child: Text('Nenhum resultado de simulação disponível'))
          : Column(
              children: [
                _buildVisualizationControls(),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildVisualizationView(),
                      ),
                      Expanded(
                        flex: 1,
                        child: _buildSidePanel(),
                      ),
                    ],
                  ),
                ),
                _buildTimeControls(results),
              ],
            ),
    );
  }
  
  Widget _buildVisualizationControls() {
    return VisualizationControls(
      visualizationMode: _visualizationMode,
      sliceType: _sliceType,
      slicePosition: _slicePosition,
      showGrid: _showGrid,
      showTorches: _showTorches,
      showHeatFlux: _showHeatFlux,
      showIsosurfaces: _showIsosurfaces,
      colorScale: _colorScale,
      onVisualizationModeChanged: _updateVisualizationMode,
      onSliceTypeChanged: _updateSliceType,
      onSlicePositionChanged: _updateSlicePosition,
      onShowGridChanged: _updateShowGrid,
      onShowTorchesChanged: _updateShowTorches,
      onShowHeatFluxChanged: _updateShowHeatFlux,
      onShowIsosurfacesChanged: _updateShowIsosurfaces,
      onColorScaleChanged: _updateColorScale,
    );
  }
  
  Widget _buildVisualizationView() {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          _viewportWidth = constraints.maxWidth.toInt();
          _viewportHeight = constraints.maxHeight.toInt();
          
          return Stack(
            children: [
              // Visualização principal
              Center(
                child: _visualizationData == null
                    ? const CircularProgressIndicator()
                    : _buildVisualizationWidget(),
              ),
              
              // Escala de cores
              Positioned(
                right: 16,
                top: 16,
                bottom: 16,
                child: ColorScaleWidget(
                  colorScale: _colorScale,
                  minValue: _visualizationData?['range']?[0] ?? 0.0,
                  maxValue: _visualizationData?['range']?[1] ?? 100.0,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildVisualizationWidget() {
    if (_visualizationMode == '3D') {
      // Placeholder para visualização 3D
      return GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _rotationY += details.delta.dx * 0.01;
            _rotationX += details.delta.dy * 0.01;
          });
          _renderVisualization();
        },
        onScaleUpdate: (details) {
          setState(() {
            _zoom = (_zoom * details.scale).clamp(0.5, 5.0);
          });
          _renderVisualization();
        },
        child: Container(
          width: _viewportWidth.toDouble(),
          height: _viewportHeight.toDouble(),
          color: Colors.black,
          child: const Center(
            child: Text(
              'Visualização 3D',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
    } else if (_visualizationMode == 'Slice') {
      // Placeholder para visualização de corte
      return Container(
        width: _viewportWidth.toDouble(),
        height: _viewportHeight.toDouble(),
        color: Colors.black,
        child: Center(
          child: Text(
            'Visualização de Corte: $_sliceType',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    } else if (_visualizationMode == 'HeatFlux') {
      // Placeholder para visualização de fluxo de calor
      return Container(
        width: _viewportWidth.toDouble(),
        height: _viewportHeight.toDouble(),
        color: Colors.black,
        child: const Center(
          child: Text(
            'Visualização de Fluxo de Calor',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
    
    return const SizedBox.shrink();
  }
  
  Widget _buildSidePanel() {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Controles de Visualização',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Controles de opacidade
            const Text('Opacidade:'),
            Slider(
              value: _opacity,
              min: 0.1,
              max: 1.0,
              divisions: 9,
              label: _opacity.toStringAsFixed(1),
              onChanged: _updateOpacity,
            ),
            
            const SizedBox(height: 16),
            
            // Controles de rotação (apenas para 3D)
            if (_visualizationMode == '3D') ...[
              const Text('Rotação X:'),
              Slider(
                value: _rotationX,
                min: -math.pi,
                max: math.pi,
                onChanged: (value) => _updateRotation(value, _rotationY, _rotationZ),
              ),
              
              const Text('Rotação Y:'),
              Slider(
                value: _rotationY,
                min: -math.pi,
                max: math.pi,
                onChanged: (value) => _updateRotation(_rotationX, value, _rotationZ),
              ),
              
              const Text('Rotação Z:'),
              Slider(
                value: _rotationZ,
                min: -math.pi,
                max: math.pi,
                onChanged: (value) => _updateRotation(_rotationX, _rotationY, value),
              ),
              
              const Text('Zoom:'),
              Slider(
                value: _zoom,
                min: 0.5,
                max: 5.0,
                onChanged: _updateZoom,
              ),
            ],
            
            const Spacer(),
            
            // Informações da simulação
            const Text(
              'Informações',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Passo de tempo: $_currentTimeStep'),
            if (_visualizationData != null && _visualizationData!.containsKey('range'))
              Text('Temperatura: ${_visualizationData!['range'][0].toStringAsFixed(1)} - ${_visualizationData!['range'][1].toStringAsFixed(1)} °C'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTimeControls(SimulationResults results) {
    final maxTimeStep = results.timeSteps - 1;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous),
                onPressed: () => _updateTimeStep(0),
              ),
              IconButton(
                icon: const Icon(Icons.fast_rewind),
                onPressed: _currentTimeStep > 0
                    ? () => _updateTimeStep(_currentTimeStep - 5)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _currentTimeStep > 0
                    ? () => _updateTimeStep(_currentTimeStep - 1)
                    : null,
              ),
              Expanded(
                child: Slider(
                  value: _currentTimeStep.toDouble(),
                  min: 0,
                  max: maxTimeStep.toDouble(),
                  divisions: maxTimeStep,
                  label: 'Passo ${_currentTimeStep + 1}/${maxTimeStep + 1}',
                  onChanged: (value) => _updateTimeStep(value.toInt()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: _currentTimeStep < maxTimeStep
                    ? () => _updateTimeStep(_currentTimeStep + 1)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.fast_forward),
                onPressed: _currentTimeStep < maxTimeStep - 5
                    ? () => _updateTimeStep(_currentTimeStep + 5)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.skip_next),
                onPressed: () => _updateTimeStep(maxTimeStep),
              ),
            ],
          ),
          Text(
            'Tempo: ${(_currentTimeStep * results.timeStep).toStringAsFixed(1)} s / ${results.totalTime.toStringAsFixed(1)} s',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
