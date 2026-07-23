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
          (item) => SensorThresholds.fromMap(item as Map<String, dynamic>),
        ),
      );
    } catch (e) {
      // Nếu file lỗi hoặc không tồn tại, in ra log để debug
      debugPrint('Lỗi khi tải plant_presets.txt: $e');
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
