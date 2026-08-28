// ignore_for_file: avoid_print
import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:greenpulse/models/farm_model.dart';
import 'package:greenpulse/models/plant_preset_manager.dart';


double evaluateWithN(SensorData duLieuCamBien, int soBuocChia) {
  final cayTrong = PlantPresetManager.getCropById(duLieuCamBien.cropId);
  final giaiDoan = cayTrong?.getStageById(duLieuCamBien.stageId);

  final phToiThieu = cayTrong?.soilPhMin ?? 5.5;
  final phToiDa = cayTrong?.soilPhMax ?? 6.5;
  final nhietDoToiThieu = giaiDoan?.tempMin ?? 24.0;
  final nhietDoToiDa = giaiDoan?.tempMax ?? 30.0;
  final doAmKhongKhiToiThieu = giaiDoan?.airHumidityMin ?? 70.0;
  final doAmKhongKhiToiDa = giaiDoan?.airHumidityMax ?? 85.0;
  final doAmDatToiThieu = giaiDoan?.soilMoistureMin ?? 60.0;
  final doAmDatToiDa = giaiDoan?.soilMoistureMax ?? 80.0;
  final anhSangToiThieu = giaiDoan?.luxMin ?? 50000.0;
  final anhSangToiDa = giaiDoan?.luxMax ?? 80000.0;

  MapEntry<double, String> tinhDoLech(double val, double min, double max) {
    if (val < min) return MapEntry(((min - val) / (max - min)).clamp(0.0, 2.0), 'thap');
    if (val > max) return MapEntry(((val - max) / (max - min)).clamp(0.0, 2.0), 'cao');
    return const MapEntry(0.0, 'binh_thuong');
  }

  Map<String, double> moHoa(double d) {
    double hthang(double x, double a, double b, double c, double d) {
      if (a == b && x <= b) return 1.0;
      if (c == d && x >= c) return 1.0;
      if (x <= a || x >= d) return 0.0;
      if (x >= b && x <= c) return 1.0;
      if (x > a && x < b) return (x - a) / (b - a);
      if (x > c && x < d) return (d - x) / (d - c);
      return 0.0;
    }
    double tgiac(double x, double a, double b, double c) {
      if (x <= a || x >= c) return 0.0;
      if (x == b) return 1.0;
      if (x > a && x < b) return (x - a) / (b - a);
      return (c - x) / (c - b);
    }
    return {
      'binh_thuong': hthang(d, 0.0, 0.0, 0.10, 0.25),
      'canh_bao': tgiac(d, 0.15, 0.45, 0.75),
      'nguy_hiem': hthang(d, 0.55, 0.85, 2.0, 2.0),
    };
  }

  final danhSachDoLech = <String, MapEntry<double, String>>{
    'ph': tinhDoLech(duLieuCamBien.ph, phToiThieu, phToiDa),
    'temperature': tinhDoLech(duLieuCamBien.temperature, nhietDoToiThieu, nhietDoToiDa),
    'humidity': tinhDoLech(duLieuCamBien.humidity, doAmKhongKhiToiThieu, doAmKhongKhiToiDa),
    'soil': tinhDoLech(duLieuCamBien.soil, doAmDatToiThieu, doAmDatToiDa),
    'light': tinhDoLech(duLieuCamBien.light, anhSangToiThieu, anhSangToiDa),
  };

  final trongSoMap = {'soil': 0.25, 'temperature': 0.25, 'humidity': 0.20, 'ph': 0.15, 'light': 0.15};

  final luoiNguyCo = List<double>.generate(soBuocChia, (i) => i * (100.0 / (soBuocChia - 1)));
  final tapNguyCoTongHop = List<double>.filled(soBuocChia, 0.0);

  double hthang(double x, double a, double b, double c, double d) {
    if (x <= a || x >= d) return 0.0;
    if (x >= b && x <= c) return 1.0;
    if (x > a && x < b) return (x - a) / (b - a);
    return (d - x) / (d - c);
  }
  double tgiac(double x, double a, double b, double c) {
    if (x <= a || x >= c) return 0.0;
    if (x == b) return 1.0;
    if (x > a && x < b) return (x - a) / (b - a);
    return (c - x) / (c - b);
  }

  final hamThap = List<double>.generate(soBuocChia, (i) => hthang(luoiNguyCo[i], 0, 0, 20, 35));
  final hamMed = List<double>.generate(soBuocChia, (i) => tgiac(luoiNguyCo[i], 25, 50, 75));
  final hamCao = List<double>.generate(soBuocChia, (i) => hthang(luoiNguyCo[i], 65, 80, 100, 100));

  danhSachDoLech.forEach((k, v) {
    final tapMo = moHoa(v.key);
    final w = trongSoMap[k]!;
    final actLow = tapMo['binh_thuong']! * w;
    final actMed = tapMo['canh_bao']! * w;
    final actHigh = tapMo['nguy_hiem']! * w;

    for (int i = 0; i < soBuocChia; i++) {
      final cLow = math.min(actLow, hamThap[i]);
      final cMed = math.min(actMed, hamMed[i]);
      final cHigh = math.min(actHigh, hamCao[i]);
      final m = math.max(cLow, math.max(cMed, cHigh));
      tapNguyCoTongHop[i] = math.max(tapNguyCoTongHop[i], m);
    }
  });

  double tuSo = 0.0;
  double mauSo = 0.0;
  for (int i = 0; i < soBuocChia; i++) {
    tuSo += luoiNguyCo[i] * tapNguyCoTongHop[i];
    mauSo += tapNguyCoTongHop[i];
  }
  return mauSo > 0 ? (tuSo / mauSo) : 0.0;
}

