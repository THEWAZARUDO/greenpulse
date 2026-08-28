import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'ai_evaluation_model.dart';

enum StatusLevel { normal, warning, danger }

extension StatusLevelExtension on StatusLevel {
  Color get color {
    switch (this) {
      case StatusLevel.normal:
        return const Color(0xFF2E7D32); // Green
      case StatusLevel.warning:
        return const Color(0xFFF57C00); // Orange / Amber
      case StatusLevel.danger:
        return const Color(0xFFD32F2F); // Red
    }
  }

  String get label {
    switch (this) {
      case StatusLevel.normal:
        return 'An toàn';
      case StatusLevel.warning:
        return 'Cảnh báo';
      case StatusLevel.danger:
        return 'Nguy hiểm';
    }
  }

  IconData get icon {
    switch (this) {
      case StatusLevel.normal:
        return Icons.check_circle_outline;
      case StatusLevel.warning:
        return Icons.warning_amber_outlined;
      case StatusLevel.danger:
        return Icons.error_outline;
    }
  }
}

class SensorData {
  final String id;
  final double humidity;
  final double light;
  final double soil;
  final double temperature;
  final double ph;
  final bool hasHumidity;
  final bool hasLight;
  final bool hasSoil;
  final bool hasTemperature;
  final bool hasPh;
  final String? cropId;
  final int stageId;
  final DateTime? plantingDate;
  final AiEvaluationResult? aiEvaluation;
  final Map<String, dynamic> extra;

  const SensorData({
    this.id = 'sensor_1',
    required this.humidity,
    required this.light,
    required this.soil,
    required this.temperature,
    this.ph = 6.5,
    this.hasHumidity = true,
    this.hasLight = true,
    this.hasSoil = true,
    this.hasTemperature = true,
    this.hasPh = true,
    this.cropId,
    this.stageId = 1,
    this.plantingDate,
    this.aiEvaluation,
    this.extra = const {},
  });

  /// Kiểm tra xem cảm biến có ít nhất 1 giá trị đo gửi về hay không
  bool get isSensorOnline =>
      hasHumidity || hasLight || hasSoil || hasTemperature || hasPh;

  /// Hàm ép kiểu số thực an toàn từ dynamic (hỗ trợ num, String, định dạng phẩy)
  static double? tryParseDouble(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toDouble();
    if (val is String) {
      final clean = val.trim().replaceAll(',', '.');
      return double.tryParse(clean);
    }
    return null;
  }

  factory SensorData.fromMap(
    Map<String, dynamic> data, {
    String id = 'sensor_1',
  }) {
    final known = {
      'humidity',
      'light',
      'soil',
      'temperature',
      'ph',
      'id',
      'plantName',
      'cropId',
      'crop_id',
      'stageId',
      'stage_id',
      'plantingDate',
    };
    final extra = Map<String, dynamic>.fromEntries(
      data.entries.where((e) => !known.contains(e.key)),
    );

    DateTime? pDate;
    if (data['plantingDate'] != null) {
      if (data['plantingDate'] is Timestamp) {
        pDate = (data['plantingDate'] as Timestamp).toDate();
      } else if (data['plantingDate'] is String) {
        pDate = DateTime.tryParse(data['plantingDate'].toString());
      }
    }

    final cropIdVal = (data['cropId'] ?? data['crop_id'] ?? data['plantName'])?.toString();
    final stageRaw = data['stageId'] ?? data['stage_id'];
    int stageIdVal = 1;
    if (stageRaw is num) {
      stageIdVal = stageRaw.toInt();
    } else if (stageRaw is String) {
      stageIdVal = int.tryParse(stageRaw.trim()) ?? 1;
    }

    final humVal = tryParseDouble(data['humidity']);
    final lightVal = tryParseDouble(data['light']);
    final soilVal = tryParseDouble(data['soil']);
    final tempVal = tryParseDouble(data['temperature']);
    final phVal = tryParseDouble(data['ph']);

    return SensorData(
      id: (data['id'] ?? id).toString(),
      humidity: humVal ?? 0.0,
      light: lightVal ?? 0.0,
      soil: soilVal ?? 0.0,
      temperature: tempVal ?? 0.0,
      ph: phVal ?? 6.5,
      hasHumidity: humVal != null,
      hasLight: lightVal != null,
      hasSoil: soilVal != null,
      hasTemperature: tempVal != null,
      hasPh: phVal != null,
      cropId: cropIdVal,
      stageId: stageIdVal,
      plantingDate: pDate,
      extra: extra,
    );
  }

  factory SensorData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SensorData.fromMap(data, id: doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'humidity': humidity,
      'light': light,
      'soil': soil,
      'temperature': temperature,
      'ph': ph,
      if (cropId != null) 'cropId': cropId,
      'stageId': stageId,
      if (plantingDate != null) 'plantingDate': plantingDate!.toIso8601String(),
      ...extra,
    };
  }

  SensorData copyWith({
    String? id,
    double? humidity,
    double? light,
    double? soil,
    double? temperature,
    double? ph,
    bool? hasHumidity,
    bool? hasLight,
    bool? hasSoil,
    bool? hasTemperature,
    bool? hasPh,
    String? cropId,
    int? stageId,
    DateTime? plantingDate,
    AiEvaluationResult? aiEvaluation,
    Map<String, dynamic>? extra,
  }) {
    return SensorData(
      id: id ?? this.id,
      humidity: humidity ?? this.humidity,
      light: light ?? this.light,
      soil: soil ?? this.soil,
      temperature: temperature ?? this.temperature,
      ph: ph ?? this.ph,
      hasHumidity: hasHumidity ?? this.hasHumidity,
      hasLight: hasLight ?? this.hasLight,
      hasSoil: hasSoil ?? this.hasSoil,
      hasTemperature: hasTemperature ?? this.hasTemperature,
      hasPh: hasPh ?? this.hasPh,
      cropId: cropId ?? this.cropId,
      stageId: stageId ?? this.stageId,
      plantingDate: plantingDate ?? this.plantingDate,
      aiEvaluation: aiEvaluation ?? this.aiEvaluation,
      extra: extra ?? this.extra,
    );
  }


  StatusLevel get tempStatus =>
      aiEvaluation?.getParamStatus('temperature') ?? StatusLevel.normal;

  StatusLevel get humidityStatus =>
      aiEvaluation?.getParamStatus('humidity') ?? StatusLevel.normal;

  StatusLevel get soilStatus =>
      aiEvaluation?.getParamStatus('soil') ?? StatusLevel.normal;

  StatusLevel get lightStatus =>
      aiEvaluation?.getParamStatus('light') ?? StatusLevel.normal;

  StatusLevel get phStatus =>
      aiEvaluation?.getParamStatus('ph') ?? StatusLevel.normal;

  StatusLevel get overallStatus =>
      aiEvaluation?.overallStatus ?? StatusLevel.normal;

  List<String> get adviceList {
    if (aiEvaluation != null && aiEvaluation!.adviceList.isNotEmpty) {
      return aiEvaluation!.adviceList;
    }
    return const ['Tất cả các chỉ số cảm biến đang ở mức an toàn.'];
  }
}

class FarmModel {
  final String id;
  final String name;
  final String? locationName;
  final double? latitude;
  final double? longitude;

  const FarmModel({
    required this.id,
    required this.name,
    this.locationName,
    this.latitude,
    this.longitude,
  });

  factory FarmModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return FarmModel(
      id: doc.id,
      name: data['name'] as String? ?? doc.id,
      locationName: data['locationName'] as String?,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        if (locationName != null) 'locationName': locationName,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };
}
