import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart' show Factory;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
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
  GoogleMapController? _mapController;
  LatLng? _currentLocation;
  bool _isLoading = true;
  MapType _currentMapType = MapType.normal;

  // Walk Mode Features
  bool _walkMode = false;
  bool _isWalking = false;
  LatLng? _lastPosition;
  LatLng? _lastCaptureLocation;
  DateTime? _lastMoveTime;
  static const int maxPoints = 4;
  static const double movementThreshold = 1.5; // meters - more accurate
  static const int stationaryTimeout = 3; // seconds - more responsive
  static const double captureThreshold = 3.0; // meters - more precise

  // Points and Tracking
  final Set<Marker> _markers = {};
  final List<LatLng> _capturedPoints = [];
  final List<LatLng> _walkPath = [];
  final Set<Polyline> _polylines = {};
  double _walkDistance = 0.0;
  LatLng? _walkStartPoint;

  // GPS Tracking
  StreamSubscription<Position>? _positionStream;

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
    // No tap functionality - only walk mode capturing
  }

  void _addPointDuringWalk() {
    if (!_walkMode || _currentLocation == null) {
      _showErrorNotification('Please start walk mode first!');
      return;
    }

    if (_capturedPoints.length >= maxPoints) {
      _showErrorNotification('Maximum $maxPoints points reached!');
      return;
    }

    // Check if trying to capture at same location as any previous point
    for (int i = 0; i < _capturedPoints.length; i++) {
      double distanceFromExistingPoint = Geolocator.distanceBetween(
        _capturedPoints[i].latitude,
        _capturedPoints[i].longitude,
        _currentLocation!.latitude,
        _currentLocation!.longitude,
      );

      if (distanceFromExistingPoint < captureThreshold) {
        _showErrorNotification(
            '📍 Already captured a point here!\nPlease move to another location to capture a new point');
        return;
      }
    }

    _savePointDirectly(_currentLocation!);
    setState(() {
      _lastCaptureLocation = _currentLocation;
    });
  }

  void _savePointDirectly(LatLng position) {
    setState(() {
      _capturedPoints.add(position);
      _lastCaptureLocation = position;

      _markers.add(
        Marker(
          markerId: MarkerId('point_${_capturedPoints.length}'),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: '📍 Point ${_capturedPoints.length}',
            snippet: '${position.latitude.toStringAsFixed(6)}, ${position
                .longitude.toStringAsFixed(6)}',
          ),
        ),
      );

      _updatePointConnections();
    });

    String message = 'Point ${_capturedPoints.length}/$maxPoints captured!';
    if (_capturedPoints.length == maxPoints) {
      message = '🔲 Square completed! Ready to save.';
    }

    _showSuccessNotification(message);
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
    _polylines.removeWhere((polyline) =>
    polyline.polylineId.value != 'walk_path');

    if (_capturedPoints.length >= 2) {
      if (_capturedPoints.length == maxPoints) {
        List<LatLng> squarePoints = List.from(_capturedPoints);
        squarePoints.add(_capturedPoints[0]);

        _polylines.add(
          Polyline(
            polylineId: const PolylineId('square_outline'),
            points: squarePoints,
            color: Colors.red,
            width: 3,
          ),
        );
      } else {
        for (int i = 0; i < _capturedPoints.length - 1; i++) {
          _polylines.add(
            Polyline(
              polylineId: PolylineId('line_$i'),
              points: [_capturedPoints[i], _capturedPoints[i + 1]],
              color: Colors.blue,
              width: 2,
            ),
          );
        }
      }
    }
  }

  void _startWalkMode() {
    if (_currentLocation == null) return;

    setState(() {
      _walkMode = true;
      _isWalking = false;
      _walkPath.clear();
      _walkDistance = 0.0;
      _walkStartPoint = _currentLocation;
      _lastPosition = _currentLocation;
      _lastMoveTime = DateTime.now();
      _lastCaptureLocation = null;
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_currentLocation!, 19.0),
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      ),
    ).listen((Position position) {
      if (!_walkMode) return;

      LatLng newPosition = LatLng(position.latitude, position.longitude);

      if (_lastPosition != null) {
        double distanceMoved = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          newPosition.latitude,
          newPosition.longitude,
        );

        if (distanceMoved >= movementThreshold) {
          setState(() {
            _isWalking = true;
            _lastMoveTime = DateTime.now();
            _walkDistance += distanceMoved;
            _walkPath.add(newPosition);
            _lastPosition = newPosition;
            _currentLocation = newPosition;
          });

          _mapController?.animateCamera(
            CameraUpdate.newLatLng(newPosition),
          );

          _updateWalkPolyline();
        } else {
          if (_lastMoveTime != null) {
            int secondsSinceLastMove = DateTime
                .now()
                .difference(_lastMoveTime!)
                .inSeconds;
            if (secondsSinceLastMove > stationaryTimeout && _isWalking) {
              setState(() {
                _isWalking = false;
              });
            }
          }
        }
      }
    });

    _showSuccessNotification(
        'Walk mode started! Move around and capture points.');
  }

  void _stopWalkTracking() {
    _positionStream?.cancel();
    setState(() {
      _walkMode = false;
      _isWalking = false;
      _lastCaptureLocation = null;
    });

    _markers.removeWhere((marker) => marker.markerId.value == 'walk_start');
    _showSuccessNotification(
        'Walk stopped! Distance: ${_walkDistance.toStringAsFixed(1)}m');
  }

  void _updateWalkPolyline() {
    if (_walkPath.length < 2) return;

    setState(() {
      _polylines.removeWhere((polyline) =>
      polyline.polylineId.value == 'walk_path');
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('walk_path'),
          points: _walkPath,
          color: Colors.purple.withOpacity(0.7),
          width: 2,
          patterns: [PatternItem.dash(10), PatternItem.gap(5)],
        ),
      );
    });
  }

  void _showSaveDialog() {
    if (_capturedPoints.length != maxPoints) {
      _showErrorNotification('Complete all 4 points first!');
      return;
    }

    double totalArea = _calculatePolygonArea(_capturedPoints);
    double perimeter = _calculatePerimeter(_capturedPoints);

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
                      _buildDetailRow('Points:', '$maxPoints corners'),
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
                      labelText: 'Area Name',
                      hintText: 'Enter name for this area',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Material(
                  child: TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText: 'Enter description (optional)',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    maxLines: 2,
                  ),
                ),
                const SizedBox(height: 16),

                const Text('📍 Corner Points', style: TextStyle(
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
                await _saveAreaToDatabase(nameController.text.trim(),
                    descriptionController.text.trim(), totalArea, perimeter);
                Navigator.of(context).pop();
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
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Save each point as a LandPoint to the database
      for (int i = 0; i < _capturedPoints.length; i++) {
        final point = _capturedPoints[i];
        final landPoint = LandPoint(
          id: '${DateTime.now().millisecondsSinceEpoch}_$i',
          latitude: point.latitude,
          longitude: point.longitude,
          timestamp: DateTime.now(),
          notes: name.isEmpty
              ? 'Land Area Point ${i + 1}'
              : '$name - Point ${i + 1}',
          // You can add analysis data here if needed
        );

        await _databaseService.saveLandPoint(landPoint);
      }

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
      });

      _positionStream?.cancel();

      // Hide loading indicator
      if (mounted) {
        Navigator.of(context).pop();
      }

      _showSuccessNotification(
          'Area saved successfully! ${area.toStringAsFixed(2)} m²');

      // Navigate to SavedPointsPage immediately
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SavedPointsPage(),
          ),
        );
      }
    } catch (e) {
      // Hide loading indicator if still showing
      if (mounted) {
        Navigator.of(context).pop();
      }
      _showErrorNotification('Failed to save area: $e');
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
          title: Row(
            children: [
              const Icon(Icons.list, color: Colors.blue, size: 24),
              const SizedBox(width: 8),
              Text('Current Points (${_capturedPoints.length}/$maxPoints)'),
              if (_capturedPoints.length == maxPoints) const Text(
                  ' ✅', style: TextStyle(fontSize: 16)),
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
      _mapController!.animateCamera(CameraUpdate.newLatLngZoom(position, 18.0));
    }
    _showSuccessNotification('Navigating to point');
  }

  void _clearAllPoints() {
    setState(() {
      _capturedPoints.clear();
      _markers.clear();
      _polylines.clear();
    });
    _showSuccessNotification('All points cleared!');
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
                      if (_walkMode)
                        _buildCompactButton(
                          heroTag: "addPoint",
                          onPressed: _addPointDuringWalk,
                          icon: const Icon(Icons.add_location,
                              color: Colors.white, size: 16),
                          label: 'Capture',
                          backgroundColor: Colors.deepOrange,
                        ),

                      // Save Button (only when 4 points completed)
                      if (_capturedPoints.length == maxPoints)
                        _buildCompactButton(
                          heroTag: "saveButton",
                          onPressed: _showSaveDialog,
                          icon: const Icon(Icons.save,
                              color: Colors.white, size: 16),
                          label: 'Save Area',
                          backgroundColor: Colors.green[600]!,
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

                        // Points Counter
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _capturedPoints.length >= maxPoints
                                ? Colors.green[600]
                                : Colors.blue[600],
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: (_capturedPoints.length >= maxPoints
                                        ? Colors.green[600]!
                                        : Colors.blue[600]!)
                                    .withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _capturedPoints.length >= maxPoints
                                    ? Icons.check_circle
                                    : Icons.location_on,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${_capturedPoints.length}/$maxPoints${_capturedPoints.length == maxPoints ? ' ✅' : ''}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11),
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
}
