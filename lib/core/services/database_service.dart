import 'dart:io';
import 'dart:math' as math;

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/land_point.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  static const String _landPointsBoxName = 'land_points';
  static const String _settingsBoxName = 'settings';
  static const String _cacheBoxName = 'cache';

  Box<LandPoint>? _landPointsBox;
  Box? _settingsBox;
  Box? _cacheBox;

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    try {
      await Hive.initFlutter();

      // Register adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(LandPointAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(LandAnalysisAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(DetectedFeatureAdapter());
      }

      // Open boxes
      _landPointsBox = await Hive.openBox<LandPoint>(_landPointsBoxName);
      _settingsBox = await Hive.openBox(_settingsBoxName);
      _cacheBox = await Hive.openBox(_cacheBoxName);

      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize database: $e');
    }
  }

  // Land Points CRUD Operations
  Future<void> saveLandPoint(LandPoint landPoint) async {
    try {
      await _ensureInitialized();
      await _landPointsBox!.put(landPoint.id, landPoint);
    } catch (e) {
      throw Exception('Failed to save land point: $e');
    }
  }

  Future<LandPoint?> getLandPoint(String id) async {
    try {
      await _ensureInitialized();
      return _landPointsBox!.get(id);
    } catch (e) {
      throw Exception('Failed to get land point: $e');
    }
  }

  Future<List<LandPoint>> getAllLandPoints() async {
    try {
      await _ensureInitialized();
      return _landPointsBox!.values.toList();
    } catch (e) {
      throw Exception('Failed to get all land points: $e');
    }
  }

  Future<List<LandPoint>> getLandPointsByTimeRange(DateTime start,
      DateTime end) async {
    try {
      await _ensureInitialized();
      return _landPointsBox!.values
          .where((point) =>
      point.timestamp.isAfter(start) && point.timestamp.isBefore(end))
          .toList();
    } catch (e) {
      throw Exception('Failed to get land points by time range: $e');
    }
  }

  Future<List<LandPoint>> getLandPointsByArea(double centerLat,
      double centerLon,
      double radiusKm,) async {
    try {
      await _ensureInitialized();
      return _landPointsBox!.values.where((point) {
        final distance = _calculateDistance(
          centerLat,
          centerLon,
          point.latitude,
          point.longitude,
        );
        return distance <= radiusKm;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get land points by area: $e');
    }
  }

  Future<List<LandPoint>> searchLandPoints(String query) async {
    try {
      await _ensureInitialized();
      final lowerQuery = query.toLowerCase();
      return _landPointsBox!.values.where((point) {
        return point.notes?.toLowerCase().contains(lowerQuery) == true ||
            point.tags.any((tag) => tag.toLowerCase().contains(lowerQuery)) ||
            point.analysis?.dominantLandFeature.toLowerCase().contains(
                lowerQuery) == true ||
            point.analysis?.soilType.toLowerCase().contains(lowerQuery) == true;
      }).toList();
    } catch (e) {
      throw Exception('Failed to search land points: $e');
    }
  }

  Future<void> updateLandPoint(LandPoint landPoint) async {
    try {
      await _ensureInitialized();
      await _landPointsBox!.put(landPoint.id, landPoint);
    } catch (e) {
      throw Exception('Failed to update land point: $e');
    }
  }

  Future<void> deleteLandPoint(String id) async {
    try {
      await _ensureInitialized();
      await _landPointsBox!.delete(id);
    } catch (e) {
      throw Exception('Failed to delete land point: $e');
    }
  }

  Future<void> deleteMultipleLandPoints(List<String> ids) async {
    try {
      await _ensureInitialized();
      await _landPointsBox!.deleteAll(ids);
    } catch (e) {
      throw Exception('Failed to delete multiple land points: $e');
    }
  }

  // Sync Management
  Future<List<LandPoint>> getUnsyncedLandPoints() async {
    try {
      await _ensureInitialized();
      return _landPointsBox!.values.where((point) => !point.isSynced).toList();
    } catch (e) {
      throw Exception('Failed to get unsynced land points: $e');
    }
  }

  Future<void> markAsSynced(String id) async {
    try {
      await _ensureInitialized();
      final landPoint = _landPointsBox!.get(id);
      if (landPoint != null) {
        final updatedPoint = landPoint.copyWith(isSynced: true);
        await _landPointsBox!.put(id, updatedPoint);
      }
    } catch (e) {
      throw Exception('Failed to mark as synced: $e');
    }
  }

  Future<void> markMultipleAsSynced(List<String> ids) async {
    try {
      await _ensureInitialized();
      for (final id in ids) {
        await markAsSynced(id);
      }
    } catch (e) {
      throw Exception('Failed to mark multiple as synced: $e');
    }
  }

  // Settings Management
  Future<void> saveSetting(String key, dynamic value) async {
    try {
      await _ensureInitialized();
      await _settingsBox!.put(key, value);
    } catch (e) {
      throw Exception('Failed to save setting: $e');
    }
  }

  Future<T?> getSetting<T>(String key, [T? defaultValue]) async {
    try {
      await _ensureInitialized();
      return _settingsBox!.get(key, defaultValue: defaultValue) as T?;
    } catch (e) {
      return defaultValue;
    }
  }

  Future<void> deleteSetting(String key) async {
    try {
      await _ensureInitialized();
      await _settingsBox!.delete(key);
    } catch (e) {
      throw Exception('Failed to delete setting: $e');
    }
  }

  // Cache Management
  Future<void> cacheData(String key, dynamic data) async {
    try {
      await _ensureInitialized();
      await _cacheBox!.put(key, {
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to cache data: $e');
    }
  }

  Future<T?> getCachedData<T>(String key, {Duration? maxAge}) async {
    try {
      await _ensureInitialized();
      final cached = _cacheBox!.get(key);
      if (cached != null) {
        final timestamp = DateTime.parse(cached['timestamp']);
        if (maxAge == null || DateTime.now().difference(timestamp) <= maxAge) {
          return cached['data'] as T?;
        } else {
          // Remove expired cache
          await _cacheBox!.delete(key);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> clearCache() async {
    try {
      await _ensureInitialized();
      await _cacheBox!.clear();
    } catch (e) {
      throw Exception('Failed to clear cache: $e');
    }
  }

  // Statistics
  Future<Map<String, dynamic>> getDatabaseStats() async {
    try {
      await _ensureInitialized();
      final allPoints = await getAllLandPoints();
      final unsyncedPoints = await getUnsyncedLandPoints();

      final landFeatureCounts = <String, int>{};
      final soilTypeCounts = <String, int>{};

      for (final point in allPoints) {
        if (point.analysis != null) {
          final feature = point.analysis!.dominantLandFeature;
          landFeatureCounts[feature] = (landFeatureCounts[feature] ?? 0) + 1;

          final soilType = point.analysis!.soilType;
          soilTypeCounts[soilType] = (soilTypeCounts[soilType] ?? 0) + 1;
        }
      }

      return {
        'totalPoints': allPoints.length,
        'unsyncedPoints': unsyncedPoints.length,
        'syncedPoints': allPoints.length - unsyncedPoints.length,
        'landFeatureCounts': landFeatureCounts,
        'soilTypeCounts': soilTypeCounts,
        'oldestPoint': allPoints.isEmpty ? null : allPoints
            .map((p) => p.timestamp)
            .reduce((a, b) => a.isBefore(b) ? a : b),
        'newestPoint': allPoints.isEmpty ? null : allPoints
            .map((p) => p.timestamp)
            .reduce((a, b) => a.isAfter(b) ? a : b),
      };
    } catch (e) {
      throw Exception('Failed to get database stats: $e');
    }
  }

  // Utility Methods
  double _calculateDistance(double lat1, double lon1, double lat2,
      double lon2) {
    const double earthRadius = 6371; // Earth radius in kilometers
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final double c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  // Database Maintenance
  Future<void> compactDatabase() async {
    try {
      await _ensureInitialized();
      await _landPointsBox!.compact();
      await _settingsBox!.compact();
      await _cacheBox!.compact();
    } catch (e) {
      throw Exception('Failed to compact database: $e');
    }
  }

  Future<Map<String, dynamic>> getDatabaseSize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final hiveDir = Directory('${appDir.path}/hive');

      int totalSize = 0;
      if (await hiveDir.exists()) {
        await for (final entity in hiveDir.list(recursive: true)) {
          if (entity is File) {
            totalSize += await entity.length();
          }
        }
      }

      return {
        'totalSizeBytes': totalSize,
        'totalSizeMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
        'landPointsCount': _landPointsBox?.length ?? 0,
        'settingsCount': _settingsBox?.length ?? 0,
        'cacheCount': _cacheBox?.length ?? 0,
      };
    } catch (e) {
      return {
        'totalSizeBytes': 0,
        'totalSizeMB': '0.00',
        'landPointsCount': 0,
        'settingsCount': 0,
        'cacheCount': 0,
      };
    }
  }

  Future<void> close() async {
    try {
      await _landPointsBox?.close();
      await _settingsBox?.close();
      await _cacheBox?.close();
      _isInitialized = false;
    } catch (e) {
      throw Exception('Failed to close database: $e');
    }
  }

  void dispose() {
    close();
  }
}
