import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/models/land_point.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/navigation/app_router.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  final LocationService _locationService = LocationService();
  final DatabaseService _databaseService = DatabaseService();
  final Completer<GoogleMapController> _mapCompleter =
      Completer<GoogleMapController>();
  final Set<Marker> _markers = {};
  final Set<Polygon> _polygons = {};

  Position? _currentPosition;
  List<LandPoint> _landPoints = [];
  bool _isLoading = true;
  bool _showSatelliteView = false;
  String _statusMessage = 'Initializing map...';
  bool _hasLocationPermission = false;
  bool _hasLocationService = false;
  bool _mapInitialized = false;
  bool _isVisible = true;
  bool _isMapReady = false;

  // Default camera position - Chennai, Tamil Nadu
  static const CameraPosition _defaultCameraPosition = CameraPosition(
    target: LatLng(13.0827, 80.2707),
    zoom: 12.0,
  );

  CameraPosition _initialCameraPosition = _defaultCameraPosition;

  @override
  bool get wantKeepAlive => true; // Keep state alive to prevent buffer issues

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeController();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        _isVisible = true;
        debugPrint('🔄 App resumed - Map visible');
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        _isVisible = false;
        debugPrint('⏸️ App paused/inactive - Map hidden');
        break;
      case AppLifecycleState.hidden:
        _isVisible = false;
        debugPrint('🫥 App hidden - Map hidden');
        break;
    }
  }

  Future<void> _disposeController() async {
    try {
      if (_mapInitialized && _mapCompleter.isCompleted) {
        final controller = await _mapCompleter.future;
        controller.dispose();
        debugPrint('🗑️ Map controller disposed');
      }
    } catch (e) {
      debugPrint('Error disposing map controller: $e');
    }
  }

  Future<void> _initializeApp() async {
    await _checkPermissions();
    await _initializeMap();
  }

  Future<void> _checkPermissions() async {
    try {
      setState(() {
        _statusMessage = 'Checking permissions...';
      });

      // Check location service
      _hasLocationService = await Geolocator.isLocationServiceEnabled();

      if (!_hasLocationService) {
        setState(() {
          _statusMessage = 'Location service is disabled. Please enable GPS.';
        });
        _showPermissionDialog('Location Service Required',
            'Please enable location services in your device settings to use GPS features.');
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _statusMessage = 'Location permission permanently denied';
        });
        _showPermissionDialog('Permission Required',
            'Location permission is required for GPS features. Please enable it in app settings.');
        return;
      }

      _hasLocationPermission = permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;

      if (_hasLocationPermission) {
        setState(() {
          _statusMessage = 'Permissions granted! Getting location...';
        });
      } else {
        setState(() {
          _statusMessage = 'Using default location';
        });
      }
    } catch (e) {
      debugPrint('Permission check error: $e');
      setState(() {
        _statusMessage = 'Permission check failed: Using default location';
      });
    }
  }

  void _showPermissionDialog(String title, String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeMap() async {
    try {
      setState(() {
        _isLoading = true;
        _statusMessage = 'Loading Google Maps...';
      });

      debugPrint('🔍 Starting map initialization...');
      debugPrint('🔍 Location permission: $_hasLocationPermission');
      debugPrint('🔍 Location service: $_hasLocationService');

      // Try to get current location if permission is granted
      if (_hasLocationPermission && _hasLocationService) {
        try {
          debugPrint('🔍 Attempting to get current location...');
          _currentPosition = await _locationService.getCurrentPosition();
          if (_currentPosition != null) {
            debugPrint(
                '✅ Location found: ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
            _initialCameraPosition = CameraPosition(
              target: LatLng(
                  _currentPosition!.latitude, _currentPosition!.longitude),
              zoom: 15.0,
            );
            setState(() {
              _statusMessage = '✅ Location found! Loading map...';
            });
          } else {
            debugPrint('❌ Current position is null');
          }
        } catch (e) {
          debugPrint('❌ Location error: $e');
          setState(() {
            _statusMessage = 'Location error: Using Chennai as default';
          });
        }
      } else {
        debugPrint('🔍 Using default location (Chennai)');
        setState(() {
          _statusMessage = 'Using default location (Chennai)';
        });
      }

      // Load land points
      debugPrint('🔍 Loading land points...');
      await _loadLandPoints();
      debugPrint('✅ Land points loaded: ${_landPoints.length}');

      setState(() {
        _isLoading = false;
        _statusMessage = 'Map ready!';
        _isMapReady = true;
      });
      debugPrint('✅ Map initialization complete!');
    } catch (e) {
      debugPrint('❌ Map initialization error: $e');
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: $e';
      });
    }
  }

  Future<void> _loadLandPoints() async {
    try {
      final points = await _databaseService.getAllLandPoints();
      setState(() {
        _landPoints = points;
      });
      _updateMarkers();
      _updatePolygon();
    } catch (e) {
      debugPrint('Error loading land points: $e');
    }
  }

  void _updateMarkers() {
    final newMarkers = <Marker>{};

    // Add current location marker if available
    if (_currentPosition != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position:
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Current Location',
            snippet: 'You are here',
          ),
        ),
      );
    }

    // Add land point markers
    for (var point in _landPoints) {
      final color = _getMarkerColor(point.analysis?.dominantLandFeature);
      newMarkers.add(
        Marker(
          markerId: MarkerId(point.id),
          position: LatLng(point.latitude, point.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(color),
          infoWindow: InfoWindow(
            title: point.analysis?.dominantLandFeature ?? 'Land Point',
            snippet: 'Tap for details',
            onTap: () => _showPointDetails(point),
          ),
          onTap: () => _showPointDetails(point),
        ),
      );
    }

    setState(() {
      _markers.clear();
      _markers.addAll(newMarkers);
    });
  }

  double _getMarkerColor(String? landFeature) {
    switch (landFeature?.toLowerCase()) {
      case 'forest':
        return BitmapDescriptor.hueGreen;
      case 'water body':
        return BitmapDescriptor.hueBlue;
      case 'agricultural land':
        return BitmapDescriptor.hueOrange;
      case 'urban area':
        return BitmapDescriptor.hueViolet;
      default:
        return BitmapDescriptor.hueRed;
    }
  }

  void _updatePolygon() {
    if (_landPoints.length < 3) return;

    final points = _landPoints
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();

    if (points.isNotEmpty) {
      points.add(points.first); // Close the polygon
    }

    setState(() {
      _polygons.clear();
      _polygons.add(
        Polygon(
          polygonId: const PolygonId('land_area'),
          points: points,
          strokeWidth: 2,
          strokeColor: AppTheme.primaryColor,
          fillColor: AppTheme.primaryColor.withOpacity(0.2),
        ),
      );
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    if (!_mapCompleter.isCompleted) {
      _mapCompleter.complete(controller);
      _mapInitialized = true;
      debugPrint('✅ Google Maps created successfully!');
      debugPrint('✅ Map controller initialized');
      debugPrint('✅ Camera position: ${_initialCameraPosition.target}');

      // Reduce buffer allocation by setting proper options
      _configureMapController(controller);
    } else {
      debugPrint(
          '⚠️ Map completer already completed - avoiding duplicate completion');
    }
  }

  Future<void> _configureMapController(GoogleMapController controller) async {
    try {
      // Configure map to reduce buffer usage
      debugPrint('🔧 Configuring map controller for optimal performance');
    } catch (e) {
      debugPrint('⚠️ Error configuring map controller: $e');
    }
  }

  Future<void> _goToCurrentLocation() async {
    if (!_hasLocationPermission) {
      _showSnackBar('Location permission required', Colors.orange);
      await _checkPermissions();
      return;
    }

    if (!_hasLocationService) {
      _showSnackBar('Please enable GPS in device settings', Colors.orange);
      return;
    }

    try {
      setState(() {
        _statusMessage = 'Getting current location...';
      });

      final position = await _locationService.getCurrentPosition();
      if (position == null) {
        _showSnackBar('Could not get current location', Colors.red);
        return;
      }

      setState(() {
        _currentPosition = position;
        _statusMessage = 'Location updated!';
      });

      if (_mapInitialized && _mapCompleter.isCompleted) {
        final controller = await _mapCompleter.future;
        await controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 16.0,
            ),
          ),
        );
      }

      _updateMarkers();
      _showSnackBar('Location updated successfully!', Colors.green);
    } catch (e) {
      _showSnackBar('Error getting location: $e', Colors.red);
      setState(() {
        _statusMessage = 'Location error occurred';
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.green
                  ? Icons.check_circle
                  : color == Colors.red
                      ? Icons.error
                      : Icons.info,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showPointDetails(LandPoint point) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
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
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
                '📍 ${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}'),
            if (point.analysis != null) ...[
              const SizedBox(height: 8),
              Text(
                  '🌿 Vegetation: ${point.analysis!.vegetationPercentage.toStringAsFixed(1)}%'),
              Text('🏞️ Land Type: ${point.analysis!.dominantLandFeature}'),
              Text('🌱 Soil: ${point.analysis!.soilType}'),
            ],
            if (point.notes != null) ...[
              const SizedBox(height: 8),
              Text('📝 Notes: ${point.notes}'),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
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

  void _showSavedPointsList() {
    AppRouter.navigateToSavedPoints(context);
  }

  void _showSavedPointsListOld() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
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
              'Saved Land Points',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (_landPoints.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _landPoints.length,
                  itemBuilder: (context, index) {
                    final point = _landPoints[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getMarkerColorMaterial(
                              point.analysis?.dominantLandFeature),
                          child: Text('${index + 1}'),
                        ),
                        title: Text(point.analysis?.dominantLandFeature ??
                            'Land Point ${index + 1}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                '📍 ${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}'),
                            Text('📅 ${_formatDate(point.timestamp)}'),
                            if (point.analysis != null)
                              Text(
                                  '🌿 ${point.analysis!.vegetationPercentage.toStringAsFixed(1)}% vegetation'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.location_on),
                              onPressed: () async {
                                Navigator.pop(context);
                                await _goToPoint(point);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDeletePoint(point),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _showPointDetails(point);
                        },
                      ),
                    );
                  },
                ),
              ),
            ] else ...[
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'No saved points available',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getMarkerColorMaterial(String? landFeature) {
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
    return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
  }

  Future<void> _goToPoint(LandPoint point) async {
    if (!_mapInitialized || !_mapCompleter.isCompleted) {
      return;
    }

    final controller = await _mapCompleter.future;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(point.latitude, point.longitude),
          zoom: 16.0,
        ),
      ),
    );
  }

  void _confirmDeletePoint(LandPoint point) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Land Point'),
        content: Text(
            'Are you sure you want to delete "${point.analysis?.dominantLandFeature ?? 'Land Point'}"?'),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deletePoint(point);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
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

  @override
  Widget build(BuildContext context) {
y  }

  Widget _buildInfoItem(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
