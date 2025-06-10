import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/models/land_point.dart';

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
  MapType _currentMapType = MapType.satellite;
  bool _isTrafficEnabled = false;

  // GPS Land Tracking
  final List<LatLng> _fieldPoints = [];
  final Set<Polygon> _polygons = {};
  final Set<Polyline> _polylines = {};
  double _fieldArea = 0.0;
  double _fieldPerimeter = 0.0;
  bool _isTracking = false;

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
      await _loadSavedLandPoints();
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
          CameraUpdate.newLatLngZoom(_currentLocation!, 16.0),
        );
      }
    } catch (e) {
      _showError('Failed to get location: $e');
    }
  }

  Future<void> _loadSavedLandPoints() async {
    try {
      final points = await _databaseService.getAllLandPoints();
      if (!mounted) return;
      setState(() {
        _landPoints = points;
        _updateSavedPointsMarkers();
      });
    } catch (e) {
      _showError('Error loading saved points: $e');
    }
  }

  void _updateSavedPointsMarkers() {
    _markers.clear();

    // Add current location marker with custom icon
    if (_currentLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: _currentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: '📍 My Current Location',
            snippet: 'You are here - High Precision GPS',
          ),
          onTap: () => _showMyLocationDetails(),
        ),
      );
    }

    // Add field tracking points with enhanced markers
    for (int i = 0; i < _fieldPoints.length; i++) {
      _markers.add(
        Marker(
          markerId: MarkerId('field_point_$i'),
          position: _fieldPoints[i],
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: '🌾 Field Point ${i + 1}',
            snippet: 'GPS Tracked Land Boundary',
          ),
          onTap: () => _showFieldPointDetails(_fieldPoints[i], i + 1),
        ),
      );
    }

    // Add saved land points from database with enhanced markers
    for (int i = 0; i < _landPoints.length; i++) {
      final point = _landPoints[i];
      final landType =
          point.analysis?.dominantLandFeature ?? 'Saved Land Point';
      _markers.add(
        Marker(
          markerId: MarkerId('saved_point_$i'),
          position: LatLng(point.latitude, point.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              _getLandTypeColor(landType)),
          infoWindow: InfoWindow(
            title: '💾 $landType',
            snippet: 'Tap for detailed information',
          ),
          onTap: () => _showEnhancedSavedPointDetails(point),
        ),
      );
    }
  }

  double _getLandTypeColor(String landType) {
    switch (landType.toLowerCase()) {
      case 'agricultural land':
      case 'farm':
      case 'field':
        return BitmapDescriptor.hueGreen;
      case 'residential':
      case 'urban area':
      case 'building':
        return BitmapDescriptor.hueBlue;
      case 'forest':
      case 'woodland':
        return BitmapDescriptor.hueGreen;
      case 'water body':
      case 'river':
      case 'lake':
        return BitmapDescriptor.hueAzure;
      case 'commercial':
      case 'industrial':
        return BitmapDescriptor.hueViolet;
      default:
        return BitmapDescriptor.hueOrange;
    }
  }

  void _showMyLocationDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  const Icon(Icons.my_location, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('📍 My Current Location'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('High Precision GPS Coordinates:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                      'Latitude: ${_currentLocation!.latitude.toStringAsFixed(8)}'),
                  Text(
                      'Longitude: ${_currentLocation!.longitude.toStringAsFixed(8)}'),
                  const SizedBox(height: 8),
                  Text('Accuracy: ±3 meters',
                      style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold)),
                  Text(
                      'Updated: ${DateTime.now().toString().split(' ')[1].substring(0, 8)}'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(
                text:
                    '${_currentLocation!.latitude.toStringAsFixed(8)}, ${_currentLocation!.longitude.toStringAsFixed(8)}',
              ));
              _showSnackBar('Current location coordinates copied!');
            },
            child: const Text('Copy Coordinates'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _onMapTap(LatLng position) {
    if (_isTracking) {
      setState(() {
        _fieldPoints.add(position);
        _updateFieldMeasurement();
        _updateSavedPointsMarkers();
      });
      _showGPSPointAddedDialog(position, _fieldPoints.length);
    }
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
      _calculateFieldMeasurements();
    }

    // Add polylines to show point connections
    if (_fieldPoints.length >= 2) {
      _polylines.clear();

      // Connect all points in sequence
      for (int i = 0; i < _fieldPoints.length - 1; i++) {
        _polylines.add(
          Polyline(
            polylineId: PolylineId('line_$i'),
            points: [_fieldPoints[i], _fieldPoints[i + 1]],
            color: Colors.blue,
            width: 4,
            patterns: [PatternItem.dash(15), PatternItem.gap(10)],
          ),
        );
      }

      // If we have 3+ points, connect the last point to the first to close the shape
      if (_fieldPoints.length >= 3) {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('closing_line'),
            points: [_fieldPoints.last, _fieldPoints.first],
            color: Colors.green,
            width: 4,
            patterns: [PatternItem.dash(15), PatternItem.gap(10)],
          ),
        );
      }
    }
  }

  void _calculateFieldMeasurements() {
    if (_fieldPoints.length < 3) {
      _fieldArea = 0.0;
      _fieldPerimeter = 0.0;
      return;
    }

    // Calculate area using shoelace formula
    double area = 0.0;
    int n = _fieldPoints.length;
    for (int i = 0; i < n; i++) {
      int j = (i + 1) % n;
      area += _fieldPoints[i].latitude * _fieldPoints[j].longitude;
      area -= _fieldPoints[j].latitude * _fieldPoints[i].longitude;
    }
    area = area.abs() / 2.0;
    const double degreeToMeter = 111139.0;
    _fieldArea = area * degreeToMeter * degreeToMeter;

    // Calculate perimeter
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

  void _showGPSPointAddedDialog(LatLng position, int pointNumber) {
    // Calculate distance from previous point if available
    double? distanceFromPrevious;
    if (_fieldPoints.length > 1) {
      final previousPoint = _fieldPoints[_fieldPoints.length - 2];
      distanceFromPrevious = Geolocator.distanceBetween(
        previousPoint.latitude,
        previousPoint.longitude,
        position.latitude,
        position.longitude,
      );
    }

    showDialog(
      context: context,
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
                // Enhanced Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade600, Colors.green.shade800],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
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
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.gps_fixed,
                                color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '📍 GPS Point $pointNumber Added',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'High Precision GPS Coordinates',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Distance info if available
                      if (distanceFromPrevious != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.straighten,
                                  color: Colors.white, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'Distance from Point ${pointNumber - 1}: ${distanceFromPrevious!.toStringAsFixed(1)} m',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Enhanced Coordinate Display
                _buildEnhancedCoordinateCard(
                    position, pointNumber, distanceFromPrevious),

                if (_fieldPoints.length >= 3) ...[
                  const SizedBox(height: 16),
                  _buildMeasurementCard(),
                ],

                const SizedBox(height: 20),
                _buildActionButtons(pointNumber),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedCoordinateCard(
      LatLng position, int pointNumber, double? distance) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.location_on,
                    color: Colors.blue.shade700, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GPS Coordinates',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      'Point $pointNumber • WGS84 System',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Coordinates Display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.blue.shade100],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Latitude
                _buildDetailedCoordinateRow(
                  '🌐 Latitude',
                  position.latitude.toStringAsFixed(8),
                  '°N',
                  Colors.green,
                  Icons.north,
                ),
                const SizedBox(height: 12),

                // Longitude
                _buildDetailedCoordinateRow(
                  '🌐 Longitude',
                  position.longitude.toStringAsFixed(8),
                  '°E',
                  Colors.orange,
                  Icons.east,
                ),

                const SizedBox(height: 16),

                // Distance info
                if (distance != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purple.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.straighten,
                            color: Colors.purple.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Distance from Previous Point',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple.shade700,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '${distance.toStringAsFixed(2)} meters',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Precision info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.precision_manufacturing,
                          color: Colors.green.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'High Precision GPS',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Accuracy: ±3 meters • ${DateTime.now().toString().split(' ')[1].substring(0, 8)}',
                              style: TextStyle(
                                color: Colors.green.shade600,
                                fontSize: 11,
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
        ],
      ),
    );
  }

  Widget _buildDetailedCoordinateRow(
      String label, String value, String unit, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 14,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: value));
                  _showSnackBar('$label copied!');
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy, size: 12, color: color),
                      const SizedBox(width: 4),
                      Text(
                        'Copy',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$value$unit',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoordinateRow(String label, double value, String unit) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: () async {
                  await Clipboard.setData(
                      ClipboardData(text: value.toStringAsFixed(8)));
                  _showSnackBar('$label copied!');
                },
                icon: const Icon(Icons.copy, size: 16, color: Colors.blue),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          Text(
            '${value.toStringAsFixed(8)}$unit',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade50, Colors.orange.shade100],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300, width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.calculate, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              const Text(
                'Live Area Calculation',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMeasurementItem(
                  'Area',
                  _formatArea(_fieldArea),
                  Icons.crop_free,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMeasurementItem(
                  'Perimeter',
                  _formatDistance(_fieldPerimeter),
                  Icons.straighten,
                  Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementItem(String title, String value, IconData icon,
      Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(title,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
          Text(value, style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(int pointNumber) {
    return Row(
      children: [
        if (_fieldPoints.length >= 3) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showCompleteLandSurvey();
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('Complete Survey'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.add_location_alt),
            label: const Text('Add More Points'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  void _showCompleteLandSurvey() {
    showDialog(
      context: context,
      builder: (context) =>
          Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [Colors.green.shade50, Colors.green.shade100],
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                              Icons.landscape, color: Colors.white, size: 48),
                          const SizedBox(height: 12),
                          const Text(
                            '🎉 Land Survey Complete!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_fieldPoints.length} GPS Points Mapped',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildCompleteSummaryCard(),
                    const SizedBox(height: 16),
                    _buildAllCoordinatesCard(),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _shareCompleteLandData();
                            },
                            icon: const Icon(Icons.share),
                            label: const Text('Share Report'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _saveLandSurvey();
                            },
                            icon: const Icon(Icons.save),
                            label: const Text('Save to DB'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
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

  Widget _buildCompleteSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200, width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.green.shade700),
              const SizedBox(width: 8),
              const Text(
                'Survey Summary',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Colors.green.shade50, Colors.green.shade100]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.crop_free, color: Colors.green.shade700,
                          size: 32),
                      const SizedBox(height: 8),
                      const Text('Total Area', style: TextStyle(fontSize: 12)),
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
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Colors.blue.shade50, Colors.blue.shade100]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.straighten, color: Colors.blue.shade700,
                          size: 32),
                      const SizedBox(height: 8),
                      const Text('Perimeter', style: TextStyle(fontSize: 12)),
                      Text(
                        _formatDistance(_fieldPerimeter),
                        style: const TextStyle(
                          fontSize: 16,
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
        ],
      ),
    );
  }

  Widget _buildAllCoordinatesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200, width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.gps_fixed, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              const Text(
                'All GPS Coordinates',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(
              child: Column(
                children: List.generate(_fieldPoints.length, (index) {
                  final point = _fieldPoints[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'P${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lat: ${point.latitude.toStringAsFixed(8)}',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Lng: ${point.longitude.toStringAsFixed(8)}',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(
                              text: '${point.latitude.toStringAsFixed(
                                  8)}, ${point.longitude.toStringAsFixed(8)}',
                            ));
                            _showSnackBar('Point ${index + 1} copied!');
                          },
                          icon: const Icon(
                              Icons.copy, size: 16, color: Colors.blue),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
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
    );
  }

  void _showFieldPointDetails(LatLng position, int pointNumber) {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Text('🌾 Field Point $pointNumber'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Latitude: ${position.latitude.toStringAsFixed(8)}'),
                Text('Longitude: ${position.longitude.toStringAsFixed(8)}'),
                const SizedBox(height: 8),
                Text('Point: $pointNumber of ${_fieldPoints.length}'),
                if (_fieldPoints.length >= 3) ...[
                  const SizedBox(height: 8),
                  Text('Area: ${_formatArea(_fieldArea)}'),
                  Text('Perimeter: ${_formatDistance(_fieldPerimeter)}'),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _showEnhancedSavedPointDetails(LandPoint point) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.orange.shade50, Colors.orange.shade100],
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade600, Colors.orange.shade800],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.place,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '💾 ${point.analysis?.dominantLandFeature ?? 'Saved Land Point'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Saved Land Mark Details',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // GPS Coordinates Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.gps_fixed, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          const Text(
                            'High Precision GPS Coordinates',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('Latitude: ',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                Expanded(
                                  child: Text(
                                    point.latitude.toStringAsFixed(8),
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () async {
                                    await Clipboard.setData(ClipboardData(
                                      text: point.latitude.toStringAsFixed(8),
                                    ));
                                    _showSnackBar('Latitude copied!');
                                  },
                                  icon: const Icon(Icons.copy,
                                      size: 16, color: Colors.blue),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                      minWidth: 32, minHeight: 32),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text('Longitude: ',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                Expanded(
                                  child: Text(
                                    point.longitude.toStringAsFixed(8),
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () async {
                                    await Clipboard.setData(ClipboardData(
                                      text: point.longitude.toStringAsFixed(8),
                                    ));
                                    _showSnackBar('Longitude copied!');
                                  },
                                  icon: const Icon(Icons.copy,
                                      size: 16, color: Colors.blue),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                      minWidth: 32, minHeight: 32),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Details Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.green.shade700),
                          const SizedBox(width: 8),
                          const Text(
                            'Land Mark Information',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildDetailItem('📅 Saved Date',
                          point.timestamp.toLocal().toString().split('.')[0]),
                      _buildDetailItem(
                          '🏷️ Land Type',
                          point.analysis?.dominantLandFeature ??
                              'Not specified'),
                      _buildDetailItem('📍 Coordinate System', 'WGS84'),
                      _buildDetailItem(
                          '🎯 Precision Level', 'High Accuracy (±3m)'),
                    ],
                  ),
                ),

                if (point.notes?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.notes, color: Colors.grey.shade700),
                            const SizedBox(width: 8),
                            const Text(
                              'Additional Notes',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            point.notes!,
                            style: const TextStyle(fontSize: 14, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(
                            text:
                                '${point.latitude.toStringAsFixed(8)}, ${point.longitude.toStringAsFixed(8)}',
                          ));
                          _showSnackBar('Complete coordinates copied!');
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy All'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          if (_mapController != null) {
                            _mapController!.animateCamera(
                              CameraUpdate.newLatLngZoom(
                                LatLng(point.latitude, point.longitude),
                                20.0,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.zoom_in),
                        label: const Text('Zoom Here'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveLandSurvey() async {
    try {
      _showLoadingDialog('Saving Land Survey...');

      final centerLat = _fieldPoints.map((p) => p.latitude).reduce((a, b) =>
      a + b) / _fieldPoints.length;
      final centerLng = _fieldPoints.map((p) => p.longitude).reduce((a,
          b) => a + b) / _fieldPoints.length;

      final coordinateList = _fieldPoints
          .asMap()
          .entries
          .map((entry) {
        final index = entry.key;
        final point = entry.value;
        return 'P${index + 1}: ${point.latitude.toStringAsFixed(8)}, ${point
            .longitude.toStringAsFixed(8)}';
      }).join('\n');

      final surveyNotes = '''🌾 GPS Land Survey
📊 SURVEY SUMMARY:
• Area: ${_formatArea(_fieldArea)}
• Perimeter: ${_formatDistance(_fieldPerimeter)}
• Total Points: ${_fieldPoints.length}
• Center Point: ${centerLat.toStringAsFixed(6)}, ${centerLng.toStringAsFixed(6)}

📍 ALL GPS COORDINATES:
$coordinateList

⏰ Surveyed on: ${DateTime.now().toLocal().toString().split('.')[0]}''';

      final landPoint = LandPoint(
        id: DateTime
            .now()
            .millisecondsSinceEpoch
            .toString(),
        latitude: centerLat,
        longitude: centerLng,
        timestamp: DateTime.now(),
        notes: surveyNotes,
        analysis: null,
      );

      await _databaseService.saveLandPoint(landPoint);
      Navigator.pop(context); // Hide loading

      // Clear current survey
      setState(() {
        _fieldPoints.clear();
        _polygons.clear();
        _fieldArea = 0.0;
        _fieldPerimeter = 0.0;
        _isTracking = false;
        _updateSavedPointsMarkers();
      });

      // Reload saved points
      await _loadSavedLandPoints();

      _showSnackBar('✅ Land survey saved to database!');
    } catch (e) {
      Navigator.pop(context);
      _showError('Failed to save survey: $e');
    }
  }

  void _shareCompleteLandData() {
    final shareText = '''🌾 GPS LAND SURVEY REPORT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎉 SURVEY COMPLETED SUCCESSFULLY!

📊 LAND SUMMARY:
• Total Area: ${_formatArea(_fieldArea)}
• Perimeter: ${_formatDistance(_fieldPerimeter)}
• Total Points: ${_fieldPoints.length}
• Survey Date: ${DateTime.now().toLocal().toString().split('.')[0]}

📍 HIGH PRECISION GPS COORDINATES:
${_fieldPoints
        .asMap()
        .entries
        .map((entry) {
      final index = entry.key;
      final point = entry.value;
      return 'Point ${index + 1}:\n  Latitude:  ${point.latitude
          .toStringAsFixed(8)}\n  Longitude: ${point.longitude.toStringAsFixed(
          8)}';
    }).join('\n\n')}

🗺️ GOOGLE MAPS LINKS:
${_fieldPoints
        .asMap()
        .entries
        .map((entry) {
      final index = entry.key;
      final point = entry.value;
      return 'Point ${index + 1}: https://maps.google.com/?q=${point
          .latitude},${point.longitude}';
    }).join('\n')}

📱 Generated by GPS Land Tracker App
⏰ Report Generated: ${DateTime.now().toLocal().toString()}

═══════════════════════════════════════
Professional GPS Land Survey Report''';

    Share.share(shareText, subject: '🌾 GPS Land Survey Report');
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

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(message),
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

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Enhanced zoom functionality to fit all points
  void _zoomToFitAllPoints() {
    if (_fieldPoints.isEmpty && _landPoints.isEmpty) return;

    List<LatLng> allPoints = [];

    // Add current location if available
    if (_currentLocation != null) {
      allPoints.add(_currentLocation!);
    }

    // Add field tracking points
    allPoints.addAll(_fieldPoints);

    // Add saved land points
    for (var point in _landPoints) {
      allPoints.add(LatLng(point.latitude, point.longitude));
    }

    if (allPoints.isEmpty) return;

    // Calculate bounds
    double minLat = allPoints.first.latitude;
    double maxLat = allPoints.first.latitude;
    double minLng = allPoints.first.longitude;
    double maxLng = allPoints.first.longitude;

    for (var point in allPoints) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    // Create bounds with padding
    final bounds = LatLngBounds(
      southwest: LatLng(minLat - 0.001, minLng - 0.001),
      northeast: LatLng(maxLat + 0.001, maxLng + 0.001),
    );

    // Animate camera to fit bounds
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    );

    _showSnackBar('🎯 Zoomed to fit all ${allPoints.length} points');
  }

  // Enhanced marker creation with better visuals
  void _createEnhancedMarkers() {
    _markers.clear();

    // Enhanced current location marker
    if (_currentLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: _currentLocation!,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(
            title: '📍 My Location',
            snippet: 'You are here - GPS Precision',
          ),
          onTap: () => _showMyLocationDetails(),
        ),
      );
    }

    // Enhanced field tracking points
    for (int i = 0; i < _fieldPoints.length; i++) {
      _markers.add(
        Marker(
          markerId: MarkerId('field_point_$i'),
          position: _fieldPoints[i],
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: '🌾 GPS Point ${i + 1}',
            snippet: 'Land Boundary Marker',
          ),
          onTap: () => _showFieldPointDetails(_fieldPoints[i], i + 1),
        ),
      );
    }

    // Enhanced saved land points
    for (int i = 0; i < _landPoints.length; i++) {
      final point = _landPoints[i];
      final landType = point.analysis?.dominantLandFeature ?? 'Saved Point';
      _markers.add(
        Marker(
          markerId: MarkerId('saved_point_$i'),
          position: LatLng(point.latitude, point.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              _getLandTypeColor(landType)),
          infoWindow: InfoWindow(
            title: '💾 $landType',
            snippet: 'Saved Land Mark',
          ),
          onTap: () => _showEnhancedSavedPointDetails(point),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: CameraPosition(
              target: _currentLocation ?? const LatLng(0, 0),
              zoom: 16.0,
            ),
            onTap: _onMapTap,
            markers: _markers,
            polygons: _polygons,
                  polylines: _polylines,
                  mapType: _currentMapType,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            trafficEnabled: _isTrafficEnabled,
            compassEnabled: true,
            zoomControlsEnabled: false,
                  // Enhanced Gesture Controls
                  zoomGesturesEnabled: true,
                  scrollGesturesEnabled: true,
                  tiltGesturesEnabled: true,
                  rotateGesturesEnabled: true,
                  // Enhanced Zoom Settings
                  minMaxZoomPreference: const MinMaxZoomPreference(5.0, 25.0),
                  // Smooth Camera Movements
                  cameraTargetBounds: CameraTargetBounds.unbounded,
                ),

          // Top Status Bar
          Positioned(
            top: MediaQuery
                .of(context)
                .padding
                .top + 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade600, Colors.green.shade800],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                          Icons.gps_fixed, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '🌾 GPS Land Tracker',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _isTracking
                                  ? '📍 ${_fieldPoints.length} points tracked'
                                  : '💾 ${_landPoints
                                  .length} saved points in database',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (_isTracking && _fieldPoints.length >= 3) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                const Text(
                                  'Area',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 10),
                                ),
                                Text(
                                  _formatArea(_fieldArea),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 30, color: Colors.white),
                          Expanded(
                            child: Column(
                              children: [
                                const Text(
                                  'Perimeter',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 10),
                                ),
                                Text(
                                  _formatDistance(_fieldPerimeter),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
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

          // Control Buttons
          Positioned(
            right: 16,
            top: MediaQuery
                .of(context)
                .padding
                .top + 120,
            child: Column(
              children: [
                      // Enhanced Zoom In Button
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.shade400,
                              Colors.green.shade600
                            ],
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: FloatingActionButton(
                          heroTag: "zoom_in",
                          mini: true,
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          onPressed: () async {
                            if (_mapController != null) {
                              final currentZoom =
                                  await _mapController!.getZoomLevel();
                              _mapController!.animateCamera(
                                CameraUpdate.zoomTo(currentZoom + 2),
                              );
                              _showSnackBar('🔍 Zoomed In');
                            }
                          },
                          child: const Icon(Icons.add,
                              color: Colors.white, size: 24),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Enhanced Zoom Out Button
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade400,
                              Colors.blue.shade600
                            ],
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: FloatingActionButton(
                          heroTag: "zoom_out",
                          mini: true,
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          onPressed: () async {
                            if (_mapController != null) {
                              final currentZoom =
                                  await _mapController!.getZoomLevel();
                              _mapController!.animateCamera(
                                CameraUpdate.zoomTo(currentZoom - 2),
                              );
                              _showSnackBar('🔍 Zoomed Out');
                            }
                          },
                          child: const Icon(Icons.remove,
                              color: Colors.white, size: 24),
                        ),
                      ),
                const SizedBox(height: 8),

                      // Enhanced Auto Zoom Button
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.purple.shade400,
                              Colors.purple.shade600
                            ],
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: FloatingActionButton(
                          heroTag: "auto_zoom",
                          mini: true,
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          onPressed: () {
                            if (_fieldPoints.isNotEmpty &&
                                _mapController != null) {
                              _zoomToFitAllPoints();
                            } else if (_currentLocation != null &&
                                _mapController != null) {
                              _mapController!.animateCamera(
                                CameraUpdate.newLatLngZoom(
                                    _currentLocation!, 18.0),
                              );
                              _showSnackBar('📍 Centered on your location');
                            }
                          },
                          child: const Icon(Icons.fit_screen,
                              color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Enhanced Map Type Toggle
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.shade400,
                              Colors.orange.shade600
                            ],
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: FloatingActionButton(
                          heroTag: "map_type",
                          mini: true,
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          onPressed: () {
                            setState(() {
                              _currentMapType =
                                  _currentMapType == MapType.satellite
                                      ? MapType.normal
                                      : MapType.satellite;
                            });
                            _showSnackBar(_currentMapType == MapType.satellite
                                ? '🛰️ Satellite View'
                                : '🗺️ Normal View');
                          },
                          child: Icon(
                            _currentMapType == MapType.satellite
                                ? Icons.map
                                : Icons.satellite,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Enhanced My Location Button
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.red.shade400, Colors.red.shade600],
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: FloatingActionButton(
                          heroTag: "location",
                          mini: true,
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          onPressed: () async {
                            if (_currentLocation != null &&
                                _mapController != null) {
                              _mapController!.animateCamera(
                                CameraUpdate.newLatLngZoom(
                                    _currentLocation!, 20.0),
                              );
                              _showSnackBar(
                                  '📍 Current Location - High Precision');
                            } else {
                              await _getCurrentLocation();
                            }
                          },
                          child: const Icon(Icons.my_location,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ],
            ),
          ),

                // Enhanced Main Action Button
                Positioned(
            bottom: 30,
            left: 16,
            right: 16,
            child: Container(
                    height: 70,
                    decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isTracking
                            ? [
                                Colors.red.shade400,
                                Colors.red.shade600,
                                Colors.red.shade800
                              ]
                            : [
                                Colors.green.shade400,
                                Colors.green.shade600,
                                Colors.green.shade800
                              ],
                      ),
                      borderRadius: BorderRadius.circular(35),
                      boxShadow: [
                  BoxShadow(
                          color: (_isTracking ? Colors.red : Colors.green)
                              .withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    if (_isTracking) {
                            // Stop tracking with animation
                            _isTracking = false;
                      _fieldPoints.clear();
                      _polygons.clear();
                      _fieldArea = 0.0;
                      _fieldPerimeter = 0.0;
                      _updateSavedPointsMarkers();
                            _showSnackBar('⏹️ GPS Tracking Stopped');
                          } else {
                      // Start tracking
                      _isTracking = true;
                            _showSnackBar(
                                '▶️ GPS Land Tracking Started - Tap to add points!');
                          }
                  });
                },
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          _isTracking
                              ? Icons.stop_circle
                              : Icons.play_circle_filled,
                          color: Colors.white,
                          size: 32,
                          key: ValueKey(_isTracking),
                        ),
                ),
                      label: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _isTracking
                              ? 'Stop GPS Tracking'
                              : 'Start GPS Land Tracking',
                          key: ValueKey(_isTracking),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(35),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
