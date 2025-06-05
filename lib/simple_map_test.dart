import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

class SimpleMapTest extends StatefulWidget {
  const SimpleMapTest({super.key});

  @override
  State<SimpleMapTest> createState() => _SimpleMapTestState();
}

class _SimpleMapTestState extends State<SimpleMapTest> {
  final Completer<GoogleMapController> _controller = Completer();
  bool _mapLoaded = false;
  String _status = 'Initializing Google Maps...';
  String _errorMessage = '';

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(13.0827, 80.2707), // Chennai, Tamil Nadu
    zoom: 12.0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Maps API Test'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Status Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _mapLoaded ? Colors.green.shade100 : (_errorMessage
                .isNotEmpty ? Colors.red.shade100 : Colors.orange.shade100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _mapLoaded ? Icons.check_circle : (_errorMessage
                          .isNotEmpty ? Icons.error : Icons.access_time),
                      color: _mapLoaded ? Colors.green : (_errorMessage
                          .isNotEmpty ? Colors.red : Colors.orange),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _status,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _mapLoaded
                              ? Colors.green.shade800
                              : (_errorMessage.isNotEmpty
                              ? Colors.red.shade800
                              : Colors.orange.shade800),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'API Key: AIzaSyDzhBYBKT8s-bbrrYGBSCAFwudEMdVqyNU',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontFamily: 'monospace',
                  ),
                ),
                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Error: $_errorMessage',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade800,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Map Area
          Expanded(
            child: GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: _initialPosition,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
                setState(() {
                  _mapLoaded = true;
                  _status =
                  '✅ Google Maps loaded successfully! API Key is working.';
                  _errorMessage = '';
                });
                debugPrint('✅ Google Maps loaded successfully');
              },
              markers: {
                const Marker(
                  markerId: MarkerId('test_marker'),
                  position: LatLng(13.0827, 80.2707),
                  infoWindow: InfoWindow(
                    title: 'Chennai, Tamil Nadu',
                    snippet: 'Google Maps Test Location',
                  ),
                ),
              },
              onTap: (LatLng position) {
                debugPrint('Map tapped at: ${position.latitude}, ${position
                    .longitude}');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Tapped at: ${position.latitude.toStringAsFixed(
                            4)}, ${position.longitude.toStringAsFixed(4)}'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),

          // Action Buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final controller = await _controller.future;
                      controller.animateCamera(
                        CameraUpdate.newCameraPosition(
                          const CameraPosition(
                            target: LatLng(13.0827, 80.2707),
                            zoom: 15.0,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.my_location),
                    label: const Text('Go to Chennai'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final controller = await _controller.future;
                      controller.animateCamera(
                        CameraUpdate.newCameraPosition(
                          const CameraPosition(
                            target: LatLng(28.6139, 77.2090), // Delhi
                            zoom: 12.0,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.location_city),
                    label: const Text('Go to Delhi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
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