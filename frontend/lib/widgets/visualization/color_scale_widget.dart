import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ColorScaleWidget extends ConsumerWidget {
  final String colorScale;
  final double minValue;
  final double maxValue;
  final double width;

  const ColorScaleWidget({
    Key? key,
    required this.colorScale,
    required this.minValue,
    required this.maxValue,
    this.width = 30.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              maxValue.toStringAsFixed(1),
              style: const TextStyle(fontSize: 10),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              width: width - 10,
              decoration: BoxDecoration(
                gradient: _buildGradient(),
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text(
              minValue.toStringAsFixed(1),
              style: const TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  LinearGradient _buildGradient() {
    switch (colorScale) {
      case 'BlueToRed':
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.red,
            Colors.orange,
            Colors.yellow,
            Colors.green,
            Colors.blue,
          ],
        );
      case 'Rainbow':
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.purple,
            Colors.blue,
            Colors.cyan,
            Colors.green,
            Colors.yellow,
            Colors.orange,
            Colors.red,
          ],
        );
      case 'Grayscale':
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Colors.grey,
            Colors.black,
          ],
        );
      case 'Custom':
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFF0000),
            Color(0xFFFF8000),
            Color(0xFFFFFF00),
            Color(0xFF00FF00),
            Color(0xFF0000FF),
          ],
        );
      default:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.red,
            Colors.orange,
            Colors.yellow,
            Colors.green,
            Colors.blue,
          ],
        );
    }
  }
}
