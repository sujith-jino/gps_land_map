import 'package:flutter/material.dart';

class HomeStatsCard extends StatelessWidget {
  final Map<String, dynamic> stats;

  const HomeStatsCard({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics',
              style: Theme
                  .of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Overview Stats
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.location_on,
                    value: '${stats['totalPoints'] ?? 0}',
                    label: 'Total Points',
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.sync,
                    value: '${stats['syncedPoints'] ?? 0}',
                    label: 'Synced',
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.sync_disabled,
                    value: '${stats['unsyncedPoints'] ?? 0}',
                    label: 'Unsynced',
                    color: Colors.orange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Land Features
            if (stats['landFeatureCounts'] != null &&
                (stats['landFeatureCounts'] as Map).isNotEmpty) ...[
              Text(
                'Top Land Features',
                style: Theme
                    .of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _buildLandFeaturesChart(stats['landFeatureCounts']),
            ],

            const SizedBox(height: 16),

            // Soil Types
            if (stats['soilTypeCounts'] != null &&
                (stats['soilTypeCounts'] as Map).isNotEmpty) ...[
              Text(
                'Soil Types Distribution',
                style: Theme
                    .of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _buildSoilTypesChart(stats['soilTypeCounts']),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLandFeaturesChart(Map<String, dynamic> landFeatures) {
    final total = landFeatures.values.fold<int>(
        0, (sum, count) => sum + (count as int));

    return Column(
      children: landFeatures.entries.take(5).map((entry) {
        final percentage = (entry.value as int) / total;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  entry.key,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getColorForLandFeature(entry.key),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${entry.value}',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSoilTypesChart(Map<String, dynamic> soilTypes) {
    final total = soilTypes.values.fold<int>(
        0, (sum, count) => sum + (count as int));

    return Column(
      children: soilTypes.entries.take(4).map((entry) {
        final percentage = (entry.value as int) / total;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  entry.key,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getColorForSoilType(entry.key),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${entry.value}',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getColorForLandFeature(String feature) {
    switch (feature.toLowerCase()) {
      case 'forest':
        return Colors.green;
      case 'water body':
        return Colors.blue;
      case 'agricultural land':
        return Colors.yellow[700]!;
      case 'urban area':
        return Colors.grey;
      case 'desert':
        return Colors.orange;
      case 'grassland':
        return Colors.lightGreen;
      case 'rocky terrain':
        return Colors.brown;
      case 'wetland':
        return Colors.teal;
      default:
        return Colors.purple;
    }
  }

  Color _getColorForSoilType(String soilType) {
    switch (soilType.toLowerCase()) {
      case 'clay':
        return Colors.red[300]!;
      case 'sandy':
        return Colors.yellow[600]!;
      case 'loam':
        return Colors.brown[400]!;
      case 'silt':
        return Colors.grey[500]!;
      case 'peat':
        return Colors.brown[800]!;
      case 'chalk':
        return Colors.grey[300]!;
      case 'rocky':
        return Colors.blueGrey;
      default:
        return Colors.brown;
    }
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme
                .of(context)
                .textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 14,
                ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          Text(
            label,
            style: Theme
                .of(context)
                .textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}
