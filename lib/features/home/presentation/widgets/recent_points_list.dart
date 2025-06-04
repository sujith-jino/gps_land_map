import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/land_point.dart';
import '../../../../shared/theme/app_theme.dart';

class RecentPointsList extends StatelessWidget {
  final List<LandPoint> points;
  final Function(LandPoint) onPointTap;

  const RecentPointsList({
    super.key,
    required this.points,
    required this.onPointTap,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Card(
        child: Container(
          height: 200,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_off,
                  size: 48,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No land points mapped yet',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Start by taking a photo!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Points',
                  style: Theme
                      .of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${points.length} ${points.length == 1 ? 'point' : 'points'}',
                  style: Theme
                      .of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: points.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final point = points[index];
              return _PointListTile(
                point: point,
                onTap: () => onPointTap(point),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PointListTile extends StatelessWidget {
  final LandPoint point;
  final VoidCallback onTap;

  const _PointListTile({
    required this.point,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, y • HH:mm');

    return Container(
      height: 50, // Force a specific height to prevent overflow
      child: ListTile(
        onTap: onTap,
        leading: _buildLocationIcon(),
        title: _buildTitle(context),
        subtitle: _buildSubtitle(context, dateFormat),
        trailing: _buildTrailing(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        dense: true,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildLocationIcon() {
    final hasAnalysis = point.analysis != null;
    final color = hasAnalysis ? _getColorForLandFeature(
        point.analysis!.dominantLandFeature) : Colors.grey;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        _getIconForLandFeature(point.analysis?.dominantLandFeature),
        color: color,
        size: 24,
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    final hasAnalysis = point.analysis != null;
    final title = hasAnalysis
        ? point.analysis!.dominantLandFeature
        : 'Land Point';

    return Text(
      title,
      style: Theme
          .of(context)
          .textTheme
          .titleSmall
          ?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context, DateFormat dateFormat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${point.latitude.toStringAsFixed(4)}, ${point.longitude
              .toStringAsFixed(4)}',
          style: Theme
              .of(context)
              .textTheme
              .bodySmall
              ?.copyWith(
            color: Colors.grey[600],
                fontSize: 12,
              ),
        ),
        const SizedBox(height: 1),
        Text(
          dateFormat.format(point.timestamp),
          style: Theme
              .of(context)
              .textTheme
              .bodySmall
              ?.copyWith(
            color: Colors.grey[500],
                fontSize: 10,
              ),
        ),
      ],
    );
  }

  Widget _buildTrailing(BuildContext context) {
    return Container(
      width: 70,
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Percentage badge (if available)
          if (point.analysis != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${point.analysis!.vegetationPercentage.toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 2),
          ],

          // Icons in a vertical micro-column
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (point.imagePath != null)
                const Icon(
                  Icons.image,
                  size: 10,
                  color: Colors.blue,
                ),
              Icon(
                point.isSynced ? Icons.cloud_done : Icons.cloud_off,
                size: 10,
                color: point.isSynced ? Colors.green : Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getColorForLandFeature(String feature) {
    switch (feature.toLowerCase()) {
      case 'forest':
        return AppTheme.vegetationColor;
      case 'water body':
        return AppTheme.waterColor;
      case 'agricultural land':
        return AppTheme.agricultureColor;
      case 'urban area':
        return AppTheme.urbanColor;
      case 'desert':
        return Colors.orange;
      case 'grassland':
        return Colors.lightGreen;
      case 'rocky terrain':
        return AppTheme.rockColor;
      case 'wetland':
        return Colors.teal;
      default:
        return Colors.purple;
    }
  }

  IconData _getIconForLandFeature(String? feature) {
    if (feature == null) return Icons.location_on;

    switch (feature.toLowerCase()) {
      case 'forest':
        return Icons.forest;
      case 'water body':
        return Icons.water;
      case 'agricultural land':
        return Icons.agriculture;
      case 'urban area':
        return Icons.location_city;
      case 'desert':
        return Icons.landscape;
      case 'grassland':
        return Icons.grass;
      case 'rocky terrain':
        return Icons.terrain;
      case 'wetland':
        return Icons.waves;
      default:
        return Icons.location_on;
    }
  }
}
