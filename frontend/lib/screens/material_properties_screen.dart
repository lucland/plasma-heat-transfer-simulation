import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/simulation_parameters.dart';
import '../state/simulation_state.dart';

class MaterialPropertiesScreen extends ConsumerStatefulWidget {
  const MaterialPropertiesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MaterialPropertiesScreen> createState() => _MaterialPropertiesScreenState();
}

class _MaterialPropertiesScreenState extends ConsumerState<MaterialPropertiesScreen> {
  final _formKey = GlobalKey<FormState>();
  late MaterialProperties _material;
  bool _showAdvancedOptions = false;
  bool _showPhaseChangeOptions = false;
  String _selectedPredefinedMaterial = 'custom';

  // Lista de materiais pré-definidos
  final Map<String, MaterialProperties> _predefinedMaterials = {
    'custom': MaterialProperties(
      name: 'Material Personalizado',
      density: 1000.0,
      specificHeat: 1500.0,
      thermalConductivity: 0.5,
      emissivity: 0.9,
    ),
    'steel': MaterialProperties(
      name: 'Aço Carbono',
      density: 7850.0,
      specificHeat: 490.0,
      thermalConductivity: 45.0,
      emissivity: 0.8,
      meltingPoint: 1450.0,
      latentHeatFusion: 270000.0,
      vaporizationPoint: 3000.0,
      latentHeatVaporization: 6340000.0,
    ),
    'aluminum': MaterialProperties(
      name: 'Alumínio',
      density: 2700.0,
      specificHeat: 900.0,
      thermalConductivity: 237.0,
      emissivity: 0.7,
      meltingPoint: 660.0,
      latentHeatFusion: 397000.0,
      vaporizationPoint: 2520.0,
      latentHeatVaporization: 10500000.0,
    ),
    'copper': MaterialProperties(
      name: 'Cobre',
      density: 8960.0,
      specificHeat: 385.0,
      thermalConductivity: 401.0,
      emissivity: 0.6,
      meltingPoint: 1085.0,
      latentHeatFusion: 205000.0,
      vaporizationPoint: 2560.0,
      latentHeatVaporization: 4730000.0,
    ),
    'concrete': MaterialProperties(
      name: 'Concreto',
      density: 2300.0,
      moistureContent: 2.0,
      specificHeat: 880.0,
      thermalConductivity: 1.4,
      emissivity: 0.94,
    ),
    'wood': MaterialProperties(
      name: 'Madeira',
      density: 700.0,
      moistureContent: 12.0,
      specificHeat: 1700.0,
      thermalConductivity: 0.16,
      emissivity: 0.9,
    ),
    'glass': MaterialProperties(
      name: 'Vidro',
      density: 2500.0,
      specificHeat: 840.0,
      thermalConductivity: 0.8,
      emissivity: 0.95,
      meltingPoint: 1400.0,
      latentHeatFusion: 140000.0,
    ),
  };

