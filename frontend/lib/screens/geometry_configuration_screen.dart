import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/simulation_parameters.dart';
import '../state/simulation_state.dart';
import 'torch_configuration_screen.dart';

class GeometryConfigurationScreen extends ConsumerStatefulWidget {
  const GeometryConfigurationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<GeometryConfigurationScreen> createState() => _GeometryConfigurationScreenState();
}

class _GeometryConfigurationScreenState extends ConsumerState<GeometryConfigurationScreen> {
  final _formKey = GlobalKey<FormState>();
  late SimulationParameters _parameters;
  bool _showAdvancedOptions = false;

  @override
  void initState() {
    super.initState();
    // Obter parâmetros atuais do estado
    final simulationState = ref.read(simulationStateProvider);
    _parameters = SimulationParameters.defaultParams();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuração de Geometria'),
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
              _buildTorchesSection(),
              const SizedBox(height: 24),
              _buildAdvancedOptionsToggle(),
              if (_showAdvancedOptions) ...[
                const SizedBox(height: 24),
                _buildAdvancedMeshSection(),
              ],
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
              'Dimensões da Fornalha',
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
                    onChanged: (value) {
                      final height = double.tryParse(value);
                      if (height != null) {
                        setState(() {
                          _parameters = _parameters.copyWith(height: height);
                        });
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
                    onChanged: (value) {
                      final radius = double.tryParse(value);
                      if (radius != null) {
                        setState(() {
                          _parameters = _parameters.copyWith(radius: radius);
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Center(
                child: CustomPaint(
                  size: const Size(180, 180),
                  painter: CylinderPainter(
                    height: _parameters.height,
                    radius: _parameters.radius,
                    torches: _parameters.torches,
                  ),
                ),
              ),
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
              'Configuração da Malha',
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
                    onChanged: (value) {
                      final nr = int.tryParse(value);
                      if (nr != null) {
                        setState(() {
                          _parameters = _parameters.copyWith(nr: nr);
                        });
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
                    onChanged: (value) {
                      final nz = int.tryParse(value);
                      if (nz != null) {
                        setState(() {
                          _parameters = _parameters.copyWith(nz: nz);
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

  Widget _buildTorchesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tochas de Plasma',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total de tochas: ${_parameters.torches.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.settings),
                        label: const Text('Configurar Tochas'),
                        onPressed: () async {
                          // Salvar parâmetros atuais no estado
                          await ref.read(simulationStateProvider.notifier).setParameters(_parameters);
                          
                          // Navegar para a tela de configuração de tochas
                          if (mounted) {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TorchConfigurationScreen(),
                              ),
                            );
                            
                            // Atualizar parâmetros ao retornar
                            final simulationState = ref.read(simulationStateProvider);
                            // Atualizar parâmetros quando o modelo for atualizado
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _parameters.torches.length,
                    itemBuilder: (context, index) {
                      final torch = _parameters.torches[index];
                      return ListTile(
                        leading: const Icon(Icons.whatshot),
                        title: Text('Tocha ${index + 1}'),
                        subtitle: Text(
                          'Posição: (${torch.rPosition.toStringAsFixed(2)}, ${torch.zPosition.toStringAsFixed(2)}) - '
                          'Potência: ${torch.power.toStringAsFixed(1)} kW',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      );
                    },
                  ),
                ],
              ),
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

  Widget _buildAdvancedMeshSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuração Avançada da Malha',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Nós angulares (para visualização 3D)',
                border: OutlineInputBorder(),
              ),
              initialValue: '12', // Valor padrão
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Campo obrigatório';
                }
                final ntheta = int.tryParse(value);
                if (ntheta == null || ntheta < 4) {
                  return 'Mínimo de 4 nós';
                }
                return null;
              },
              onChanged: (value) {
                // Implementar quando o modelo suportar ntheta
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Zonas de Material',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'A configuração de zonas de material será implementada em uma versão futura.',
              style: TextStyle(fontStyle: FontStyle.italic),
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
            // Salvar configuração e voltar
            ref.read(simulationStateProvider.notifier).setParameters(_parameters).then((_) {
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

// Painter personalizado para desenhar o cilindro com tochas
class CylinderPainter extends CustomPainter {
  final double height;
  final double radius;
  final List<PlasmaTorch> torches;

  CylinderPainter({
    required this.height,
    required this.radius,
    required this.torches,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    
    // Escala para ajustar as dimensões ao tamanho do canvas
    final double scale = size.width / (2.2 * radius);
    
    // Desenhar cilindro (vista lateral)
    final Paint cylinderPaint = Paint()
      ..color = Colors.blue.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    
    final Paint borderPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    // Retângulo representando o cilindro (vista lateral)
    final double scaledRadius = radius * scale;
    final double scaledHeight = height * scale;
    
    final Rect cylinderRect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: 2 * scaledRadius,
      height: scaledHeight,
    );
    
    canvas.drawRect(cylinderRect, cylinderPaint);
    canvas.drawRect(cylinderRect, borderPaint);
    
    // Desenhar tochas
    final Paint torchPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    
    for (var torch in torches) {
      // Converter posição da tocha para coordenadas do canvas
      final double torchX = centerX - scaledRadius + torch.rPosition * scale;
      final double torchY = centerY + scaledHeight / 2 - torch.zPosition * scale;
      
      // Desenhar tocha como um círculo
      canvas.drawCircle(Offset(torchX, torchY), 5.0, torchPaint);
      
      // Desenhar linha de direção da tocha
      final double torchLength = 15.0;
      final double pitchRad = torch.pitch * 3.14159 / 180.0;
      final double yawRad = torch.yaw * 3.14159 / 180.0;
      
      final double dirX = torchLength * pitchRad.sin() * yawRad.cos();
      final double dirY = -torchLength * pitchRad.cos();
      
      final Paint directionPaint = Paint()
        ..color = Colors.orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      
      canvas.drawLine(
        Offset(torchX, torchY),
        Offset(torchX + dirX, torchY + dirY),
        directionPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CylinderPainter oldDelegate) {
    return oldDelegate.height != height ||
           oldDelegate.radius != radius ||
           oldDelegate.torches != torches;
  }
}
