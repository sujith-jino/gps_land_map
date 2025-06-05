import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/models/land_point.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/navigation/app_router.dart';

class SavedPointsPage extends StatefulWidget {
  const SavedPointsPage({super.key});

  @override
  State<SavedPointsPage> createState() => _SavedPointsPageState();
}

class _SavedPointsPageState extends State<SavedPointsPage> {
  final DatabaseService _databaseService = DatabaseService();
  List<LandPoint> _landPoints = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'all';

  final List<String> _filterOptions = [
    'all',
    'forest',
    'water body',
    'agricultural land',
    'urban area',
    'other'
  ];

  @override
  void initState() {
    super.initState();
    _loadLandPoints();
  }

  Future<void> _loadLandPoints() async {
    setState(() => _isLoading = true);
    try {
      final points = await _databaseService.getAllLandPoints();
      setState(() {
        _landPoints = points;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error loading points: $e', Colors.red);
    }
  }

  List<LandPoint> get _filteredPoints {
    var filtered = _landPoints;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((point) {
        return point.analysis?.dominantLandFeature
            ?.toLowerCase()
            .contains(_searchQuery.toLowerCase()) ??
            false ||
                point.notes!.toLowerCase().contains(
                    _searchQuery.toLowerCase()) ??
            false;
      }).toList();
    }

    // Apply category filter
    if (_selectedFilter != 'all') {
      filtered = filtered.where((point) {
        return point.analysis?.dominantLandFeature?.toLowerCase() ==
            _selectedFilter.toLowerCase();
      }).toList();
    }

    return filtered;
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _getMarkerColor(String? landFeature) {
    switch (landFeature?.toLowerCase()) {
      case 'forest':
        return Colors.green;
      case 'water body':
        return Colors.blue;
      case 'agricultural land':
        return Colors.orange;
      case 'urban area':
        return Colors.purple;
      default:
        return Colors.red;
    }
  }

  String _formatDate(DateTime timestamp) {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  String _formatTime(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute
        .toString().padLeft(2, '0')}';
  }

  void _navigateToMap(LandPoint point) {
    Navigator.pop(context, point);
  }

  void _showPointDetails(LandPoint point) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) =>
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                const SizedBox(height: 16),

                Text(
                  point.analysis?.dominantLandFeature ?? 'Land Point',
                  style: Theme
                      .of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Location Info
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${point.latitude.toStringAsFixed(6)}, ${point.longitude
                            .toStringAsFixed(6)}',
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Date & Time
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text('${_formatDate(point.timestamp)} at ${_formatTime(
                        point.timestamp)}'),
                  ],
                ),

                if (point.analysis != null) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Analysis Details
                  Text(
                    'Analysis Details',
                    style: Theme
                        .of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(Icons.eco, color: Colors.green),
                      const SizedBox(width: 8),
                      Text('Vegetation: ${point.analysis!.vegetationPercentage
                          .toStringAsFixed(1)}%'),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(Icons.landscape, color: Colors.brown),
                      const SizedBox(width: 8),
                      Text('Land Type: ${point.analysis!.dominantLandFeature}'),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(Icons.grass, color: Colors.brown),
                      const SizedBox(width: 8),
                      Text('Soil: ${point.analysis!.soilType}'),
                    ],
                  ),
                ],

                if (point.notes != null && point.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.note, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Notes: ${point.notes}')),
                    ],
                  ),
                ],

                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _navigateToMap(point);
                        },
                        icon: const Icon(Icons.map),
                        label: const Text('View on Map'),
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
                        label: const Text('Capture'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  void _confirmDeletePoint(LandPoint point) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Delete Land Point'),
            content: Text(
              'Are you sure you want to delete "${point.analysis
                  ?.dominantLandFeature ??
                  'Land Point'}"?\n\nThis action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deletePoint(point);
                },
                child: const Text(
                    'Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  void _deletePoint(LandPoint point) async {
    try {
      await _databaseService.deleteLandPoint(point.id);
      await _loadLandPoints();
      _showSnackBar('Land point deleted successfully', Colors.green);
    } catch (e) {
      _showSnackBar('Error deleting point: $e', Colors.red);
    }
  }

  void _deleteAllPoints() {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Delete All Points'),
            content: const Text(
              'Are you sure you want to delete ALL saved points?\n\nThis action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    final pointIds = _landPoints.map((p) => p.id).toList();
                    await _databaseService.deleteMultipleLandPoints(pointIds);
                    await _loadLandPoints();
                    _showSnackBar(
                        'All points deleted successfully', Colors.green);
                  } catch (e) {
                    _showSnackBar('Error deleting points: $e', Colors.red);
                  }
                },
                child: const Text(
                    'Delete All', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredPoints = _filteredPoints;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Points'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLandPoints,
            tooltip: 'Refresh',
          ),
          if (_landPoints.isNotEmpty)
            PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) =>
              [
                const PopupMenuItem(
                  value: 'delete_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_forever, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete All Points'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'delete_all') {
                  _deleteAllPoints();
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search points...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Filter Chips
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filterOptions.length,
                    itemBuilder: (context, index) {
                      final filter = _filterOptions[index];
                      final isSelected = _selectedFilter == filter;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter.toUpperCase()),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() => _selectedFilter = filter);
                          },
                          selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Points List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredPoints.isEmpty
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
                    _landPoints.isEmpty
                        ? 'No saved points yet'
                        : 'No points match your search',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _landPoints.isEmpty
                        ? 'Start capturing land points with the camera'
                        : 'Try adjusting your search or filter',
                    style: TextStyle(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredPoints.length,
              itemBuilder: (context, index) {
                final point = filteredPoints[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: _getMarkerColor(
                          point.analysis?.dominantLandFeature),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      point.analysis?.dominantLandFeature ??
                          'Land Point ${index + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${point.latitude.toStringAsFixed(6)}, ${point
                                    .longitude.toStringAsFixed(6)}',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.access_time,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '${_formatDate(point.timestamp)} ${_formatTime(
                                  point.timestamp)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        if (point.analysis != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.eco,
                                  size: 16, color: Colors.green),
                              const SizedBox(width: 4),
                              Text(
                                '${point.analysis!.vegetationPercentage
                                    .toStringAsFixed(1)}% vegetation',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.map, color: Colors.blue),
                          onPressed: () => _navigateToMap(point),
                          tooltip: 'View on Map',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDeletePoint(point),
                          tooltip: 'Delete Point',
                        ),
                      ],
                    ),
                    onTap: () => _showPointDetails(point),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AppRouter.navigateToCamera(context),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add_a_photo, color: Colors.white),
        label: const Text('Add Point', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}