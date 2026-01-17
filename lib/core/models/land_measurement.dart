import 'package:google_maps_flutter/google_maps_flutter.dart';

class LandMeasurement {
  final String id;
  final List<LatLng> points;
  final double area; // in square meters
  final double perimeter; // in meters
  final DateTime createdAt;
  final String? name;
  final String? notes;

  LandMeasurement({
    required this.id,
    required this.points,
    required this.area,
    required this.perimeter,
    required this.createdAt,
    this.name,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'points': points
          .map((p) => {'lat': p.latitude, 'lng': p.longitude})
          .toList(),
      'area': area,
      'perimeter': perimeter,
      'createdAt': createdAt.toIso8601String(),
      'name': name,
      'notes': notes,
    };
  }

  factory LandMeasurement.fromJson(Map<String, dynamic> json) {
    return LandMeasurement(
      id: json['id'],
      points: (json['points'] as List)
          .map((p) => LatLng(p['lat'], p['lng']))
          .toList(),
      area: json['area'].toDouble(),
      perimeter: json['perimeter'].toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
      name: json['name'],
      notes: json['notes'],
    );
  }

  String get formattedArea {
    if (area >= 10000) {
      return '${(area / 10000).toStringAsFixed(2)} hectares';
    } else if (area >= 1) {
      return '${area.toStringAsFixed(2)} sq m';
    } else {
      return '${(area * 10000).toStringAsFixed(0)} sq cm';
    }
  }

  String get formattedPerimeter {
    if (perimeter >= 1000) {
      return '${(perimeter / 1000).toStringAsFixed(2)} km';
    } else {
      return '${perimeter.toStringAsFixed(2)} m';
    }
  }
}