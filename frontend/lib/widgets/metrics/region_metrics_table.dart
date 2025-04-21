import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/metrics.dart';

class RegionMetricsTable extends ConsumerWidget {
  final List<RegionMetrics> regionMetrics;

  const RegionMetricsTable({
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
                  DataColumn(label: Text('Temp. Mín (°C)')),
                  DataColumn(label: Text('Temp. Máx (°C)')),
                  DataColumn(label: Text('Temp. Média (°C)')),
                  DataColumn(label: Text('Volume (m³)')),
                  DataColumn(label: Text('Energia (J)')),
                ],
                rows: regionMetrics.map((region) {
                  return DataRow(
                    cells: [
                      DataCell(Text(region.name)),
                      DataCell(Text(region.minTemperature.toStringAsFixed(1))),
                      DataCell(Text(region.maxTemperature.toStringAsFixed(1))),
                      DataCell(Text(region.avgTemperature.toStringAsFixed(1))),
                      DataCell(Text(region.volume.toExponential(2))),
                      DataCell(Text(region.energy.toExponential(2))),
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
}