void main() {
  test('Scientific Experiment: Comparing N grid discretization values', () {
    // Chuẩn bị 500 kịch bản cảm biến ngẫu nhiên
    final random = math.Random(12345);
    final testSensors = List.generate(500, (i) {
      return SensorData(
        id: 's_$i',
        temperature: 18.0 + random.nextDouble() * 25.0,
        humidity: 35.0 + random.nextDouble() * 60.0,
        soil: 15.0 + random.nextDouble() * 80.0,
        light: 15000.0 + random.nextDouble() * 80000.0,
        ph: 4.2 + random.nextDouble() * 3.8,
        cropId: 'sau_rieng',
        stageId: 1,
      );
    });

    // 1. Tính sai số so với Ground Truth (N = 100,000)
    const int groundTruthN = 100000;
    final groundTruthResults = testSensors.map((s) => evaluateWithN(s, groundTruthN)).toList();

    final nValues = [10, 50, 100, 200, 300, 500];
    print('\n===============================================================');
    print('📊 BẢNG KẾT QUẢ THỰC NGHIỆM SO SÁNH SAI SỐ THEO GIÁ TRỊ N (500 MẪU)');
    print('===============================================================');
    for (final n in nValues) {
      double totalAbsError = 0.0;
      double maxAbsError = 0.0;
      double totalRelErrorPercent = 0.0;

      for (int i = 0; i < testSensors.length; i++) {
        final approx = evaluateWithN(testSensors[i], n);
        final exact = groundTruthResults[i];
        final absErr = (approx - exact).abs();
        final relErr = (absErr / exact) * 100.0;

        totalAbsError += absErr;
        if (absErr > maxAbsError) maxAbsError = absErr;
        totalRelErrorPercent += relErr;
      }

      final avgAbsError = totalAbsError / testSensors.length;
      final avgRelError = totalRelErrorPercent / testSensors.length;

      print('N = ${n.toString().padRight(4)}: Sai số TB = ${avgAbsError.toStringAsFixed(5)} điểm (${avgRelError.toStringAsFixed(4)}%), Sai số max = ${maxAbsError.toStringAsFixed(5)} điểm');
    }

    // 2. Đo thời gian chạy thực nghiệm cho 20,000 lần lặp
    const int benchIterations = 20000;
    print('\n===============================================================');
    print('⚡ BẢNG KẾT QUẢ BENCHMARK THỜI GIAN VÀ TỐC ĐỘ (20,000 LẦN LẶP)');
    print('===============================================================');
    for (final n in [50, 100, 200, 300, 500]) {
      // Warmup
      for (int i = 0; i < 500; i++) {
        evaluateWithN(testSensors[i % testSensors.length], n);
      }

      final sw = Stopwatch()..start();
      for (int i = 0; i < benchIterations; i++) {
        evaluateWithN(testSensors[i % testSensors.length], n);
      }
      sw.stop();

      final ms = sw.elapsedMilliseconds;
      final microPerOp = (sw.elapsedMicroseconds / benchIterations).toStringAsFixed(2);
      final opsSec = (benchIterations / (ms / 1000.0)).round();

      print('N = ${n.toString().padRight(4)}: Tổng thời gian = ${ms.toString().padLeft(4)}ms | Tốc độ = ${opsSec.toString().padLeft(6)} ops/s | Độ trễ = ${microPerOp.toString().padLeft(6)} µs/lần');
    }
    print('===============================================================\n');

    expect(groundTruthResults.length, equals(500));
  });
}

