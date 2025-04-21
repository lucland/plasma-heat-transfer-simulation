import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/validation.dart';

enum ErrorQuality {
  good,
  moderate,
  poor
}

class ErrorMetricsCard extends ConsumerWidget {
  final String title;
  final String value;
  final String description;
  final ErrorQuality quality;
  final bool isHigherBetter;

  const ErrorMetricsCard({
    Key? key,
    required this.title,
    required this.value,
    required this.description,
    required this.quality,
    this.isHigherBetter = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIcon(),
              size: 40,
              color: _getColor(),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _getColor(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _getProgressValue(),
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(_getColor()),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon() {
    if (isHigherBetter) {
      switch (quality) {
        case ErrorQuality.good:
          return Icons.thumb_up;
        case ErrorQuality.moderate:
          return Icons.thumbs_up_down;
        case ErrorQuality.poor:
          return Icons.thumb_down;
      }
    } else {
      switch (quality) {
        case ErrorQuality.good:
          return Icons.check_circle;
        case ErrorQuality.moderate:
          return Icons.info;
        case ErrorQuality.poor:
          return Icons.error;
      }
    }
  }

  Color _getColor() {
    switch (quality) {
      case ErrorQuality.good:
        return Colors.green;
      case ErrorQuality.moderate:
        return Colors.orange;
      case ErrorQuality.poor:
        return Colors.red;
    }
  }

  double _getProgressValue() {
    if (isHigherBetter) {
      switch (quality) {
        case ErrorQuality.good:
          return 0.9;
        case ErrorQuality.moderate:
          return 0.6;
        case ErrorQuality.poor:
          return 0.3;
      }
    } else {
      switch (quality) {
        case ErrorQuality.good:
          return 0.9;
        case ErrorQuality.moderate:
          return 0.6;
        case ErrorQuality.poor:
          return 0.3;
      }
    }
  }
}
