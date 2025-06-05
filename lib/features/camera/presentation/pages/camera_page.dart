import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
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
  final ImagePicker _imagePicker = ImagePicker();

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

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _cameraService.dispose();
    });
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      setState(() {
        _isInitializing = true;
        _errorMessage = null;
      });

      await _cameraService.initializeCamera();
      _maxZoom = await _cameraService.getMaxZoom();
      _minZoom = await _cameraService.getMinZoom();
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  Future<void> _capturePhoto() async {
    if (_isCapturing || !_cameraService.isInitialized) return;

    try {
      setState(() => _isCapturing = true);
      final imagePath = await _cameraService.captureImage();

      Position? position;
      try {
        position = await _locationService.getCurrentPosition();
      } catch (e) {
        debugPrint('Location error: $e');
      }

      final landPoint = LandPoint(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        latitude: position?.latitude ?? 0.0,
        longitude: position?.longitude ?? 0.0,
        imagePath: imagePath,
        timestamp: DateTime.now(),
        isSynced: false,
      );

      await _databaseService.saveLandPoint(landPoint);

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
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      Position? position;
      try {
        position = await _locationService.getCurrentPosition();
      } catch (e) {
        debugPrint('Location error: $e');
      }

      final landPoint = LandPoint(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        latitude: position?.latitude ?? 0.0,
        longitude: position?.longitude ?? 0.0,
        imagePath: image.path,
        timestamp: DateTime.now(),
        isSynced: false,
      );

      await _databaseService.saveLandPoint(landPoint);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image imported successfully!'),
            backgroundColor: Colors.green,
          ),
        );
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
        case FlashMode.torch:
          newMode = FlashMode.off;
          break;
      }
      await _cameraService.setFlashMode(newMode);
      setState(() => _flashMode = newMode);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to toggle flash: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _switchCamera() async {
    try {
      await _cameraService.switchCamera();
      _maxZoom = await _cameraService.getMaxZoom();
      _minZoom = await _cameraService.getMinZoom();
      setState(() => _currentZoom = 1.0);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to switch camera: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Initializing camera...', style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Camera Error',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _initializeCamera,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;

    return Stack(
      children: [
        // Camera preview
        Positioned.fill(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: size.width,
              height: size.width * deviceRatio,
              child: CameraPreview(_cameraService.controller!),
            ),
          ),
        ),

        // Top controls
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Flash mode
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

              // Close button
              Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),

        // Bottom controls
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 16,
          left: 0,
          right: 0,
          child: Column(
            children: [
              // Zoom slider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Row(
                  children: [
                    const Icon(Icons.zoom_out, color: Colors.white),
                    Expanded(
                      child: Slider(
                        value: _currentZoom,
                        min: _minZoom,
                        max: _maxZoom,
                        divisions: (_maxZoom - _minZoom > 1)
                            ? (_maxZoom - _minZoom).round() * 10
                            : null,
                        onChanged: (value) {
                          setState(() => _currentZoom = value);
                        },
                        onChangeEnd: (value) {
                          _cameraService.setZoom(value);
                        },
                        activeColor: Colors.white,
                        inactiveColor: Colors.white54,
                      ),
                    ),
                    const Icon(Icons.zoom_in, color: Colors.white),
                  ],
                ),
              ),

              // Capture button row
              Row(
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
                      width: 70,
                      height: 70,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: _isCapturing ? Colors.grey : Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: _isCapturing
                            ? const Center(
                          child: SizedBox(
                            width: 30,
                            height: 30,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 3,
                            ),
                          ),
                        )
                            : null,
                      ),
                    ),
                  ),

                  // Switch camera button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: IconButton(
                      onPressed: _switchCamera,
                      icon: const Icon(
                        Icons.switch_camera,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _isInitializing
            ? _buildLoadingView()
            : _errorMessage != null
            ? _buildErrorView()
            : _buildCameraView(),
      ),
    );
  }
}
