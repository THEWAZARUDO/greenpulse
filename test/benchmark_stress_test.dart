// ignore_for_file: avoid_print
import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:greenpulse/models/farm_model.dart';
import 'package:greenpulse/models/fuzzy_logic_engine.dart';


void main() {
  test('Stress Test & Benchmark: 20,000 Fuzzy Logic Evaluations', () {
    const int iterations = 20000;
    final random = math.Random(42);

    final testSensors = List.generate(iterations, (i) {
      return SensorData(
        id: 'sensor_$i',
        temperature: 15.0 + random.nextDouble() * 30.0,
        humidity: 30.0 + random.nextDouble() * 65.0,
        soil: 10.0 + random.nextDouble() * 85.0,
        light: 10000.0 + random.nextDouble() * 90000.0,
        ph: 4.0 + random.nextDouble() * 4.5,
        cropId: i % 2 == 0 ? 'sau_rieng' : 'ca_phe',
        stageId: (i % 3) + 1,
      );
    });

    // Warmup
    for (int i = 0; i < 1000; i++) {
      FuzzyLogicEngine.evaluate(testSensors[i]);
    }

    final stopwatch = Stopwatch()..start();

    int normalCount = 0;
    int warningCount = 0;
    int dangerCount = 0;

    for (int i = 0; i < iterations; i++) {
      final result = FuzzyLogicEngine.evaluate(testSensors[i]);
      if (result.riskScore >= 50.0) {
        dangerCount++;
      } else if (result.riskScore >= 25.0) {
        warningCount++;
      } else {
        normalCount++;
      }
    }

    stopwatch.stop();
    final elapsedMs = stopwatch.elapsedMilliseconds;
    final elapsedMicro = stopwatch.elapsedMicroseconds;
    final opsPerSec = (iterations / (elapsedMs / 1000.0)).round();
    final avgLatencyUs = (elapsedMicro / iterations).toStringAsFixed(2);

    print('\n===============================================================');
    print('GREENPULSE STRESS TEST / BENCHMARK RESULTS:');
    print(' - Tổng số lần đánh giá: $iterations phép suy diễn');
    print(' - Thời gian thực thi: $elapsedMs ms');

    print(' - Tốc độ xử lý (Throughput): $opsPerSec phép tính/giây');
    print(' - Độ trễ trung bình mỗi lần: $avgLatencyUs µs (microsecond)');
    print(' - Phân bổ: Normal=$normalCount, Warning=$warningCount, Danger=$dangerCount');
    print('===============================================================\n');

    expect(iterations, equals(20000));
    expect(opsPerSec, greaterThan(1000));
  });
}
