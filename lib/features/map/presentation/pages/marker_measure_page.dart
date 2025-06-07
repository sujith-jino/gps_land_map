import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MarkerMeasurePage extends StatefulWidget {
  const MarkerMeasurePage({super.key});

  @override
  State<MarkerMeasurePage> createState() => _MarkerMeasurePageState();
}

class _MarkerMeasurePageState extends State<MarkerMeasurePage> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final List<MarkerData> _markerList = [];

  LatLng? _currentLocation;
  bool _isLoading = false;
  bool _isAddingMarkers = false;
  int _markerCounter = 0;

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
    if (!_isAddingMarkers) return;

    _addMarker(position);
  }

  void _addMarker(LatLng position) {
    _markerCounter++;
    final markerData = MarkerData(
      id: 'marker_$_markerCounter',
      position: position,
      title: 'Point $_markerCounter',
      description: 'Added at ${DateTime.now().toLocal().toString().split(' ')[1]
          .substring(0, 5)}',
    );

    setState(() {
      _markerList.add(markerData);
      _updateMarkers();
    });
  }

  void _updateMarkers() {
    _markers.clear();

    // Add current location marker if available
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

    // Add custom markers
    for (int i = 0; i < _markerList.length; i++) {
      final markerData = _markerList[i];
      _markers.add(
        Marker(
          markerId: MarkerId(markerData.id),
          position: markerData.position,
          icon: BitmapDescriptor.defaultMarkerWithHue(_getMarkerColor(i)),
          infoWindow: InfoWindow(
            title: markerData.title,
            snippet: markerData.description,
          ),
          onTap: () => _showMarkerOptions(i),
        ),
      );
    }
  }

  double _getMarkerColor(int index) {
    final colors = [
      BitmapDescriptor.hueRed,
      BitmapDescriptor.hueOrange,
      BitmapDescriptor.hueYellow,
      BitmapDescriptor.hueGreen,
      BitmapDescriptor.hueCyan,
      BitmapDescriptor.hueViolet,
      BitmapDescriptor.hueRose,
    ];
    return colors[index % colors.length];
  }

  void _showMarkerOptions(int index) {
    final markerData = _markerList[index];
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text(markerData.title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Location: ${markerData.position.latitude.toStringAsFixed(
                    6)}, ${markerData.position.longitude.toStringAsFixed(6)}'),
                const SizedBox(height: 8),
                Text('Description: ${markerData.description}'),
                if (_currentLocation != null) ...[
                  const SizedBox(height: 8),
                  Text('Distance from you: ${_calculateDistance(
                      markerData.position)}'),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _removeMarker(index);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Remove'),
              ),
            ],
          ),
    );
  }

  void _removeMarker(int index) {
    setState(() {
      _markerList.removeAt(index);
      _updateMarkers();
    });
  }

  String _calculateDistance(LatLng markerPosition) {
    if (_currentLocation == null) return 'Unknown';

    final distance = Geolocator.distanceBetween(
      _currentLocation!.latitude,
      _currentLocation!.longitude,
      markerPosition.latitude,
      markerPosition.longitude,
    );

    if (distance < 1000) {
      return '${distance.toStringAsFixed(1)} m';
    } else {
      return '${(distance / 1000).toStringAsFixed(2)} km';
    }
  }

  void _startAddingMarkers() {
    setState(() {
      _isAddingMarkers = !_isAddingMarkers;
    });

    if (_isAddingMarkers) {
      _showInfo('Tap on the map to add markers');
    }
  }

  void _clearAllMarkers() {
    setState(() {
      _markerList.clear();
      _markerCounter = 0;
      _updateMarkers();
      _isAddingMarkers = false;
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
        backgroundColor: Colors.purple,
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
            Icon(Icons.place, size: 24),
            SizedBox(width: 8),
            Text('Marker Measure'),
          ],
        ),
        backgroundColor: Colors.purple,
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
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapType: MapType.hybrid,
          ),

          // Markers Info Panel
          if (_markerList.isNotEmpty)
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
                child: Row(
                  children: [
                    const Icon(Icons.place, color: Colors.purple),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Markers Added',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_markerList.length} markers on map',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
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
                        onPressed: _startAddingMarkers,
                        icon: Icon(_isAddingMarkers ? Icons.pause : Icons
                            .add_location),
                        label: Text(
                            _isAddingMarkers ? 'Stop Adding' : 'Add Marker'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isAddingMarkers
                              ? Colors.orange
                              : Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _markerList.isNotEmpty
                          ? _clearAllMarkers
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      child: const Icon(Icons.clear_all),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Adding Status
          if (_isAddingMarkers)
            Positioned(
              top: _markerList.isNotEmpty ? 100 : 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.touch_app, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Tap on map to add markers',
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