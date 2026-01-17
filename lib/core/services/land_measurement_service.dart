import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LandMeasurementService {
  static const double _earthRadiusMeters = 6371000;

  /// Calculate the area of a polygon in square meters using Shoelace formula
  static double calculateArea(List<LatLng> points) {
    if (points.length < 3) return 0.0;

    // Convert to Mercator projection for area calculation
    double area = 0.0;
    int n = points.length;

    for (int i = 0; i < n; i++) {
      int j = (i + 1) % n;
      double xi = points[i].longitude * math.pi / 180;
      double yi = points[i].latitude * math.pi / 180;
      double xj = points[j].longitude * math.pi / 180;
      double yj = points[j].latitude * math.pi / 180;

      area += (xj - xi) * (2 + math.sin(yi) + math.sin(yj));
    }

    area = area.abs() * _earthRadiusMeters * _earthRadiusMeters / 2;
    return area;
  }

  /// Calculate the perimeter of a polygon in meters
  static double calculatePerimeter(List<LatLng> points) {
    if (points.length < 2) return 0.0;

    double perimeter = 0.0;

    for (int i = 0; i < points.length; i++) {
      final current = points[i];
      final next = points[(i + 1) % points.length];
      perimeter += _distanceBetween(current, next);
    }

    return perimeter;
  }

  /// Calculate distance between two points using Haversine formula
  static double _distanceBetween(LatLng point1, LatLng point2) {
    final lat1Rad = _toRadians(point1.latitude);
    final lat2Rad = _toRadians(point2.latitude);
    final deltaLatRad = _toRadians(point2.latitude - point1.latitude);
    final deltaLngRad = _toRadians(point2.longitude - point1.longitude);

    final a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLngRad / 2) *
            math.sin(deltaLngRad / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return _earthRadiusMeters * c;
  }

  /// Convert degrees to radians
  static double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  /// Get the center point of a polygon
  static LatLng getCenterPoint(List<LatLng> points) {
    if (points.isEmpty) return const LatLng(0, 0);
    if (points.length == 1) return points.first;

    double sumLat = 0;
    double sumLng = 0;

    for (final point in points) {
      sumLat += point.latitude;
      sumLng += point.longitude;
    }

    return LatLng(
      sumLat / points.length,
      sumLng / points.length,
    );
  }

  /// Format area for display
  static String formatArea(double areaInSquareMeters) {
    if (areaInSquareMeters >= 10000) {
      // Convert to hectares
      final hectares = areaInSquareMeters / 10000;
      return '${hectares.toStringAsFixed(2)} hectares';
    } else if (areaInSquareMeters >= 1) {
      return '${areaInSquareMeters.toStringAsFixed(2)} sq m';
    } else {
      // Convert to square centimeters for very small areas
      final sqCm = areaInSquareMeters * 10000;
      return '${sqCm.toStringAsFixed(0)} sq cm';
    }
  }

  /// Format perimeter for display
  static String formatPerimeter(double perimeterInMeters) {
    if (perimeterInMeters >= 1000) {
      // Convert to kilometers
      final kilometers = perimeterInMeters / 1000;
      return '${kilometers.toStringAsFixed(2)} km';
    } else {
      return '${perimeterInMeters.toStringAsFixed(2)} m';
    }
  }

  /// Check if a polygon is valid (at least 3 points, not self-intersecting)
  static bool isValidPolygon(List<LatLng> points) {
    if (points.length < 3) return false;

    // For simplicity, we'll consider any 3+ point polygon as valid
    // In a production app, you might want to check for self-intersection
    return true;
  }

  /// Create markers for polygon points
  static Set<Marker> createPolygonMarkers(List<LatLng> points, {
    Function(int)? onMarkerTap,
  }) {
    final markers = <Marker>{};

    for (int i = 0; i < points.length; i++) {
      markers.add(
        Marker(
          markerId: MarkerId('point_$i'),
          position: points[i],
          draggable: true,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            i == 0 ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
          ),
          infoWindow: InfoWindow(
            title: i == 0 ? 'Start Point' : 'Point ${i + 1}',
            snippet: '${points[i].latitude.toStringAsFixed(6)}, ${points[i]
                .longitude.toStringAsFixed(6)}',
          ),
          onTap: onMarkerTap != null ? () => onMarkerTap(i) : null,
        ),
      );
    }

    return markers;
  }

  /// Create polygon overlay
  static Polygon createPolygon(List<LatLng> points, {String? polygonId}) {
    return Polygon(
      polygonId: PolygonId(polygonId ?? 'measurement_polygon'),
      points: points,
      strokeColor: const Color(0xFF2E7D32),
      strokeWidth: 3,
      fillColor: const Color(0xFF4CAF50).withOpacity(0.3),
      consumeTapEvents: true,
    );
  }
}
