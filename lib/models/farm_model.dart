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
    this.cropId,
    this.stageId = 1,
    this.plantingDate,
    this.aiEvaluation,
    this.extra = const {},
  });

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
    final stageIdVal = (data['stageId'] ?? data['stage_id'] as num?)?.toInt() ?? 1;

    return SensorData(
      id: (data['id'] ?? id).toString(),
      humidity: (data['humidity'] ?? 0).toDouble(),
      light: (data['light'] ?? 0).toDouble(),
      soil: (data['soil'] ?? 0).toDouble(),
      temperature: (data['temperature'] ?? 0).toDouble(),
      ph: (data['ph'] ?? 6.5).toDouble(),
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
  const FarmModel({required this.id, required this.name});
  factory FarmModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return FarmModel(id: doc.id, name: data['name'] as String? ?? doc.id);
  }
  Map<String, dynamic> toMap() => {'name': name};
}
