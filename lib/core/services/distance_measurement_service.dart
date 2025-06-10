import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/distance_measurement.dart';

class DistanceMeasurementService {
  static const String _storageKey = 'distance_measurements';

  Future<List<DistanceMeasurement>> getAllMeasurements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final measurementsJson = prefs.getStringList(_storageKey) ?? [];

      return measurementsJson
          .map((json) => DistanceMeasurement.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      print('Error loading distance measurements: $e');
      return [];
    }
  }

  Future<void> saveMeasurement(DistanceMeasurement measurement) async {
    try {
      final measurements = await getAllMeasurements();
      measurements.add(measurement);

      final prefs = await SharedPreferences.getInstance();
      final measurementsJson = measurements
          .map((m) => jsonEncode(m.toJson()))
          .toList();

      await prefs.setStringList(_storageKey, measurementsJson);
    } catch (e) {
      print('Error saving distance measurement: $e');
      throw Exception('Failed to save measurement');
    }
  }

  Future<void> deleteMeasurement(String id) async {
    try {
      final measurements = await getAllMeasurements();
      measurements.removeWhere((m) => m.id == id);

      final prefs = await SharedPreferences.getInstance();
      final measurementsJson = measurements
          .map((m) => jsonEncode(m.toJson()))
          .toList();

      await prefs.setStringList(_storageKey, measurementsJson);
    } catch (e) {
      print('Error deleting distance measurement: $e');
      throw Exception('Failed to delete measurement');
    }
  }

  Future<void> clearAllMeasurements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      print('Error clearing distance measurements: $e');
      throw Exception('Failed to clear measurements');
    }
  }

  String formatDistance(double distance) {
    if (distance < 1000) {
      return '${distance.toStringAsFixed(1)} m';
    } else {
      return '${(distance / 1000).toStringAsFixed(2)} km';
    }
  }
}