import 'package:firebase_database/firebase_database.dart';
import '../models/farm_model.dart';
import '../services/ai_api_service.dart';
import '../services/notification_service.dart';

class RTDBService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  /// Stream dữ liệu của các sensors trong 1 farm từ Realtime Database,
  /// tự động ENRICH dữ liệu qua AI Service (hoặc Offline Fallback Evaluator) SONG SONG (Future.wait)
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

      // ENRICH SONG SONG (Parallel Execution via Future.wait)
      final enrichedSensors = await Future.wait(
        rawSensors.map((rawSensor) async {
          final aiResult = await AiApiService.evaluateSensor(rawSensor);
          final enriched = rawSensor.copyWith(aiEvaluation: aiResult);

          if (enriched.overallStatus != StatusLevel.normal) {
            NotificationService().processSensorAlerts(
              farmName,
              enriched,
            );
          }
          return enriched;
        }),
      );

      return enrichedSensors;
    });
  }

  /// Lấy toàn bộ sensors của người dùng trên tất cả farms (đã qua ENRICH AI song song)
  Stream<List<SensorData>> watchAllSensors(String uid) {
    final ref = _db.ref('sensors/$uid');
    return ref.onValue.asyncMap((event) async {
      final snapshot = event.snapshot;
      final List<SensorData> allSensors = [];
      if (!snapshot.exists || snapshot.value == null) {
        return allSensors;
      }

      final dataMap = Map<String, dynamic>.from(snapshot.value as Map);
      final List<SensorData> rawSensors = [];

      dataMap.forEach((farmId, farmValue) {
        if (farmValue is Map) {
          final sensorsMap = Map<String, dynamic>.from(farmValue);
          sensorsMap.forEach((sensorId, sensorValue) {
            if (sensorValue is Map) {
              final sensorData = Map<String, dynamic>.from(sensorValue);
              sensorData['__farmId'] = farmId.toString();
              rawSensors.add(SensorData.fromMap(sensorData, id: sensorId.toString()));
            }
          });
        }
      });

      final enrichedSensors = await Future.wait(
        rawSensors.map((rawSensor) async {
          final aiResult = await AiApiService.evaluateSensor(rawSensor);
          return rawSensor.copyWith(aiEvaluation: aiResult);
        }),
      );

      return enrichedSensors;
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
