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

  static String baseUrl = 'https://greenpulse-ai-26gw.onrender.com';

  // Trạng thái đang gửi ping thức dậy cho Render.com (Cold Start ~50s)
  static bool isWakingUp = false;
  static final StreamController<void> _refreshNotifier = StreamController<void>.broadcast();
  static Stream<void> get onRefreshNeeded => _refreshNotifier.stream;

  // Cache kết quả đánh giá Mờ trong bộ nhớ tránh trùng lặp request giữa các Tab
  static final Map<String, _CacheEntry> _cache = {};

  // Circuit Breaker: Thời điểm xảy ra lỗi/timeout gần nhất
  static DateTime? _lastFailureTime;
  static const Duration _circuitBreakerDuration = Duration(seconds: 30);

  static String _getCacheKey(SensorData sensor) {
    return '${sensor.id}_${sensor.cropId}_${sensor.stageId}_${sensor.temperature}_${sensor.humidity}_${sensor.soil}_${sensor.light}_${sensor.ph}';
  }

  /// Kiểm tra xem cảm biến đã có kết quả cache hợp lệ chưa
  static bool hasValidCache(SensorData sensor) {
    final cacheKey = _getCacheKey(sensor);
    return _cache.containsKey(cacheKey) && _cache[cacheKey]!.isValid;
  }

  /// Trả về cảm biến với kết quả đánh giá tức thì 0ms (Cache hoặc Offline Evaluator)
  static SensorData evaluateFast(SensorData sensor) {
    final cacheKey = _getCacheKey(sensor);
    if (_cache.containsKey(cacheKey) && _cache[cacheKey]!.isValid) {
      return sensor.copyWith(aiEvaluation: _cache[cacheKey]!.result);
    }
    final offlineRes = PlantPresetManager.evaluateOffline(sensor);
    return sensor.copyWith(aiEvaluation: offlineRes);
  }

  /// Tự động gửi request với timeout dài (70s) ở background để thức dậy Render.com (Cold Start)
  static void triggerBackgroundWakeUp(SensorData sensor) {
    if (isWakingUp) return;
    isWakingUp = true;
    _refreshNotifier.add(null);

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

    http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(payload),
        )
        .timeout(const Duration(seconds: 70))
        .then((response) {
      isWakingUp = false;
      if (response.statusCode == 200) {
        debugPrint('Render.com AI Server đã thức dậy thành công!');
        _lastFailureTime = null;
        final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        final result = AiEvaluationResult.fromMap(data, isOffline: false);
        final cacheKey = _getCacheKey(sensor);
        _cache[cacheKey] = _CacheEntry(result: result, timestamp: DateTime.now());
        _refreshNotifier.add(null);
      } else {
        _refreshNotifier.add(null);
      }
    }).catchError((e) {
      isWakingUp = false;
      debugPrint('Không thể thức dậy Render.com Server: $e');
      _refreshNotifier.add(null);
    });
  }

  /// Gửi dữ liệu cảm biến tới Python Fuzzy AI Service.
  static Future<AiEvaluationResult> evaluateSensor(SensorData sensor) async {
    final cacheKey = _getCacheKey(sensor);

    // 1. Trả về kết quả từ Cache nếu còn hiệu lực
    if (_cache.containsKey(cacheKey) && _cache[cacheKey]!.isValid) {
      return _cache[cacheKey]!.result;
    }

    // 2. Circuit Breaker: Nếu AI Server vừa bị lỗi trong 30s gần đây -> Trả về Offline lập tức 0ms & Thức dậy Render
    if (_lastFailureTime != null &&
        DateTime.now().difference(_lastFailureTime!) < _circuitBreakerDuration) {
      triggerBackgroundWakeUp(sensor);
      final offlineRes = PlantPresetManager.evaluateOffline(sensor);
      _cache[cacheKey] = _CacheEntry(
        result: offlineRes,
        timestamp: DateTime.now(),
      );
      return offlineRes;
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
          .timeout(const Duration(milliseconds: 1500));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            json.decode(utf8.decode(response.bodyBytes));
        final result = AiEvaluationResult.fromMap(data, isOffline: false);

        // Reset Circuit Breaker khi kết nối thành công
        _lastFailureTime = null;
        isWakingUp = false;

        _cache[cacheKey] = _CacheEntry(
          result: result,
          timestamp: DateTime.now(),
        );

        return result;
      } else {
        _lastFailureTime = DateTime.now();
        triggerBackgroundWakeUp(sensor);
        final offlineRes = PlantPresetManager.evaluateOffline(sensor);
        _cache[cacheKey] = _CacheEntry(
          result: offlineRes,
          timestamp: DateTime.now(),
        );
        return offlineRes;
      }
    } catch (e) {
      debugPrint('AI API Timeout (Gửi background wake-up cho Render.com): $e');
      _lastFailureTime = DateTime.now();
      triggerBackgroundWakeUp(sensor);
      final offlineRes = PlantPresetManager.evaluateOffline(sensor);
      _cache[cacheKey] = _CacheEntry(
        result: offlineRes,
        timestamp: DateTime.now(),
      );
      return offlineRes;
    }
  }
}


