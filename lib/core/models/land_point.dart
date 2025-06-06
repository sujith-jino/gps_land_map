import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'dart:math' as math;

part 'land_point.g.dart';

// Simple ID generation helper
String _generateId() {
  final random = math.Random();
  return '${random.nextInt(100000)}-${DateTime
      .now()
      .millisecondsSinceEpoch}';
}

@HiveType(typeId: 0)
class LandPoint extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double latitude;

  @HiveField(2)
  final double longitude;

  @HiveField(3)
  final double? altitude;

  @HiveField(4)
  final double? accuracy;

  @HiveField(5)
  final DateTime timestamp;

  @HiveField(6)
  final String? imagePath;

  @HiveField(7)
  final LandAnalysis? analysis;

  @HiveField(8)
  final String? notes;

  @HiveField(9)
  final List<String> tags;

  @HiveField(10)
  final bool isSynced;

  const LandPoint({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.accuracy,
    required this.timestamp,
    this.imagePath,
    this.analysis,
    this.notes,
    this.tags = const [],
    this.isSynced = false,
  });

  // Factory constructor with auto-generated ID
  factory LandPoint.create({
    required double latitude,
    required double longitude,
    double? altitude,
    double? accuracy,
    DateTime? timestamp,
    String? imagePath,
    LandAnalysis? analysis,
    String? notes,
    List<String> tags = const [],
    bool isSynced = false,
  }) {
    return LandPoint(
      id: _generateId(),
      latitude: latitude,
      longitude: longitude,
      altitude: altitude,
      accuracy: accuracy,
      timestamp: timestamp ?? DateTime.now(),
      imagePath: imagePath,
      analysis: analysis,
      notes: notes,
      tags: tags,
      isSynced: isSynced,
    );
  }

  LandPoint copyWith({
    String? id,
    double? latitude,
    double? longitude,
    double? altitude,
    double? accuracy,
    DateTime? timestamp,
    String? imagePath,
    LandAnalysis? analysis,
    String? notes,
    List<String>? tags,
    bool? isSynced,
  }) {
    return LandPoint(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      accuracy: accuracy ?? this.accuracy,
      timestamp: timestamp ?? this.timestamp,
      imagePath: imagePath ?? this.imagePath,
      analysis: analysis ?? this.analysis,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
      'imagePath': imagePath,
      'analysis': analysis?.toJson(),
      'notes': notes,
      'tags': tags,
      'isSynced': isSynced,
    };
  }

  factory LandPoint.fromJson(Map<String, dynamic> json) {
    return LandPoint(
      id: json['id'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      altitude: json['altitude']?.toDouble(),
      accuracy: json['accuracy']?.toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
      imagePath: json['imagePath'],
      analysis: json['analysis'] != null ? LandAnalysis.fromJson(
          json['analysis']) : null,
      notes: json['notes'],
      tags: List<String>.from(json['tags'] ?? []),
      isSynced: json['isSynced'] ?? false,
    );
  }

  @override
  List<Object?> get props =>
      [
        id, latitude, longitude, altitude, accuracy,
        timestamp, imagePath, analysis, notes, tags, isSynced
      ];
}

@HiveType(typeId: 1)
class LandAnalysis extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double vegetationPercentage;

  @HiveField(2)
  final double waterBodyPercentage;

  @HiveField(3)
  final String dominantLandFeature;

  @HiveField(4)
  final String soilType;

  @HiveField(5)
  final double elevationEstimate;

  @HiveField(6)
  final List<DetectedFeature> detectedFeatures;

  @HiveField(7)
  final double confidenceScore;

  @HiveField(8)
  final DateTime analysisTime;

  const LandAnalysis({
    required this.id,
    required this.vegetationPercentage,
    required this.waterBodyPercentage,
    required this.dominantLandFeature,
    required this.soilType,
    required this.elevationEstimate,
    required this.detectedFeatures,
    required this.confidenceScore,
    required this.analysisTime,
  });

  // Factory constructor with auto-generated ID
  factory LandAnalysis.create({
    required double vegetationPercentage,
    required double waterBodyPercentage,
    required String dominantLandFeature,
    required String soilType,
    required double elevationEstimate,
    required List<DetectedFeature> detectedFeatures,
    required double confidenceScore,
    DateTime? analysisTime,
  }) {
    return LandAnalysis(
      id: _generateId(),
      vegetationPercentage: vegetationPercentage,
      waterBodyPercentage: waterBodyPercentage,
      dominantLandFeature: dominantLandFeature,
      soilType: soilType,
      elevationEstimate: elevationEstimate,
      detectedFeatures: detectedFeatures,
      confidenceScore: confidenceScore,
      analysisTime: analysisTime ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vegetationPercentage': vegetationPercentage,
      'waterBodyPercentage': waterBodyPercentage,
      'dominantLandFeature': dominantLandFeature,
      'soilType': soilType,
      'elevationEstimate': elevationEstimate,
      'detectedFeatures': detectedFeatures.map((f) => f.toJson()).toList(),
      'confidenceScore': confidenceScore,
      'analysisTime': analysisTime.toIso8601String(),
    };
  }

  factory LandAnalysis.fromJson(Map<String, dynamic> json) {
    return LandAnalysis(
      id: json['id'],
      vegetationPercentage: json['vegetationPercentage'].toDouble(),
      waterBodyPercentage: json['waterBodyPercentage'].toDouble(),
      dominantLandFeature: json['dominantLandFeature'],
      soilType: json['soilType'],
      elevationEstimate: json['elevationEstimate'].toDouble(),
      detectedFeatures: (json['detectedFeatures'] as List)
          .map((f) => DetectedFeature.fromJson(f))
          .toList(),
      confidenceScore: json['confidenceScore'].toDouble(),
      analysisTime: DateTime.parse(json['analysisTime']),
    );
  }

  @override
  List<Object?> get props =>
      [
        id,
        vegetationPercentage,
        waterBodyPercentage,
        dominantLandFeature,
        soilType,
        elevationEstimate,
        detectedFeatures,
        confidenceScore,
        analysisTime
      ];
}

@HiveType(typeId: 2)
class DetectedFeature extends Equatable {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final double confidence;

  @HiveField(2)
  final String category;

  @HiveField(3)
  final Map<String, dynamic> boundingBox;

  const DetectedFeature({
    required this.name,
    required this.confidence,
    required this.category,
    required this.boundingBox,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'confidence': confidence,
      'category': category,
      'boundingBox': boundingBox,
    };
  }

  factory DetectedFeature.fromJson(Map<String, dynamic> json) {
    return DetectedFeature(
      name: json['name'],
      confidence: json['confidence'].toDouble(),
      category: json['category'],
      boundingBox: Map<String, dynamic>.from(json['boundingBox']),
    );
  }

  @override
  List<Object?> get props => [name, confidence, category, boundingBox];
}
