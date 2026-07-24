import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'ai_evaluation_model.dart';
import 'crop_preset_model.dart';
import 'farm_model.dart';

class PlantPresetManager {
  PlantPresetManager._();

  static final List<CropModel> _crops = [];

  /// Tải danh sách cấu hình đa giai đoạn sinh trưởng từ file assets/plant_presets.txt
  static Future<void> loadPresets() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/plant_presets.txt',
      );
      final Map<String, dynamic> jsonMap = json.decode(response);
      final List<dynamic> cropsData = jsonMap['crops'] ?? [];
      
      _crops.clear();
      _crops.addAll(
        cropsData.map((item) => CropModel.fromMap(Map<String, dynamic>.from(item as Map))),
      );
    } catch (e) {
      debugPrint('Lỗi khi tải plant_presets.txt: $e');
    }
  }

  static List<CropModel> get crops => _crops;

  static CropModel? getCropById(String? cropId) {
    if (_crops.isEmpty) return null;
    if (cropId == null || cropId.isEmpty) return _crops.isNotEmpty ? _crops.first : null;
    try {
      return _crops.firstWhere(
        (c) => c.cropId == cropId || c.cropName.toLowerCase() == cropId.toLowerCase(),
      );
    } catch (_) {
      return _crops.isNotEmpty ? _crops.first : null;
    }
  }

  /// Evaluator ngoại tuyến (Offline Fallback Evaluator)
  /// Được gọi khi kết nối API AI Python bị timeout hoặc AI server đang ở trạng thái sleep.
  static AiEvaluationResult evaluateOffline(SensorData sensor) {
    final crop = getCropById(sensor.cropId);
    if (crop == null) {
      return const AiEvaluationResult(
        riskScore: 0.0,
        overallStatus: StatusLevel.normal,
        isAlertTriggered: false,
        paramStatuses: {},
        adviceList: ['Đang chạy ở chế độ ngoại tuyến. Không tìm thấy cấu hình cây.'],
        isOfflineFallback: true,
      );
    }

    final stage = crop.getStageById(sensor.stageId);
    final Map<String, StatusLevel> paramStatuses = {};
    final List<String> advice = [];
    int dangerCount = 0;

    // Check Temperature
    if (sensor.temperature < stage.tempMin || sensor.temperature > stage.tempMax) {
      paramStatuses['temperature'] = StatusLevel.danger;
      dangerCount++;
      advice.add(
        '[Offline] Nhiệt độ (${sensor.temperature}°C) ngoài khoảng tối ưu (${stage.tempMin}°C - ${stage.tempMax}°C).',
      );
    } else {
      paramStatuses['temperature'] = StatusLevel.normal;
    }

    // Check Humidity
    if (sensor.humidity < stage.airHumidityMin || sensor.humidity > stage.airHumidityMax) {
      paramStatuses['humidity'] = StatusLevel.danger;
      dangerCount++;
      advice.add(
        '[Offline] Độ ẩm không khí (${sensor.humidity}%) ngoài khoảng tối ưu (${stage.airHumidityMin}% - ${stage.airHumidityMax}%).',
      );
    } else {
      paramStatuses['humidity'] = StatusLevel.normal;
    }

    // Check Soil Moisture
    if (sensor.soil < stage.soilMoistureMin || sensor.soil > stage.soilMoistureMax) {
      paramStatuses['soil'] = StatusLevel.danger;
      dangerCount++;
      advice.add(
        '[Offline] Độ ẩm đất (${sensor.soil}%) ngoài khoảng tối ưu (${stage.soilMoistureMin}% - ${stage.soilMoistureMax}%).',
      );
    } else {
      paramStatuses['soil'] = StatusLevel.normal;
    }

    // Check Light
    if (sensor.light < stage.luxMin || sensor.light > stage.luxMax) {
      paramStatuses['light'] = StatusLevel.danger;
      dangerCount++;
      advice.add(
        '[Offline] Cường độ ánh sáng (${sensor.light} lux) ngoài khoảng tối ưu (${stage.luxMin} lux - ${stage.luxMax} lux).',
      );
    } else {
      paramStatuses['light'] = StatusLevel.normal;
    }

    // Check pH
    if (sensor.ph < crop.soilPhMin || sensor.ph > crop.soilPhMax) {
      paramStatuses['ph'] = StatusLevel.danger;
      dangerCount++;
      advice.add(
        '[Offline] Độ pH đất (${sensor.ph}) nằm ngoài ngưỡng an toàn (${crop.soilPhMin} - ${crop.soilPhMax}).',
      );
    } else {
      paramStatuses['ph'] = StatusLevel.normal;
    }

    final double riskScore = (dangerCount / 5.0) * 100.0;
    final StatusLevel overall = dangerCount > 0 ? StatusLevel.danger : StatusLevel.normal;

    if (advice.isEmpty) {
      advice.add('[Offline] Các chỉ số đạt ngưỡng an toàn cho giai đoạn ${stage.stageName}.');
    }

    return AiEvaluationResult(
      riskScore: riskScore,
      overallStatus: overall,
      isAlertTriggered: dangerCount > 0,
      paramStatuses: paramStatuses,
      adviceList: advice,
      cropName: crop.cropName,
      stageName: stage.stageName,
      isOfflineFallback: true,
    );
  }
}
