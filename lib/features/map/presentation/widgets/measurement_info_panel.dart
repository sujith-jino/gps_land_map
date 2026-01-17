import 'package:flutter/material.dart';
import '../../../../core/services/land_measurement_service.dart';

class MeasurementInfoPanel extends StatelessWidget {
  final int pointCount;
  final double area;
  final double perimeter;
  final bool isVisible;

  const MeasurementInfoPanel({
    super.key,
    required this.pointCount,
    required this.area,
    required this.perimeter,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.straighten,
                    color: Color(0xFF2E7D32),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Measurement Info',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Points Count
            _buildInfoRow(
              Icons.location_on,
              'Points Added',
              '$pointCount',
              pointCount >= 3 ? Colors.green : Colors.orange,
            ),

            if (pointCount >= 3) ...[
              const SizedBox(height: 12),

              // Total Area
              _buildInfoRow(
                Icons.crop_free,
                'Total Area',
                LandMeasurementService.formatArea(area),
                const Color(0xFF2E7D32),
              ),

              const SizedBox(height: 12),

              // Perimeter
              _buildInfoRow(
                Icons.timeline,
                'Perimeter',
                LandMeasurementService.formatPerimeter(perimeter),
                const Color(0xFF1976D2),
              ),
            ],

            if (pointCount > 0 && pointCount < 3) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange[700],
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Add ${3 - pointCount} more point${3 - pointCount > 1
                            ? 's'
                            : ''} to measure area',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}