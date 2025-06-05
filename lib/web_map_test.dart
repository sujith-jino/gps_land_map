import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

class SimpleWebMapTest extends StatefulWidget {
  const SimpleWebMapTest({super.key});

  @override
  State<SimpleWebMapTest> createState() => _SimpleWebMapTestState();
}

class _SimpleWebMapTestState extends State<SimpleWebMapTest> {
  final Completer<GoogleMapController> _controller = Completer();
  bool _mapLoaded = false;
  String _status = 'Loading Google Maps...';
  String _errorMessage = '';

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(13.0827, 80.2707), // Chennai, Tamil Nadu
    zoom: 12.0,
  );

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  void _initializeMap() {
    setState(() {
      _status = 'Initializing Google Maps JavaScript API...';
      _errorMessage = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Web Google Maps Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Status Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _mapLoaded
                ? Colors.green.shade100
                : (_errorMessage.isNotEmpty ? Colors.red.shade100 : Colors.blue
                .shade100),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      _mapLoaded
                          ? Icons.check_circle
                          : (_errorMessage.isNotEmpty ? Icons.error : Icons
                          .access_time),
                      color: _mapLoaded
                          ? Colors.green
                          : (_errorMessage.isNotEmpty ? Colors.red : Colors
                          .blue),
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
                              : Colors.blue.shade800),
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
                const SizedBox(height: 4),
                const Text(
                  'Platform: Web (JavaScript API)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Error Details:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _errorMessage,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Web Platform Requirements:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text('✅ Google Maps JavaScript API enabled'),
                Text('✅ API key added to web/index.html'),
                Text('✅ Maps JavaScript API library loaded'),
                SizedBox(height: 8),
                Text(
                  'If the map doesn\'t load, ensure:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                    '• Maps JavaScript API is enabled in Google Cloud Console'),
                Text('• Web domains are added to API key restrictions'),
                Text('• Billing is enabled for the Google Cloud project'),
              ],
            ),
          ),

          // Map Area
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: _initialPosition,
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                    setState(() {
                      _mapLoaded = true;
                      _status = '✅ Google Maps loaded successfully on Web!';
                      _errorMessage = '';
                    });
                    debugPrint('✅ Google Maps loaded successfully on Web');
                  },
                  markers: {
                    const Marker(
                      markerId: MarkerId('chennai'),
                      position: LatLng(13.0827, 80.2707),
                      infoWindow: InfoWindow(
                        title: 'Chennai, Tamil Nadu',
                        snippet: 'Web Maps Test Location',
                      ),
                    ),
                  },
                  onTap: (LatLng position) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Tapped: ${position.latitude.toStringAsFixed(
                              4)}, ${position.longitude.toStringAsFixed(4)}',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _status = 'Refreshing map...';
                        _mapLoaded = false;
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
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