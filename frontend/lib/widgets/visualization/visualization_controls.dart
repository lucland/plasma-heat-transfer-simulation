import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VisualizationControls extends ConsumerWidget {
  final String visualizationMode;
  final String sliceType;
  final double slicePosition;
  final bool showGrid;
  final bool showTorches;
  final bool showHeatFlux;
  final bool showIsosurfaces;
  final String colorScale;
  
  final Function(String) onVisualizationModeChanged;
  final Function(String) onSliceTypeChanged;
  final Function(double) onSlicePositionChanged;
  final Function(bool) onShowGridChanged;
  final Function(bool) onShowTorchesChanged;
  final Function(bool) onShowHeatFluxChanged;
  final Function(bool) onShowIsosurfacesChanged;
  final Function(String) onColorScaleChanged;

  const VisualizationControls({
    Key? key,
    required this.visualizationMode,
    required this.sliceType,
    required this.slicePosition,
    required this.showGrid,
    required this.showTorches,
    required this.showHeatFlux,
    required this.showIsosurfaces,
    required this.colorScale,
    required this.onVisualizationModeChanged,
    required this.onSliceTypeChanged,
    required this.onSlicePositionChanged,
    required this.onShowGridChanged,
    required this.onShowTorchesChanged,
    required this.onShowHeatFluxChanged,
    required this.onShowIsosurfacesChanged,
    required this.onColorScaleChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildVisualizationModeSelector(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildColorScaleSelector(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildVisualizationOptions(),
                ),
                if (visualizationMode == 'Slice') ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSliceControls(),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualizationModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Modo de Visualização:'),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment<String>(
              value: '3D',
              label: Text('3D'),
              icon: Icon(Icons.view_in_ar),
            ),
            ButtonSegment<String>(
              value: 'Slice',
              label: Text('Corte'),
              icon: Icon(Icons.crop),
            ),
            ButtonSegment<String>(
              value: 'HeatFlux',
              label: Text('Fluxo'),
              icon: Icon(Icons.waves),
            ),
          ],
          selected: {visualizationMode},
          onSelectionChanged: (Set<String> selection) {
            if (selection.isNotEmpty) {
              onVisualizationModeChanged(selection.first);
            }
          },
        ),
      ],
    );
  }

  Widget _buildColorScaleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Escala de Cores:'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          value: colorScale,
          items: const [
            DropdownMenuItem(
              value: 'BlueToRed',
              child: Text('Azul para Vermelho'),
            ),
            DropdownMenuItem(
              value: 'Rainbow',
              child: Text('Arco-íris'),
            ),
            DropdownMenuItem(
              value: 'Grayscale',
              child: Text('Escala de Cinza'),
            ),
            DropdownMenuItem(
              value: 'Custom',
              child: Text('Personalizada'),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              onColorScaleChanged(value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildVisualizationOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Opções:'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: const Text('Malha'),
              selected: showGrid,
              onSelected: onShowGridChanged,
            ),
            FilterChip(
              label: const Text('Tochas'),
              selected: showTorches,
              onSelected: onShowTorchesChanged,
            ),
            FilterChip(
              label: const Text('Fluxo de Calor'),
              selected: showHeatFlux,
              onSelected: onShowHeatFluxChanged,
            ),
            FilterChip(
              label: const Text('Isosuperfícies'),
              selected: showIsosurfaces,
              onSelected: onShowIsosurfacesChanged,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSliceControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Tipo de Corte:'),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: sliceType,
              items: const [
                DropdownMenuItem(
                  value: 'Axial',
                  child: Text('Axial'),
                ),
                DropdownMenuItem(
                  value: 'Radial',
                  child: Text('Radial'),
                ),
                DropdownMenuItem(
                  value: 'Angular',
                  child: Text('Angular'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  onSliceTypeChanged(value);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Posição:'),
            const SizedBox(width: 8),
            Expanded(
              child: Slider(
                value: slicePosition,
                min: 0.0,
                max: 1.0,
                divisions: 20,
                label: slicePosition.toStringAsFixed(2),
                onChanged: onSlicePositionChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
