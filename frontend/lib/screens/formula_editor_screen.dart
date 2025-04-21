import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import '../services/ffi_bridge.dart';
import '../models/formula.dart';
import '../state/formula_state.dart';

class FormulaEditorScreen extends ConsumerStatefulWidget {
  const FormulaEditorScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FormulaEditorScreen> createState() => _FormulaEditorScreenState();
}

class _FormulaEditorScreenState extends ConsumerState<FormulaEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedFormulaId = '';
  String _selectedCategory = 'MaterialProperty';
  String _resultUnit = '';
  List<FormulaParameter> _parameters = [];
  
  bool _isEditing = false;
  bool _isValidating = false;
  String? _validationError;
  List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadFormulas();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadFormulas() async {
    final ffiBridge = FFIBridge();
    try {
      await ref.read(formulaStateProvider.notifier).loadFormulas();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar fórmulas: $e')),
        );
      }
    }
  }

  void _selectFormula(String id) {
    final formulas = ref.read(formulaStateProvider).formulas;
    final formula = formulas.firstWhere((f) => f.id == id);
    
    setState(() {
      _selectedFormulaId = id;
      _nameController.text = formula.name;
      _descriptionController.text = formula.description;
      _codeController.text = formula.source;
      _selectedCategory = formula.category;
      _resultUnit = formula.resultUnit;
      _parameters = List.from(formula.parameters);
      _isEditing = true;
      _validationError = null;
    });
  }

  void _createNewFormula() {
    setState(() {
      _selectedFormulaId = '';
      _nameController.text = '';
      _descriptionController.text = '';
      _codeController.text = 'return 0.0;';
      _selectedCategory = 'MaterialProperty';
      _resultUnit = '';
      _parameters = [];
      _isEditing = true;
      _validationError = null;
    });
  }

  Future<void> _validateFormula() async {
    if (_codeController.text.isEmpty) {
      setState(() {
        _validationError = 'O código da fórmula não pode estar vazio';
      });
      return;
    }

    setState(() {
      _isValidating = true;
      _validationError = null;
    });

    try {
      final ffiBridge = FFIBridge();
      final result = await ffiBridge.validateFormula(
        _codeController.text,
        _parameters,
      );
      
      setState(() {
        _isValidating = false;
        _logs = result.logs;
        if (!result.isValid) {
          _validationError = result.error;
        }
      });
      
      if (result.isValid && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fórmula validada com sucesso!')),
        );
      }
    } catch (e) {
      setState(() {
        _isValidating = false;
        _validationError = 'Erro ao validar fórmula: $e';
      });
    }
  }

  Future<void> _saveFormula() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Validar a fórmula antes de salvar
    await _validateFormula();
    if (_validationError != null) {
      return;
    }
    
    final formula = Formula(
      id: _selectedFormulaId.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : _selectedFormulaId,
      name: _nameController.text,
      description: _descriptionController.text,
      source: _codeController.text,
      category: _selectedCategory,
      resultUnit: _resultUnit,
      parameters: _parameters,
    );
    
    try {
      await ref.read(formulaStateProvider.notifier).saveFormula(formula);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fórmula salva com sucesso!')),
        );
        setState(() {
          _isEditing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar fórmula: $e')),
        );
      }
    }
  }

  Future<void> _deleteFormula() async {
    if (_selectedFormulaId.isEmpty) {
      return;
    }
    
    // Confirmar exclusão
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text('Tem certeza que deseja excluir esta fórmula? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) {
      return;
    }
    
    try {
      await ref.read(formulaStateProvider.notifier).deleteFormula(_selectedFormulaId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fórmula excluída com sucesso!')),
        );
        setState(() {
          _isEditing = false;
          _selectedFormulaId = '';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir fórmula: $e')),
        );
      }
    }
  }

  void _addParameter() {
    setState(() {
      _parameters.add(
        FormulaParameter(
          name: 'param${_parameters.length + 1}',
          description: 'Parâmetro ${_parameters.length + 1}',
          type: 'Float',
          defaultValue: '0.0',
          unit: '',
        ),
      );
    });
  }

  void _removeParameter(int index) {
    setState(() {
      _parameters.removeAt(index);
    });
  }

  void _updateParameter(int index, FormulaParameter parameter) {
    setState(() {
      _parameters[index] = parameter;
    });
  }

  @override
  Widget build(BuildContext context) {
    final formulaState = ref.watch(formulaStateProvider);
    final formulas = formulaState.formulas;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor de Fórmulas'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: 'Salvar',
              onPressed: _saveFormula,
            ),
          if (_isEditing && _selectedFormulaId.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Excluir',
              onPressed: _deleteFormula,
            ),
        ],
      ),
      body: Row(
        children: [
          // Lista de fórmulas
          SizedBox(
            width: 250,
            child: Card(
              margin: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Fórmulas',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: formulaState.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            itemCount: formulas.length,
                            itemBuilder: (context, index) {
                              final formula = formulas[index];
                              return ListTile(
                                title: Text(formula.name),
                                subtitle: Text(
                                  _getCategoryName(formula.category),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                selected: _selectedFormulaId == formula.id,
                                onTap: () => _selectFormula(formula.id),
                              );
                            },
                          ),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Nova Fórmula'),
                      onPressed: _createNewFormula,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Editor de fórmulas
          Expanded(
            child: _isEditing
                ? _buildFormulaEditor()
                : const Center(
                    child: Text('Selecione uma fórmula para editar ou crie uma nova'),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormulaEditor() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Informações básicas
          Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informações Básicas',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nome da Fórmula',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Nome é obrigatório';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Categoria',
                            border: OutlineInputBorder(),
                          ),
                          value: _selectedCategory,
                          items: [
                            DropdownMenuItem(
                              value: 'MaterialProperty',
                              child: Text(_getCategoryName('MaterialProperty')),
                            ),
                            DropdownMenuItem(
                              value: 'HeatSource',
                              child: Text(_getCategoryName('HeatSource')),
                            ),
                            DropdownMenuItem(
                              value: 'BoundaryCondition',
                              child: Text(_getCategoryName('BoundaryCondition')),
                            ),
                            DropdownMenuItem(
                              value: 'PhysicalModel',
                              child: Text(_getCategoryName('PhysicalModel')),
                            ),
                            DropdownMenuItem(
                              value: 'PostProcessing',
                              child: Text(_getCategoryName('PostProcessing')),
                            ),
                            DropdownMenuItem(
                              value: 'Utility',
                              child: Text(_getCategoryName('Utility')),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedCategory = value;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          initialValue: _resultUnit,
                          decoration: const InputDecoration(
                            labelText: 'Unidade do Resultado',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _resultUnit = value;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Descrição',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Descrição é obrigatória';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // Parâmetros
          Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Parâmetros',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Adicionar Parâmetro'),
                        onPressed: _addParameter,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _parameters.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('Nenhum parâmetro definido'),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _parameters.length,
                          itemBuilder: (context, index) {
                            return _buildParameterItem(index);
                          },
                        ),
                ],
              ),
            ),
          ),
          
          // Editor de código
          Expanded(
            child: Card(
              margin: const EdgeInsets.all(8.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Código da Fórmula',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Validar'),
                          onPressed: _isValidating ? null : _validateFormula,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_validationError != null)
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Text(
                          _validationError!,
                          style: TextStyle(color: Colors.red.shade900),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: HighlightView(
                          _codeController.text,
                          language: 'javascript',
                          theme: githubTheme,
                          padding: const EdgeInsets.all(12),
                          textStyle: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: TextField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                          labelText: 'Editar Código',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: null,
                        expands: true,
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Logs
          if (_logs.isNotEmpty)
            Card(
              margin: const EdgeInsets.all(8.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Logs',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 100,
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          return Text(
                            _logs[index],
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          );
                        },
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

  Widget _buildParameterItem(int index) {
    final parameter = _parameters[index];
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                initialValue: parameter.name,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _updateParameter(
                    index,
                    parameter.copyWith(name: value),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: TextFormField(
                initialValue: parameter.description,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _updateParameter(
                    index,
                    parameter.copyWith(description: value),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                  border: OutlineInputBorder(),
                ),
                value: parameter.type,
                items: const [
                  DropdownMenuItem(value: 'Integer', child: Text('Inteiro')),
                  DropdownMenuItem(value: 'Float', child: Text('Decimal')),
                  DropdownMenuItem(value: 'Boolean', child: Text('Booleano')),
                  DropdownMenuItem(value: 'String', child: Text('Texto')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _updateParameter(
                      index,
                      parameter.copyWith(type: value),
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: TextFormField(
                initialValue: parameter.defaultValue,
                decoration: const InputDecoration(
                  labelText: 'Valor Padrão',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _updateParameter(
                    index,
                    parameter.copyWith(defaultValue: value),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: TextFormField(
                initialValue: parameter.unit,
                decoration: const InputDecoration(
                  labelText: 'Unidade',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _updateParameter(
                    index,
                    parameter.copyWith(unit: value),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _removeParameter(index),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryName(String category) {
    switch (category) {
      case 'MaterialProperty':
        return 'Propriedade de Material';
      case 'HeatSource':
        return 'Fonte de Calor';
      case 'BoundaryCondition':
        return 'Condição de Contorno';
      case 'PhysicalModel':
        return 'Modelo Físico';
      case 'PostProcessing':
        return 'Pós-Processamento';
      case 'Utility':
        return 'Utilitário';
      default:
        return category;
    }
  }
}
