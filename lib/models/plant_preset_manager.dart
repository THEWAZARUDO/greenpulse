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

  /// Evaluator ngoại tuyến (Offline Fallback Evaluator) với 3 cấp độ: Normal / Warning / Danger
  static AiEvaluationResult evaluateOffline(SensorData sensor) {
    final crop = getCropById(sensor.cropId);
    if (crop == null) {
      return const AiEvaluationResult(
        riskScore: 0.0,
        overallStatus: StatusLevel.normal,
        isAlertTriggered: false,
        paramStatuses: {},
        adviceList: ['Đang chạy ở chế độ ngoại tuyến.'],
        isOfflineFallback: true,
      );
    }

    final stage = crop.getStageById(sensor.stageId);
    final Map<String, StatusLevel> paramStatuses = {};
    final List<String> advice = [];
    int warningCount = 0;
    int dangerCount = 0;

    StatusLevel evalParam(double val, double minVal, double maxVal, String paramName, String unit) {
      if (val >= minVal && val <= maxVal) {
        return StatusLevel.normal;
      }
      final span = maxVal - minVal <= 0 ? 10.0 : maxVal - minVal;
      final dev = val < minVal ? (minVal - val) / span : (val - maxVal) / span;

      if (dev > 0.35) {
        dangerCount++;
        advice.add('[Offline] Cảnh báo nguy hiểm $paramName ($val $unit) vượt khoảng an toàn ($minVal - $maxVal $unit).');
        return StatusLevel.danger;
      } else {
        warningCount++;
        advice.add('[Offline] $paramName ($val $unit) chênh nhẹ so với mức tối ưu ($minVal - $maxVal $unit).');
        return StatusLevel.warning;
      }
    }

    paramStatuses['temperature'] = evalParam(sensor.temperature, stage.tempMin, stage.tempMax, 'Nhiệt độ', '°C');
    paramStatuses['humidity'] = evalParam(sensor.humidity, stage.airHumidityMin, stage.airHumidityMax, 'Độ ẩm không khí', '%');
    paramStatuses['soil'] = evalParam(sensor.soil, stage.soilMoistureMin, stage.soilMoistureMax, 'Độ ẩm đất', '%');
    paramStatuses['light'] = evalParam(sensor.light, stage.luxMin, stage.luxMax, 'Ánh sáng', 'lux');
    paramStatuses['ph'] = evalParam(sensor.ph, crop.soilPhMin, crop.soilPhMax, 'Độ pH đất', 'pH');

    final double riskScore = ((dangerCount * 2 + warningCount) / 10.0) * 100.0;
    
    StatusLevel overall = StatusLevel.normal;
    if (dangerCount > 0) {
      overall = StatusLevel.danger;
    } else if (warningCount > 0) {
      overall = StatusLevel.warning;
    }

    if (advice.isEmpty) {
      advice.add('[Offline] Các chỉ số đạt ngưỡng an toàn cho giai đoạn ${stage.stageName}.');
    }

    return AiEvaluationResult(
      riskScore: riskScore.clamp(0.0, 100.0),
      overallStatus: overall,
      isAlertTriggered: overall != StatusLevel.normal,
      paramStatuses: paramStatuses,
      adviceList: advice,
      cropName: crop.cropName,
      stageName: stage.stageName,
      isOfflineFallback: true,
    );
  }
}
