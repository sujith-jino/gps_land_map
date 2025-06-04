import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/models/land_point.dart';
import '../../../../shared/navigation/app_router.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final LocationService _locationService = LocationService();
  final DatabaseService _databaseService = DatabaseService();

  Position? _currentPosition;
  List<LandPoint> _landPoints = [];
  bool _isLoading = true;
  String _viewMode = 'list'; // 'list' or 'grid'

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      setState(() => _isLoading = true);

      // Get current location
      try {
        _currentPosition = await _locationService.getCurrentPosition();
      } catch (e) {
        print('Location error: $e');
      }

      // Load land points from database
      await _loadLandPoints();

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing map: $e')),
        );
      }
    }
  }

  Future<void> _loadLandPoints() async {
    try {
      final points = await _databaseService.getAllLandPoints();
      setState(() {
        _landPoints = points;
      });
    } catch (e) {
      print('Error loading land points: $e');
    }
  }

  void _goToCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentPosition();

      if (position == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get current location')),
        );
        return;
      }

      // position is now guaranteed to be non-null
      final currentPos = position;
      setState(() => _currentPosition = currentPos);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Current Location: ${currentPos.latitude.toStringAsFixed(4)}, ${currentPos.longitude.toStringAsFixed(4)}',
          ),
          action: SnackBarAction(
            label: 'Take Photo',
            onPressed: () => AppRouter.navigateToCamera(context),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  Color _getColorForLandFeature(String? feature) {
    if (feature == null) return Colors.grey;

    switch (feature.toLowerCase()) {
      case 'forest':
        return Colors.green;
      case 'water body':
        return Colors.blue;
      case 'agricultural land':
        return Colors.orange;
      case 'urban area':
        return Colors.purple;
      case 'desert':
        return Colors.orange.shade700;
      case 'grassland':
        return Colors.lightGreen;
      case 'rocky terrain':
        return Colors.brown;
      case 'wetland':
        return Colors.teal;
      default:
        return Colors.grey;
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

  void _showPointDetails(LandPoint point) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title with icon
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getColorForLandFeature(
                                point.analysis?.dominantLandFeature)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getIconForLandFeature(
                            point.analysis?.dominantLandFeature),
                        color: _getColorForLandFeature(
                            point.analysis?.dominantLandFeature),
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            point.analysis?.dominantLandFeature ?? 'Land Point',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            'Captured ${_formatDate(point.timestamp)}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Location info
                _buildInfoCard([
                  _buildInfoRow(Icons.location_on, 'Coordinates',
                      '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}'),
                  if (_currentPosition != null)
                    _buildInfoRow(
                        Icons.straighten,
                        'Distance from current location',
                        '${_calculateDistance(point).toStringAsFixed(2)} km'),
                ]),

                if (point.analysis != null) ...[
                  const SizedBox(height: 16),
                  _buildInfoCard([
                    _buildInfoRow(Icons.landscape, 'Land Feature',
                        point.analysis!.dominantLandFeature),
                    _buildInfoRow(Icons.grass, 'Vegetation Coverage',
                        '${point.analysis!.vegetationPercentage.toStringAsFixed(1)}%'),
                    _buildInfoRow(
                        Icons.terrain, 'Soil Type', point.analysis!.soilType),
                  ]),
                ],

                if (point.notes != null) ...[
                  const SizedBox(height: 16),
                  _buildInfoCard([
                    _buildInfoRow(Icons.note, 'Notes', point.notes!),
                  ]),
                ],

                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showNavigationOptions(point);
                        },
                        icon: const Icon(Icons.navigation),
                        label: const Text('Navigate'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          AppRouter.navigateToCamera(context);
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Take Photo'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  double _calculateDistance(LandPoint point) {
    if (_currentPosition == null) return 0.0;

    return Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          point.latitude,
          point.longitude,
        ) /
        1000; // Convert to kilometers
  }

  void _showNavigationOptions(LandPoint point) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Navigation Options',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.map, color: Colors.blue),
              title: const Text('Open in Google Maps'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Launch Google Maps with coordinates
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Coordinates: ${point.latitude}, ${point.longitude}'),
                    action: SnackBarAction(
                      label: 'Copy',
                      onPressed: () {
                        // TODO: Copy to clipboard
                      },
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.green),
              title: const Text('Share Location'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Share coordinates
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sharing feature coming soon!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLandPointCard(LandPoint point) {
    final color = _getColorForLandFeature(point.analysis?.dominantLandFeature);
    final distance =
        _currentPosition != null ? _calculateDistance(point) : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showPointDetails(point),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getIconForLandFeature(point.analysis?.dominantLandFeature),
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      point.analysis?.dominantLandFeature ?? 'Land Point',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(point.timestamp),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Distance and status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (distance != null) ...[
                    Text(
                      '${distance.toStringAsFixed(1)} km',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (point.analysis != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${point.analysis!.vegetationPercentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Icon(
                    point.isSynced ? Icons.cloud_done : Icons.cloud_off,
                    size: 16,
                    color: point.isSynced ? Colors.green : Colors.orange,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentLocationCard() {
    if (_currentPosition == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 3,
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.my_location,
                color: Colors.blue,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Location',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => AppRouter.navigateToCamera(context),
              icon: const Icon(Icons.add_a_photo, size: 18),
              label: const Text('Capture'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.mapView),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _goToCurrentLocation,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLandPoints,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'filter':
                  // TODO: Implement filter
                  break;
                case 'export':
                  // TODO: Implement export
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'filter',
                child: Row(
                  children: [
                    Icon(Icons.filter_list),
                    SizedBox(width: 8),
                    Text('Filter Points'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Export Data'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Current location card
                _buildCurrentLocationCard(),

                // Stats summary
                if (_landPoints.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text(
                              '${_landPoints.length}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text('Total Points'),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              '${_landPoints.where((p) => p.analysis != null).length}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text('Analyzed'),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              '${_landPoints.where((p) => p.isSynced).length}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text('Synced'),
                          ],
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Land points list
                Expanded(
                  child: _landPoints.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_off,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No land points mapped yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start by taking a photo!',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () =>
                                    AppRouter.navigateToCamera(context),
                                icon: const Icon(Icons.camera_alt),
                                label: const Text('Take First Photo'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _landPoints.length,
                          itemBuilder: (context, index) {
                            return _buildLandPointCard(_landPoints[index]);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AppRouter.navigateToCamera(context),
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Add Point'),
      ),
    );
  }
}
