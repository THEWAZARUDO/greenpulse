import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/ai_evaluation_model.dart';
import '../models/farm_model.dart';
import '../models/plant_preset_manager.dart';

class _CacheEntry {
  final AiEvaluationResult result;
  final DateTime timestamp;

  _CacheEntry({required this.result, required this.timestamp});

  bool get isValid => DateTime.now().difference(timestamp).inSeconds < 15;
}

class AiApiService {
  AiApiService._();

  // Mặc định URL API AI khi test local / Android Emulator hoặc Cloud VPS
  static String baseUrl = 'http://10.0.2.2:8000';

  // Cache kết quả đánh giá Mờ trong bộ nhớ tránh trùng lặp request giữa các Tab
  static final Map<String, _CacheEntry> _cache = {};

  /// Gửi dữ liệu cảm biến tới Python Fuzzy AI Service.
  /// Tự động sử dụng In-Memory Cache (15s) nếu thông số cảm biến chưa thay đổi,
  /// và dùng Offline Fallback Evaluator nếu API timeout (>4s).
  static Future<AiEvaluationResult> evaluateSensor(SensorData sensor) async {
    final cacheKey =
        '${sensor.id}_${sensor.cropId}_${sensor.stageId}_${sensor.temperature}_${sensor.humidity}_${sensor.soil}_${sensor.light}_${sensor.ph}';

    // 1. Trả về kết quả từ Cache nếu còn hiệu lực (giảm 75% API calls trùng lặp)
    if (_cache.containsKey(cacheKey) && _cache[cacheKey]!.isValid) {
      return _cache[cacheKey]!.result;
    }

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
        final Map<String, dynamic> data =
            json.decode(utf8.decode(response.bodyBytes));
        final result = AiEvaluationResult.fromMap(data, isOffline: false);

        // Lưu vào Cache
        _cache[cacheKey] = _CacheEntry(
          result: result,
          timestamp: DateTime.now(),
        );

        return result;
      } else {
        debugPrint('AI API trả về lỗi status ${response.statusCode}: ${response.body}');
        final offlineRes = PlantPresetManager.evaluateOffline(sensor);
        _cache[cacheKey] = _CacheEntry(
          result: offlineRes,
          timestamp: DateTime.now(),
        );
        return offlineRes;
      }
    } catch (e) {
      debugPrint('AI API Timeout / Offline: $e');
      final offlineRes = PlantPresetManager.evaluateOffline(sensor);
      _cache[cacheKey] = _CacheEntry(
        result: offlineRes,
        timestamp: DateTime.now(),
      );
      return offlineRes;
    }
  }
}
