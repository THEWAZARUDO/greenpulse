import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'farm_model.dart';

class PlantPresetManager {
  PlantPresetManager._();

  static final List<SensorThresholds> _presets = [];

  /// Tải danh sách cấu hình từ file assets/plant_presets.txt
  /// Hàm này được gọi 1 lần khi khởi động app (trong main.dart)
  static Future<void> loadPresets() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/plant_presets.txt',
      );
      final List<dynamic> data = json.decode(response);
      _presets.clear();
      _presets.addAll(
        data.map(
          (item) => SensorThresholds.fromMap(
            Map<String, dynamic>.from(item as Map),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Lỗi khi tải plant_presets.txt: $e');
      if (_presets.isEmpty) {
        _presets.add(
          const SensorThresholds(
            plantName: 'Cà phê vối',
            minTemp: 24.0,
            maxTemp: 30.0,
            minHumidity: 80.0,
            maxHumidity: 85.0,
            minSoil: 26.0,
            maxSoil: 28.0,
            minLight: 1000.0,
            maxLight: 2000.0,
          ),
        );
      }
    }
  }

  /// Trả về toàn bộ danh sách các cây đang có trong hệ thống
  static List<SensorThresholds> get presets => _presets;

  /// Lấy cấu hình ngưỡng dựa theo tên cây
  static SensorThresholds? getPresetByName(String plantName) {
    try {
      return _presets.firstWhere((p) => p.plantName == plantName);
    } catch (_) {
      return null;
    }
  }
}
