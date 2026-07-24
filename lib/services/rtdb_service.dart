import 'package:firebase_database/firebase_database.dart';
import '../models/farm_model.dart';
import '../services/ai_api_service.dart';
import '../services/notification_service.dart';

class RTDBService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  /// Stream dữ liệu của các sensors trong 1 farm từ Realtime Database,
  /// tự động ENRICH dữ liệu qua AI Service (hoặc Offline Fallback Evaluator)
  /// và phát Push Notification nếu phát hiện nguy hiểm/cảnh báo.
  Stream<List<SensorData>> watchSensors(String uid, String farmId, {String farmName = 'Nông trại'}) {
    final ref = _db.ref('sensors/$uid/$farmId');
    return ref.onValue.asyncMap((event) async {
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) {
        return <SensorData>[];
      }

      final dataMap = Map<String, dynamic>.from(snapshot.value as Map);
      final List<SensorData> rawSensors = [];

      dataMap.forEach((key, value) {
        if (value is Map) {
          final sensorData = Map<String, dynamic>.from(value);
          rawSensors.add(SensorData.fromMap(sensorData, id: key.toString()));
        }
      });

      // ENRICH: Gửi từng cảm biến qua AI Service để tính toán aiEvaluation
      final List<SensorData> enrichedSensors = [];
      for (final rawSensor in rawSensors) {
        final aiResult = await AiApiService.evaluateSensor(rawSensor);
        final enrichedSensor = rawSensor.copyWith(aiEvaluation: aiResult);
        enrichedSensors.add(enrichedSensor);

        // Tự động kiểm tra và phát Push Notification nếu có cảnh báo nguy hiểm
        if (enrichedSensor.overallStatus != StatusLevel.normal) {
          NotificationService().processSensorAlerts(
            farmName,
            enrichedSensor,
          );
        }
      }

      return enrichedSensors;
    });
  }

  /// Lấy toàn bộ sensors của người dùng trên tất cả farms (đã qua ENRICH AI)
  Stream<List<SensorData>> watchAllSensors(String uid) {
    final ref = _db.ref('sensors/$uid');
    return ref.onValue.asyncMap((event) async {
      final snapshot = event.snapshot;
      final List<SensorData> allSensors = [];
      if (!snapshot.exists || snapshot.value == null) {
        return allSensors;
      }

      final dataMap = Map<String, dynamic>.from(snapshot.value as Map);
      for (final farmEntry in dataMap.entries) {
        final farmId = farmEntry.key.toString();
        if (farmEntry.value is Map) {
          final sensorsMap = Map<String, dynamic>.from(farmEntry.value as Map);
          for (final sensorEntry in sensorsMap.entries) {
            if (sensorEntry.value is Map) {
              final sensorData = Map<String, dynamic>.from(sensorEntry.value as Map);
              sensorData['__farmId'] = farmId;
              final rawSensor = SensorData.fromMap(sensorData, id: sensorEntry.key.toString());
              final aiResult = await AiApiService.evaluateSensor(rawSensor);
              allSensors.add(rawSensor.copyWith(aiEvaluation: aiResult));
            }
          }
        }
      }

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
    return ref.onValue.asyncMap((event) async {
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) {
        return null;
      }
      final dataMap = Map<String, dynamic>.from(snapshot.value as Map);
      final rawSensor = SensorData.fromMap(dataMap, id: sensorId);
      final aiResult = await AiApiService.evaluateSensor(rawSensor);
      return rawSensor.copyWith(aiEvaluation: aiResult);
    });
  }

  /// Thêm hoặc Cập nhật Cảm biến
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
