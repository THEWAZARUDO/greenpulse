import 'package:flutter_test/flutter_test.dart';
import 'package:greenpulse/models/farm_model.dart';
import 'package:greenpulse/models/fuzzy_logic_engine.dart';


void main() {
  group('Chaos & Edge Cases Tests: SensorData Parsing', () {
    test('Handles String numbers, commas, and whitespace gracefully without throwing', () {
      final chaosMap = {
        'temperature': ' 29.8 ',
        'humidity': '80,5', // Số kiểu Châu Âu dùng dấu phẩy
        'soil': 65,         // int thay vì double
        'light': '62000',
        'ph': '6.4',
        'cropId': 'sau_rieng',
        'stageId': '2',     // String id
      };

      final sensor = SensorData.fromMap(chaosMap, id: 'chaos_01');

      expect(sensor.temperature, equals(29.8));
      expect(sensor.humidity, equals(80.5));
      expect(sensor.soil, equals(65.0));
      expect(sensor.light, equals(62000.0));
      expect(sensor.ph, equals(6.4));
      expect(sensor.stageId, equals(2));
      expect(sensor.hasTemperature, isTrue);
      expect(sensor.hasHumidity, isTrue);
      expect(sensor.hasSoil, isTrue);
      expect(sensor.isSensorOnline, isTrue);
    });

    test('Handles null and missing fields without forcing 0.0 or crashing', () {
      final missingMap = {
        'soil': 45.0, // Chỉ có độ ẩm đất
      };

      final sensor = SensorData.fromMap(missingMap, id: 'missing_01');

      expect(sensor.soil, equals(45.0));
      expect(sensor.hasSoil, isTrue);
      expect(sensor.hasTemperature, isFalse);
      expect(sensor.hasHumidity, isFalse);
      expect(sensor.hasLight, isFalse);
      expect(sensor.hasPh, isFalse);
      expect(sensor.isSensorOnline, isTrue);
    });

    test('Handles completely empty Map as offline sensor', () {
      final emptyMap = <String, dynamic>{};
      final sensor = SensorData.fromMap(emptyMap, id: 'empty_01');

      expect(sensor.isSensorOnline, isFalse);
      expect(sensor.hasTemperature, isFalse);
      expect(sensor.hasSoil, isFalse);

      final result = FuzzyLogicEngine.evaluate(sensor);
      expect(result.overallStatus, equals(StatusLevel.normal));
      expect(result.riskScore, equals(0.0));
      expect(result.isAlertTriggered, isFalse);
    });

    test('Handles invalid garbage types in fields without crashing', () {
      final garbageMap = {
        'temperature': ['invalid', 'list'],
        'humidity': {'nested': 'object'},
        'soil': true,
        'light': 'invalid_string_not_a_number',
      };

      final sensor = SensorData.fromMap(garbageMap, id: 'garbage_01');

      expect(sensor.hasTemperature, isFalse);
      expect(sensor.hasHumidity, isFalse);
      expect(sensor.hasSoil, isFalse);
      expect(sensor.hasLight, isFalse);
      expect(sensor.isSensorOnline, isFalse);
    });
  });

  group('Chaos & Edge Cases Tests: Fuzzy Logic Resilience', () {
    test('Fuzzy evaluation with partial missing sensors dynamically normalizes active weights', () {
      // Cảm biến mất nhiệt độ và ánh sáng, chỉ có đất quá khô (20%)
      const partialSensor = SensorData(
        soil: 20.0,
        humidity: 75.0,
        ph: 6.0,
        temperature: 0.0,
        light: 0.0,
        hasSoil: true,
        hasHumidity: true,
        hasPh: true,
        hasTemperature: false, // Mất tín hiệu
        hasLight: false,       // Mất tín hiệu
        cropId: 'ca_phe',
        stageId: 1,
      );

      final result = FuzzyLogicEngine.evaluate(partialSensor);

      // Không đánh giá nhiệt độ là 0 độ C
      expect(result.paramStatuses.containsKey('temperature'), isFalse);
      expect(result.paramStatuses['soil'], isNot(equals(StatusLevel.normal)));
      expect(result.isAlertTriggered, isTrue);
      expect(result.adviceList.any((a) => a.contains('Độ ẩm đất')), isTrue);
    });

    test('Extreme boundary stress: All values extreme high or low', () {
      const extremeMaxSensor = SensorData(
        temperature: 120.0,
        humidity: 150.0,
        soil: 100.0,
        light: 200000.0,
        ph: 14.0,
        cropId: 'sau_rieng',
        stageId: 1,
      );

      final result = FuzzyLogicEngine.evaluate(extremeMaxSensor);

      expect(result.overallStatus, equals(StatusLevel.danger));
      expect(result.riskScore, greaterThan(60.0));
      expect(result.isAlertTriggered, isTrue);
    });
  });
}
