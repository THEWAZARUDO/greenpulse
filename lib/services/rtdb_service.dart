import 'package:firebase_database/firebase_database.dart';
import '../models/farm_model.dart';
import '../services/ai_api_service.dart';
import '../services/notification_service.dart';

class RTDBService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  // Shared Broadcast Stream Cache: Đảm bảo cả 4 Tab chỉ chia sẻ duy nhất 1 Stream kết nối tới RTDB per Farm
  static final Map<String, Stream<List<SensorData>>> _sensorStreamsCache = {};
  static final Map<String, Stream<List<SensorData>>> _allSensorsStreamsCache = {};
  static final Map<String, Stream<SensorData?>> _singleSensorStreamsCache = {};

  /// Stream dữ liệu của các sensors trong 1 farm từ Realtime Database.
  /// Sử dụng Shared Broadcast Stream Cache để loại bỏ 100% việc tạo Stream và gọi AI đúp giữa các Tab.
  Stream<List<SensorData>> watchSensors(String uid, String farmId, {String farmName = 'Nông trại'}) {
    final cacheKey = '${uid}_$farmId';
    if (_sensorStreamsCache.containsKey(cacheKey)) {
      return _sensorStreamsCache[cacheKey]!;
    }

    final ref = _db.ref('sensors/$uid/$farmId');
    final stream = ref.onValue.asyncMap((event) async {
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
    }).asBroadcastStream();

    _sensorStreamsCache[cacheKey] = stream;
    return stream;
  }

  /// Lấy toàn bộ sensors của người dùng trên tất cả farms (đã qua Broadcast Stream Cache)
  Stream<List<SensorData>> watchAllSensors(String uid) {
    final cacheKey = 'all_$uid';
    if (_allSensorsStreamsCache.containsKey(cacheKey)) {
      return _allSensorsStreamsCache[cacheKey]!;
    }

    final ref = _db.ref('sensors/$uid');
    final stream = ref.onValue.asyncMap((event) async {
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
    }).asBroadcastStream();

    _allSensorsStreamsCache[cacheKey] = stream;
    return stream;
  }

  /// Lấy 1 sensor cụ thể
  Stream<SensorData?> watchSingleSensor(
    String uid,
    String farmId,
    String sensorId,
  ) {
    final cacheKey = '${uid}_${farmId}_$sensorId';
    if (_singleSensorStreamsCache.containsKey(cacheKey)) {
      return _singleSensorStreamsCache[cacheKey]!;
    }

    final ref = _db.ref('sensors/$uid/$farmId/$sensorId');
    final stream = ref.onValue.asyncMap((event) async {
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) {
        return null;
      }
      final dataMap = Map<String, dynamic>.from(snapshot.value as Map);
      final rawSensor = SensorData.fromMap(dataMap, id: sensorId);
      final aiResult = await AiApiService.evaluateSensor(rawSensor);
      return rawSensor.copyWith(aiEvaluation: aiResult);
    }).asBroadcastStream();

    _singleSensorStreamsCache[cacheKey] = stream;
    return stream;
  }

  /// Xóa cache stream khi người dùng đăng xuất hoặc cấu hình lại
  static void clearStreamCache() {
    _sensorStreamsCache.clear();
    _allSensorsStreamsCache.clear();
    _singleSensorStreamsCache.clear();
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
