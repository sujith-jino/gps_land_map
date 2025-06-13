import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

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
  bool _isWalking = false; // Track if user is actually moving
  LatLng? _lastPosition;
  DateTime? _lastMoveTime;
  static const int maxPoints = 4;
  static const double movementThreshold = 2.0; // meters
  static const int stationaryTimeout = 5; // seconds

  // Points and Tracking
  final Set<Marker> _markers = {};
  final List<LatLng> _capturedPoints = [];
  final List<Map<String, dynamic>> _savedPoints = [];
  final List<LatLng> _walkPath = [];
  final Set<Polyline> _polylines = {};
  double _walkDistance = 0.0;
  LatLng? _walkStartPoint;

  // GPS Tracking
  StreamSubscription<Position>? _positionStream;

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
        desiredAccuracy: LocationAccuracy.high,
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
      // Ignore errors for clean interface
    }
  }

  void _onMapTap(LatLng position) {
    // No tap functionality
  }

  void _addCapturePoint(LatLng position) {
    // Check if maximum points reached
    if (_capturedPoints.length >= maxPoints) {
      _showErrorNotification(
          'Maximum $maxPoints points allowed! Complete current square first.');
      return;
    }

    // Check if point already exists nearby (within 5 meters)
    for (LatLng existingPoint in _capturedPoints) {
      double distance = Geolocator.distanceBetween(
        existingPoint.latitude,
        existingPoint.longitude,
        position.latitude,
        position.longitude,
      );

      if (distance < 5.0) {
        _showErrorNotification(
            'Already pointed here! Please choose another area.');
        return;
      }
    }

    _showPointDetailsDialog(position);
  }

  void _addPointDuringWalk() {
    if (_currentLocation == null) return;

    // Check if maximum points reached
    if (_capturedPoints.length >= maxPoints) {
      _showErrorNotification(
          'Maximum $maxPoints points reached! Complete current square first.');
      return;
    }

    // Check if point already exists nearby (within 5 meters)
    for (LatLng existingPoint in _capturedPoints) {
      double distance = Geolocator.distanceBetween(
        existingPoint.latitude,
        existingPoint.longitude,
        _currentLocation!.latitude,
        _currentLocation!.longitude,
      );

      if (distance < 5.0) {
        _showErrorNotification(
            'Already pointed here! Please walk to another area.');
        return;
      }
    }

    _showPointDetailsDialog(_currentLocation!);
  }

  void _showPointDetailsDialog(LatLng position) {
    final TextEditingController descriptionController = TextEditingController();

    // Calculate distance from reference point
    double distanceFromReference = 0.0;
    String distanceLabel = '📏 Distance:';

    if (_capturedPoints.isNotEmpty) {
      LatLng previousPoint = _capturedPoints.last;
      distanceFromReference = Geolocator.distanceBetween(
        previousPoint.latitude,
        previousPoint.longitude,
        position.latitude,
        position.longitude,
      );
      distanceLabel = '📏 Distance from Point ${_capturedPoints.length}:';
    } else if (_walkStartPoint != null) {
      distanceFromReference = Geolocator.distanceBetween(
        _walkStartPoint!.latitude,
        _walkStartPoint!.longitude,
        position.latitude,
        position.longitude,
      );
      distanceLabel = '📏 Distance from start:';
    } else if (_currentLocation != null) {
      distanceFromReference = Geolocator.distanceBetween(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
        position.latitude,
        position.longitude,
      );
      distanceLabel = '📏 Distance from current location:';
    }

    // Calculate area if this will be the 4th point
    double? totalArea;
    if (_capturedPoints.length == 3) {
      List<LatLng> allPoints = List.from(_capturedPoints)..add(position);
      totalArea = _calculatePolygonArea(allPoints);
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.add_location_alt, color: Colors.green),
              const SizedBox(width: 8),
              Text('Point ${_capturedPoints.length + 1} of $maxPoints'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                    '📍 Latitude:', position.latitude.toStringAsFixed(6)),
                const SizedBox(height: 8),
                _buildDetailRow(
                    '📍 Longitude:', position.longitude.toStringAsFixed(6)),
                const SizedBox(height: 8),
                _buildDetailRow(distanceLabel,
                    '${distanceFromReference.toStringAsFixed(2)} m'),
                if (totalArea != null) ...[
                  const SizedBox(height: 8),
                  _buildDetailRow(
                      '📐 Total Area:', '${totalArea.toStringAsFixed(2)} sq.m'),
                ],
                const SizedBox(height: 16),
                const Text(
                  'Description:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    hintText: 'Enter point description...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  maxLines: 2,
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
              onPressed: () {
                _savePointWithDetails(
                  position,
                  descriptionController.text.trim(),
                  distanceFromReference,
                );
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save Point'),
            ),
          ],
        );
      },
    );
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

    area = (area.abs() / 2.0) *
        111000 *
        111000; // Convert to square meters approximately
    return area;
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  void _savePointWithDetails(
      LatLng position, String description, double distance) {
    final pointData = {
      'position': position,
      'description': description.isEmpty
          ? 'Point ${_capturedPoints.length + 1}'
          : description,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'distance': distance,
      'timestamp': DateTime.now(),
    };

    setState(() {
      _capturedPoints.add(position);
      _savedPoints.add(pointData);

      // Add marker
      _markers.add(
        Marker(
          markerId: MarkerId('capture_point_${_capturedPoints.length}'),
          position: position,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: '📍 ${pointData['description']}',
            snippet:
                'Point ${_capturedPoints.length}: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
          ),
        ),
      );

      _updatePointConnections();
    });

    String message = 'Point ${_capturedPoints.length}/$maxPoints saved! 📍';

    // Show save button if 4 points are completed
    if (_capturedPoints.length == maxPoints) {
      message = '🔲 Square completed! Tap SAVE to save all points.';
    }

    _showSuccessNotification(message);
  }

  void _updatePointConnections() {
    // Clear existing polylines except walk path
    _polylines
        .removeWhere((polyline) => polyline.polylineId.value != 'walk_path');

    if (_capturedPoints.length >= 2) {
      if (_capturedPoints.length == maxPoints) {
        // Create square with all 4 points
        List<LatLng> squarePoints = List.from(_capturedPoints);
        squarePoints.add(_capturedPoints[0]); // Close the square

        _polylines.add(
          Polyline(
            polylineId: const PolylineId('square_outline'),
            points: squarePoints,
            color: Colors.red,
            width: 4,
          ),
        );
      } else {
        // Connect points in sequence (lines between consecutive points)
        for (int i = 0; i < _capturedPoints.length - 1; i++) {
          _polylines.add(
            Polyline(
              polylineId: PolylineId('line_$i'),
              points: [_capturedPoints[i], _capturedPoints[i + 1]],
              color: Colors.blue,
              width: 3,
            ),
          );
        }
      }
    }
  }

  void _startWalkTracking() {
    if (_currentLocation == null) return;

    setState(() {
      _walkMode = true;
      _isWalking = false;
      _walkPath.clear();
      _walkDistance = 0.0;
      _walkStartPoint = _currentLocation;
      _lastPosition = _currentLocation;
      _lastMoveTime = DateTime.now();
    });

    // Add starting point marker
    _markers.add(
      Marker(
        markerId: const MarkerId('walk_start'),
        position: _currentLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(
          title: '🚶‍♂️ Walk Start',
          snippet: 'Starting point of your walk',
        ),
      ),
    );

    // Zoom to current location with good zoom level
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_currentLocation!, 19.0),
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
      ),
    ).listen((Position position) {
      if (!_walkMode) return;

      LatLng newPosition = LatLng(position.latitude, position.longitude);

      // Check if user is actually moving
      if (_lastPosition != null) {
        double distanceMoved = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          newPosition.latitude,
          newPosition.longitude,
        );

        if (distanceMoved >= movementThreshold) {
          // User is moving
          setState(() {
            _isWalking = true;
            _lastMoveTime = DateTime.now();
            _walkDistance += distanceMoved;
            _walkPath.add(newPosition);
            _lastPosition = newPosition;
          });

          // Follow user's movement with smooth camera animation
          _mapController?.animateCamera(
            CameraUpdate.newLatLng(newPosition),
          );

          _updateWalkPolyline();
        } else {
          // Check if user has been stationary for too long
          if (_lastMoveTime != null) {
            int secondsSinceLastMove =
                DateTime.now().difference(_lastMoveTime!).inSeconds;
            if (secondsSinceLastMove > stationaryTimeout && _isWalking) {
              setState(() {
                _isWalking = false;
              });
            }
          }
        }
      }
    });

    _showSuccessNotification('🚶‍♂️ Walk started! Move to track your path.');
  }

  void _stopWalkTracking() {
    _positionStream?.cancel();
    setState(() {
      _walkMode = false;
      _isWalking = false;
    });

    // Remove start marker
    _markers.removeWhere((marker) => marker.markerId.value == 'walk_start');

    _showSuccessNotification(
        '🛑 Walk stopped! Total distance: ${_walkDistance.toStringAsFixed(1)}m');
  }

  void _updateWalkPolyline() {
    if (_walkPath.length < 2) return;

    setState(() {
      _polylines
          .removeWhere((polyline) => polyline.polylineId.value == 'walk_path');
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('walk_path'),
          points: _walkPath,
          color: Colors.purple,
          width: 3,
          patterns: [PatternItem.dash(8), PatternItem.gap(4)],
        ),
      );
    });
  }

  void _showSaveDialog() {
    if (_capturedPoints.length != maxPoints) return;

    // Calculate total area
    double totalArea = _calculatePolygonArea(_capturedPoints);

    // Calculate perimeter
    double perimeter = 0.0;
    for (int i = 0; i < _capturedPoints.length; i++) {
      int nextIndex = (i + 1) % _capturedPoints.length;
      perimeter += Geolocator.distanceBetween(
        _capturedPoints[i].latitude,
        _capturedPoints[i].longitude,
        _capturedPoints[nextIndex].latitude,
        _capturedPoints[nextIndex].longitude,
      );
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.save, color: Colors.green),
              SizedBox(width: 8),
              Text('Save Land Area'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Land Area Summary:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                    '📐 Total Area:', '${totalArea.toStringAsFixed(2)} sq.m'),
                const SizedBox(height: 8),
                _buildDetailRow(
                    '📏 Perimeter:', '${perimeter.toStringAsFixed(2)} m'),
                const SizedBox(height: 8),
                _buildDetailRow('📍 Points:', '$maxPoints corners'),
                const SizedBox(height: 16),

                // Show all points
                const Text(
                  'Corner Points:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                for (int i = 0; i < _savedPoints.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Point ${i + 1}: ${_savedPoints[i]['description']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                            'Lat: ${_savedPoints[i]['latitude'].toStringAsFixed(6)}'),
                        Text(
                            'Lng: ${_savedPoints[i]['longitude'].toStringAsFixed(6)}'),
                        if (i < _savedPoints.length - 1) const Divider(),
                      ],
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
              onPressed: () {
                _saveAllPoints(totalArea, perimeter);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _saveAllPoints(double area, double perimeter) {
    // Here you would typically save to database
    // For now, we'll just clear and show success

    setState(() {
      _capturedPoints.clear();
      _savedPoints.clear();
      _markers.clear();
      _polylines.clear();
      _walkPath.clear();
      _walkDistance = 0.0;
      _walkStartPoint = null;
    });

    _showSuccessNotification(
        '✅ Land area saved successfully!\nArea: ${area.toStringAsFixed(2)} sq.m');
  }

  void _toggleMapType() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal;
    });

    _showSuccessNotification(_currentMapType == MapType.satellite
        ? '🛰️ Satellite View Enabled'
        : '🗺️ Default Map View Enabled');
  }

  void _zoomIn() async {
    if (_mapController != null) {
      final currentZoom = await _mapController!.getZoomLevel();
      _mapController!.animateCamera(
        CameraUpdate.zoomTo(currentZoom + 1),
      );
    }
  }

  void _zoomOut() async {
    if (_mapController != null) {
      final currentZoom = await _mapController!.getZoomLevel();
      _mapController!.animateCamera(
        CameraUpdate.zoomTo(currentZoom - 1),
      );
    }
  }

  void _showErrorNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSavedPointsList() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.list, color: Colors.blue),
              const SizedBox(width: 8),
              Text('Points (${_capturedPoints.length}/$maxPoints)'),
              if (_capturedPoints.length == maxPoints)
                const Text(' 🔲', style: TextStyle(fontSize: 20)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: _savedPoints.isEmpty
                ? const Center(
                    child: Text('No points saved yet'),
                  )
                : ListView.builder(
                    itemCount: _savedPoints.length,
                    itemBuilder: (context, index) {
                      final point = _savedPoints[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            point['description'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  '📍 ${point['latitude'].toStringAsFixed(6)}, ${point['longitude'].toStringAsFixed(6)}'),
                              Text(
                                  '📏 Distance: ${point['distance'].toStringAsFixed(2)}m'),
                              Text(
                                  '🕒 ${_formatTimestamp(point['timestamp'])}'),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'navigate') {
                                _navigateToPoint(point['position']);
                                Navigator.of(context).pop();
                              } else if (value == 'delete') {
                                _deletePoint(index);
                              }
                            },
                            itemBuilder: (BuildContext context) => [
                              const PopupMenuItem<String>(
                                value: 'navigate',
                                child: Row(
                                  children: [
                                    Icon(Icons.navigation, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text('Navigate'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem<String>(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            if (_capturedPoints.length >= maxPoints)
              TextButton(
                onPressed: () {
                  _clearAllPoints();
                  Navigator.of(context).pop();
                },
                child: const Text('Clear All',
                    style: TextStyle(color: Colors.red)),
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

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  void _navigateToPoint(LatLng position) {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(position, 18.0),
      );
    }
    _showSuccessNotification('Navigating to point 🧭');
  }

  void _deletePoint(int index) {
    setState(() {
      _savedPoints.removeAt(index);
      _capturedPoints.removeAt(index);

      // Rebuild all markers with correct numbering
      _markers.clear();
      for (int i = 0; i < _savedPoints.length; i++) {
        final point = _savedPoints[i];
        _markers.add(
          Marker(
            markerId: MarkerId('capture_point_${i + 1}'),
            position: point['position'],
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(
              title: '📍 ${point['description']}',
              snippet:
                  'Lat: ${point['latitude'].toStringAsFixed(6)}, Lng: ${point['longitude'].toStringAsFixed(6)}\nDistance: ${point['distance'].toStringAsFixed(1)}m',
            ),
          ),
        );
      }

      // Update polylines
      _updatePointConnections();
    });

    _showSuccessNotification('Point deleted successfully! 🗑️');
  }

  void _clearAllPoints() {
    setState(() {
      _savedPoints.clear();
      _capturedPoints.clear();
      _markers.clear();
      _polylines.clear();
    });
    _showSuccessNotification('All points cleared! 🧹');
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
                  gestureRecognizers: const <Factory<
                      OneSequenceGestureRecognizer>>{},
                  minMaxZoomPreference: const MinMaxZoomPreference(1.0, 25.0),
                  cameraTargetBounds: CameraTargetBounds.unbounded,
                ),

                // Map Controls - Top Left
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 16,
                  child: Column(
                    children: [
                      // Map Type Toggle Button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: FloatingActionButton(
                          heroTag: "mapType",
                          onPressed: _toggleMapType,
                          backgroundColor: Colors.white,
                          child: Icon(
                            _currentMapType == MapType.satellite
                                ? Icons.map
                                : Icons.satellite_alt,
                            color: _currentMapType == MapType.satellite
                                ? Colors.blue
                                : Colors.green,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Zoom Controls
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Zoom In
                            FloatingActionButton(
                              heroTag: "zoomIn",
                              onPressed: _zoomIn,
                              backgroundColor: Colors.white,
                              mini: true,
                              child: const Icon(
                                Icons.add,
                                color: Colors.blue,
                                size: 24,
                              ),
                            ),
                            Container(
                              height: 1,
                              width: 40,
                              color: Colors.grey.shade300,
                            ),
                            // Zoom Out
                            FloatingActionButton(
                              heroTag: "zoomOut",
                              onPressed: _zoomOut,
                              backgroundColor: Colors.white,
                              mini: true,
                              child: const Icon(
                                Icons.remove,
                                color: Colors.blue,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Walk Distance Display
                if (_walkMode)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.directions_walk,
                              color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            '🚶‍♂️ ${_walkDistance.toStringAsFixed(1)}m',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Point Button during Walk Mode
                if (_walkMode && _isWalking)
                  Positioned(
                    bottom: 100,
                    right: 16,
                    child: FloatingActionButton.extended(
                      heroTag: "addPoint",
                      onPressed: _addPointDuringWalk,
                      backgroundColor: Colors.orange,
                      icon: const Icon(Icons.add_location, color: Colors.white),
                      label: const Text(
                        'Point',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                // Save Button when 4 points completed
                if (_capturedPoints.length == maxPoints)
                  Positioned(
                    bottom: 170,
                    right: 16,
                    child: FloatingActionButton.extended(
                      heroTag: "savePoints",
                      onPressed: _showSaveDialog,
                      backgroundColor: Colors.green,
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text(
                        'SAVE',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                // Walk Mode Toggle Button
                Positioned(
                  bottom: 100,
                  right: 16,
                  child: FloatingActionButton.extended(
                    heroTag: "walkToggle",
                    onPressed: () {
                      setState(() {
                        _walkMode = !_walkMode;
                        if (_walkMode) {
                          _startWalkTracking();
                        } else {
                          _stopWalkTracking();
                        }
                      });
                    },
                    backgroundColor: _walkMode ? Colors.red : Colors.purple,
                    icon: Icon(
                      _walkMode ? Icons.stop : Icons.directions_walk,
                      color: Colors.white,
                    ),
                    label: Text(
                      _walkMode ? 'Stop Walk' : 'Start Walk',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Points Counter & View Points Button
                if (_capturedPoints.isNotEmpty)
                  Positioned(
                    bottom: MediaQuery.of(context).padding.bottom + 16,
                    left: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // View Points Button
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: FloatingActionButton.extended(
                            heroTag: "viewPoints",
                            onPressed: _showSavedPointsList,
                            backgroundColor: Colors.blue,
                            icon: const Icon(Icons.list, color: Colors.white),
                            label: const Text(
                              'View Points',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        // Points Counter
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _capturedPoints.length >= maxPoints
                                ? Colors.green
                                : Colors.blue,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: (_capturedPoints.length >= maxPoints
                                        ? Colors.green
                                        : Colors.blue)
                                    .withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                  _capturedPoints.length >= maxPoints
                                      ? Icons.check_box
                                      : Icons.location_on,
                                  color: Colors.white,
                                  size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${_capturedPoints.length}/$maxPoints Points${_capturedPoints.length == maxPoints ? ' 🔲' : ''}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
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
