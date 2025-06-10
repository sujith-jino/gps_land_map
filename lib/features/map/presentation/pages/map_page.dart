import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/models/land_point.dart';
import '../../../../core/models/distance_measurement.dart';
import '../../../../core/services/distance_measurement_service.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _mapController;
  final DatabaseService _databaseService = DatabaseService();
  final DistanceMeasurementService _distanceMeasurementService =
      DistanceMeasurementService();

  LatLng? _currentLocation;
  final Set<Marker> _markers = {};
  List<LandPoint> _landPoints = [];
  bool _isLoading = true;
  MapType _currentMapType = MapType.normal;
  bool _isTrafficEnabled = false;
  bool _isFabOpen = false;

  // Measurement state
  bool _isDistanceMeasuring = false;
  bool _isMarkerMeasuring = false;
  bool _isFieldMeasuring = false;
  final List<LatLng> _distancePoints = [];
  final List<MarkerData> _customMarkers = [];
  final List<LatLng> _fieldPoints = [];
  final Set<Polyline> _polylines = {};
  final Set<Polygon> _polygons = {};
  double _totalDistance = 0.0;
  double _fieldArea = 0.0;
  double _fieldPerimeter = 0.0;
  int _markerCounter = 0;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await _getCurrentLocation();
      await _loadLandPoints();
      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error initializing map: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showError('Location permissions are permanently denied');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });

      if (_mapController != null && _currentLocation != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_currentLocation!, 15.0),
        );
      }
    } catch (e) {
      _showError('Failed to get location: $e');
    }
  }

  Future<void> _loadLandPoints() async {
    try {
      final points = await _databaseService.getAllLandPoints();
      if (!mounted) return;
      setState(() {
        _landPoints = points;
        _updateMarkers();
      });
    } catch (e) {
      _showError('Error loading land points: $e');
    }
  }

  // Helper method to create consistent marker style
  BitmapDescriptor _createMarkerIcon(Color color) {
    return BitmapDescriptor.defaultMarkerWithHue(
      _colorToHue(color),
    );
  }

  // Convert Color to BitmapDescriptor hue
  double _colorToHue(Color color) {
    if (color == Colors.blue) return BitmapDescriptor.hueAzure;
    if (color == Colors.green) return BitmapDescriptor.hueGreen;
    if (color == Colors.red) return BitmapDescriptor.hueRed;
    if (color == Colors.orange) return BitmapDescriptor.hueOrange;
    if (color == Colors.purple) return BitmapDescriptor.hueViolet;
    return BitmapDescriptor.hueRose; // Default
  }

  void _updateMarkers() {
    if (!mounted) return;
    _markers.clear();

    // 1. Current Location Marker
    if (_currentLocation != null) {
      _addLocationMarker();
    }

    // 2. Field Measurement Markers
    for (int i = 0; i < _fieldPoints.length; i++) {
      _addFieldMarker(i);
    }

    // 3. Distance Measurement Markers
    for (int i = 0; i < _distancePoints.length; i++) {
      _addDistanceMarker(i);
    }

    // 4. Custom Markers
    for (int i = 0; i < _customMarkers.length; i++) {
      _addCustomMarkerPoint(i);
    }

    // 5. Land Point Markers
    for (int i = 0; i < _landPoints.length; i++) {
      _addLandPointMarker(i);
    }
  }

  void _addLocationMarker() {
    _markers.add(
      Marker(
        markerId: const MarkerId('current_location'),
        position: _currentLocation!,
        icon: _createMarkerIcon(Colors.blue),
        anchor: const Offset(0.5, 1.0),
        infoWindow: const InfoWindow(title: 'Your Location'),
        onTap: () => _showLocationPopup(),
      ),
    );
  }

  void _addFieldMarker(int index) {
    final point = _fieldPoints[index];
    _markers.add(
      Marker(
        markerId: MarkerId('field_point_$index'),
        position: point,
        icon: _createMarkerIcon(Colors.orange),
        anchor: const Offset(0.5, 1.0),
        infoWindow: InfoWindow(
          title: 'Field Point ${index + 1}',
          snippet: 'Tap for details',
        ),
        onTap: () => _showFieldPointPopup(index),
      ),
    );
  }

  void _addDistanceMarker(int index) {
    final isStart = index == 0;
    _markers.add(
      Marker(
        markerId: MarkerId('distance_point_$index'),
        position: _distancePoints[index],
        icon: _createMarkerIcon(isStart ? Colors.green : Colors.red),
        anchor: const Offset(0.5, 1.0),
        infoWindow: InfoWindow(
          title: isStart ? 'Start Point' : 'Point ${index + 1}',
          snippet: 'Tap for measurement',
        ),
        onTap: () => _showDistancePointPopup(index, isStart),
      ),
    );
  }

  void _addCustomMarkerPoint(int index) {
    final marker = _customMarkers[index];
    _markers.add(
      Marker(
        markerId: MarkerId('custom_${marker.id}'),
        position: marker.position,
        icon: _createMarkerIcon(Colors.purple),
        anchor: const Offset(0.5, 1.0),
        infoWindow: InfoWindow(
          title: marker.title,
          snippet: 'Custom marker',
        ),
        onTap: () => _showCustomMarkerPopup(marker, index),
      ),
    );
  }

  void _addLandPointMarker(int index) {
    final point = _landPoints[index];
    final landType = point.analysis?.dominantLandFeature ?? 'Land Point';
    _markers.add(
      Marker(
        markerId: MarkerId('land_point_$index'),
        position: LatLng(point.latitude, point.longitude),
        icon: _createMarkerIcon(_getMarkerColorFromHue(_getMarkerColor(landType))),
        anchor: const Offset(0.5, 1.0),
        infoWindow: InfoWindow(
          title: landType,
          snippet: 'Tap for details',
        ),
        onTap: () => _showLandPointPopup(point, index),
      ),
    );
  }

  // Popup methods
  void _showLocationPopup() {
    _showCleanMarkerPopup(
      position: _currentLocation!,
      title: '📍 My Location',
      subtitle: 'Current GPS Position',
      color: Colors.blue,
      icon: Icons.my_location,
      details: [
        'Latitude: ${_currentLocation!.latitude.toStringAsFixed(6)}',
        'Longitude: ${_currentLocation!.longitude.toStringAsFixed(6)}',
        'Updated: ${DateTime.now().toString().split(' ')[1].substring(0, 5)}',
      ],
    );
  }

  void _showFieldPointPopup(int index) {
    _showCleanMarkerPopup(
      position: _fieldPoints[index],
      title: '🌾 Field Point ${index + 1}',
      subtitle: 'Boundary Marker',
      color: Colors.orange,
      icon: Icons.agriculture,
      details: [
        'Latitude: ${_fieldPoints[index].latitude.toStringAsFixed(6)}',
        'Longitude: ${_fieldPoints[index].longitude.toStringAsFixed(6)}',
        'Sequence: ${index + 1} of ${_fieldPoints.length}',
        if (_fieldPoints.length >= 3) 'Area: ${_formatArea(_fieldArea)}',
        if (_fieldPoints.length >= 3) 'Perimeter: ${_formatDistance(_fieldPerimeter)}',
      ],
    );
  }

  void _showDistancePointPopup(int index, bool isStart) {
    double? segmentDistance;
    if (index > 0) {
      segmentDistance = Geolocator.distanceBetween(
        _distancePoints[index - 1].latitude,
        _distancePoints[index - 1].longitude,
        _distancePoints[index].latitude,
        _distancePoints[index].longitude,
      );
    }

    _showCleanMarkerPopup(
      position: _distancePoints[index],
      title: isStart ? '🟢 Start Point' : '📏 Point ${index + 1}',
      subtitle: isStart ? 'Measurement Start' : 'Measurement Point',
      color: isStart ? Colors.green : Colors.red,
      icon: isStart ? Icons.play_arrow : Icons.straighten,
      details: [
        'Latitude: ${_distancePoints[index].latitude.toStringAsFixed(6)}',
        'Longitude: ${_distancePoints[index].longitude.toStringAsFixed(6)}',
        if (segmentDistance != null) 'Segment: ${_formatDistance(segmentDistance)}',
        if (_distancePoints.length > 1) 'Total: ${_formatDistance(_totalDistance)}',
      ],
    );
  }

  void _showCustomMarkerPopup(MarkerData marker, int index) {
    _showCleanMarkerPopup(
      position: marker.position,
      title: '🎯 ${marker.title}',
      subtitle: 'Custom Marker',
      color: Colors.purple,
      icon: Icons.place,
      details: [
        'Latitude: ${marker.position.latitude.toStringAsFixed(6)}',
        'Longitude: ${marker.position.longitude.toStringAsFixed(6)}',
        'Created: ${marker.description}',
      ],
    );
  }

  void _showLandPointPopup(LandPoint point, int index) {
    final markerColor = _getMarkerColorFromHue(_getMarkerColor(point.analysis?.dominantLandFeature));
    
    _showCleanMarkerPopup(
      position: LatLng(point.latitude, point.longitude),
      title: '🗺️ ${point.analysis?.dominantLandFeature ?? 'Land Point'}',
      subtitle: 'Surveyed Location',
      color: markerColor,
      icon: Icons.terrain,
      details: [
        'Latitude: ${point.latitude.toStringAsFixed(6)}',
        'Longitude: ${point.longitude.toStringAsFixed(6)}',
        'Surveyed: ${point.timestamp.toLocal().toString().split('.')[0]}',
        if (point.notes?.isNotEmpty ?? false)
          'Notes: ${point.notes!.length > 50 ? '${point.notes!.substring(0, 50)}...' : point.notes!}',
      ],
      onNavigate: () => _navigateToPoint(point),
    );
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
      case 'desert':
        return BitmapDescriptor.hueYellow;
      case 'grassland':
        return BitmapDescriptor.hueGreen;
      case 'rocky terrain':
        return BitmapDescriptor.hueRed;
      default:
        return BitmapDescriptor.hueRed;
    }
  }

  Color _getMarkerColorFromHue(double hue) {
    switch (hue) {
      case BitmapDescriptor.hueGreen:
        return Colors.green;
      case BitmapDescriptor.hueBlue:
        return Colors.blue;
      case BitmapDescriptor.hueOrange:
        return Colors.orange;
      case BitmapDescriptor.hueViolet:
        return Colors.purple;
      case BitmapDescriptor.hueYellow:
        return Colors.yellow;
      case BitmapDescriptor.hueRed:
      default:
        return Colors.red;
    }
  }

  void _showPointDetails(LandPoint point) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
                width: 32,
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
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _navigateToPoint(point);
                    },
                    icon: const Icon(Icons.directions),
                    label: const Text('Directions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToPoint(LandPoint point) {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(point.latitude, point.longitude),
          18.0,
        ),
      );
    }
  }

  void _onMapTap(LatLng position) {
    print('Map tapped at: ${position.latitude}, ${position.longitude}');
    print('Field measuring: $_isFieldMeasuring');
    print('Distance measuring: $_isDistanceMeasuring');
    print('Marker measuring: $_isMarkerMeasuring');

    // Handle field measurement - LAND SELECTION
    if (_isFieldMeasuring) {
      if (!mounted) return;
      setState(() {
        _fieldPoints.add(position);
        _updateFieldMeasurement();
      });

      // Show precise GPS coordinates for each point
      _showLandPointAddedDialog(position, _fieldPoints.length);
      return;
    }

    // Handle distance measurement
    if (_isDistanceMeasuring) {
      if (!mounted) return;
      setState(() {
        _distancePoints.add(position);
        _updateDistanceMeasurement();
      });
      _showInfo('📏 Distance point ${_distancePoints.length} added');
      return;
    }

    // Handle marker measurement
    if (_isMarkerMeasuring) {
      _addCustomMarker(position);
      return;
    }

    // Normal map clicks - show coordinates popup
    _showCoordinatePopup(position);
  }

  void _showCoordinatePopup(LatLng position) {
    _showCleanMarkerPopup(
      position: position,
      title: '📍 GPS Coordinates',
      subtitle: 'Tap to add measurement',
      color: Colors.blue,
      icon: Icons.gps_fixed,
      details: [
        'Latitude: ${position.latitude.toStringAsFixed(8)}',
        'Longitude: ${position.longitude.toStringAsFixed(8)}',
        'Decimal Degrees: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
        'Accuracy: High precision GPS',
        'Time: ${DateTime.now().toLocal().toString().split('.')[0]}',
      ],
      onNavigate: () => _addLandmarkAtPosition(position),
    );
  }

  Future<void> _addLandmarkAtPosition(LatLng position) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.place_outlined,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Add GPS Landmark'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GPS Coordinates',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Latitude: ${position.latitude.toStringAsFixed(8)}'),
                    Text('Longitude: ${position.longitude.toStringAsFixed(8)}'),
                    Text('Precision: ±3 meters'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Landmark Name',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.label),
                  hintText: 'e.g., Survey Point 1, Boundary Corner',
                ),
                onChanged: (value) => {},
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.notes),
                  hintText: 'Add notes about this landmark...',
                ),
                maxLines: 3,
                onChanged: (value) => {},
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context,
                {'name': 'GPS Landmark', 'notes': 'Added via map click'}),
            icon: const Icon(Icons.add_location),
            label: const Text('Add Landmark'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (result != null) {
      await _saveLandmarkPoint(position, result['name']!, result['notes']!);
    }
  }

  Future<void> _saveLandmarkPoint(
      LatLng position, String name, String notes) async {
    try {
      _showLoadingDialog('Saving GPS Landmark...');

      final landmarkNotes = '''📍 GPS Landmark: $name
  ${notes.isNotEmpty ? '📝 $notes\n' : ''}
  📊 GPS DETAILS:
  • Latitude: ${position.latitude.toStringAsFixed(8)}
  • Longitude: ${position.longitude.toStringAsFixed(8)}
  • Precision: High accuracy GPS
  • Coordinate System: WGS84
  
  ⏰ Recorded on: ${DateTime.now().toLocal().toString().split('.')[0]}''';

      final landPoint = LandPoint(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
        notes: landmarkNotes,
        analysis: null,
      );

      await _databaseService.saveLandPoint(landPoint);
      Navigator.pop(context); // Hide loading
      await _loadLandPoints(); // Reload to show new point

      _showSuccessDialog(
        title: '📍 GPS Landmark Saved!',
        message: 'Landmark "$name" has been saved successfully',
        details: 'GPS coordinates stored with high precision',
      );
    } catch (e) {
      Navigator.pop(context);
      _showErrorDialog('Failed to save GPS landmark', e.toString());
    }
  }

  void _goToCurrentLocation() async {
    if (_currentLocation != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          _currentLocation!,
          16.0,
        ),
      );
    } else {
      await _getCurrentLocation();
    }
  }

  void _showMapTypeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Map Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text('Default'),
              trailing: _currentMapType == MapType.normal
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () {
                setState(() => _currentMapType = MapType.normal);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.satellite),
              title: const Text('Satellite'),
              trailing: _currentMapType == MapType.satellite
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () {
                setState(() => _currentMapType = MapType.satellite);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.terrain),
              title: const Text('Terrain'),
              trailing: _currentMapType == MapType.terrain
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () {
                setState(() => _currentMapType = MapType.terrain);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Traffic'),
              value: _isTrafficEnabled,
              onChanged: (value) {
                setState(() => _isTrafficEnabled = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Show dialog when land point is added
  void _showLandPointAddedDialog(LatLng position, int pointNumber) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.green.shade50, Colors.green.shade100],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.agriculture,
                    color: Colors.white, size: 32),
              ),
              const SizedBox(height: 16),

              Text(
                '🌾 Land Point $pointNumber Added',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 16),

              // GPS Coordinates Display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.gps_fixed,
                            color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        const Text('GPS Coordinates',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(),
                    _buildCoordinateDisplayRow('Latitude', position.latitude),
                    const SizedBox(height: 8),
                    _buildCoordinateDisplayRow('Longitude', position.longitude),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.place, color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Text('Point: $pointNumber of ${_fieldPoints.length}'),
                      ],
                    ),
                  ],
                ),
              ),

              // Land Progress Info
              if (_fieldPoints.length >= 3) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info, color: Colors.green),
                          const SizedBox(width: 8),
                          const Text('Land Area Calculated',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Area: ${_formatArea(_fieldArea)}'),
                      Text('Perimeter: ${_formatDistance(_fieldPerimeter)}'),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  if (_fieldPoints.length >= 3) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showCompletedLandDialog();
                        },
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Complete Land'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.add_location, size: 18),
                      label: const Text('Add More Points'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoordinateDisplayRow(String label, double value) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child:
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: Text(
            value.toStringAsFixed(8),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ),
        IconButton(
          onPressed: () async {
            await Clipboard.setData(
                ClipboardData(text: value.toStringAsFixed(8)));
            _showInfo('$label copied!');
          },
          icon: const Icon(Icons.copy, size: 16, color: Colors.green),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  // Show complete land details dialog
  void _showCompletedLandDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.green.shade50, Colors.green.shade100],
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with animation
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.landscape,
                          color: Colors.white, size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        '🎉 Land Measurement Complete!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_fieldPoints.length} Points Successfully Mapped',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Main Land Summary with enhanced design
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green.shade200, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.analytics,
                                color: Colors.green.shade700),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Land Measurement Summary',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Enhanced measurement cards
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.green.shade50,
                                    Colors.green.shade100
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: Colors.green.shade200),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.crop_free,
                                      color: Colors.green.shade700, size: 32),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Total Area',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatArea(_fieldArea),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue.shade50,
                                    Colors.blue.shade100
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.straighten,
                                      color: Colors.blue.shade700, size: 32),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Perimeter',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDistance(_fieldPerimeter),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Additional details
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            _buildDetailRow(
                                '📍 Total Points', '${_fieldPoints.length}'),
                            _buildDetailRow('⏰ Completion Time',
                                DateTime.now().toString().split('.')[0]),
                            _buildDetailRow('🎯 Measurement Type',
                                'Field Boundary Mapping'),
                            _buildDetailRow(
                                '📏 Precision Level', 'High Accuracy GPS'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Enhanced GPS Coordinates Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade200, width: 2),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.gps_fixed,
                                color: Colors.blue.shade700),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Complete GPS Coordinates',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: SingleChildScrollView(
                          child: Column(
                            children:
                                List.generate(_fieldPoints.length, (index) {
                              final point = _fieldPoints[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.blue.shade50, Colors.white],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: Colors.blue.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.blue,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'Point ${index + 1}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          onPressed: () async {
                                            await Clipboard.setData(ClipboardData(
                                                text:
                                                    '${point.latitude.toStringAsFixed(8)}, ${point.longitude.toStringAsFixed(8)}'));
                                            _showInfo(
                                                'Point ${index + 1} coordinates copied!');
                                          },
                                          icon: const Icon(Icons.copy,
                                              size: 16, color: Colors.blue),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Text('Lat: ',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w500)),
                                        Expanded(
                                          child: Text(
                                            point.latitude.toStringAsFixed(8),
                                            style: const TextStyle(
                                              fontFamily: 'monospace',
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        const Text('Lng: ',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w500)),
                                        Expanded(
                                          child: Text(
                                            point.longitude.toStringAsFixed(8),
                                            style: const TextStyle(
                                              fontFamily: 'monospace',
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Enhanced Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _shareCompleteLandData();
                        },
                        icon: const Icon(Icons.share, size: 20),
                        label: const Text('Share Details'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showFieldSaveDialog();
                        },
                        icon: const Icon(Icons.save, size: 20),
                        label: const Text('Save Land'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Close button
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Text(
                      'Continue Measuring',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _shareCompleteLandData() {
    final shareText = '''🌾 COMPLETE LAND MEASUREMENT REPORT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎉 MEASUREMENT COMPLETED SUCCESSFULLY!

📊 LAND SUMMARY:
• Total Area: ${_formatArea(_fieldArea)}
• Perimeter: ${_formatDistance(_fieldPerimeter)}
• Total Points: ${_fieldPoints.length}
• Measurement Type: Field Boundary Mapping
• Precision Level: High Accuracy GPS
• Completion Time: ${DateTime.now().toLocal().toString().split('.')[0]}

📍 COMPLETE GPS COORDINATES:
${_fieldPoints.asMap().entries.map((entry) {
      final index = entry.key;
      final point = entry.value;
      return '''Point ${index + 1}:
  • Latitude:  ${point.latitude.toStringAsFixed(8)}
  • Longitude: ${point.longitude.toStringAsFixed(8)}
  • Decimal:   ${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}''';
    }).join('\n\n')}

🗺️ GOOGLE MAPS LINKS:
${_fieldPoints.asMap().entries.map((entry) {
      final index = entry.key;
      final point = entry.value;
      return 'Point ${index + 1}: https://maps.google.com/?q=${point.latitude},${point.longitude}';
    }).join('\n')}

📈 MEASUREMENT ANALYSIS:
• Shape: ${_fieldPoints.length}-sided polygon
• Average Point Distance: ${(_fieldPerimeter / _fieldPoints.length).toStringAsFixed(1)} m
• Coordinate System: WGS84 (World Geodetic System)
• Measurement Method: GPS Field Survey

📱 Generated by GPS Land Mapper App
⏰ Report Generated: ${DateTime.now().toLocal().toString()}

═══════════════════════════════════════
This report contains high-precision GPS coordinates for accurate land boundary mapping and surveying purposes.''';

    Share.share(shareText, subject: 'Complete Land Measurement Report');
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog({
    required String title,
    required String message,
    required String details,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(color: Colors.green)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 8),
            Text(details,
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(color: Colors.red)),
        content: Text(error),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveFieldMeasurement(String name, String notes) async {
    try {
      // Show loading
      _showLoadingDialog('Saving Field Measurement...');

      // Calculate center point
      final centerLat =
          _fieldPoints.map((p) => p.latitude).reduce((a, b) => a + b) /
              _fieldPoints.length;
      final centerLng =
          _fieldPoints.map((p) => p.longitude).reduce((a, b) => a + b) /
              _fieldPoints.length;

      // Create a clean coordinate list
      final coordinateList = _fieldPoints.asMap().entries.map((entry) {
        final index = entry.key;
        final point = entry.value;
        return 'P${index + 1}: ${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}';
      }).join('\n');

      final fieldNotes = '''🌾 Field Measurement: $name
${notes.isNotEmpty ? '📝 $notes\n' : ''}
📊 FIELD SUMMARY:
• Area: ${_formatArea(_fieldArea)}
• Perimeter: ${_formatDistance(_fieldPerimeter)}
• Total Points: ${_fieldPoints.length}
• Center Point: ${centerLat.toStringAsFixed(6)}, ${centerLng.toStringAsFixed(6)}

📍 ALL FIELD COORDINATES:
$coordinateList

⏰ Measured on: ${DateTime.now().toLocal().toString().split('.')[0]}''';

      final landPoint = LandPoint(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        latitude: centerLat,
        longitude: centerLng,
        timestamp: DateTime.now(),
        notes: fieldNotes,
        analysis: null,
      );

      await _databaseService.saveLandPoint(landPoint);

      // Hide loading
      Navigator.pop(context);

      // Clear measurement data with animation
      await _clearFieldMeasurement();

      // Reload points to show the new one
      await _loadLandPoints();

      // Show success with enhanced feedback
      _showSuccessDialog(
        title: '✅ Field Saved Successfully!',
        message:
            'Field "$name" has been saved with ${_fieldPoints.length} points',
        details:
            'Area: ${_formatArea(_fieldArea)} • Perimeter: ${_formatDistance(_fieldPerimeter)}',
      );

    } catch (e) {
      Navigator.pop(context); // Hide loading
      _showErrorDialog('Failed to save field measurement', e.toString());
    }
  }

  Future<void> _saveDistanceMeasurementWithDialog(
      String name, String notes) async {
    try {
      _showLoadingDialog('Saving Distance Measurement...');

      // Convert LatLng points to MeasurementPoint objects
      final List<MeasurementPoint> measurementPoints = [];
      for (int i = 0; i < _distancePoints.length; i++) {
        double? distanceFromPrevious;
        if (i > 0) {
          distanceFromPrevious = Geolocator.distanceBetween(
            _distancePoints[i - 1].latitude,
            _distancePoints[i - 1].longitude,
            _distancePoints[i].latitude,
            _distancePoints[i].longitude,
          );
        }
        measurementPoints.add(
          MeasurementPoint.fromLatLng(_distancePoints[i], i + 1,
              distanceFromPrevious: distanceFromPrevious),
        );
      }

      final measurement = DistanceMeasurement.create(
        points: measurementPoints,
        totalDistance: _totalDistance,
        name: name,
        notes: notes.isNotEmpty
            ? notes
            : 'Distance measurement with ${_distancePoints.length} points',
      );

      await _distanceMeasurementService.saveMeasurement(measurement);

      // Also create a land point
      final startPoint = _distancePoints.first;
      final distanceNotes = '''📏 Distance Measurement: $name
${notes.isNotEmpty ? '📝 $notes\n' : ''}
📊 MEASUREMENT SUMMARY:
• Total Distance: ${_formatDistance(_totalDistance)}
• Points: ${_distancePoints.length}
• Start Point: ${startPoint.latitude.toStringAsFixed(6)}, ${startPoint.longitude.toStringAsFixed(6)}

📍 FULL PATH COORDINATES:
${_distancePoints.asMap().entries.map((entry) {
        final index = entry.key;
        final point = entry.value;
        return 'P${index + 1}: ${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}';
      }).join('\n')}

⏰ Measured on: ${DateTime.now().toLocal().toString().split('.')[0]}''';

      final landPoint = LandPoint(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        latitude: startPoint.latitude,
        longitude: startPoint.longitude,
        timestamp: DateTime.now(),
        notes: distanceNotes,
        analysis: null,
      );

      await _databaseService.saveLandPoint(landPoint);

      Navigator.pop(context); // Hide loading

      // Clear measurement with animation
      await _clearDistanceMeasurement();

      // Reload points
      await _loadLandPoints();

      _showSuccessDialog(
        title: '📏 Distance Saved Successfully!',
        message:
            'Distance "$name" has been saved with ${_distancePoints.length} points',
        details: 'Total Distance: ${_formatDistance(_totalDistance)}',
      );

    } catch (e) {
      Navigator.pop(context);
      _showErrorDialog('Failed to save distance measurement', e.toString());
    }
  }

  // Measurement methods
  void _startFieldMeasure() {
    if (!mounted) return;
    setState(() {
      _isFieldMeasuring = true;
      _isDistanceMeasuring = false;
      _isMarkerMeasuring = false;
      _fieldPoints.clear();
      _fieldArea = 0.0;
      _fieldPerimeter = 0.0;
      _polygons.clear();
      _updateMarkers();
    });
    _showInfo('Tap on map to add field measurement points');
  }

  void _startDistanceMeasure() {
    if (!mounted) return;
    setState(() {
      _isDistanceMeasuring = true;
      _isMarkerMeasuring = false;
      _isFieldMeasuring = false;
      _distancePoints.clear();
      _totalDistance = 0.0;
      _polylines.clear();
      _updateMarkers();
    });
    _showInfo('Tap on map to add distance measurement points');
  }

  void _startMarkerMeasure() {
    if (!mounted) return;
    setState(() {
      _isMarkerMeasuring = true;
      _isDistanceMeasuring = false;
      _isFieldMeasuring = false;
      _updateMarkers();
    });
    _showInfo('Tap on map to add markers');
  }

  void _stopMeasuring() {
    if (!mounted) return;
    setState(() {
      _isDistanceMeasuring = false;
      _isMarkerMeasuring = false;
      _isFieldMeasuring = false;
      _distancePoints.clear();
      _customMarkers.clear();
      _fieldPoints.clear();
      _polylines.clear();
      _polygons.clear();
      _totalDistance = 0.0;
      _fieldArea = 0.0;
      _fieldPerimeter = 0.0;
      _markerCounter = 0;
      _updateMarkers();
    });
    _showInfo('🔄 Measurement stopped and cleared');
  }

  Future<void> _clearFieldMeasurement() async {
    if (!mounted) return;

    // Animate the clearing
    for (int i = _fieldPoints.length - 1; i >= 0; i--) {
      setState(() {
        _fieldPoints.removeAt(i);
        _updateFieldMeasurement();
      });
      await Future.delayed(const Duration(milliseconds: 100));
    }

    setState(() {
      _isFieldMeasuring = false;
      _fieldArea = 0.0;
      _fieldPerimeter = 0.0;
      _polygons.clear();
      _updateMarkers();
    });
  }

  Future<void> _clearDistanceMeasurement() async {
    if (!mounted) return;

    for (int i = _distancePoints.length - 1; i >= 0; i--) {
      setState(() {
        _distancePoints.removeAt(i);
        _updateDistanceMeasurement();
      });
      await Future.delayed(const Duration(milliseconds: 100));
    }

    setState(() {
      _isDistanceMeasuring = false;
      _totalDistance = 0.0;
      _polylines.clear();
      _updateMarkers();
    });
  }

  Future<void> _clearMarkerMeasurement() async {
    if (!mounted) return;

    for (int i = _customMarkers.length - 1; i >= 0; i--) {
      setState(() {
        _customMarkers.removeAt(i);
        _updateMarkers();
      });
      await Future.delayed(const Duration(milliseconds: 100));
    }

    setState(() {
      _isMarkerMeasuring = false;
      _markerCounter = 0;
      _updateMarkers();
    });
  }

  void _updateFieldMeasurement() {
    if (!mounted) return;
    _polygons.clear();

    if (_fieldPoints.length >= 3) {
      _polygons.add(
        Polygon(
          polygonId: const PolygonId('field_polygon'),
          points: _fieldPoints,
          fillColor: Colors.green.withOpacity(0.3),
          strokeColor: Colors.green,
          strokeWidth: 3,
        ),
      );

      // Calculate area and perimeter
      _calculateFieldArea();
      _calculateFieldPerimeter();
    }

    _updateMarkers();
  }

  void _calculateFieldArea() {
    if (_fieldPoints.length < 3) {
      _fieldArea = 0.0;
      return;
    }

    // Using the shoelace formula for polygon area
    double area = 0.0;
    int n = _fieldPoints.length;

    for (int i = 0; i < n; i++) {
      int j = (i + 1) % n;
      area += _fieldPoints[i].latitude * _fieldPoints[j].longitude;
      area -= _fieldPoints[j].latitude * _fieldPoints[i].longitude;
    }

    area = area.abs() / 2.0;

    // Convert to square meters (approximate)
    const double degreeToMeter = 111139.0; // meters per degree at equator
    _fieldArea = area * degreeToMeter * degreeToMeter;
  }

  void _calculateFieldPerimeter() {
    if (_fieldPoints.length < 2) {
      _fieldPerimeter = 0.0;
      return;
    }

    _fieldPerimeter = 0.0;
    for (int i = 0; i < _fieldPoints.length; i++) {
      int nextIndex = (i + 1) % _fieldPoints.length;
      _fieldPerimeter += Geolocator.distanceBetween(
        _fieldPoints[i].latitude,
        _fieldPoints[i].longitude,
        _fieldPoints[nextIndex].latitude,
        _fieldPoints[nextIndex].longitude,
      );
    }
  }

  String _formatArea(double area) {
    if (area < 10000) {
      return '${area.toStringAsFixed(1)} m²';
    } else {
      return '${(area / 10000).toStringAsFixed(2)} hectares';
    }
  }

  String _formatDistance(double distance) {
    if (distance < 1000) {
      return '${distance.toStringAsFixed(1)} m';
    } else {
      return '${(distance / 1000).toStringAsFixed(2)} km';
    }
  }

  void _updateDistanceMeasurement() {
    if (!mounted) return;
    _polylines.clear();

    if (_distancePoints.length > 1) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('distance_line'),
          points: _distancePoints,
          color: Colors.blue,
          width: 3,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      );

      // Calculate total distance
      _totalDistance = 0.0;
      for (int i = 0; i < _distancePoints.length - 1; i++) {
        _totalDistance += Geolocator.distanceBetween(
          _distancePoints[i].latitude,
          _distancePoints[i].longitude,
          _distancePoints[i + 1].latitude,
          _distancePoints[i + 1].longitude,
        );
      }
    }

    _updateMarkers();
  }

  void _addCustomMarker(LatLng position) {
    if (!mounted) return;

    _markerCounter++;
    final markerData = MarkerData(
      id: 'custom_marker_$_markerCounter',
      position: position,
      title: 'Marker $_markerCounter',
      description:
          'Added at ${DateTime.now().toLocal().toString().split(' ')[1].substring(0, 5)}',
    );

    setState(() {
      _customMarkers.add(markerData);
      _updateMarkers();
    });

    // Show feedback to user
    _showInfo(
        '📍 Marker $_markerCounter added at ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}');
  }

  void _showInfo(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showFieldSaveDialog() async {
    if (_fieldPoints.length < 3) {
      _showError('Need at least 3 points to save field measurement');
      return;
    }

    String name = 'Field ${DateTime.now().toString().split(' ')[0]}';
    String notes = '';

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.crop_free, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Save Field Measurement'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Measurement Summary',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Area',
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12)),
                              Text(_formatArea(_fieldArea),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Perimeter',
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12)),
                              Text(_formatDistance(_fieldPerimeter),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Points: ${_fieldPoints.length}',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Field Name',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.label),
                ),
                controller: TextEditingController(text: name),
                onChanged: (value) => name = value,
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.notes),
                  hintText: 'Add description or notes...',
                ),
                maxLines: 3,
                onChanged: (value) => notes = value,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () =>
                Navigator.pop(context, {'name': name, 'notes': notes}),
            icon: const Icon(Icons.save),
            label: const Text('Save Field'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (result != null) {
      await _saveFieldMeasurement(result['name']!, result['notes']!);
    }
  }

  void _showDistanceSaveDialog() async {
    if (_distancePoints.length < 2) {
      _showError('Need at least 2 points to save distance measurement');
      return;
    }

    String name = 'Distance ${DateTime.now().toString().split(' ')[0]}';
    String notes = '';

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.timeline, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Save Distance Measurement'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Measurement Summary',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total Distance',
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12)),
                              Text(_formatDistance(_totalDistance),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Points',
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12)),
                              Text('${_distancePoints.length}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Measurement Name',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.label),
                ),
                controller: TextEditingController(text: name),
                onChanged: (value) => name = value,
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.notes),
                  hintText: 'Add description or notes...',
                ),
                maxLines: 3,
                onChanged: (value) => notes = value,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () =>
                Navigator.pop(context, {'name': name, 'notes': notes}),
            icon: const Icon(Icons.save),
            label: const Text('Save Distance'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (result != null) {
      await _saveDistanceMeasurementWithDialog(
          result['name']!, result['notes']!);
    }
  }

  void _showMarkerSaveDialog() async {
    if (_customMarkers.isEmpty) {
      _showError('No markers to save');
      return;
    }

    String name = 'Markers ${DateTime.now().toString().split(' ')[0]}';
    String notes = '';

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.place, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Save Marker Set'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Marker Summary',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Total Markers: ${_customMarkers.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                        'First Marker: ${_customMarkers.first.position.latitude.toStringAsFixed(6)}, ${_customMarkers.first.position.longitude.toStringAsFixed(6)}'),
                    if (_customMarkers.length > 1)
                      Text(
                          'Last Marker: ${_customMarkers.last.position.latitude.toStringAsFixed(6)}, ${_customMarkers.last.position.longitude.toStringAsFixed(6)}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Marker Set Name',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.label),
                ),
                controller: TextEditingController(text: name),
                onChanged: (value) => name = value,
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.notes),
                  hintText: 'Add description or notes...',
                ),
                maxLines: 3,
                onChanged: (value) => notes = value,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _shareMarkerMeasurement(),
                icon: const Icon(Icons.share),
                label: const Text('Share'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () =>
                    Navigator.pop(context, {'name': name, 'notes': notes}),
                icon: const Icon(Icons.save),
                label: const Text('Save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (result != null) {
      await _saveMarkerMeasurement(result['name']!, result['notes']!);
    }
  }

  Future<void> _saveMarkerMeasurement(String name, String notes) async {
    try {
      _showLoadingDialog('Saving Marker Set...');

      for (int i = 0; i < _customMarkers.length; i++) {
        final marker = _customMarkers[i];
        final markerNotes = '''📍 Marker Set: $name - Point ${i + 1}
${notes.isNotEmpty ? '📝 $notes\n' : ''}
📊 MARKER DETAILS:
• Position: ${marker.position.latitude.toStringAsFixed(6)}, ${marker.position.longitude.toStringAsFixed(6)}
• Point Number: ${i + 1} of ${_customMarkers.length}
• Added Time: ${marker.description}
• Marker ID: ${marker.id}

⏰ Saved on: ${DateTime.now().toLocal().toString().split('.')[0]}''';

        final landPoint = LandPoint(
          id: '${DateTime.now().millisecondsSinceEpoch}_marker_$i',
          latitude: marker.position.latitude,
          longitude: marker.position.longitude,
          timestamp: DateTime.now(),
          notes: markerNotes,
          analysis: null,
        );

        await _databaseService.saveLandPoint(landPoint);
      }

      Navigator.pop(context); // Hide loading

      // Clear markers with animation
      await _clearMarkerMeasurement();

      // Reload points
      await _loadLandPoints();

      _showSuccessDialog(
        title: '🎯 Markers Saved Successfully!',
        message:
            'Marker set "$name" has been saved with ${_customMarkers.length} markers',
        details: 'All markers are now stored in database',
      );

    } catch (e) {
      Navigator.pop(context);
      _showErrorDialog('Failed to save markers', e.toString());
    }
  }

  void _saveDistanceMeasurement() async {
    if (_distancePoints.isEmpty) {
      _showError('No points to save');
      return;
    }

    // Convert LatLng points to MeasurementPoint objects with distances
    final List<MeasurementPoint> measurementPoints = [];

    for (int i = 0; i < _distancePoints.length; i++) {
      double? distanceFromPrevious;

      if (i > 0) {
        distanceFromPrevious = Geolocator.distanceBetween(
          _distancePoints[i - 1].latitude,
          _distancePoints[i - 1].longitude,
          _distancePoints[i].latitude,
          _distancePoints[i].longitude,
        );
      }

      measurementPoints.add(
        MeasurementPoint.fromLatLng(
          _distancePoints[i],
          i + 1,
          distanceFromPrevious: distanceFromPrevious,
        ),
      );
    }

    final measurement = DistanceMeasurement.create(
      points: measurementPoints,
      totalDistance: _totalDistance,
      name: 'Distance Measurement ${DateTime.now().toString().split(' ')[0]}',
      notes:
          'Measured ${_distancePoints.length} points with total distance ${_formatDistance(_totalDistance)}',
    );

    try {
      await _distanceMeasurementService.saveMeasurement(measurement);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Measurement Saved!'),
                    Text(
                      '${_distancePoints.length} points • ${_formatDistance(_totalDistance)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to save measurement: $e');
    }
  }

  void _showCleanMarkerPopup({
    required LatLng position,
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required List<String> details,
    VoidCallback? onNavigate,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with gradient
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color.withOpacity(0.8), color],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Details section
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...details
                        .map((detail) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 4,
                                    height: 4,
                                    margin: const EdgeInsets.only(
                                        top: 8, right: 12),
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      detail,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade700,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ],
                ),
              ),

              // Action buttons
              Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    if (onNavigate != null) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            onNavigate();
                          },
                          icon: const Icon(Icons.navigation, size: 18),
                          label: const Text('Navigate'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Text(
                          'Close',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : Stack(
            children: [
              // Google Map - Full Screen
              GoogleMap(
                onMapCreated: (controller) => _mapController = controller,
                initialCameraPosition: CameraPosition(
                  target: _currentLocation ?? const LatLng(0, 0),
                  zoom: 15.0,
                ),
                onTap: _onMapTap,
                markers: _markers,
                polylines: _polylines,
                polygons: _polygons,
                mapType: _currentMapType,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                trafficEnabled: _isTrafficEnabled,
                compassEnabled: true,
                rotateGesturesEnabled: true,
                scrollGesturesEnabled: true,
                tiltGesturesEnabled: true,
                zoomGesturesEnabled: true,
                zoomControlsEnabled: false,
              ),

              // Top Search Bar (Google Maps style)
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 16,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      const Icon(Icons.search, color: Colors.grey),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Search for places',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.mic, color: Colors.grey),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),

              // Map Controls (Right side)
              Positioned(
                right: 16,
                top: MediaQuery.of(context).padding.top + 80,
                child: Column(
                  children: [
                    // Layers button
                    FloatingActionButton(
                      heroTag: "layers",
                      mini: true,
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      onPressed: _showMapTypeSelector,
                      child: const Icon(Icons.layers),
                    ),
                    const SizedBox(height: 12),

                    // My Location button
                    FloatingActionButton(
                      heroTag: "location",
                      mini: true,
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      onPressed: _goToCurrentLocation,
                      child: const Icon(Icons.my_location),
                    ),
                  ],
                ),
              ),

              // Field Measurement Info Panel
              if (_isFieldMeasuring && _fieldPoints.isNotEmpty)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 80,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.green.shade50,
                          Colors.green.shade100,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: Colors.green.shade300, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.crop_free,
                                  color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Field Measurement',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  Text(
                                    '${_fieldPoints.length} points added',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_fieldPoints.length >= 3)
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: _shareFieldMeasurement,
                                    icon: const Icon(Icons.share, size: 16),
                                    label: const Text('Share'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      minimumSize: Size.zero,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: _showFieldSaveDialog,
                                    icon: const Icon(Icons.save, size: 16),
                                    label: const Text('Save'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      minimumSize: Size.zero,
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: _stopMeasuring,
                              icon: const Icon(Icons.close, color: Colors.red),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.red.shade50,
                                padding: const EdgeInsets.all(8),
                                minimumSize: Size.zero,
                              ),
                            ),
                          ],
                        ),
                        if (_fieldPoints.length >= 3) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Area',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        _formatArea(_fieldArea),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 30,
                                  color: Colors.green.shade200,
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Perimeter',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        _formatDistance(_fieldPerimeter),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.shade300),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: Colors.orange.shade700, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Add ${3 - _fieldPoints.length} more points to calculate area',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

              // Distance Measurement Info Panel
              if (_isDistanceMeasuring && _distancePoints.isNotEmpty)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 80,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.blue.shade50,
                          Colors.blue.shade100,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.shade300, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.timeline,
                                  color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Distance Measurement',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  Text(
                                    '${_distancePoints.length} points connected',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _shareDistanceMeasurement,
                                  icon: const Icon(Icons.share, size: 16),
                                  label: const Text('Share'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    minimumSize: Size.zero,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: _showDistanceSaveDialog,
                                  icon: const Icon(Icons.save, size: 16),
                                  label: const Text('Save'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    minimumSize: Size.zero,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: _stopMeasuring,
                              icon: const Icon(Icons.close, color: Colors.red),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.red.shade50,
                                padding: const EdgeInsets.all(8),
                                minimumSize: Size.zero,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Distance',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      _formatDistance(_totalDistance),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 30,
                                color: Colors.blue.shade200,
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Points',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '${_distancePoints.length}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Marker Measurement Info Panel
              if (_isMarkerMeasuring && _customMarkers.isNotEmpty)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 80,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.purple.shade50,
                          Colors.purple.shade100,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: Colors.purple.shade300, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.purple,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.place,
                                  color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Marker Measurement',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple,
                                    ),
                                  ),
                                  Text(
                                    '${_customMarkers.length} markers placed',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.purple.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _showMarkerSaveDialog,
                              icon: const Icon(Icons.save, size: 16),
                              label: const Text('Save'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                minimumSize: Size.zero,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: _stopMeasuring,
                              icon: const Icon(Icons.close, color: Colors.red),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.red.shade50,
                                padding: const EdgeInsets.all(8),
                                minimumSize: Size.zero,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.purple.shade200),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Markers',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '${_customMarkers.length}',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.purple,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 30,
                                color: Colors.purple.shade200,
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Latest Time',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      DateTime.now()
                                          .toLocal()
                                          .toString()
                                          .split(' ')[1]
                                          .substring(0, 5),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.purple,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Measurement Status Indicator
              if (_isDistanceMeasuring ||
                  _isMarkerMeasuring ||
                  _isFieldMeasuring)
                Positioned(
                  top: MediaQuery.of(context).padding.top +
                      ((_distancePoints.isNotEmpty ||
                              _customMarkers.isNotEmpty ||
                              _fieldPoints.isNotEmpty)
                          ? 160
                          : 80),
                  left: 16,
                  right: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: (_isFieldMeasuring
                              ? Colors.green
                              : _isDistanceMeasuring
                                  ? Colors.blue
                                  : Colors.purple)
                          .withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.touch_app,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          _isFieldMeasuring
                              ? 'Tap to add field points'
                              : _isDistanceMeasuring
                                  ? 'Tap to add distance points'
                                  : 'Tap to add markers',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Floating Action Button with Speed Dial
              Positioned(
                right: 16,
                bottom: 100,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Speed Dial Options
                    if (_isFabOpen) ...[
                      // Field Measure
                      _buildSpeedDialButton(
                        icon: Icons.crop_free,
                        label: 'Field Measure',
                        color: Colors.green,
                        onTap: () {
                          if (!mounted) return;
                          setState(() {
                            _isFabOpen = false;
                            _startFieldMeasure();
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      // Distance Measure
                      _buildSpeedDialButton(
                        icon: Icons.timeline,
                        label: 'Distance Measure',
                        color: Colors.blue,
                        onTap: () {
                          if (!mounted) return;
                          setState(() {
                            _isFabOpen = false;
                            _startDistanceMeasure();
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      // Marker Measure
                      _buildSpeedDialButton(
                        icon: Icons.place,
                        label: 'Marker Measure',
                        color: Colors.purple,
                        onTap: () {
                          if (!mounted) return;
                          setState(() {
                            _isFabOpen = false;
                            _startMarkerMeasure();
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Main FAB with gradient and shadow
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.orange.shade400,
                            Colors.deepOrange.shade600,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: FloatingActionButton(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        onPressed: () {
                          if (!mounted) return;
                          setState(() {
                            _isFabOpen = !_isFabOpen;
                          });
                        },
                        child: AnimatedRotation(
                          turns: _isFabOpen ? 0.25 : 0,
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            _isFabOpen ? Icons.close : Icons.straighten,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Overlay to close FAB when tapping outside
              if (_isFabOpen)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      if (!mounted) return;
                      setState(() => _isFabOpen = false);
                    },
                    child: Container(
                      color: Colors.black.withOpacity(0.2),
                    ),
                  ),
                ),
            ],
          );
  }
  Widget _buildSpeedDialButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label with background
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Circular button with animation
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.8),
                  color,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ],
    );
  }

  // Enhanced Share Functions
  void _shareFieldMeasurement() async {
    if (_fieldPoints.isEmpty) {
      _showError('No field data to share');
      return;
    }

    final shareText = '''🌾 FIELD MEASUREMENT REPORT
━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 FIELD SUMMARY:
• Area: ${_formatArea(_fieldArea)}
• Perimeter: ${_formatDistance(_fieldPerimeter)}
• Points: ${_fieldPoints.length}
• Measured: ${DateTime.now().toLocal().toString().split('.')[0]}

📍 COORDINATES:
${_fieldPoints.asMap().entries.map((entry) {
      final index = entry.key;
      final point = entry.value;
      return 'Point ${index + 1}: ${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}';
    }).join('\n')}

📱 Shared from Land Mapper App''';

    await Share.share(shareText, subject: 'Field Measurement Report');
  }

  void _shareDistanceMeasurement() async {
    if (_distancePoints.isEmpty) {
      _showError('No distance data to share');
      return;
    }

    final shareText = '''📏 DISTANCE MEASUREMENT REPORT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 MEASUREMENT SUMMARY:
• Total Distance: ${_formatDistance(_totalDistance)}
• Points: ${_distancePoints.length}
• Measured: ${DateTime.now().toLocal().toString().split('.')[0]}

📍 PATH COORDINATES:
${_distancePoints.asMap().entries.map((entry) {
      final index = entry.key;
      final point = entry.value;
      return 'Point ${index + 1}: ${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}';
    }).join('\n')}

📱 Shared from Land Mapper App''';

    await Share.share(shareText, subject: 'Distance Measurement Report');
  }

  void _shareMarkerMeasurement() async {
    if (_customMarkers.isEmpty) {
      _showError('No markers to share');
      return;
    }

    final shareText = '''🎯 MARKER SET REPORT
━━━━━━━━━━━━━━━━━━━━━━━

📊 MARKER SUMMARY:
• Total Markers: ${_customMarkers.length}
• Created: ${DateTime.now().toLocal().toString().split('.')[0]}

📍 MARKER LOCATIONS:
${_customMarkers.asMap().entries.map((entry) {
      final index = entry.key;
      final marker = entry.value;
      return 'Marker ${index + 1}: ${marker.title}\n  Location: ${marker.position.latitude.toStringAsFixed(6)}, ${marker.position.longitude.toStringAsFixed(6)}';
    }).join('\n')}

📱 Shared from Land Mapper App''';

    await Share.share(shareText, subject: 'Marker Set Report');
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

class MarkerData {
  final String id;
  final LatLng position;
  final String title;
  final String description;

  MarkerData({
    required this.id,
    required this.position,
    required this.title,
    required this.description,
  });
}

// Enhanced Share Function with Multiple Options

