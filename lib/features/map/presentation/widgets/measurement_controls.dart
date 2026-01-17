import 'package:flutter/material.dart';

class MeasurementControls extends StatelessWidget {
  final bool isAddingPoints;
  final bool hasPoints;
  final bool canMeasure;
  final VoidCallback onAddPoint;
  final VoidCallback onMeasureArea;
  final VoidCallback onReset;

  const MeasurementControls({
    super.key,
    required this.isAddingPoints,
    required this.hasPoints,
    required this.canMeasure,
    required this.onAddPoint,
    required this.onMeasureArea,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status Indicator
            if (isAddingPoints)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    vertical: 8, horizontal: 12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Tap on map to add points',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            // Control Buttons Row
            Row(
              children: [
                // Add Point Button
                Expanded(
                  child: _buildControlButton(
                    onPressed: onAddPoint,
                    icon: isAddingPoints ? Icons.pause : Icons.add_location,
                    label: isAddingPoints ? 'Stop Adding' : 'Add Point',
                    isPrimary: !isAddingPoints,
                    color: isAddingPoints ? Colors.orange : const Color(
                        0xFF2E7D32),
                  ),
                ),

                const SizedBox(width: 12),

                // Measure Area Button
                Expanded(
                  child: _buildControlButton(
                    onPressed: canMeasure ? onMeasureArea : null,
                    icon: Icons.calculate,
                    label: 'Measure Area',
                    isPrimary: true,
                    color: const Color(0xFF1976D2),
                  ),
                ),

                const SizedBox(width: 12),

                // Reset Button
                _buildIconButton(
                  onPressed: hasPoints ? onReset : null,
                  icon: Icons.refresh,
                  color: Colors.red,
                  tooltip: 'Reset',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required bool isPrimary,
    required Color color,
  }) {
    final isEnabled = onPressed != null;

    return AnimatedOpacity(
      opacity: isEnabled ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 200),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? color : Colors.white,
          foregroundColor: isPrimary ? Colors.white : color,
          side: isPrimary ? null : BorderSide(color: color),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: isPrimary ? 2 : 0,
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required Color color,
    required String tooltip,
  }) {
    final isEnabled = onPressed != null;

    return AnimatedOpacity(
      opacity: isEnabled ? 1.0 : 0.3,
      duration: const Duration(milliseconds: 200),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: color),
          tooltip: tooltip,
          padding: const EdgeInsets.all(12),
        ),
      ),
    );
  }
}