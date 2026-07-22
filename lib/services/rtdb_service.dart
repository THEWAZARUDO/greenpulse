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

  /// Lấy 1 sensor cụ thể
  Stream<SensorData?> watchSingleSensor(String uid, String farmId, String sensorId) {
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
}
