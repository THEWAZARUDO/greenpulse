import 'package:firebase_database/firebase_database.dart';
import '../models/farm_model.dart';
import '../models/fuzzy_logic_engine.dart';
import 'notification_service.dart';

/// Service tương tác trực tiếp với Firebase Realtime Database.
/// 
/// Đọc/Ghi dữ liệu cảm biến nông trại chuẩn Realtime, 
/// loại bỏ hoàn toàn các luồng kiểm tra API/Server AI rườm rà.
class RTDBService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  /// Stream dữ liệu cảm biến của 1 Nông trại từ Realtime Database.
  Stream<List<SensorData>> watchSensors(
    String uid,
    String farmId, {
    String farmName = 'Nông trại',
  }) {
    final ref = _db.ref('sensors/$uid/$farmId');
    ref.keepSynced(true);
    return ref.onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) {
        return <SensorData>[];
      }

      final dataMap = Map<String, dynamic>.from(snapshot.value as Map);
      final List<SensorData> sensors = [];

      dataMap.forEach((key, value) {
        if (value is Map) {
          final sensorData = Map<String, dynamic>.from(value);
          final raw = SensorData.fromMap(sensorData, id: key.toString());
          final aiResult = FuzzyLogicEngine.evaluate(raw);
          final enriched = raw.copyWith(aiEvaluation: aiResult);

          if (enriched.overallStatus != StatusLevel.normal) {
            NotificationService().processSensorAlerts(farmName, enriched);
          }
          sensors.add(enriched);
        }
      });

      return sensors;
    });
  }

  /// Lấy toàn bộ danh sách cảm biến của người dùng trên tất cả nông trại
  Stream<List<SensorData>> watchAllSensors(String uid) {
    final ref = _db.ref('sensors/$uid');
    ref.keepSynced(true);
    return ref.onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) {
        return <SensorData>[];
      }

      final dataMap = Map<String, dynamic>.from(snapshot.value as Map);
      final List<SensorData> allSensors = [];

      dataMap.forEach((farmId, farmValue) {
        if (farmValue is Map) {
          final sensorsMap = Map<String, dynamic>.from(farmValue);
          sensorsMap.forEach((sensorId, sensorValue) {
            if (sensorValue is Map) {
              final sensorData = Map<String, dynamic>.from(sensorValue);
              sensorData['__farmId'] = farmId.toString();
              final raw = SensorData.fromMap(sensorData, id: sensorId.toString());
              final aiResult = FuzzyLogicEngine.evaluate(raw);
              allSensors.add(raw.copyWith(aiEvaluation: aiResult));
            }
          });
        }
      });

      return allSensors;
    });
  }

  /// Lấy dữ liệu 1 cảm biến cụ thể theo thời gian thực
  Stream<SensorData?> watchSingleSensor(
    String uid,
    String farmId,
    String sensorId,
  ) {
    final ref = _db.ref('sensors/$uid/$farmId/$sensorId');
    ref.keepSynced(true);
    return ref.onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) {
        return null;
      }
      final dataMap = Map<String, dynamic>.from(snapshot.value as Map);
      final rawSensor = SensorData.fromMap(dataMap, id: sensorId);
      final aiResult = FuzzyLogicEngine.evaluate(rawSensor);
      return rawSensor.copyWith(aiEvaluation: aiResult);
    });
  }

  /// Thêm hoặc Cập nhật Cảm biến lên Realtime Database
  Future<void> addOrUpdateSensor(
    String uid,
    String farmId,
    String sensorId,
    SensorData data,
  ) async {
    final ref = _db.ref('sensors/$uid/$farmId/${sensorId.trim()}');
    await ref.set(data.toMap());
  }

  /// Xóa 1 Cảm biến
  Future<void> deleteSensor(String uid, String farmId, String sensorId) async {
    final ref = _db.ref('sensors/$uid/$farmId/$sensorId');
    await ref.remove();
  }

  /// Xóa toàn bộ Cảm biến của một Nông trại
  Future<void> deleteFarmData(String uid, String farmId) async {
    final ref = _db.ref('sensors/$uid/$farmId');
    await ref.remove();
  }

  /// Cập nhật loại cây (cropId) và giai đoạn sinh trưởng (stageId) cho cảm biến
  Future<void> updateSensorCropAndStage(
    String uid,
    String farmId,
    String sensorId,
    String cropId, {
    int stageId = 1,
  }) async {
    final ref = _db.ref('sensors/$uid/$farmId/$sensorId');
    await ref.update({'cropId': cropId, 'stageId': stageId});
  }
}
