import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;

class CameraService {
  static final CameraService _instance = CameraService._internal();

  factory CameraService() => _instance;

  CameraService._internal();

  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  final ImagePicker _imagePicker = ImagePicker();

  bool get isInitialized => _cameraController?.value.isInitialized ?? false;

  CameraController? get controller => _cameraController;

  Future<bool> requestCameraPermission() async {
    final permission = await Permission.camera.request();
    return permission.isGranted;
  }

  Future<bool> requestStoragePermission() async {
    final permission = await Permission.storage.request();
    return permission.isGranted;
  }

  Future<void> initializeCamera() async {
    try {
      // Dispose existing controller first
      await _cameraController?.dispose();
      _cameraController = null;

      final hasPermission = await requestCameraPermission();
      if (!hasPermission) {
        throw Exception('Camera permission denied');
      }

      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        throw Exception('No cameras available');
      }

      _cameraController = CameraController(
        _cameras!.first,
        ResolutionPreset.medium,
        // Reduced from high to medium to prevent buffer issues
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      // Set initial flash mode
      await _cameraController!.setFlashMode(FlashMode.off);

      // Add small delay to ensure camera is fully ready
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      // Cleanup on error
      await _cameraController?.dispose();
      _cameraController = null;
      throw Exception('Failed to initialize camera: $e');
    }
  }

  Future<String> captureImage() async {
    try {
      if (_cameraController == null ||
          !_cameraController!.value.isInitialized) {
        throw Exception('Camera not initialized');
      }

      // Add delay before capture to prevent buffer issues
      await Future.delayed(const Duration(milliseconds: 50));

      final XFile image = await _cameraController!.takePicture();

      // Save to app directory
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String imagePath = path.join(
        appDir.path,
        'images',
        'land_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      // Create directory if it doesn't exist
      final Directory imageDir = Directory(path.dirname(imagePath));
      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }

      // Copy image to permanent location
      await File(image.path).copy(imagePath);

      // Clean up temporary file
      try {
        await File(image.path).delete();
      } catch (e) {
        // Ignore cleanup errors
      }

      return imagePath;
    } catch (e) {
      throw Exception('Failed to capture image: $e');
    }
  }

  Future<String?> pickImageFromGallery() async {
    try {
      final hasStoragePermission = await requestStoragePermission();
      if (!hasStoragePermission) {
        throw Exception('Storage permission denied');
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        // Copy to app directory
        final Directory appDir = await getApplicationDocumentsDirectory();
        final String imagePath = path.join(
          appDir.path,
          'images',
          'gallery_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );

        // Create directory if it doesn't exist
        final Directory imageDir = Directory(path.dirname(imagePath));
        if (!await imageDir.exists()) {
          await imageDir.create(recursive: true);
        }

        // Copy image to permanent location
        await File(image.path).copy(imagePath);

        return imagePath;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick image from gallery: $e');
    }
  }

  Future<void> switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) {
      throw Exception('Cannot switch camera - only one camera available');
    }

    try {
      final currentCameraIndex = _cameras!.indexOf(
          _cameraController!.description);
      final nextCameraIndex = (currentCameraIndex + 1) % _cameras!.length;

      // Properly dispose current controller
      await _cameraController?.dispose();
      _cameraController = null;

      _cameraController = CameraController(
        _cameras![nextCameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();
      await _cameraController!.setFlashMode(FlashMode.off);
    } catch (e) {
      // Cleanup on error
      await _cameraController?.dispose();
      _cameraController = null;
      throw Exception('Failed to switch camera: $e');
    }
  }

  Future<void> setFlashMode(FlashMode mode) async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      await _cameraController!.setFlashMode(mode);
    }
  }

  Future<void> setZoom(double zoom) async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      final maxZoom = await _cameraController!.getMaxZoomLevel();
      final minZoom = await _cameraController!.getMinZoomLevel();
      final clampedZoom = zoom.clamp(minZoom, maxZoom);
      await _cameraController!.setZoomLevel(clampedZoom);
    }
  }

  Future<double> getMaxZoom() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      return await _cameraController!.getMaxZoomLevel();
    }
    return 1.0;
  }

  Future<double> getMinZoom() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      return await _cameraController!.getMinZoomLevel();
    }
    return 1.0;
  }

  Future<void> startVideoRecording() async {
    if (_cameraController != null &&
        _cameraController!.value.isInitialized &&
        !_cameraController!.value.isRecordingVideo) {
      await _cameraController!.startVideoRecording();
    }
  }

  Future<String?> stopVideoRecording() async {
    if (_cameraController != null &&
        _cameraController!.value.isInitialized &&
        _cameraController!.value.isRecordingVideo) {
      final XFile video = await _cameraController!.stopVideoRecording();

      // Save to app directory
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String videoPath = path.join(
        appDir.path,
        'videos',
        'land_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );

      // Create directory if it doesn't exist
      final Directory videoDir = Directory(path.dirname(videoPath));
      if (!await videoDir.exists()) {
        await videoDir.create(recursive: true);
      }

      // Copy video to permanent location
      await File(video.path).copy(videoPath);

      return videoPath;
    }
    return null;
  }

  Future<Uint8List?> getImageBytes(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      if (await imageFile.exists()) {
        return await imageFile.readAsBytes();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteImage(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      if (await imageFile.exists()) {
        await imageFile.delete();
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> dispose() async {
    await _cameraController?.dispose();
    _cameraController = null;
  }
}
