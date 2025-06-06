import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/models/land_measurement.dart';
import '../../../../core/services/land_measurement_service.dart';
import '../widgets/measurement_info_panel.dart';
import '../widgets/measurement_controls.dart';

class LandMeasurePage extends StatefulWidget {
  const LandMeasurePage({super.key});

  @override
  State<LandMeasurePage> createState() => _LandMeasurePageState();
}

class _LandMeasurePageState extends State<LandMeasurePage> {
  GoogleMapController? _mapController;
  final List<LatLng> _polygonPoints = [];
  final Set<Marker> _markers = {};
  final Set<Polygon> _polygons = {};

  LatLng? _currentLocation;
  bool _isLoading = false;
  bool _isAddingPoints = false;
  double _currentArea = 0.0;
  double _currentPerimeter = 0.0;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);

    try {
      // Check permissions
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

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

      // Move camera to current location
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
    if (!_isAddingPoints) return;

    setState(() {
      _polygonPoints.add(position);
      _updateMapElements();
      _calculateMeasurements();
    });
  }

  void _updateMapElements() {
    // Update markers
    _markers.clear();
    _markers.addAll(
      LandMeasurementService.createPolygonMarkers(
        _polygonPoints,
        onMarkerTap: _onMarkerTap,
      ),
    );

    // Update polygon
    _polygons.clear();
    if (_polygonPoints.length >= 3) {
      _polygons.add(
        LandMeasurementService.createPolygon(_polygonPoints),
      );
    }
  }

  void _calculateMeasurements() {
    if (_polygonPoints.length >= 3) {
      _currentArea = LandMeasurementService.calculateArea(_polygonPoints);
      _currentPerimeter =
          LandMeasurementService.calculatePerimeter(_polygonPoints);
    } else {
      _currentArea = 0.0;
      _currentPerimeter = 0.0;
    }
  }

  void _onMarkerTap(int index) {
    // Show options to remove point
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text('Point ${index + 1}'),
            content: Text('What would you like to do with this point?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _removePoint(index);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Remove'),
              ),
            ],
          ),
    );
  }

  void _removePoint(int index) {
    setState(() {
      _polygonPoints.removeAt(index);
      _updateMapElements();
      _calculateMeasurements();
    });
  }

  void _addPoint() {
    setState(() {
      _isAddingPoints = !_isAddingPoints;
    });

    if (_isAddingPoints) {
      _showInfo('Tap on the map to add measurement points');
    }
  }

  void _measureArea() {
    if (_polygonPoints.length < 3) {
      _showError('Please add at least 3 points to measure area');
      return;
    }

    _calculateMeasurements();
    _showMeasurementResult();
  }

  void _showMeasurementResult() {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.calculate, color: Colors.green),
                SizedBox(width: 8),
                Text('Measurement Result'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Area: ${LandMeasurementService.formatArea(
                      _currentArea)}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Perimeter: ${LandMeasurementService.formatPerimeter(
                      _currentPerimeter)}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  'Points: ${_polygonPoints.length}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _saveMeasurement();
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _saveMeasurement() {
    // For now, just show success message
    // In a real app, you'd save to database
    _showInfo('Measurement saved successfully!');
  }

  void _reset() {
    setState(() {
      _polygonPoints.clear();
      _markers.clear();
      _polygons.clear();
      _currentArea = 0.0;
      _currentPerimeter = 0.0;
      _isAddingPoints = false;
    });
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
            Icon(Icons.straighten, size: 24),
            SizedBox(width: 8),
            Text('Land Measurement'),
          ],
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isAddingPoints ? Icons.pause : Icons.gps_fixed),
            onPressed: _isAddingPoints ? null : _getCurrentLocation,
            tooltip: 'Get Current Location',
          ),
        ],
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
            polygons: _polygons,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapType: MapType.hybrid,
            compassEnabled: true,
            rotateGesturesEnabled: true,
            scrollGesturesEnabled: true,
            tiltGesturesEnabled: true,
            zoomGesturesEnabled: true,
          ),

          // Measurement Info Panel
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: MeasurementInfoPanel(
              pointCount: _polygonPoints.length,
              area: _currentArea,
              perimeter: _currentPerimeter,
              isVisible: _polygonPoints.isNotEmpty,
            ),
          ),

          // Control Buttons
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: MeasurementControls(
              isAddingPoints: _isAddingPoints,
              hasPoints: _polygonPoints.isNotEmpty,
              canMeasure: _polygonPoints.length >= 3,
              onAddPoint: _addPoint,
              onMeasureArea: _measureArea,
              onReset: _reset,
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