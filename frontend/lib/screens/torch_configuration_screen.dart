import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/simulation_parameters.dart';
import '../state/simulation_state.dart';

class TorchConfigurationScreen extends ConsumerStatefulWidget {
  const TorchConfigurationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TorchConfigurationScreen> createState() => _TorchConfigurationScreenState();
}

class _TorchConfigurationScreenState extends ConsumerState<TorchConfigurationScreen> {
  final _formKey = GlobalKey<FormState>();
  late SimulationParameters _parameters;
  int _selectedTorchIndex = -1;
  
  @override
  void initState() {
    super.initState();
    // Obter parâmetros atuais do estado
    final simulationState = ref.read(simulationStateProvider);
    _parameters = SimulationParameters.defaultParams();
    
    // Adicionar uma tocha padrão se não houver nenhuma
    if (_parameters.torches.isEmpty) {
      _parameters = _parameters.copyWith(
        torches: [
          PlasmaTorch(
            rPosition: 0.0,
            zPosition: _parameters.height / 2,
            pitch: 90.0,
            yaw: 0.0,
            power: 100.0,
            gasFlow: 0.01,
            gasTemperature: 5000.0,
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuração de Tochas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addNewTorch,
            tooltip: 'Adicionar nova tocha',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildTorchList(),
            Expanded(
              child: _selectedTorchIndex >= 0 && _selectedTorchIndex < _parameters.torches.length
                  ? _buildTorchEditor(_parameters.torches[_selectedTorchIndex])
                  : const Center(child: Text('Selecione uma tocha para editar')),
            ),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildTorchList() {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(8.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _parameters.torches.length,
        itemBuilder: (context, index) {
          final torch = _parameters.torches[index];
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedTorchIndex = index;
              });
            },
            child: Container(
              width: 80,
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              decoration: BoxDecoration(
                color: _selectedTorchIndex == index ? Colors.blue.shade100 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: _selectedTorchIndex == index ? Colors.blue : Colors.grey,
                  width: 2.0,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.whatshot,
                    color: _selectedTorchIndex == index ? Colors.blue : Colors.grey,
                    size: 32,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tocha ${index + 1}',
                    style: TextStyle(
                      fontWeight: _selectedTorchIndex == index ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  Text(
                    '${torch.power} kW',
                    style: TextStyle(
                      fontSize: 12,
                      color: _selectedTorchIndex == index ? Colors.blue.shade800 : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTorchEditor(PlasmaTorch torch) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Editar Tocha ${_selectedTorchIndex + 1}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildPositionSection(torch),
          const SizedBox(height: 24),
          _buildOrientationSection(torch),
          const SizedBox(height: 24),
          _buildPowerSection(torch),
        ],
      ),
    );
  }

  Widget _buildPositionSection(PlasmaTorch torch) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Posição',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Posição radial (m)',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: torch.rPosition.toString(),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo obrigatório';
                      }
                      final pos = double.tryParse(value);
                      if (pos == null || pos < 0 || pos > _parameters.radius) {
                        return 'Valor deve estar entre 0 e ${_parameters.radius}';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      final pos = double.tryParse(value);
                      if (pos != null) {
                        setState(() {
                          final newTorch = torch.copyWith(rPosition: pos);
                          _updateTorch(newTorch);
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Posição angular (°)',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: '0.0', // Valor padrão para compatibilidade
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo obrigatório';
                      }
                      final angle = double.tryParse(value);
                      if (angle == null) {
                        return 'Valor inválido';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      final angle = double.tryParse(value);
                      if (angle != null) {
                        setState(() {
                          // Implementar quando o modelo suportar posição angular
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Posição axial (m)',
                border: OutlineInputBorder(),
              ),
              initialValue: torch.zPosition.toString(),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Campo obrigatório';
                }
                final pos = double.tryParse(value);
                if (pos == null || pos < 0 || pos > _parameters.height) {
                  return 'Valor deve estar entre 0 e ${_parameters.height}';
                }
                return null;
              },
              onChanged: (value) {
                final pos = double.tryParse(value);
                if (pos != null) {
                  setState(() {
                    final newTorch = torch.copyWith(zPosition: pos);
                    _updateTorch(newTorch);
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrientationSection(PlasmaTorch torch) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Orientação',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Inclinação (°)',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: torch.pitch.toString(),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo obrigatório';
                      }
                      final angle = double.tryParse(value);
                      if (angle == null || angle < 0 || angle > 180) {
                        return 'Valor deve estar entre 0 e 180';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      final angle = double.tryParse(value);
                      if (angle != null) {
                        setState(() {
                          final newTorch = torch.copyWith(pitch: angle);
                          _updateTorch(newTorch);
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Rotação (°)',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: torch.yaw.toString(),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo obrigatório';
                      }
                      final angle = double.tryParse(value);
                      if (angle == null) {
                        return 'Valor inválido';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      final angle = double.tryParse(value);
                      if (angle != null) {
                        setState(() {
                          final newTorch = torch.copyWith(yaw: angle);
                          _updateTorch(newTorch);
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPowerSection(PlasmaTorch torch) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Potência e Gás',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Potência (kW)',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: torch.power.toString(),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo obrigatório';
                      }
                      final power = double.tryParse(value);
                      if (power == null || power <= 0) {
                        return 'Potência deve ser positiva';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      final power = double.tryParse(value);
                      if (power != null) {
                        setState(() {
                          final newTorch = torch.copyWith(power: power);
                          _updateTorch(newTorch);
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Fluxo de gás (kg/s)',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: torch.gasFlow.toString(),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo obrigatório';
                      }
                      final flow = double.tryParse(value);
                      if (flow == null || flow <= 0) {
                        return 'Fluxo deve ser positivo';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      final flow = double.tryParse(value);
                      if (flow != null) {
                        setState(() {
                          final newTorch = torch.copyWith(gasFlow: flow);
                          _updateTorch(newTorch);
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Temperatura do gás (°C)',
                border: OutlineInputBorder(),
              ),
              initialValue: torch.gasTemperature.toString(),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Campo obrigatório';
                }
                final temp = double.tryParse(value);
                if (temp == null || temp <= 0) {
                  return 'Temperatura deve ser positiva';
                }
                return null;
              },
              onChanged: (value) {
                final temp = double.tryParse(value);
                if (temp != null) {
                  setState(() {
                    final newTorch = torch.copyWith(gasTemperature: temp);
                    _updateTorch(newTorch);
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: _selectedTorchIndex >= 0 ? _deleteTorch : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Excluir Tocha'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                // Salvar configuração e voltar
                ref.read(simulationStateProvider.notifier).setParameters(_parameters).then((_) {
                  Navigator.pop(context);
                });
              }
            },
            child: const Text('Salvar Configuração'),
          ),
        ],
      ),
    );
  }

  void _addNewTorch() {
    setState(() {
      final newTorch = PlasmaTorch(
        rPosition: 0.0,
        zPosition: _parameters.height / 2,
        pitch: 90.0,
        yaw: 0.0,
        power: 100.0,
        gasFlow: 0.01,
        gasTemperature: 5000.0,
      );
      
      final torches = List<PlasmaTorch>.from(_parameters.torches);
      torches.add(newTorch);
      _parameters = _parameters.copyWith(torches: torches);
      _selectedTorchIndex = torches.length - 1;
    });
  }

  void _deleteTorch() {
    if (_selectedTorchIndex < 0 || _parameters.torches.length <= 1) {
      // Não permitir excluir a última tocha
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pelo menos uma tocha deve ser mantida'),
        ),
      );
      return;
    }
    
    setState(() {
      final torches = List<PlasmaTorch>.from(_parameters.torches);
      torches.removeAt(_selectedTorchIndex);
      _parameters = _parameters.copyWith(torches: torches);
      _selectedTorchIndex = torches.isEmpty ? -1 : 0;
    });
  }

  void _updateTorch(PlasmaTorch newTorch) {
    if (_selectedTorchIndex >= 0 && _selectedTorchIndex < _parameters.torches.length) {
      final torches = List<PlasmaTorch>.from(_parameters.torches);
      torches[_selectedTorchIndex] = newTorch;
      _parameters = _parameters.copyWith(torches: torches);
    }
  }
}
