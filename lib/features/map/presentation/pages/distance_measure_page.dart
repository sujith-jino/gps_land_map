import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class DistanceMeasurePage extends StatefulWidget {
  const DistanceMeasurePage({super.key});

  @override
  State<DistanceMeasurePage> createState() => _DistanceMeasurePageState();
}

class _DistanceMeasurePageState extends State<DistanceMeasurePage> {
  GoogleMapController? _mapController;
  final List<LatLng> _points = [];
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  LatLng? _currentLocation;
  bool _isLoading = false;
  bool _isMeasuring = false;
  double _totalDistance = 0.0;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Location permissions are denied');
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_currentLocation!, 18.0),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to get location: $e');
    }
  }

  void _onMapTap(LatLng position) {
    if (!_isMeasuring) return;

    setState(() {
      _points.add(position);
      _updateMapElements();
      _calculateDistance();
    });
  }

  void _updateMapElements() {
    _markers.clear();
    _polylines.clear();

    // Add markers for each point
    for (int i = 0; i < _points.length; i++) {
      _markers.add(
        Marker(
          markerId: MarkerId('point_$i'),
          position: _points[i],
          icon: BitmapDescriptor.defaultMarkerWithHue(
            i == 0 ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
          ),
          infoWindow: InfoWindow(
            title: i == 0 ? 'Start Point' : 'Point ${i + 1}',
            snippet: '${_points[i].latitude.toStringAsFixed(6)}, ${_points[i]
                .longitude.toStringAsFixed(6)}',
          ),
        ),
      );
    }

    // Add polyline connecting the points
    if (_points.length > 1) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('distance_line'),
          points: _points,
          color: Colors.blue,
          width: 3,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      );
    }
  }

  void _calculateDistance() {
    if (_points.length < 2) {
      _totalDistance = 0.0;
      return;
    }

    double distance = 0.0;
    for (int i = 0; i < _points.length - 1; i++) {
      distance += Geolocator.distanceBetween(
        _points[i].latitude,
        _points[i].longitude,
        _points[i + 1].latitude,
        _points[i + 1].longitude,
      );
    }

    _totalDistance = distance;
  }

  void _startMeasuring() {
    setState(() {
      _isMeasuring = !_isMeasuring;
    });

    if (_isMeasuring) {
      _showInfo('Tap on the map to add distance measurement points');
    }
  }

  void _clearMeasurement() {
    setState(() {
      _points.clear();
      _markers.clear();
      _polylines.clear();
      _totalDistance = 0.0;
      _isMeasuring = false;
    });
  }

  String _formatDistance(double distance) {
    if (distance < 1000) {
      return '${distance.toStringAsFixed(1)} m';
    } else {
      return '${(distance / 1000).toStringAsFixed(2)} km';
    }
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
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.timeline, size: 24),
            SizedBox(width: 8),
            Text('Distance Measure'),
          ],
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Getting your location...'),
          ],
        ),
      )
          : Stack(
        children: [
          // Google Map
          GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: CameraPosition(
              target: _currentLocation ?? const LatLng(0, 0),
              zoom: 18.0,
            ),
            onTap: _onMapTap,
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapType: MapType.hybrid,
          ),

          // Distance Info Panel
          if (_points.isNotEmpty)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.timeline, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Distance Measurement',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Distance',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              _formatDistance(_totalDistance),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Points',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '${_points.length}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Control Buttons
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _startMeasuring,
                        icon: Icon(
                            _isMeasuring ? Icons.pause : Icons.add_location),
                        label: Text(_isMeasuring
                            ? 'Stop Measuring'
                            : 'Start Measuring'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isMeasuring ? Colors.orange : Colors
                              .blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _points.isNotEmpty ? _clearMeasurement : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      child: const Icon(Icons.clear),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Measuring Status
          if (_isMeasuring)
            Positioned(
              top: _points.isNotEmpty ? 140 : 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.touch_app, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Tap on map to add points',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}