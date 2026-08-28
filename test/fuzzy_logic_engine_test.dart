import 'package:flutter_test/flutter_test.dart';
import 'package:greenpulse/models/crop_preset_model.dart';
import 'package:greenpulse/models/farm_model.dart';
import 'package:greenpulse/models/fuzzy_logic_engine.dart';
import 'package:greenpulse/models/plant_preset_manager.dart';

void main() {
  group('FuzzyLogicEngine Tests', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    test('Evaluates normal sensor values as Normal status with low risk score', () {
      const normalSensor = SensorData(
        temperature: 26.0,
        humidity: 75.0,
        soil: 70.0,
        light: 60000.0,
        ph: 6.0,
        cropId: 'sau_rieng',
        stageId: 1,
      );

      final result = FuzzyLogicEngine.evaluate(normalSensor);

      expect(result.overallStatus, equals(StatusLevel.normal));
      expect(result.isAlertTriggered, isFalse);
      expect(result.riskScore, lessThan(35.0));
      expect(result.paramStatuses['temperature'], equals(StatusLevel.normal));
      expect(result.paramStatuses['soil'], equals(StatusLevel.normal));
    });

    test('Detects dry soil and triggers warning/danger alert with irrigation advice', () {
      const drySoilSensor = SensorData(
        temperature: 27.0,
        humidity: 75.0,
        soil: 25.0,
        light: 55000.0,
        ph: 6.0,
        cropId: 'ca_phe',
        stageId: 2,
      );

      final result = FuzzyLogicEngine.evaluate(drySoilSensor);

      expect(result.isAlertTriggered, isTrue);
      expect(result.paramStatuses['soil'], isNot(equals(StatusLevel.normal)));
      expect(result.adviceList.any((a) => a.contains('Độ ẩm đất') || a.contains('tưới nước')), isTrue);
    });

    test('Detects extreme temperature and acidic pH generating proper advice', () {
      const extremeSensor = SensorData(
        temperature: 42.0,
        humidity: 40.0,
        soil: 65.0,
        light: 95000.0,
        ph: 4.0,
        cropId: 'sau_rieng',
        stageId: 2,
      );

      final result = FuzzyLogicEngine.evaluate(extremeSensor);

      expect(result.overallStatus, equals(StatusLevel.danger));
      expect(result.isAlertTriggered, isTrue);
      expect(result.riskScore, greaterThanOrEqualTo(50.0));
      expect(result.paramStatuses['temperature'], equals(StatusLevel.danger));
      expect(result.paramStatuses['ph'], isNot(equals(StatusLevel.normal)));
      expect(result.adviceList.any((a) => a.contains('Đất bị chua')), isTrue);
      expect(result.adviceList.any((a) => a.contains('Nhiệt độ')), isTrue);
    });

    test('PlantPresetManager evaluateOffline operates without network and generates accurate status', () {
      const sensor = SensorData(
        temperature: 38.0,
        humidity: 80.0,
        soil: 70.0,
        light: 60000.0,
        ph: 6.0,
        cropId: 'sau_rieng',
        stageId: 1,
      );

      final result = PlantPresetManager.evaluateOffline(sensor);

      expect(result.isOfflineFallback, isTrue);
      expect(result.paramStatuses['temperature'], isNot(equals(StatusLevel.normal)));
    });
  });

  group('FarmModel & CropModel Serialization Tests', () {
    test('FarmModel serializes correctly to map', () {
      const farm = FarmModel(
        id: 'farm_001',
        name: 'Vườn Sầu Riêng Ea Kar',
        locationName: 'Ea Kar, Đắk Lắk',
        latitude: 12.8082,
        longitude: 108.4490,
      );

      final map = farm.toMap();
      expect(map['name'], equals('Vườn Sầu Riêng Ea Kar'));
      expect(map['locationName'], equals('Ea Kar, Đắk Lắk'));
      expect(map['latitude'], equals(12.8082));
      expect(map['longitude'], equals(108.4490));
    });

    test('CropModel and GrowthStage properties and lookups work properly', () {
      const stage = GrowthStage(
        stageId: 1,
        stageName: 'Ra hoa - Đậu trái',
        tempMin: 22.0,
        tempMax: 30.0,
        airHumidityMin: 60.0,
        airHumidityMax: 80.0,
        soilMoistureMin: 55.0,
        soilMoistureMax: 70.0,
        luxMin: 40000.0,
        luxMax: 70000.0,
        notes: 'Giai đoạn nhạy cảm độ ẩm',
      );

      const crop = CropModel(
        cropId: 'ca_phe',
        cropName: 'Cà phê Robusta',
        soilPhMin: 5.5,
        soilPhMax: 6.5,
        growthStages: [stage],
      );

      expect(crop.cropName, equals('Cà phê Robusta'));
      expect(crop.getStageById(1).stageName, equals('Ra hoa - Đậu trái'));
      expect(crop.getStageById(99).stageId, equals(1)); // Fallback to first stage
    });
  });
}
