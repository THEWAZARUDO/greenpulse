import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/ai_evaluation_model.dart';
import '../models/farm_model.dart';
import '../models/plant_preset_manager.dart';

class AiApiService {
  AiApiService._();

  // Mặc định URL API AI khi test local / Android Emulator hoặc Cloud VPS
  // Khi deploy lên Cloud (Render/Railway), hãy thay URL tại đây.
  static String baseUrl = 'http://10.0.2.2:8000'; // Android emulator localhost

  /// Gửi dữ liệu cảm biến tới Python Fuzzy AI Service.
  /// Nếu API đang Sleep (Timeout > 4s hoặc lỗi mạng), tự động chuyển sang Offline Fallback Evaluator.
  static Future<AiEvaluationResult> evaluateSensor(SensorData sensor) async {
    final url = Uri.parse('$baseUrl/api/v1/evaluate');
    final payload = {
      'temperature': sensor.temperature,
      'humidity': sensor.humidity,
      'soil': sensor.soil,
      'light': sensor.light,
      'ph': sensor.ph,
      'crop_id': sensor.cropId ?? 'robusta_coffee',
      'stage_id': sensor.stageId,
    };

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(payload),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        return AiEvaluationResult.fromMap(data, isOffline: false);
      } else {
        debugPrint('AI API trả về lỗi status ${response.statusCode}: ${response.body}');
        return PlantPresetManager.evaluateOffline(sensor);
      }
    } catch (e) {
      debugPrint('AI API Timeout / Offline (API Server đang Sleep): $e');
      // Tự động kích hoạt Offline Evaluator đảm bảo app không bị gián đoạn cảnh báo
      return PlantPresetManager.evaluateOffline(sensor);
    }
  }
}
