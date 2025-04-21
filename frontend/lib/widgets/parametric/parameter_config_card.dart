import 'package:flutter/material.dart';
import '../models/parametric_study.dart';

class ParameterConfigCard extends StatefulWidget {
  final ParametricParameter parameter;
  final Function(ParametricParameter) onUpdate;
  final VoidCallback onRemove;

  const ParameterConfigCard({
    Key? key,
    required this.parameter,
    required this.onUpdate,
    required this.onRemove,
  }) : super(key: key);

  @override
  State<ParameterConfigCard> createState() => _ParameterConfigCardState();
}

class _ParameterConfigCardState extends State<ParameterConfigCard> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _unitController;
  late TextEditingController _minValueController;
  late TextEditingController _maxValueController;
  late TextEditingController _numPointsController;
  late ScaleType _scaleType;
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.parameter.name);
    _descriptionController = TextEditingController(text: widget.parameter.description);
    _unitController = TextEditingController(text: widget.parameter.unit);
    _minValueController = TextEditingController(text: widget.parameter.minValue.toString());
    _maxValueController = TextEditingController(text: widget.parameter.maxValue.toString());
    _numPointsController = TextEditingController(text: widget.parameter.numPoints.toString());
    _scaleType = widget.parameter.scaleType;
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _unitController.dispose();
    _minValueController.dispose();
    _maxValueController.dispose();
    _numPointsController.dispose();
    super.dispose();
  }
  
  void _updateParameter() {
    final updatedParameter = ParametricParameter(
      name: _nameController.text,
      description: _descriptionController.text,
      unit: _unitController.text,
      minValue: double.tryParse(_minValueController.text) ?? widget.parameter.minValue,
      maxValue: double.tryParse(_maxValueController.text) ?? widget.parameter.maxValue,
      numPoints: int.tryParse(_numPointsController.text) ?? widget.parameter.numPoints,
      scaleType: _scaleType,
      specificValues: widget.parameter.specificValues,
    );
    
    widget.onUpdate(updatedParameter);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _formatParameterName(widget.parameter.name),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Remover parâmetro',
                  onPressed: widget.onRemove,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Nome do parâmetro
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome do parâmetro',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) => _updateParameter(),
            ),
            
            const SizedBox(height: 12),
            
            // Descrição
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) => _updateParameter(),
            ),
            
            const SizedBox(height: 12),
            
            // Unidade
            TextFormField(
              controller: _unitController,
              decoration: const InputDecoration(
                labelText: 'Unidade',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) => _updateParameter(),
            ),
            
            const SizedBox(height: 12),
            
            // Valores mínimo e máximo
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minValueController,
                    decoration: const InputDecoration(
                      labelText: 'Valor mínimo',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _updateParameter(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _maxValueController,
                    decoration: const InputDecoration(
                      labelText: 'Valor máximo',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _updateParameter(),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Número de pontos
            TextFormField(
              controller: _numPointsController,
              decoration: const InputDecoration(
                labelText: 'Número de pontos',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => _updateParameter(),
            ),
            
            const SizedBox(height: 12),
            
            // Tipo de escala
            const Text(
              'Tipo de escala',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            SegmentedButton<ScaleType>(
              segments: const [
                ButtonSegment<ScaleType>(
                  value: ScaleType.linear,
                  label: Text('Linear'),
                ),
                ButtonSegment<ScaleType>(
                  value: ScaleType.logarithmic,
                  label: Text('Logarítmica'),
                ),
              ],
              selected: {_scaleType},
              onSelectionChanged: (Set<ScaleType> selection) {
                if (selection.isNotEmpty) {
                  setState(() {
                    _scaleType = selection.first;
                  });
                  _updateParameter();
                }
              },
            ),
          ],
        ),
      ),
    );
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
}
