import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'plant_preset_manager.dart';

enum StatusLevel { normal, danger }

extension StatusLevelExtension on StatusLevel {
  Color get color {
    switch (this) {
      case StatusLevel.normal:
        return const Color(0xFF2E7D32); // Green
      case StatusLevel.danger:
        return const Color(0xFFD32F2F); // Red
    }
  }

  String get label {
    switch (this) {
      case StatusLevel.normal:
        return 'An toàn';
      case StatusLevel.danger:
        return 'Nguy hiểm';
    }
  }

  IconData get icon {
    switch (this) {
      case StatusLevel.normal:
        return Icons.check_circle_outline;
      case StatusLevel.danger:
        return Icons.error_outline;
    }
  }
}

// ─── MODEL CẤU HÌNH NGƯỠNG AI TÙY CHỈNH ─────────────────────────────────────
class SensorThresholds {
  final String plantName;
  final double minTemp;
  final double maxTemp;
  final double minHumidity;
  final double maxHumidity;
  final double minSoil;
  final double maxSoil;
  final double minLight;
  final double maxLight;
  const SensorThresholds({
    this.plantName = 'Mặc định',
    this.minTemp = 15.0,
    this.maxTemp = 35.0,
    this.minHumidity = 40.0,
    this.maxHumidity = 50.0,
    this.minSoil = 30.0,
    this.maxSoil = 50.0,
    this.minLight = 300.0,
    this.maxLight = 2800.0,
  });
  factory SensorThresholds.fromMap(Map<String, dynamic> data) {
    return SensorThresholds(
      plantName: (data['name'] ?? data['plantName'])?.toString() ?? 'Mặc định',
      minTemp: (data['minTemp'] as num?)?.toDouble() ?? 15.0,
      maxTemp: (data['maxTemp'] as num?)?.toDouble() ?? 35.0,
      minHumidity: (data['minHumidity'] as num?)?.toDouble() ?? 40.0,
      maxHumidity: (data['maxHumidity'] as num?)?.toDouble() ?? 50.0,
      minSoil: (data['minSoil'] as num?)?.toDouble() ?? 30.0,
      maxSoil: (data['maxSoil'] as num?)?.toDouble() ?? 50.0,
      minLight: (data['minLight'] as num?)?.toDouble() ?? 300.0,
      maxLight: (data['maxLight'] as num?)?.toDouble() ?? 2800.0,
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'plantName': plantName,
      'minTemp': minTemp,
      'maxTemp': maxTemp,
      'minHumidity': minHumidity,
      'maxHumidity': maxHumidity,
      'minSoil': minSoil,
      'maxSoil': maxSoil,
      'minLight': minLight,
      'maxLight': maxLight,
    };
  }
}

