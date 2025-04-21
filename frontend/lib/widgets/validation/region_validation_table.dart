import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/validation.dart';

class RegionValidationTable extends ConsumerWidget {
  final Map<String, ValidationMetrics> regionMetrics;

  const RegionValidationTable({
    Key? key,
    required this.regionMetrics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Região')),
                  DataColumn(label: Text('MAE (°C)')),
                  DataColumn(label: Text('RMSE (°C)')),
                  DataColumn(label: Text('MAPE (%)')),
                  DataColumn(label: Text('R²')),
                ],
                rows: regionMetrics.entries.map((entry) {
                  final region = entry.key;
                  final metrics = entry.value;
                  
                  return DataRow(
                    cells: [
                      DataCell(Text(region)),
                      DataCell(
                        Text(
                          metrics.meanAbsoluteError.toStringAsFixed(2),
                          style: TextStyle(
                            color: _getErrorColor(metrics.meanAbsoluteError, 10.0, 30.0),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          metrics.rootMeanSquaredError.toStringAsFixed(2),
                          style: TextStyle(
                            color: _getErrorColor(metrics.rootMeanSquaredError, 15.0, 40.0),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          metrics.meanAbsolutePercentageError.toStringAsFixed(2),
                          style: TextStyle(
                            color: _getErrorColor(metrics.meanAbsolutePercentageError, 5.0, 15.0),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          metrics.rSquared.toStringAsFixed(3),
                          style: TextStyle(
                            color: _getRSquaredColor(metrics.rSquared),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getErrorColor(double error, double goodThreshold, double badThreshold) {
    if (error <= goodThreshold) {
      return Colors.green;
    } else if (error <= badThreshold) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Color _getRSquaredColor(double rSquared) {
    if (rSquared >= 0.9) {
      return Colors.green;
    } else if (rSquared >= 0.7) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
