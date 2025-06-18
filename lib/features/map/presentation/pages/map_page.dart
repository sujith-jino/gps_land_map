import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart' show Factory;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_android/geolocator_android.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'dart:async';
import '../../../../core/services/database_service.dart';
import '../../../../core/models/land_point.dart';
import '../../../saved_points/presentation/pages/saved_points_page.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // Removed maxPoints limit to allow unlimited points
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  bool _isLoading = true;
  MapType _currentMapType = MapType.normal;

  // Walk Mode Features
  bool _walkMode = false;
  bool _isWalking = false;
  bool _showCaptureButton = false;
  LatLng? _lastPosition;
  LatLng? _lastCaptureLocation;
  DateTime? _lastMoveTime;
  // Removed maxPoints limit to allow unlimited points
  // Enhanced accuracy settings for walking mode
  static const double movementThreshold = 0.5; // meters - high precision movement threshold
  static const int stationaryTimeout = 1; // seconds - more responsive updates
  static const double captureThreshold = 2.0; // meters - precise point capture
  static const double minimumPointDistance = 1.5; // meters - minimum distance between points
  static const double maxAcceptableAccuracy = 5.0; // meters - maximum acceptable accuracy
  static const int minSamplesForAccuracy = 3; // Minimum samples for accuracy check
  static const int maxSamplesForAveraging = 5; // Max samples to average for position

  // Points and Tracking
  final Set<Marker> _markers = {};
  final List<LatLng> _capturedPoints = [];
  final List<LatLng> _walkPath = [];
  final Set<Polyline> _polylines = {};
  double _walkDistance = 0.0;
  LatLng? _walkStartPoint;

  // GPS Tracking
  StreamSubscription<Position>? _positionStream;
  double? _currentAccuracy;
  bool _isHighAccuracy = false;
  final List<LatLng> _positionSamples = [];
  double _averageAccuracy = 0.0;

  // Database Service
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await _getCurrentLocation();
      if (!mounted) return;
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );

      if (!mounted) return;
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });

      if (_mapController != null && _currentLocation != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_currentLocation!, 18.0),
        );
      }
    } catch (e) {
      // Handle error silently
    }
  }

  void _onMapTap(LatLng position) {
    if (!_walkMode) return; // Only allow adding points in walk mode
    
    // Check minimum distance from all existing points
    for (int i = 0; i < _capturedPoints.length; i++) {
      double distance = Geolocator.distanceBetween(
        _capturedPoints[i].latitude,
        _capturedPoints[i].longitude,
        position.latitude,
        position.longitude,
      );

      if (distance < minimumPointDistance) {
        _showErrorNotification('Point must be at least ${minimumPointDistance}m away from other points');
        return;
      }
    }
    
    // Check minimum distance from all existing points
    for (int i = 0; i < _capturedPoints.length; i++) {
      double distance = Geolocator.distanceBetween(
        _capturedPoints[i].latitude,
        _capturedPoints[i].longitude,
        position.latitude,
        position.longitude,
      );

      if (distance < minimumPointDistance) {
        _showErrorNotification('Point must be at least ${minimumPointDistance}m away from other points');
        return;
      }
    }
    
    // Save the tapped position
    _savePointDirectly(position);
    
    // Show success message
    _showSuccessNotification('Point ${_capturedPoints.length} captured!');
  }

  void _addPointDuringWalk() {
    if (!_walkMode || _currentLocation == null) {
      _showErrorNotification('Please start walk mode first!');
      return;
    }

    // Check GPS accuracy before capturing point
    if (_currentAccuracy == null || _currentAccuracy! > maxAcceptableAccuracy) {
      _showErrorNotification(
        'Low GPS accuracy (${_currentAccuracy?.toStringAsFixed(1) ?? 'unknown'}m). '
        'Move to a clearer area with open sky view.'
      );
      return;
    }
    
    // Check if we have enough position samples for accuracy
    if (_positionSamples.length < minSamplesForAccuracy) {
      _showErrorNotification('Getting better GPS fix... Please wait');
      return;
    }
    
    // Calculate average position from recent samples
    double avgLat = 0.0;
    double avgLng = 0.0;
    for (var pos in _positionSamples) {
      avgLat += pos.latitude;
      avgLng += pos.longitude;
    }
    avgLat /= _positionSamples.length;
    avgLng /= _positionSamples.length;
    final averagedPosition = LatLng(avgLat, avgLng);
    
    // Check minimum distance from last point
    if (_capturedPoints.isNotEmpty) {
      double distanceFromLast = Geolocator.distanceBetween(
        _capturedPoints.last.latitude,
        _capturedPoints.last.longitude,
        averagedPosition.latitude,
        averagedPosition.longitude,
      );
      
      if (distanceFromLast < minimumPointDistance) {
        _showErrorNotification('Move at least ${minimumPointDistance}m from the last point');
        return;
      }
      
      // Check if point forms a valid angle with previous points
      if (_capturedPoints.length > 1) {
        final prevPoint1 = _capturedPoints[_capturedPoints.length - 2];
        final prevPoint2 = _capturedPoints.last;
        
        final angle = _calculateAngle(prevPoint1, prevPoint2, averagedPosition);
        if (angle < 30.0) {
          _showErrorNotification('Sharp angle detected. Adjust your path.');
          return;
        }
      }
    }
    
    // Check minimum distance from all other points
    for (int i = 0; i < _capturedPoints.length; i++) {
      double distanceFromPoint = Geolocator.distanceBetween(
        _capturedPoints[i].latitude,
        _capturedPoints[i].longitude,
        averagedPosition.latitude,
        averagedPosition.longitude,
      );
      
      if (distanceFromPoint < minimumPointDistance) {
        _showErrorNotification('Point too close to point ${i + 1} (${distanceFromPoint.toStringAsFixed(1)}m)');
        return;
      }
    }
    
    // Save the averaged position
    _savePointDirectly(averagedPosition);
    
    // Clear position samples after capturing a point
    _positionSamples.clear();
    
    // Provide haptic feedback
    try {
      HapticFeedback.mediumImpact();
    } catch (e) {
      debugPrint('Haptic feedback not available: $e');
    }
    
    // Show point details with accuracy information
    String pointInfo = '✅ Point ${_capturedPoints.length} captured!\n'
                      '• Accuracy: ${_currentAccuracy!.toStringAsFixed(1)}m';
    
    if (_capturedPoints.length > 1) {
      double distanceFromLast = Geolocator.distanceBetween(
        _capturedPoints[_capturedPoints.length - 2].latitude,
        _capturedPoints[_capturedPoints.length - 2].longitude,
        averagedPosition.latitude,
        averagedPosition.longitude,
      );
      pointInfo += '\n• Distance: ${distanceFromLast.toStringAsFixed(1)}m';
    }
    
    _showSuccessNotification(pointInfo);
  }
  
  double _calculateAngle(LatLng a, LatLng b, LatLng c) {
    // Calculate angle at point b between a and c
    final angle1 = atan2(c.latitude - b.latitude, c.longitude - b.longitude);
    final angle2 = atan2(a.latitude - b.latitude, a.longitude - b.longitude);
    var angle = (angle1 - angle2).abs() * (180.0 / 3.141592653589793);
    return angle > 180.0 ? 360.0 - angle : angle;
  }

  // Helper method to safely show marker info window
  void _showInfoWindow(String markerId) async {
    if (markerId.isEmpty) {
      debugPrint('Cannot show info window: Empty markerId');
      return;
    }
    
    try {
      await _mapController?.showMarkerInfoWindow(MarkerId(markerId));
    } catch (e) {
      debugPrint('Error showing info window for marker $markerId: $e');
    }
  }

  void _savePointDirectly(LatLng position) {
    // Generate marker ID before modifying _capturedPoints to ensure correct numbering
    final markerId = 'point_${_capturedPoints.length + 1}';
    
    setState(() {
      _capturedPoints.add(position);
      _lastCaptureLocation = position;

      _markers.add(
        Marker(
          markerId: MarkerId(markerId),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: '📍 Point ${_capturedPoints.length}',
            snippet: '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
          ),
          onTap: () => _showInfoWindow(markerId),
        ),
      );

      _updatePointConnections();

      // Show save button when at least 2 points are captured
      if (_capturedPoints.length >= 2) {
        _showCaptureButton = true;
      }
    });

    // Zoom to the captured point with fixed zoom level
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: position,
          zoom: 20.0,  // Fixed high zoom level
          bearing: 0.0,  // North-up orientation
          tilt: 0.0,    // Top-down view
        ),
      ),
      duration: const Duration(milliseconds: 300),
    );

    // Disable zoom controls and gestures
    _mapController?.setMapStyle('''
      [
        {
          "featureType": "all",
          "elementType": "all",
          "stylers": [
            { "saturation": 0 },
            { "lightness": 0 },
            { "gamma": 1.0 }
          ]
        }
      ]
    ''');

    // Show distance to previous point if available
    if (_capturedPoints.length > 1) {
      LatLng prevPoint = _capturedPoints[_capturedPoints.length - 2];
      double distance = Geolocator.distanceBetween(
        prevPoint.latitude,
        prevPoint.longitude,
        position.latitude,
        position.longitude,
      );
      _showSuccessNotification('Point ${_capturedPoints.length} captured!\nDistance from last point: ${distance.toStringAsFixed(1)}m');
    } else {
      _showSuccessNotification('Point 1 captured!');
    }
  }

  double _calculatePolygonArea(List<LatLng> points) {
    if (points.length < 3) return 0.0;

    double area = 0.0;
    int n = points.length;

    for (int i = 0; i < n; i++) {
      int j = (i + 1) % n;
      area += points[i].longitude * points[j].latitude;
      area -= points[j].longitude * points[i].latitude;
    }

    // More accurate area calculation
    area = (area.abs() / 2.0) * 111320 * 111320 *
        (1 - 0.00669437999014 * (points[0].latitude * 3.14159 / 180).abs());
    return area;
  }

  double _calculatePerimeter(List<LatLng> points) {
    if (points.length < 2) return 0.0;

    double perimeter = 0.0;
    for (int i = 0; i < points.length; i++) {
      int nextIndex = (i + 1) % points.length;
      perimeter += Geolocator.distanceBetween(
        points[i].latitude,
        points[i].longitude,
        points[nextIndex].latitude,
        points[nextIndex].longitude,
      );
    }
    return perimeter;
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _updatePointConnections() {
    // Keep only the walk path polyline
    _polylines.removeWhere((polyline) =>
        polyline.polylineId.value != 'walk_path');
    // Add lines between all captured points
    if (_capturedPoints.length >= 2) {
      // Add lines between consecutive points
      for (int i = 0; i < _capturedPoints.length - 1; i++) {
        _polylines.add(
          Polyline(
            polylineId: PolylineId('line_${i}_${i + 1}'),
            points: [_capturedPoints[i], _capturedPoints[i + 1]],
            color: Colors.blue,
            width: 2,
          ),
        );
      }
      // Add line from last point to first point if more than 2 points
      if (_capturedPoints.length > 2) {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('closing_line'),
            points: [_capturedPoints.last, _capturedPoints.first],
            color: Colors.blue,
            width: 2,
            patterns: [PatternItem.dash(15), PatternItem.gap(5)],
          ),
        );
      }
    }
  }
  void _startWalkMode() async {
    if (_currentLocation == null) {
      _showErrorNotification('Unable to determine current location');
      return;
    }
    
    // Request high accuracy location
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showErrorNotification('Please enable location services');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse && 
          permission != LocationPermission.always) {
        _showErrorNotification('Location permissions are required for walk mode');
        return;
      }
    }

    // Clear any existing data
    setState(() {
      _capturedPoints.clear();
      _markers.clear();
      _polylines.clear();
      _walkPath.clear();
      _positionSamples.clear();
      _walkDistance = 0.0;
      _lastPosition = null;
      _lastMoveTime = DateTime.now();
      _lastCaptureLocation = null;
      _isHighAccuracy = false;
      _averageAccuracy = 0.0;
      _walkMode = true;
      _isWalking = true;
      _showCaptureButton = true;
    });

    // Set initial walk path point
    _walkPath.add(_currentLocation!);
    _walkStartPoint = _currentLocation!;

    // Zoom to current location with optimal settings
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _currentLocation!,
          zoom: 19.0,
          bearing: 0.0,
          tilt: 45.0,
        ),
      ),
      duration: const Duration(milliseconds: 500),
    );

    // Start high accuracy position stream
    _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        intervalDuration: const Duration(milliseconds: 500),
        forceLocationManager: true,
      ),
    ).listen((Position position) {
      if (!_walkMode || !mounted) return;
      
      final newPosition = LatLng(position.latitude, position.longitude);
      final accuracy = position.accuracy;

      // Update position samples for accuracy calculation
      _positionSamples.add(newPosition);
      if (_positionSamples.length > maxSamplesForAveraging) {
        _positionSamples.removeAt(0);
      }

      // Calculate averaged position for better accuracy
      LatLng effectivePosition = newPosition;
      if (_positionSamples.length >= minSamplesForAccuracy) {
        double avgLat =
            _positionSamples.map((p) => p.latitude).reduce((a, b) => a + b) /
                _positionSamples.length;
        double avgLng =
            _positionSamples.map((p) => p.longitude).reduce((a, b) => a + b) /
                _positionSamples.length;
        effectivePosition = LatLng(avgLat, avgLng);
      }
      
      final isAccurate = accuracy <= maxAcceptableAccuracy;
      
      setState(() {
        _currentAccuracy = accuracy;
        _isHighAccuracy = isAccurate;
        _currentLocation = effectivePosition;
      });

      // Update walk path and distance
      if (_lastPosition != null && isAccurate) {
        final distanceMoved = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          effectivePosition.latitude,
          effectivePosition.longitude,
        );

        if (distanceMoved > movementThreshold) {
          setState(() {
            _isWalking = true;
            _lastMoveTime = DateTime.now();
            _walkDistance += distanceMoved;
            _lastPosition = effectivePosition;

            // Add to walk path
            if (_walkPath.isEmpty || 
                Geolocator.distanceBetween(
                  _walkPath.last.latitude,
                  _walkPath.last.longitude,
                  effectivePosition.latitude,
                  effectivePosition.longitude,
                ) >= movementThreshold) {
              _walkPath.add(effectivePosition);
              _updateWalkPolyline();
            }
          });

          // Smooth camera tracking
          if (_walkPath.length > 1) {
            final bearing = _calculateBearing(
                _walkPath[_walkPath.length - 2], effectivePosition);
            _mapController?.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: effectivePosition,
                  zoom: 19.0,
                  bearing: bearing,
                  tilt: 45.0,
                ),
              ),
            );
          }
        }
      } else if (_lastPosition == null) {
        setState(() {
          _lastPosition = effectivePosition;
          _walkPath.add(effectivePosition);
        });
        _updateWalkPolyline();
      }
    }, onError: (error) {
      debugPrint('GPS Error: $error');
      _showErrorNotification(
          'GPS error occurred. Please check your location settings.');
    });
    
    _showSuccessNotification(
      '🚶‍♂️ Walk mode started!\n'
      '• High accuracy GPS enabled\n'
      '• Tap "Capture" to add points\n'
      '• Minimum distance: ${minimumPointDistance}m',
    );
  }
  
  double _calculateBearing(LatLng from, LatLng to) {
    final lat1 = from.latitude * (3.141592653589793 / 180.0);
    final lon1 = from.longitude * (3.141592653589793 / 180.0);
    final lat2 = to.latitude * (3.141592653589793 / 180.0);
    final lon2 = to.longitude * (3.141592653589793 / 180.0);
    
    final dLon = lon2 - lon1;
    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    
    double bearing = atan2(y, x) * (180.0 / 3.141592653589793);
    return (bearing + 360) % 360;
  }
  void _stopWalkTracking() {
    _positionStream?.cancel();
    
    setState(() {
      _walkMode = false;
      _isWalking = false;
      _lastCaptureLocation = null;
      _isHighAccuracy = false;
      _showCaptureButton = _capturedPoints.isNotEmpty;
    });

    // Keep walk path polyline for reference
    if (_walkPath.isNotEmpty) {
      _updateWalkPolyline();
    }

    String walkSummary = 'Walk mode stopped!';
    if (_walkDistance > 0) {
      walkSummary +=
          '\n• Distance walked: ${_walkDistance.toStringAsFixed(1)}m';
    }
    if (_capturedPoints.isNotEmpty) {
      walkSummary += '\n• Points captured: ${_capturedPoints.length}';
      walkSummary += '\n• Tap "Save" to save your area';
    } else {
      walkSummary += '\n• No points were captured';
    }

    _showSuccessNotification(walkSummary);
  }
  void _updateWalkPolyline() {
    if (_walkPath.length < 2) return;
    
    // Calculate total distance
    double totalDistance = 0;
    for (int i = 1; i < _walkPath.length; i++) {
      totalDistance += Geolocator.distanceBetween(
        _walkPath[i-1].latitude, 
        _walkPath[i-1].longitude,
        _walkPath[i].latitude,
        _walkPath[i].longitude,
      );
    }
    _walkDistance = totalDistance;
    
    setState(() {
      _polylines.removeWhere((polyline) => 
          polyline.polylineId.value == 'walk_path');
      
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('walk_path'),
          points: List<LatLng>.from(_walkPath),
          color: Colors.blue.withOpacity(0.7),
          width: 5,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
          patterns: [
            PatternItem.dash(10),
            PatternItem.gap(5),
          ],
        ),
      );
    });
  }
  void _showSaveDialog() {
    if (_capturedPoints.length < 3) {
      _showErrorNotification('At least 3 points are required to save an area!');
      return;
    }
    double totalArea = _calculatePolygonArea(_capturedPoints);
    double perimeter = _calculatePerimeter(_capturedPoints);

    // Info windows will be automatically closed when the dialog appears
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController nameController = TextEditingController();
        final TextEditingController descriptionController = TextEditingController();

        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          title: const Row(
            children: [
              Icon(Icons.save, color: Colors.green, size: 24),
              SizedBox(width: 8),
              Text('Save Land Area', style: TextStyle(fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('📊 Area Summary', style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(
                          'Area:', '${totalArea.toStringAsFixed(2)} m²'),
                      _buildDetailRow(
                          'Perimeter:', '${perimeter.toStringAsFixed(2)} m'),
                      _buildDetailRow('Points:', '${_capturedPoints.length} corners'),
                      _buildDetailRow('Walk Distance:',
                          '${_walkDistance.toStringAsFixed(1)} m'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Material(
                  child: TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Area Name *',
                      hintText: 'Enter name for this area (required)',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.all(12),
                      errorText: null,
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
                const SizedBox(height: 12),
                Material(
                  child: TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      hintText: 'Enter description',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(height: 16),
                const Text('📍 Captured Points', style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    itemCount: _capturedPoints.length,
                    itemBuilder: (context, index) {
                      final point = _capturedPoints[index];
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.green,
                          child: Text('${index + 1}', style: const TextStyle(
                              color: Colors.white, fontSize: 12)),
                        ),
                        title: Text('Point ${index + 1}',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          'Lat: ${point.latitude.toStringAsFixed(6)}\nLng: ${point.longitude.toStringAsFixed(6)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                String areaName = nameController.text.trim();
                if (areaName.isEmpty) {
                  _showErrorNotification('Please enter the area name');
                  return;
                }
                Navigator.of(context).pop();
                await _saveAreaToDatabase(areaName,
                    descriptionController.text.trim(), totalArea, perimeter);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
  Future<void> _saveAreaToDatabase(String name, String description, double area,
      double perimeter) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Saving your land area...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$name - ${area.toStringAsFixed(2)} m²',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Generate a unique area ID
      final String areaId = 'area_${DateTime.now().millisecondsSinceEpoch}';

      // Create points data as a string for storage
      List<String> pointsData = [];
      for (int i = 0; i < _capturedPoints.length; i++) {
        final point = _capturedPoints[i];
        pointsData.add(
            'Point ${i + 1}: ${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}');
      }

      // Create comprehensive notes with all area information
      String detailedNotes = '''Area Name: $name
Description: ${description.isNotEmpty ? description : 'No description'}
Area: ${area.toStringAsFixed(2)} m²
Perimeter: ${perimeter.toStringAsFixed(2)} m
Walk Distance: ${_walkDistance.toStringAsFixed(1)} m
Total Points: ${_capturedPoints.length}
Date Captured: ${DateTime.now().toString().split('.')[0]}

Points Captured:
${pointsData.join('\n')}''';

      // Save as a single area entry using the center point of the polygon
      double centerLat =
          _capturedPoints.map((p) => p.latitude).reduce((a, b) => a + b) /
              _capturedPoints.length;
      double centerLng =
          _capturedPoints.map((p) => p.longitude).reduce((a, b) => a + b) /
              _capturedPoints.length;

      final landPoint = LandPoint(
        id: areaId,
        latitude: centerLat,
        longitude: centerLng,
        timestamp: DateTime.now(),
        notes: detailedNotes,
        tags: ['area', name.toLowerCase().replaceAll(' ', '_')],
      );

      await _databaseService.saveLandPoint(landPoint);

      // Clear the current points and reset the map
      setState(() {
        _capturedPoints.clear();
        _markers.clear();
        _polylines.clear();
        _walkPath.clear();
        _walkDistance = 0.0;
        _walkStartPoint = null;
        _lastCaptureLocation = null;
        _walkMode = false;
        _isWalking = false;
        _showCaptureButton = false;
      });
      _positionStream?.cancel();

      // Hide loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show success message
      _showSuccessNotification(
          '✅ Area "$name" saved successfully!\n${area.toStringAsFixed(2)} m² with ${_capturedPoints.length} points');

      // Wait a moment for the success message to be visible
      await Future.delayed(const Duration(milliseconds: 1000));

      // Navigate to SavedPointsPage with smooth transition
      if (mounted) {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const SavedPointsPage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;

              var tween =
                  Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);

              return SlideTransition(position: offsetAnimation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      }
    } catch (e) {
      // Hide loading dialog if still showing
      if (mounted) {
        Navigator.of(context).pop();
      }
      _showErrorNotification('Failed to save area: ${e.toString()}');
    }
  }
  void _toggleMapType() {
    setState(() {
      _currentMapType =
      _currentMapType == MapType.normal ? MapType.satellite : MapType.normal;
    });
    _showSuccessNotification(_currentMapType == MapType.satellite
        ? 'Satellite View'
        : 'Normal View');
  }
  void _showErrorNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.warning_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
      ),
    );
  }
  void _showSuccessNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
      ),
    );
  }
  void _showSavedPointsList() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Current Points', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                '${_capturedPoints.length} points added',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: _capturedPoints.isEmpty
                ? const Center(child: Text('No points captured yet'))
                : ListView.builder(
                    itemCount: _capturedPoints.length,
                    itemBuilder: (context, index) {
                      final point = _capturedPoints[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green,
                            radius: 16,
                            child: Text('${index + 1}', style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                          ),
                          title: Text('Point ${index + 1}',
                              style: const TextStyle(fontWeight: FontWeight
                                  .bold)),
                          subtitle: Text(
                              '${point.latitude.toStringAsFixed(6)}, ${point
                                  .longitude.toStringAsFixed(6)}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.navigation, color: Colors
                                .blue),
                            onPressed: () {
                              _navigateToPoint(point);
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            if (_capturedPoints.isNotEmpty)
              TextButton(
                onPressed: () {
                  _clearAllPoints();
                  Navigator.of(context).pop();
                },
                child: const Text(
                    'Clear All', style: TextStyle(color: Colors.red)),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
  void _navigateToPoint(LatLng position) {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: position,
            zoom: 20.0,  // Increased zoom level for closer view
            bearing: 0.0,  // Reset bearing for straight view
            tilt: 0.0,    // Reset tilt for top-down view
          ),
        ),
        duration: const Duration(milliseconds: 500),  // Smooth animation
      );
    }
    _showSuccessNotification('Navigating to point');
  }
  void _clearAllPoints() {
    setState(() {
      _markers.clear();
      _capturedPoints.clear();
      _polylines.clear();
      _walkPath.clear();
      _walkDistance = 0.0;
      _showCaptureButton = false;
      _isWalking = false;
      _walkMode = false;
      _lastPosition = null;
      _lastMoveTime = null;
      _lastCaptureLocation = null;
      _isHighAccuracy = false;
    });
    _positionStream?.cancel();
    _showSuccessNotification('All points and paths have been cleared');
  }
  Widget _buildCompactButton({
    required String heroTag,
    required VoidCallback onPressed,
    required Widget icon,
    required String label,
    required Color backgroundColor,
    bool isExtended = true,
    bool isSmall = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: isSmall
          ? FloatingActionButton.small(
              heroTag: heroTag,
              onPressed: onPressed,
              backgroundColor: backgroundColor,
              child: icon,
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            )
          : SizedBox(
              height: 36,
              child: FloatingActionButton.extended(
                heroTag: heroTag,
                onPressed: onPressed,
                backgroundColor: backgroundColor,
                icon: icon,
                label: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
              ),
            ),
    );
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
                    zoom: 18.0,
                  ),
                  onTap: _onMapTap,
                  markers: _markers,
                  polylines: _polylines,
                  mapType: _currentMapType,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  compassEnabled: true,
                  zoomControlsEnabled: false,
                  zoomGesturesEnabled: true,
                  scrollGesturesEnabled: true,
                  tiltGesturesEnabled: true,
                  rotateGesturesEnabled: true,
                  mapToolbarEnabled: false,
                  buildingsEnabled: true,
                  trafficEnabled: false,
                  indoorViewEnabled: true,
                  liteModeEnabled: false,
                  gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                    Factory<OneSequenceGestureRecognizer>(() =>
                        EagerGestureRecognizer()),
                  },
                  minMaxZoomPreference: const MinMaxZoomPreference(1.0, 25.0),
                  cameraTargetBounds: CameraTargetBounds.unbounded,
                ),
                // Point Counter - Top Center
                if (_capturedPoints.isNotEmpty)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 12,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          'Points: ${_capturedPoints.length}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ),
                  ),
                // Map Type Toggle - Top Left (Google Maps style)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 12,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: _toggleMapType,
                        child: Center(
                          child: Icon(
                            _currentMapType == MapType.satellite
                                ? Icons.map_outlined
                                : Icons.satellite_alt_outlined,
                            color: Colors.grey[700],
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Walk Distance Display
                if (_walkMode)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.teal,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.teal.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.directions_walk,
                              color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${_walkDistance.toStringAsFixed(1)}m',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Right Side Controls
                Positioned(
                  bottom: 60,
                  right: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Capture Point Button (only during walk mode)
                      if (_showCaptureButton)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Save Button (shown after first point is captured)
                            if (_capturedPoints.isNotEmpty)
                              _buildCompactButton(
                                heroTag: "saveButton",
                                onPressed: _showSaveDialog,
                                icon: const Icon(Icons.save,
                                    color: Colors.white, size: 16),
                                label: 'Save',
                                backgroundColor: Colors.green[600]!,
                              ),
                            // Capture Button
                            _buildCompactButton(
                              heroTag: "addPoint",
                              onPressed: _addPointDuringWalk,
                              icon: const Icon(Icons.add_location,
                                  color: Colors.white, size: 16),
                              label: 'Capture',
                              backgroundColor: Colors.deepOrange,
                            ),
                          ],
                        ),
                      // Walk Mode Toggle
                      _buildCompactButton(
                        heroTag: "walkToggle",
                        onPressed: () {
                          setState(() {
                            _walkMode = !_walkMode;
                            if (_walkMode) {
                              _startWalkMode();
                            } else {
                              _stopWalkTracking();
                            }
                          });
                        },
                        icon: Icon(
                          _walkMode ? Icons.stop : Icons.directions_walk,
                          color: Colors.white,
                          size: 16,
                        ),
                        label: _walkMode ? 'Stop' : 'Walk',
                        backgroundColor:
                            _walkMode ? Colors.red[600]! : Colors.purple[600]!,
                      ),
                    ],
                  ),
                ),
                // Left Side Controls
                if (_capturedPoints.isNotEmpty)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // View Current Points Button
                        _buildCompactButton(
                          heroTag: "viewPoints",
                          onPressed: _showSavedPointsList,
                          icon: const Icon(Icons.list,
                              color: Colors.white, size: 16),
                          label: 'Points',
                          backgroundColor: Colors.blue[600]!,
                        ),
                        // Removed points counter
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