class SensorData {
  final String id;
  final double humidity;
  final double light;
  final double soil;
  final double temperature;
  final SensorThresholds? customThresholds;
  final Map<String, dynamic> extra;
  const SensorData({
    this.id = 'sensor_1',
    required this.humidity,
    required this.light,
    required this.soil,
    required this.temperature,
    this.customThresholds,
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
      'id',
      'plantName',
    };
    final extra = Map<String, dynamic>.fromEntries(
      data.entries.where((e) => !known.contains(e.key)),
    );
    SensorThresholds? customThresholds;
    if (data['plantName'] != null) {
      customThresholds = PlantPresetManager.getPresetByName(
        data['plantName'].toString(),
      );
    }
    return SensorData(
      id: (data['id'] ?? id).toString(),
      humidity: (data['humidity'] ?? 0).toDouble(),
      light: (data['light'] ?? 0).toDouble(),
      soil: (data['soil'] ?? 0).toDouble(),
      temperature: (data['temperature'] ?? 0).toDouble(),
      customThresholds: customThresholds,
      extra: extra,
    );
  }
  factory SensorData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SensorData.fromMap(data, id: doc.id);
  }
  Map<String, dynamic> toMap() {
    final map = {
      'id': id,
      'humidity': humidity,
      'light': light,
      'soil': soil,
      'temperature': temperature,
      ...extra,
    };
    if (customThresholds != null) {
      map['plantName'] = customThresholds!.plantName;
    }
    return map;
  }

  StatusLevel get tempStatus {
    final t =
        customThresholds ??
        (PlantPresetManager.presets.isNotEmpty
            ? PlantPresetManager.presets.first
            : const SensorThresholds());
    if (temperature > t.maxTemp || temperature < t.minTemp)
      return StatusLevel.danger;
    return StatusLevel.normal;
  }

  StatusLevel get humidityStatus {
    final t =
        customThresholds ??
        (PlantPresetManager.presets.isNotEmpty
            ? PlantPresetManager.presets.first
            : const SensorThresholds());
    if (humidity < t.minHumidity || humidity > t.maxHumidity)
      return StatusLevel.danger;
    return StatusLevel.normal;
  }

  StatusLevel get soilStatus {
    final t =
        customThresholds ??
        (PlantPresetManager.presets.isNotEmpty
            ? PlantPresetManager.presets.first
            : const SensorThresholds());
    if (soil < t.minSoil || soil > t.maxSoil) return StatusLevel.danger;
    return StatusLevel.normal;
  }

  StatusLevel get lightStatus {
    final t =
        customThresholds ??
        (PlantPresetManager.presets.isNotEmpty
            ? PlantPresetManager.presets.first
            : const SensorThresholds());
    if (light < t.minLight || light > t.maxLight) return StatusLevel.danger;
    return StatusLevel.normal;
  }

  StatusLevel get overallStatus {
    final statuses = [tempStatus, humidityStatus, soilStatus, lightStatus];
    if (statuses.contains(StatusLevel.danger)) return StatusLevel.danger;
    return StatusLevel.normal;
  }

  // ─── AI ADVICE SYSTEM (LỜI KHUYÊN TỰ ĐỘNG TỪ HỆ THỐNG AI) ──────────────────
  List<String> getAiAdviceList() {
    final thresholds =
        customThresholds ??
        (PlantPresetManager.presets.isNotEmpty
            ? PlantPresetManager.presets.first
            : const SensorThresholds());
    final List<String> advice = [];
    if (temperature > thresholds.maxTemp) {
      advice.add(
        'Nhiệt độ ($temperature°C) đang quá cao. Khuyến nghị kích hoạt phun sương làm mát.',
      );
    } else if (temperature < thresholds.minTemp) {
      advice.add(
        'Nhiệt độ ($temperature°C) đang quá thấp. Bật đèn sưởi hoặc đóng rèm chắn gió.',
      );
    }
    if (soil < thresholds.minSoil) {
      advice.add(
        'Độ ẩm đất ($soil%) đang quá thấp. Khuyến nghị bật máy bơm tưới tự động.',
      );
    } else if (soil > 85.0) {
      advice.add(
        'Đất ngập nước. Tạm ngưng hệ thống tưới và kiểm tra mương thoát nước.',
      );
    }
    if (humidity < thresholds.minHumidity) {
      advice.add(
        'Độ ẩm không khí ($humidity%) quá khô. Tăng cường độ ẩm không khí.',
      );
    } else if (humidity > thresholds.maxHumidity) {
      advice.add(
        'Độ ẩm không khí ($humidity%) quá ẩm. Vui lòng thoát ẩm cho cây.',
      );
    }
    if (light < thresholds.minLight) {
      advice.add(
        'Thiếu ánh sáng ($light lux < ${thresholds.minLight} lux). Bật hệ thống đèn LED quang hợp.',
      );
    } else if (light > thresholds.maxLight) {
      advice.add(
        'Ánh sáng quá cao ($light lux > ${thresholds.maxLight} lux). Kéo lưới che nắng bảo vệ mô lá.',
      );
    }
    if (advice.isEmpty) {
      advice.add(
        'Tất cả chỉ số cảm biến đạt trạng thái tối ưu theo cấu hình ngưỡng AI.',
      );
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
    return FarmModel(id: doc.id, name: data['name'] as String? ?? doc.id);
  }
  Map<String, dynamic> toMap() => {'name': name};
}
