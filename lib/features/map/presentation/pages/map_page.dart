import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/models/land_point.dart';
import '../../../../shared/navigation/app_router.dart';
import 'distance_measure_page.dart';
import 'marker_measure_page.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _mapController;
  final DatabaseService _databaseService = DatabaseService();

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
    setState(() => _isLoading = true);

    try {
      await _getCurrentLocation();
      await _loadLandPoints();
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
      setState(() {
        _landPoints = points;
        _updateMarkers();
      });
    } catch (e) {
      _showError('Error loading land points: $e');
    }
  }

  void _updateMarkers() {
    _markers.clear();

    // Add current location marker
    if (_currentLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: _currentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Current Location',
            snippet: 'You are here',
          ),
        ),
      );
    }

    // Add field measurement markers
    for (int i = 0; i < _fieldPoints.length; i++) {
      _markers.add(
        Marker(
          markerId: MarkerId('field_point_$i'),
          position: _fieldPoints[i],
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(
            title: 'Field Point ${i + 1}',
            snippet:
                '${_fieldPoints[i].latitude.toStringAsFixed(6)}, ${_fieldPoints[i].longitude.toStringAsFixed(6)}',
          ),
        ),
      );
    }

    // Add distance measurement markers
    for (int i = 0; i < _distancePoints.length; i++) {
      _markers.add(
        Marker(
          markerId: MarkerId('distance_point_$i'),
          position: _distancePoints[i],
          icon: BitmapDescriptor.defaultMarkerWithHue(
            i == 0 ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
          ),
          infoWindow: InfoWindow(
            title: i == 0 ? 'Start Point' : 'Point ${i + 1}',
            snippet:
                '${_distancePoints[i].latitude.toStringAsFixed(6)}, ${_distancePoints[i].longitude.toStringAsFixed(6)}',
          ),
        ),
      );
    }

    // Add custom measurement markers
    for (var marker in _customMarkers) {
      _markers.add(
        Marker(
          markerId: MarkerId(marker.id),
          position: marker.position,
          infoWindow: InfoWindow(
            title: marker.title,
            snippet: marker.description,
          ),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        ),
      );
    }

    // Add land point markers
    for (int i = 0; i < _landPoints.length; i++) {
      final point = _landPoints[i];
      final color = _getMarkerColor(point.analysis?.dominantLandFeature);

      _markers.add(
        Marker(
          markerId: MarkerId('land_point_$i'),
          position: LatLng(point.latitude, point.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(color),
          infoWindow: InfoWindow(
            title: point.analysis?.dominantLandFeature ?? 'Land Point',
            snippet:
                '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}',
          ),
          onTap: () => _showPointDetails(point),
        ),
      );
    }
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
    // Handle field measurement
    if (_isFieldMeasuring) {
      setState(() {
        _fieldPoints.add(position);
        _updateFieldMeasurement();
      });
      return;
    }

    // Handle distance measurement
    if (_isDistanceMeasuring) {
      setState(() {
        _distancePoints.add(position);
        _updateDistanceMeasurement();
      });
      return;
    }

    // Handle marker measurement
    if (_isMarkerMeasuring) {
      _addCustomMarker(position);
      return;
    }

    // Normal map clicks do nothing
  }

  void _goToCurrentLocation() async {
    if (_currentLocation != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation!, 16.0),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Measurement methods
  void _startFieldMeasure() {
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
    setState(() {
      _isMarkerMeasuring = true;
      _isDistanceMeasuring = false;
      _isFieldMeasuring = false;
      _updateMarkers();
    });
    _showInfo('Tap on map to add markers');
  }

  void _stopMeasuring() {
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
  }

  void _updateFieldMeasurement() {
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
    _markerCounter++;
    final markerData = MarkerData(
      id: 'marker_$_markerCounter',
      position: position,
      title: 'Point $_markerCounter',
      description:
          'Added at ${DateTime.now().toLocal().toString().split(' ')[1].substring(0, 5)}',
    );

    setState(() {
      _customMarkers.add(markerData);
      _updateMarkers();
    });
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
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
                onTap: (_isFieldMeasuring ||
                        _isDistanceMeasuring ||
                        _isMarkerMeasuring)
                    ? _onMapTap
                    : null,
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

              // Bottom Sheet Handle (if needed)
              if (_landPoints.isNotEmpty)
                Positioned(
                  bottom: 100,
                  left: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${_landPoints.length} saved points',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),

              // Field Measurement Info Panel
              if (_isFieldMeasuring && _fieldPoints.isNotEmpty)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 80,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
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
                    child: Row(
                      children: [
                        const Icon(Icons.crop_free,
                            color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Field Measurement',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (_fieldPoints.length >= 3)
                                Text(
                                  'Area: ${_formatArea(_fieldArea)} • ${_fieldPoints.length} pts',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                )
                              else
                                Text(
                                  '${_fieldPoints.length} points (need 3+ for area)',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        TextButton(
                          onPressed: _stopMeasuring,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Stop',
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
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
                    padding: const EdgeInsets.all(12),
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
                    child: Row(
                      children: [
                        const Icon(Icons.timeline,
                            color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Distance Measurement',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Total: ${_formatDistance(_totalDistance)} • ${_distancePoints.length} pts',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        TextButton(
                          onPressed: _stopMeasuring,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Stop',
                            style: TextStyle(color: Colors.red, fontSize: 12),
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
                    padding: const EdgeInsets.all(12),
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
                    child: Row(
                      children: [
                        const Icon(Icons.place, color: Colors.purple, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Marker Measurement',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${_customMarkers.length} markers added',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        TextButton(
                          onPressed: _stopMeasuring,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Stop',
                            style: TextStyle(color: Colors.red, fontSize: 12),
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
                    FloatingActionButton(
                      backgroundColor: Colors.orange,
                      onPressed: () {
                        setState(() {
                          _isFabOpen = !_isFabOpen;
                        });
                      },
                      child: AnimatedRotation(
                        turns: _isFabOpen ? 0.125 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          _isFabOpen ? Icons.close : Icons.straighten,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (_isFabOpen) ...[
                      const SizedBox(height: 16),
                      // Field Measure
                      FloatingActionButton(
                        heroTag: "field_measure",
                        backgroundColor: Colors.green,
                        onPressed: () {
                          setState(() {
                            _isFabOpen = false;
                            _startFieldMeasure();
                          });
                        },
                        child: const Icon(Icons.crop_free, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      // Distance Measure
                      FloatingActionButton(
                        heroTag: "distance_measure",
                        backgroundColor: Colors.blue,
                        onPressed: () {
                          setState(() {
                            _isFabOpen = false;
                            _startDistanceMeasure();
                          });
                        },
                        child: const Icon(Icons.timeline, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      // Marker Measure
                      FloatingActionButton(
                        heroTag: "marker_measure",
                        backgroundColor: Colors.purple,
                        onPressed: () {
                          setState(() {
                            _isFabOpen = false;
                            _startMarkerMeasure();
                          });
                        },
                        child: const Icon(Icons.place, color: Colors.white),
                      ),
                    ],
                  ],
                ),
              ),

              // Overlay to close FAB when tapping outside
              if (_isFabOpen)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => setState(() => _isFabOpen = false),
                    child: Container(
                      color: Colors.black.withOpacity(0.2),
                    ),
                  ),
                ),
            ],
          );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
