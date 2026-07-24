import 'package:firebase_database/firebase_database.dart';
import '../models/farm_model.dart';

class RTDBService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  /// Stream dữ liệu của các sensors trong 1 farm từ Realtime Database.
  /// Cấu trúc trên RTDB: sensors/{uid}/{farmId}/{sensorId} -> { data }
  Stream<List<SensorData>> watchSensors(String uid, String farmId) {
    final ref = _db.ref('sensors/$uid/$farmId');
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
          sensors.add(SensorData.fromMap(sensorData, id: key.toString()));
        }
      });

      return sensors;
    });
  }

  /// Lấy toàn bộ sensors của người dùng trên tất cả farms
  Stream<List<SensorData>> watchAllSensors(String uid) {
    final ref = _db.ref('sensors/$uid');
    return ref.onValue.map((event) {
      final snapshot = event.snapshot;
      final List<SensorData> allSensors = [];
      if (!snapshot.exists || snapshot.value == null) {
        return allSensors;
      }

      final dataMap = Map<String, dynamic>.from(snapshot.value as Map);
      dataMap.forEach((farmId, farmData) {
        if (farmData is Map) {
          final sensorsMap = Map<String, dynamic>.from(farmData);
          sensorsMap.forEach((sensorId, sensorValue) {
            if (sensorValue is Map) {
              final sensorData = Map<String, dynamic>.from(sensorValue);
              // Để đơn giản ta lưu tạm farmId vào trường extra nếu cần truy vết
              sensorData['__farmId'] = farmId.toString();
              allSensors.add(
                SensorData.fromMap(sensorData, id: sensorId.toString()),
              );
            }
          });
        }
      });
      return allSensors;
    });
  }

  /// Lấy 1 sensor cụ thể
  Stream<SensorData?> watchSingleSensor(
    String uid,
    String farmId,
    String sensorId,
  ) {
    final ref = _db.ref('sensors/$uid/$farmId/$sensorId');
    return ref.onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) {
        return null;
      }
      final dataMap = Map<String, dynamic>.from(snapshot.value as Map);
      return SensorData.fromMap(dataMap, id: sensorId);
    });
  }

  /// Thêm hoặc Cập nhật Cảm biến / Mạch ESP32
  Future<void> addOrUpdateSensor(
    String uid,
    String farmId,
    String sensorId,
    SensorData data,
  ) async {
    final ref = _db.ref('sensors/$uid/$farmId/${sensorId.trim()}');
    await ref.set(data.toMap());
  }

  /// Xóa Cảm biến
  Future<void> deleteSensor(String uid, String farmId, String sensorId) async {
    final ref = _db.ref('sensors/$uid/$farmId/$sensorId');
    await ref.remove();
  }

  /// Xóa toàn bộ Cảm biến của một Nông trại
  Future<void> deleteFarmData(String uid, String farmId) async {
    final ref = _db.ref('sensors/$uid/$farmId');
    await ref.remove();
  }

  /// Cập nhật loại cây (cropId) và giai đoạn sinh trưởng (stageId) cho một cảm biến
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
