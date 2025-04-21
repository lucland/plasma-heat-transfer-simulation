import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/simulation_setup.dart';
import 'screens/simulation_screen.dart';
import 'screens/geometry_configuration_screen.dart';
import 'screens/torch_configuration_screen.dart';
import 'screens/material_properties_screen.dart';
import 'screens/advanced_visualization_screen.dart';
import 'screens/formula_editor_screen.dart';
import 'screens/metrics_screen.dart';
import 'screens/model_validation_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: PlasmaFurnaceApp(),
    ),
  );
}

class PlasmaFurnaceApp extends StatelessWidget {
  const PlasmaFurnaceApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simulador de Fornalha de Plasma',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SimulationSetupScreen(),
        '/simulation': (context) => const SimulationScreen(),
        '/geometry': (context) => const GeometryConfigurationScreen(),
        '/torch': (context) => const TorchConfigurationScreen(),
        '/material': (context) => const MaterialPropertiesScreen(),
        '/visualization': (context) => const AdvancedVisualizationScreen(),
        '/formula': (context) => const FormulaEditorScreen(),
        '/metrics': (context) => const MetricsScreen(),
        '/validation': (context) => const ModelValidationScreen(),
      },
    );
  }
}
