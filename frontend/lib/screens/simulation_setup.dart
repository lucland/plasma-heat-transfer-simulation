import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/simulation_parameters.dart';
import '../state/simulation_state.dart';

class SimulationSetupScreen extends ConsumerStatefulWidget {
  const SimulationSetupScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SimulationSetupScreen> createState() => _SimulationSetupScreenState();
}

class _SimulationSetupScreenState extends ConsumerState<SimulationSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late SimulationParameters _parameters;

  @override
  void initState() {
    super.initState();
    _parameters = SimulationParameters.defaultParams();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuração da Simulação'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGeometrySection(),
              const SizedBox(height: 24),
              _buildMeshSection(),
              const SizedBox(height: 24),
              _buildTemperatureSection(),
              const SizedBox(height: 24),
              _buildTimeSection(),
              const SizedBox(height: 24),
              _buildPhysicsSection(),
              const SizedBox(height: 24),
              _buildTorchSection(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeometrySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Geometria',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Altura (m)',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _parameters.height.toString(),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo obrigatório';
                      }
                      final height = double.tryParse(value);
                      if (height == null || height <= 0) {
                        return 'Altura deve ser positiva';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      if (value != null) {
                        _parameters = _parameters.copyWith(
                          height: double.parse(value),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Raio (m)',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _parameters.radius.toString(),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo obrigatório';
                      }
                      final radius = double.tryParse(value);
                      if (radius == null || radius <= 0) {
                        return 'Raio deve ser positivo';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      if (value != null) {
                        _parameters = _parameters.copyWith(
                          radius: double.parse(value),
                        );
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

  Widget _buildMeshSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Malha',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Nós radiais',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _parameters.nr.toString(),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo obrigatório';
                      }
                      final nr = int.tryParse(value);
                      if (nr == null || nr < 2) {
                        return 'Mínimo de 2 nós';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      if (value != null) {
                        _parameters = _parameters.copyWith(
                          nr: int.parse(value),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Nós axiais',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _parameters.nz.toString(),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo obrigatório';
                      }
                      final nz = int.tryParse(value);
                      if (nz == null || nz < 2) {
                        return 'Mínimo de 2 nós';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      if (value != null) {
                        _parameters = _parameters.copyWith(
                          nz: int.parse(value),
                        );
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

  Widget _buildTemperatureSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Temperatura',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Temperatura inicial (°C)',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _parameters.initialTemperature.toString(),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo obrigatório';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      if (value != null) {
                        _parameters = _parameters.copyWith(
                          initialTemperature: double.parse(value),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Temperatura ambiente (°C)',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _parameters.ambientTemperature.toString(),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo obrigatório';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      if (value != null) {
                        _parameters = _parameters.copyWith(
                          ambientTemperature: double.parse(value),
                        );
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

  Widget _buildTimeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tempo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Tempo total (s)',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _parameters.totalTime.toString(),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo obrigatório';
                      }
                      final time = double.tryParse(value);
                      if (time == null || time <= 0) {
                        return 'Tempo deve ser positivo';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      if (value != null) {
                        _parameters = _parameters.copyWith(
                          totalTime: double.parse(value),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Passo de tempo (s)',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _parameters.timeStep.toString(),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo obrigatório';
                      }
                      final step = double.tryParse(value);
                      if (step == null || step <= 0) {
                        return 'Passo deve ser positivo';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      if (value != null) {
                        _parameters = _parameters.copyWith(
                          timeStep: double.parse(value),
                        );
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

  Widget _buildPhysicsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Física',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Coeficiente de convecção (W/m²·K)',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _parameters.convectionCoefficient.toString(),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo obrigatório';
                      }
                      final coef = double.tryParse(value);
                      if (coef == null || coef < 0) {
                        return 'Valor deve ser não-negativo';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      if (value != null) {
                        _parameters = _parameters.copyWith(
                          convectionCoefficient: double.parse(value),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SwitchListTile(
                    title: const Text('Habilitar convecção'),
                    value: _parameters.enableConvection,
                    onChanged: (value) {
                      setState(() {
                        _parameters = _parameters.copyWith(
                          enableConvection: value,
                        );
                      });
                    },
                  ),
                ),
                Expanded(
                  child: SwitchListTile(
                    title: const Text('Habilitar radiação'),
                    value: _parameters.enableRadiation,
                    onChanged: (value) {
                      setState(() {
                        _parameters = _parameters.copyWith(
                          enableRadiation: value,
                        );
                      });
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

  Widget _buildTorchSection() {
    // Simplificado para a primeira versão - apenas uma tocha
    final torch = _parameters.torches.isNotEmpty
        ? _parameters.torches.first
        : PlasmaTorch(
            rPosition: 0.0,
            zPosition: 0.5,
            pitch: 90.0,
            yaw: 0.0,
            power: 100.0,
            gasFlow: 0.01,
            gasTemperature: 5000.0,
          );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tocha de Plasma',
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
                    onSaved: (value) {
                      if (value != null) {
                        final newTorch = torch.copyWith(
                          rPosition: double.parse(value),
                        );
                        _parameters = _parameters.copyWith(
                          torches: [newTorch],
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
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
                    onSaved: (value) {
                      if (value != null) {
                        final newTorch = torch.copyWith(
                          zPosition: double.parse(value),
                        );
                        _parameters = _parameters.copyWith(
                          torches: [newTorch],
                        );
                      }
                    },
                  ),
                ),
              ],
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
                    onSaved: (value) {
                      if (value != null) {
                        final newTorch = torch.copyWith(
                          power: double.parse(value),
                        );
                        _parameters = _parameters.copyWith(
                          torches: [newTorch],
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
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
                    onSaved: (value) {
                      if (value != null) {
                        final newTorch = torch.copyWith(
                          gasTemperature: double.parse(value),
                        );
                        _parameters = _parameters.copyWith(
                          torches: [newTorch],
                        );
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

  Widget _buildSubmitButton() {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            _formKey.currentState!.save();
            
            // Configurar parâmetros e navegar para a tela de simulação
            ref.read(simulationStateProvider.notifier).setParameters(_parameters).then((_) {
              Navigator.pushNamed(context, '/simulation');
            }).catchError((error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erro: $error'),
                  backgroundColor: Colors.red,
                ),
              );
            });
          }
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        ),
        child: const Text(
          'Iniciar Simulação',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
