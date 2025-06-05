import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();

  factory LocationService() => _instance;

  LocationService._internal();

  StreamSubscription<Position>? _positionStreamSubscription;
  final StreamController<Position> _positionController =
      StreamController<Position>.broadcast();

  Stream<Position> get positionStream => _positionController.stream;

  Future<bool> requestLocationPermission() async {
    try {
      // Check current permission status first
      LocationPermission permission = await checkLocationPermission();

      if (permission == LocationPermission.denied) {
        // Request permission using geolocator directly (no system settings popup)
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      // Only check location services after permission is granted
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final serviceEnabled = await isLocationServiceEnabled();
        if (!serviceEnabled) {
          // Don't open settings automatically, just return false
          return false;
        }
      }

      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  Future<LocationPermission> checkLocationPermission() async {
    return await Geolocator.checkPermission();
  }

  Future<Position?> getCurrentPosition() async {
    try {
      final permission = await checkLocationPermission();

      if (permission == LocationPermission.denied) {
        final requestedPermission = await Geolocator.requestPermission();
        if (requestedPermission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied');
      }

      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      throw Exception('Failed to get current location: $e');
    }
  }

  Future<void> startLocationTracking({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
  }) async {
    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        throw Exception('Location permission required for tracking');
      }

      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );

      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          _positionController.add(position);
        },
        onError: (error) {
          _positionController.addError(error);
        },
      );
    } catch (e) {
      throw Exception('Failed to start location tracking: $e');
    }
  }

  void stopLocationTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  Future<double> getDistanceBetween(double startLatitude,
      double startLongitude,
      double endLatitude,
      double endLongitude,) async {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  Future<String?> getAddressFromCoordinates(double latitude,
      double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        return '${placemark.street}, ${placemark.locality}, ${placemark
            .administrativeArea}, ${placemark.country}';
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<Location>?> getCoordinatesFromAddress(String address) async {
    try {
      return await locationFromAddress(address);
    } catch (e) {
      return null;
    }
  }

  String formatCoordinates(double latitude, double longitude) {
    final latDirection = latitude >= 0 ? 'N' : 'S';
    final lonDirection = longitude >= 0 ? 'E' : 'W';

    return '${latitude.abs().toStringAsFixed(6)}°$latDirection, ${longitude
        .abs().toStringAsFixed(6)}°$lonDirection';
  }

  String formatAccuracy(double accuracy) {
    if (accuracy < 5) {
      return 'Excellent (±${accuracy.toStringAsFixed(1)}m)';
    } else if (accuracy < 10) {
      return 'Good (±${accuracy.toStringAsFixed(1)}m)';
    } else if (accuracy < 25) {
      return 'Fair (±${accuracy.toStringAsFixed(1)}m)';
    } else {
      return 'Poor (±${accuracy.toStringAsFixed(1)}m)';
    }
  }

  void dispose() {
    stopLocationTracking();
    _positionController.close();
  }
}
