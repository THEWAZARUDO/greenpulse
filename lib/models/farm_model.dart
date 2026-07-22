import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum StatusLevel { normal, warning, danger }

extension StatusLevelExtension on StatusLevel {
  Color get color {
    switch (this) {
      case StatusLevel.normal:
        return const Color(0xFF2E7D32); // Green
      case StatusLevel.warning:
        return const Color(0xFFF57C00); // Orange
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
        return Icons.warning_amber_rounded;
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
  final Map<String, dynamic> extra;

  const SensorData({
    this.id = 'sensor_1',
    required this.humidity,
    required this.light,
    required this.soil,
    required this.temperature,
    this.extra = const {},
  });

  factory SensorData.fromMap(Map<String, dynamic> data, {String id = 'sensor_1'}) {
    final known = {'humidity', 'light', 'soil', 'temperature', 'id'};
    final extra = Map<String, dynamic>.fromEntries(
      data.entries.where((e) => !known.contains(e.key)),
    );
    return SensorData(
      id: (data['id'] ?? id).toString(),
      humidity: (data['humidity'] ?? 0).toDouble(),
      light: (data['light'] ?? 0).toDouble(),
      soil: (data['soil'] ?? 0).toDouble(),
      temperature: (data['temperature'] ?? 0).toDouble(),
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
      ...extra,
    };
  }

  // ─── ĐÁNH GIÁ TRẠNG THÁI THEO NGƯỠNG AN TOÀN ───────────────────────────

  StatusLevel get tempStatus {
    if (temperature > 35.0 || temperature < 12.0) return StatusLevel.danger;
    if (temperature > 32.0 || temperature < 18.0) return StatusLevel.warning;
    return StatusLevel.normal;
  }

  StatusLevel get humidityStatus {
    if (humidity < 30.0 || humidity > 92.0) return StatusLevel.danger;
    if (humidity < 45.0 || humidity > 85.0) return StatusLevel.warning;
    return StatusLevel.normal;
  }

  StatusLevel get soilStatus {
    if (soil < 20.0) return StatusLevel.danger;
    if (soil < 35.0 || soil > 85.0) return StatusLevel.warning;
    return StatusLevel.normal;
  }

  StatusLevel get lightStatus {
    if (light < 100 || light > 3500) return StatusLevel.danger;
    if (light < 250 || light > 2500) return StatusLevel.warning;
    return StatusLevel.normal;
  }

  StatusLevel get overallStatus {
    final statuses = [tempStatus, humidityStatus, soilStatus, lightStatus];
    if (statuses.contains(StatusLevel.danger)) return StatusLevel.danger;
    if (statuses.contains(StatusLevel.warning)) return StatusLevel.warning;
    return StatusLevel.normal;
  }

  // ─── AI ADVICE SYSTEM (LỜI KHUYÊN TỰ ĐỘNG TỪ HỆ THỐNG AI) ──────────────────

  List<String> getAiAdviceList() {
    final List<String> advice = [];

    if (temperature > 35.0) {
      advice.add('🔥 Nhiệt độ quá cao ($temperature°C). AI khuyến nghị kích hoạt hệ thống phun sương làm mát.');
    } else if (temperature < 15.0) {
      advice.add('❄️ Nhiệt độ quá thấp ($temperature°C). Bật đèn sưởi hoặc đóng rèm chắn gió.');
    }

    if (soil < 30.0) {
      advice.add('💧 Độ ẩm đất thấp ($soil%). AI khuyến nghị bật máy bơm tưới tự động trong 10 phút.');
    } else if (soil > 85.0) {
      advice.add('🌊 Đất quá ngập nước ($soil%). Tạm ngưng hệ thống tưới và kiểm tra mương thoát nước.');
    }

    if (humidity < 40.0) {
      advice.add('🌵 Độ ẩm không khí khô ($humidity%). Tăng cường độ ẩm không khí để lá không bị héo.');
    }

    if (light < 250) {
      advice.add('☀️ Thiếu ánh sáng ($light lux). Bật hệ thống đèn LED quang hợp trợ sáng.');
    } else if (light > 2800) {
      advice.add('🌤️ Ánh sáng gắt ($light lux). Kéo lưới che nắng để bảo vệ mô lá.');
    }

    if (advice.isEmpty) {
      advice.add('🌱 Tất cả chỉ số cảm biến đạt trạng thái tối ưu cho cây trồng phát triển.');
    }

    return advice;
  }
}

class FarmModel {
  final String id;
  final String name;

  const FarmModel({required this.id, required this.name});

  factory FarmModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return FarmModel(
      id: doc.id,
      name: data['name'] as String? ?? doc.id,
    );
  }

  Map<String, dynamic> toMap() => {'name': name};
}
