import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/camera_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/models/land_point.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final CameraService _cameraService = CameraService();
  final LocationService _locationService = LocationService();
  final DatabaseService _databaseService = DatabaseService();

  bool _isInitializing = true;
  bool _isCapturing = false;
  String? _errorMessage;
  FlashMode _flashMode = FlashMode.off;
  double _currentZoom = 1.0;
  double _maxZoom = 1.0;
  double _minZoom = 1.0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      setState(() {
        _isInitializing = true;
        _errorMessage = null;
      });

      await _cameraService.initializeCamera();

      // Get zoom levels
      _maxZoom = await _cameraService.getMaxZoom();
      _minZoom = await _cameraService.getMinZoom();

      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _capturePhoto() async {
    if (_isCapturing) return;

    try {
      setState(() => _isCapturing = true);

      // Capture image
      final imagePath = await _cameraService.captureImage();

      // Get current location
      Position? position;
      try {
        position = await _locationService.getCurrentPosition();
      } catch (e) {
        // Handle location error but still save the photo
        print('Location error: $e');
      }

      // Create land point
      final landPoint = LandPoint(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        latitude: position?.latitude ?? 0.0,
        longitude: position?.longitude ?? 0.0,
        imagePath: imagePath,
        timestamp: DateTime.now(),
        isSynced: false,
      );

      // Save to database
      await _databaseService.saveLandPoint(landPoint);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo captured and saved successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error capturing photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isCapturing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final imagePath = await _cameraService.pickImageFromGallery();

      if (imagePath != null) {
        // Get current location
        Position? position;
        try {
          position = await _locationService.getCurrentPosition();
        } catch (e) {
          print('Location error: $e');
        }

        // Create land point
        final landPoint = LandPoint(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          latitude: position?.latitude ?? 0.0,
          longitude: position?.longitude ?? 0.0,
          imagePath: imagePath,
          timestamp: DateTime.now(),
          isSynced: false,
        );

        // Save to database
        await _databaseService.saveLandPoint(landPoint);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image imported successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleFlash() async {
    try {
      FlashMode newMode;
      switch (_flashMode) {
        case FlashMode.off:
          newMode = FlashMode.auto;
          break;
        case FlashMode.auto:
          newMode = FlashMode.always;
          break;
        case FlashMode.always:
          newMode = FlashMode.off;
          break;
        case FlashMode.torch:
          newMode = FlashMode.off;
          break;
      }

      await _cameraService.setFlashMode(newMode);
      setState(() => _flashMode = newMode);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _switchCamera() async {
    try {
      await _cameraService.switchCamera();
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot switch camera: $e')),
      );
    }
  }

  Widget _buildCameraPreview() {
    if (_isInitializing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing camera...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Camera Error',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeCamera,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_cameraService.controller?.value.isInitialized == true) {
      return CameraPreview(_cameraService.controller!);
    }

    return const Center(child: Text('Camera not available'));
  }

  Widget _buildZoomSlider() {
    return Positioned(
      right: 16,
      top: 100,
      bottom: 200,
      child: RotatedBox(
        quarterTurns: 3,
        child: Slider(
          value: _currentZoom,
          min: _minZoom,
          max: _maxZoom,
          onChanged: (value) async {
            setState(() => _currentZoom = value);
            await _cameraService.setZoom(value);
          },
        ),
      ),
    );
  }

  Widget _buildTopControls() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Flash button
          Container(
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              onPressed: _toggleFlash,
              icon: Icon(
                _flashMode == FlashMode.off
                    ? Icons.flash_off
                    : _flashMode == FlashMode.auto
                        ? Icons.flash_auto
                        : Icons.flash_on,
                color: Colors.white,
              ),
            ),
          ),
          // Switch camera button
          Container(
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              onPressed: _switchCamera,
              icon: const Icon(
                Icons.flip_camera_ios,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 16,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Gallery button
          Container(
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(25),
            ),
            child: IconButton(
              onPressed: _pickFromGallery,
              icon: const Icon(
                Icons.photo_library,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
          // Capture button
          GestureDetector(
            onTap: _capturePhoto,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _isCapturing ? Colors.grey : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey, width: 4),
              ),
              child: _isCapturing
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(
                      Icons.camera_alt,
                      size: 40,
                      color: Colors.black,
                    ),
            ),
          ),
          // Settings button
          Container(
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(25),
            ),
            child: IconButton(
              onPressed: () {
                // Navigate to camera settings if needed
              },
              icon: const Icon(
                Icons.settings,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(l10n.camera),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Camera preview
          Positioned.fill(
            child: _buildCameraPreview(),
          ),
          // Zoom slider
          if (_cameraService.isInitialized) _buildZoomSlider(),
          // Top controls
          if (_cameraService.isInitialized) _buildTopControls(),
          // Bottom controls
          if (_cameraService.isInitialized) _buildBottomControls(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }
}
