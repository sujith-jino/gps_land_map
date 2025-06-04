// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'land_point.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LandPointAdapter extends TypeAdapter<LandPoint> {
  @override
  final int typeId = 0;

  @override
  LandPoint read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LandPoint(
      id: fields[0] as String,
      latitude: fields[1] as double,
      longitude: fields[2] as double,
      altitude: fields[3] as double?,
      accuracy: fields[4] as double?,
      timestamp: fields[5] as DateTime,
      imagePath: fields[6] as String?,
      analysis: fields[7] as LandAnalysis?,
      notes: fields[8] as String?,
      tags: (fields[9] as List?)?.cast<String>() ?? const [],
      isSynced: fields[10] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, LandPoint obj) {
    writer
      ..writeByte(11)..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.latitude)
      ..writeByte(2)
      ..write(obj.longitude)
      ..writeByte(3)
      ..write(obj.altitude)
      ..writeByte(4)
      ..write(obj.accuracy)
      ..writeByte(5)
      ..write(obj.timestamp)
      ..writeByte(6)
      ..write(obj.imagePath)
      ..writeByte(7)
      ..write(obj.analysis)
      ..writeByte(8)
      ..write(obj.notes)
      ..writeByte(9)
      ..write(obj.tags)
      ..writeByte(10)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is LandPointAdapter &&
              runtimeType == other.runtimeType &&
              typeId == other.typeId;
}

class LandAnalysisAdapter extends TypeAdapter<LandAnalysis> {
  @override
  final int typeId = 1;

  @override
  LandAnalysis read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LandAnalysis(
      id: fields[0] as String,
      vegetationPercentage: fields[1] as double,
      waterBodyPercentage: fields[2] as double,
      dominantLandFeature: fields[3] as String,
      soilType: fields[4] as String,
      elevationEstimate: fields[5] as double,
      detectedFeatures: (fields[6] as List).cast<DetectedFeature>(),
      confidenceScore: fields[7] as double,
      analysisTime: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, LandAnalysis obj) {
    writer
      ..writeByte(9)..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.vegetationPercentage)
      ..writeByte(2)
      ..write(obj.waterBodyPercentage)
      ..writeByte(3)
      ..write(obj.dominantLandFeature)
      ..writeByte(4)
      ..write(obj.soilType)
      ..writeByte(5)
      ..write(obj.elevationEstimate)
      ..writeByte(6)
      ..write(obj.detectedFeatures)
      ..writeByte(7)
      ..write(obj.confidenceScore)
      ..writeByte(8)
      ..write(obj.analysisTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is LandAnalysisAdapter &&
              runtimeType == other.runtimeType &&
              typeId == other.typeId;
}

class DetectedFeatureAdapter extends TypeAdapter<DetectedFeature> {
  @override
  final int typeId = 2;

  @override
  DetectedFeature read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DetectedFeature(
      name: fields[0] as String,
      confidence: fields[1] as double,
      category: fields[2] as String,
      boundingBox: (fields[3] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, DetectedFeature obj) {
    writer
      ..writeByte(4)..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.confidence)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.boundingBox);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is DetectedFeatureAdapter &&
              runtimeType == other.runtimeType &&
              typeId == other.typeId;
}