  @override
  void initState() {
    super.initState();
    // Obter parâmetros atuais do estado
    final simulationState = ref.read(simulationStateProvider);
    _material = MaterialProperties(
      name: 'Material Personalizado',
      density: 1000.0,
      specificHeat: 1500.0,
      thermalConductivity: 0.5,
      emissivity: 0.9,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Propriedades do Material'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMaterialSelector(),
              const SizedBox(height: 24),
              _buildBasicPropertiesSection(),
              const SizedBox(height: 24),
              _buildPhaseChangeToggle(),
              if (_showPhaseChangeOptions) ...[
                const SizedBox(height: 24),
                _buildPhaseChangeSection(),
              ],
              const SizedBox(height: 24),
              _buildAdvancedOptionsToggle(),
              if (_showAdvancedOptions) ...[
                const SizedBox(height: 24),
                _buildAdvancedPropertiesSection(),
              ],
              const SizedBox(height: 32),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecionar Material',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Material',
                border: OutlineInputBorder(),
              ),
              value: _selectedPredefinedMaterial,
              items: _predefinedMaterials.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(entry.value.name),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedPredefinedMaterial = value;
                    _material = _predefinedMaterials[value]!;
                    
                    // Atualizar visibilidade das opções de mudança de fase
                    _showPhaseChangeOptions = _material.meltingPoint != null || 
                                             _material.vaporizationPoint != null;
                  });
                }
              },
            ),
            const SizedBox(height: 8),
            const Text(
              'Selecione um material pré-definido ou personalize as propriedades abaixo.',
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicPropertiesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Propriedades Básicas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Nome do Material',
                border: OutlineInputBorder(),
              ),
              initialValue: _material.name,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Campo obrigatório';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _material = _material.copyWith(name: value);
                  _selectedPredefinedMaterial = 'custom';
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Densidade (kg/m³)',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _material.density.toString(),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo obrigatório';
                      }
                      final density = double.tryParse(value);
                      if (density == null || density <= 0) {
                        return 'Densidade deve ser positiva';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      final density = double.tryParse(value);
                      if (density != null) {
                        setState(() {
                          _material = _material.copyWith(density: density);
                          _selectedPredefinedMaterial = 'custom';
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Conteúdo de Umidade (%)',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _material.moistureContent.toString(),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo obrigatório';
                      }
                      final moisture = double.tryParse(value);
                      if (moisture == null || moisture < 0 || moisture > 100) {
                        return 'Valor deve estar entre 0 e 100';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      final moisture = double.tryParse(value);
                      if (moisture != null) {
                        setState(() {
                          _material = _material.copyWith(moistureContent: moisture);
                          _selectedPredefinedMaterial = 'custom';
                        });
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
                      labelText: 'Calor Específico (J/kg·K)',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _material.specificHeat.toString(),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo obrigatório';
                      }
                      final specificHeat = double.tryParse(value);
                      if (specificHeat == null || specificHeat <= 0) {
                        return 'Valor deve ser positivo';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      final specificHeat = double.tryParse(value);
                      if (specificHeat != null) {
                        setState(() {
                          _material = _material.copyWith(specificHeat: specificHeat);
                          _selectedPredefinedMaterial = 'custom';
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Condutividade Térmica (W/m·K)',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _material.thermalConductivity.toString(),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Campo obrigatório';
                      }
                      final conductivity = double.tryParse(value);
                      if (conductivity == null || conductivity <= 0) {
                        return 'Valor deve ser positivo';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      final conductivity = double.tryParse(value);
                      if (conductivity != null) {
                        setState(() {
                          _material = _material.copyWith(thermalConductivity: conductivity);
                          _selectedPredefinedMaterial = 'custom';
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
                labelText: 'Emissividade (0-1)',
                border: OutlineInputBorder(),
              ),
              initialValue: _material.emissivity.toString(),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Campo obrigatório';
                }
                final emissivity = double.tryParse(value);
                if (emissivity == null || emissivity < 0 || emissivity > 1) {
                  return 'Valor deve estar entre 0 e 1';
                }
                return null;
              },
              onChanged: (value) {
                final emissivity = double.tryParse(value);
                if (emissivity != null) {
                  setState(() {
                    _material = _material.copyWith(emissivity: emissivity);
                    _selectedPredefinedMaterial = 'custom';
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseChangeToggle() {
    return SwitchListTile(
      title: const Text(
        'Mudanças de Fase',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      subtitle: const Text('Habilitar propriedades de mudança de fase (fusão e vaporização)'),
      value: _showPhaseChangeOptions,
      onChanged: (value) {
        setState(() {
          _showPhaseChangeOptions = value;
          if (!value) {
            // Limpar valores de mudança de fase
            _material = _material.copyWith(
              meltingPoint: null,
              latentHeatFusion: null,
              vaporizationPoint: null,
              latentHeatVaporization: null,
            );
            _selectedPredefinedMaterial = 'custom';
          }
        });
      },
    );
  }

  Widget _buildPhaseChangeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Propriedades de Mudança de Fase',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Temperatura de Fusão (°C)',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _material.meltingPoint?.toString() ?? '',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return null; // Opcional
                      }
                      final temp = double.tryParse(value);
                      if (temp == null) {
                        return 'Valor inválido';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      final temp = value.isEmpty ? null : double.tryParse(value);
                      setState(() {
                        _material = _material.copyWith(meltingPoint: temp);
                        _selectedPredefinedMaterial = 'custom';
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Calor Latente de Fusão (J/kg)',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _material.latentHeatFusion?.toString() ?? '',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return null; // Opcional
                      }
                      final heat = double.tryParse(value);
                      if (heat == null || heat <= 0) {
                        return 'Valor deve ser positivo';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      final heat = value.isEmpty ? null : double.tryParse(value);
                      setState(() {
                        _material = _material.copyWith(latentHeatFusion: heat);
                        _selectedPredefinedMaterial = 'custom';
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
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Temperatura de Vaporização (°C)',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _material.vaporizationPoint?.toString() ?? '',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return null; // Opcional
                      }
                      final temp = double.tryParse(value);
                      if (temp == null) {
                        return 'Valor inválido';
                      }
                      if (_material.meltingPoint != null && temp <= _material.meltingPoint!) {
                        return 'Deve ser maior que a temperatura de fusão';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      final temp = value.isEmpty ? null : double.tryParse(value);
                      setState(() {
                        _material = _material.copyWith(vaporizationPoint: temp);
                        _selectedPredefinedMaterial = 'custom';
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Calor Latente de Vaporização (J/kg)',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _material.latentHeatVaporization?.toString() ?? '',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return null; // Opcional
                      }
                      final heat = double.tryParse(value);
                      if (heat == null || heat <= 0) {
                        return 'Valor deve ser positivo';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      final heat = value.isEmpty ? null : double.tryParse(value);
                      setState(() {
                        _material = _material.copyWith(latentHeatVaporization: heat);
                        _selectedPredefinedMaterial = 'custom';
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

  Widget _buildAdvancedOptionsToggle() {
    return SwitchListTile(
      title: const Text(
        'Opções Avançadas',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      value: _showAdvancedOptions,
      onChanged: (value) {
        setState(() {
          _showAdvancedOptions = value;
        });
      },
    );
  }

  Widget _buildAdvancedPropertiesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Propriedades Avançadas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Dependência de Temperatura',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'As propriedades abaixo permitem definir como as propriedades do material variam com a temperatura.',
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
            ),
            const SizedBox(height: 16),
            const Text(
              'Coeficientes para Calor Específico',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cp(T) = c₀ + c₁·(T-Tref)/100 + c₂·((T-Tref)/100)² + ...',
              style: TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'c₀',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _material.specificHeat.toString(),
                    enabled: false,
                    readOnly: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'c₁',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: '0.0',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'c₂',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: '0.0',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Coeficientes para Condutividade Térmica',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'k(T) = k₀ + k₁·(T-Tref)/100 + k₂·((T-Tref)/100)² + ...',
              style: TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'k₀',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _material.thermalConductivity.toString(),
                    enabled: false,
                    readOnly: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'k₁',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: '0.0',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'k₂',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: '0.0',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Temperatura de Referência (°C)',
                border: OutlineInputBorder(),
              ),
              initialValue: '25.0',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Campo obrigatório';
                }
                final temp = double.tryParse(value);
                if (temp == null) {
                  return 'Valor inválido';
                }
                return null;
              },
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
            // Obter parâmetros atuais
            final simulationState = ref.read(simulationStateProvider);
            
            // Atualizar material nos parâmetros
            final parameters = SimulationParameters.defaultParams().copyWith(
              material: _material,
            );
            
            // Salvar configuração e voltar
            ref.read(simulationStateProvider.notifier).setParameters(parameters).then((_) {
              Navigator.pop(context);
            });
          }
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        ),
        child: const Text(
          'Salvar Configuração',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
