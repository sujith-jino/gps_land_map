import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
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

class _MapPageState extends State<MapPage> {
  final LocationService _locationService = LocationService();
  final DatabaseService _databaseService = DatabaseService();
  final Completer<GoogleMapController> _mapController = Completer();
  final Map<String, BitmapDescriptor> _markerIcons = {};
  final Set<Marker> _markers = {};
  final Set<Polygon> _polygons = {};
  final Set<Polyline> _polylines = {};

  Position? _currentPosition;
  List<LandPoint> _landPoints = [];
  bool _isLoading = true;
  bool _showSatelliteView = false;
  bool _showTraffic = false;
  bool _showMarkers = true;
  bool _showPolygon = true;

  static const double _mapPadding = 100.0;
  CameraPosition? _initialCameraPosition;

  @override
  void initState() {
    super.initState();
    _loadMarkerIcons();
    _initializeMap();
  }

  Future<void> _loadMarkerIcons() async {
    // Use default markers with different colors since custom icons are not available
    _markerIcons['forest'] =
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    _markerIcons['water body'] =
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    _markerIcons['agricultural land'] =
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    _markerIcons['urban area'] =
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
    _markerIcons['default'] = BitmapDescriptor.defaultMarker;
  }

  Future<void> _initializeMap() async {
    try {
      setState(() => _isLoading = true);

      try {
        _currentPosition = await _locationService.getCurrentPosition();
        if (_currentPosition != null) {
          _initialCameraPosition = CameraPosition(
            target: LatLng(
                _currentPosition!.latitude, _currentPosition!.longitude),
            zoom: 15.0,
          );
        }
      } catch (e) {
        debugPrint('Location error: $e');
        _initialCameraPosition = const CameraPosition(
          target: LatLng(20.5937, 78.9629), // Center of India as fallback
          zoom: 5.0,
        );
      }

      await _loadLandPoints();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing map: $e')),
        );
      }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading land points: $e')),
        );
      }
    }
  }

  void _updateMarkers() {
    if (_landPoints.isEmpty) return;

    final newMarkers = <Marker>{};
    for (var point in _landPoints) {
      final markerId = MarkerId(point.id);
      final icon = _markerIcons[point.analysis?.dominantLandFeature
          ?.toLowerCase() ?? ''] ?? _markerIcons['default']!;

      newMarkers.add(
        Marker(
          markerId: markerId,
          position: LatLng(point.latitude, point.longitude),
          infoWindow: InfoWindow(
            title: 'Land Point',
            snippet: 'Tap for details',
            onTap: () => _showPointDetails(point),
          ),
          icon: icon,
          onTap: () => _onMarkerTapped(point),
        ),
      );
    }

    setState(() {
      _markers.clear();
      _markers.addAll(newMarkers);
    });
  }

  void _updatePolygon() {
    if (_landPoints.length < 3) return;

    final points = _landPoints.map((point) =>
        LatLng(point.latitude, point.longitude)).toList();

    if (points.isNotEmpty) {
      points.add(points.first);
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

      _polylines.clear();
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('boundary'),
          points: points,
          color: AppTheme.primaryColor,
          width: 3,
        ),
      );
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController.complete(controller);
    _updateCameraView();
  }

  Future<void> _updateCameraView() async {
    if (_landPoints.isEmpty) return;

    final GoogleMapController controller = await _mapController.future;
    double minLat = _landPoints.first.latitude;
    double maxLat = _landPoints.first.latitude;
    double minLng = _landPoints.first.longitude;
    double maxLng = _landPoints.first.longitude;

    for (var point in _landPoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final latDelta = (maxLat - minLat) * 1.5;
    final lngDelta = (maxLng - minLng) * 1.5;

    final bounds = LatLngBounds(
      southwest: LatLng(minLat - latDelta * 0.1, minLng - lngDelta * 0.1),
      northeast: LatLng(maxLat + latDelta * 0.1, maxLng + lngDelta * 0.1),
    );

    final cameraUpdate = CameraUpdate.newLatLngBounds(bounds, _mapPadding);
    controller.animateCamera(cameraUpdate);
  }

  void _onMarkerTapped(LandPoint point) {
    _showPointDetails(point);
  }

  void _onMapTapped(LatLng position) {
    // Handle map tap if needed
  }

  void _onCameraMove(CameraPosition position) {
    // Handle camera movement if needed
  }

  void _goToCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentPosition();
      if (position == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not get current location')),
        );
        return;
      }

      setState(() => _currentPosition = position);

      final GoogleMapController controller = await _mapController.future;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 16.0,
          ),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.my_location, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Location updated',
                  style: TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'CAPTURE',
            textColor: Colors.white,
            onPressed: () => AppRouter.navigateToCamera(context),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting location: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showPointDetails(LandPoint point) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) =>
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 20),
                Text(
                  point.analysis?.dominantLandFeature ?? 'Land Point',
                  style: Theme
                      .of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Coordinates: ${point.latitude.toStringAsFixed(6)}, ${point
                    .longitude.toStringAsFixed(6)}'),
                if (point.analysis != null) ...[
                  const SizedBox(height: 8),
                  Text('Land Feature: ${point.analysis!.dominantLandFeature}'),
                  Text('Vegetation: ${point.analysis!.vegetationPercentage
                      .toStringAsFixed(1)}%'),
                  Text('Soil Type: ${point.analysis!.soilType}'),
                ],
                if (point.notes != null) ...[
                  const SizedBox(height: 8),
                  Text('Notes: ${point.notes}'),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.mapView),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeMap,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: Icon(_showSatelliteView ? Icons.map : Icons.satellite),
            onPressed: () =>
                setState(() => _showSatelliteView = !_showSatelliteView),
            tooltip: 'Toggle Map Type',
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _goToCurrentLocation,
            tooltip: 'My Location',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
        initialCameraPosition: _initialCameraPosition!,
        onMapCreated: _onMapCreated,
        onTap: _onMapTapped,
        onCameraMove: _onCameraMove,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapType: _showSatelliteView ? MapType.satellite : MapType.normal,
        trafficEnabled: _showTraffic,
        markers: _showMarkers ? _markers : {},
        polygons: _showPolygon ? _polygons : {},
        polylines: _showPolygon ? _polylines : {},
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AppRouter.navigateToCamera(context),
        backgroundColor: Theme
            .of(context)
            .primaryColor,
        child: const Icon(Icons.add_a_photo, color: Colors.white),
      ),
    );
  }
}