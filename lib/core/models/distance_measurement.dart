import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math' as math;

// Simple ID generation helper
String _generateMeasurementId() {
  final random = math.Random();
  return 'dist_${random.nextInt(100000)}_${DateTime
      .now()
      .millisecondsSinceEpoch}';
}

class DistanceMeasurement extends Equatable {
  final String id;
  final List<MeasurementPoint> points;
  final double totalDistance;
  final DateTime createdAt;
  final String? name;
  final String? notes;

  const DistanceMeasurement({
    required this.id,
    required this.points,
    required this.totalDistance,
    required this.createdAt,
    this.name,
    this.notes,
  });

  factory DistanceMeasurement.create({
    required List<MeasurementPoint> points,
    required double totalDistance,
    String? name,
    String? notes,
  }) {
    return DistanceMeasurement(
      id: _generateMeasurementId(),
      points: points,
      totalDistance: totalDistance,
      createdAt: DateTime.now(),
      name: name,
      notes: notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'points': points.map((p) => p.toJson()).toList(),
      'totalDistance': totalDistance,
      'createdAt': createdAt.toIso8601String(),
      'name': name,
      'notes': notes,
    };
  }

  factory DistanceMeasurement.fromJson(Map<String, dynamic> json) {
    return DistanceMeasurement(
      id: json['id'],
      points: (json['points'] as List)
          .map((p) => MeasurementPoint.fromJson(p))
          .toList(),
      totalDistance: json['totalDistance'].toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
      name: json['name'],
      notes: json['notes'],
    );
  }

  @override
  List<Object?> get props =>
      [id, points, totalDistance, createdAt, name, notes];
}

class MeasurementPoint extends Equatable {
  final double latitude;
  final double longitude;
  final int pointNumber;
  final double? distanceFromPrevious;

  const MeasurementPoint({
    required this.latitude,
    required this.longitude,
    required this.pointNumber,
    this.distanceFromPrevious,
  });

  factory MeasurementPoint.fromLatLng(LatLng latLng,
      int pointNumber, {
        double? distanceFromPrevious,
      }) {
    return MeasurementPoint(
      latitude: latLng.latitude,
      longitude: latLng.longitude,
      pointNumber: pointNumber,
      distanceFromPrevious: distanceFromPrevious,
    );
  }

  LatLng get latLng => LatLng(latitude, longitude);

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'pointNumber': pointNumber,
      'distanceFromPrevious': distanceFromPrevious,
    };
  }

  factory MeasurementPoint.fromJson(Map<String, dynamic> json) {
    return MeasurementPoint(
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      pointNumber: json['pointNumber'],
      distanceFromPrevious: json['distanceFromPrevious']?.toDouble(),
    );
  }

  @override
  List<Object?> get props =>
      [latitude, longitude, pointNumber, distanceFromPrevious];
}