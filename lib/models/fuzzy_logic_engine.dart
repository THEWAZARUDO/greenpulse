import 'dart:math' as math;
import 'plant_preset_manager.dart';
import 'ai_evaluation_model.dart';
import 'farm_model.dart';

/// Bộ máy AI Mờ (Fuzzy Logic Engine) viết thuần bằng Dart (Native Edge AI).
/// 
/// Thực hiện 100% các phép toán Tập Mờ (Fuzzy Sets):
///   1. Fuzzification / Mờ hóa (Độ thuộc hàm mờ Tam giác/Hình thang)
///   2. Rule Base Inference / Suy diễn luật mờ (Mamdani Min implication)
///   3. Aggregation / Hợp thành (Max composition)
///   4. Defuzzification / Giải mờ (Centroid / Trọng tâm 200 điểm)
class FuzzyLogicEngine {
  // Trọng số nông học cho 5 tham số
  static const Map<String, double> _trongSoThamSo = {
    'soil': 0.25,
    'temperature': 0.25,
    'humidity': 0.20,
    'ph': 0.15,
    'light': 0.15,
  };

  /// Hàm mờ Hình thang (Trapezoidal Membership Function)
  static double _hamMoHinhThang(double giaTri, double diemA, double diemB, double diemC, double diemD) {
    if (diemA == diemB && giaTri <= diemB) return 1.0;
    if (diemC == diemD && giaTri >= diemC) return 1.0;
    if (giaTri <= diemA || giaTri >= diemD) return 0.0;
    if (giaTri >= diemB && giaTri <= diemC) return 1.0;
    if (giaTri > diemA && giaTri < diemB) {
      return (giaTri - diemA) / (diemB - diemA);
    }
    if (giaTri > diemC && giaTri < diemD) {
      return (diemD - giaTri) / (diemD - diemC);
    }
    return 0.0;
  }

  /// Hàm mờ Tam giác (Triangular Membership Function)
  static double _hamMoTamGiac(double giaTri, double diemA, double diemB, double diemC) {
    if (giaTri <= diemA || giaTri >= diemC) return 0.0;
    if (giaTri == diemB) return 1.0;
    if (giaTri > diemA && giaTri < diemB) {
      if (diemB == diemA) return 1.0;
      return (giaTri - diemA) / (diemB - diemA);
    }
    if (giaTri > diemB && giaTri < diemC) {
      if (diemC == diemB) return 1.0;
      return (diemC - giaTri) / (diemC - diemB);
    }
    return 0.0;
  }

  /// Tính độ lệch (deviation) của chỉ số cảm biến so với khoảng [giaTriToiThieu, giaTriToiDa]
  static MapEntry<double, String> _tinhDoLechThamSo(
      double giaTri, double giaTriToiThieu, double giaTriToiDa) {
    if (giaTri >= giaTriToiThieu && giaTri <= giaTriToiDa) {
      return const MapEntry(0.0, 'binh_thuong');
    }

    double khoangBienDo = giaTriToiDa - giaTriToiThieu;
    if (khoangBienDo <= 0) {
      khoangBienDo = math.max(1.0, giaTriToiThieu.abs() * 0.2);
    }

    if (giaTri < giaTriToiThieu) {
      final doLech = (giaTriToiThieu - giaTri) / khoangBienDo;
      return MapEntry(doLech, 'thap');
    } else {
      final doLech = (giaTri - giaTriToiDa) / khoangBienDo;
      return MapEntry(doLech, 'cao');
    }
  }

  /// FUZZIFICATION (MỜ HÓA): Suy ra độ thuộc (membership degree) vào 3 tập mờ Bình thường / Cảnh báo / Nguy hiểm
  static Map<String, double> _moHoa(double doLech) {
    final doLechGioiHan = doLech.clamp(0.0, 1.0);
    final muBinhThuong = _hamMoHinhThang(doLechGioiHan, 0, 0, 0.15, 0.40);
    final muCanhBao = _hamMoTamGiac(doLechGioiHan, 0.25, 0.50, 0.80);
    final muNguyHiem = _hamMoHinhThang(doLechGioiHan, 0.60, 0.85, 1.0, 1.0);

    return {
      'binh_thuong': muBinhThuong,
      'canh_bao': muCanhBao,
      'nguy_hiem': muNguyHiem,
    };
  }

  static AiEvaluationResult evaluate(SensorData duLieuCamBien) {
    if (!duLieuCamBien.isSensorOnline) {
      return const AiEvaluationResult(
        riskScore: 0.0,
        overallStatus: StatusLevel.normal,
        isAlertTriggered: false,
        paramStatuses: {},
        adviceList: ['Chưa có dữ liệu cảm biến gửi về từ nông trại.'],
        isOfflineFallback: true,
      );
    }

    final cayTrong = PlantPresetManager.getCropById(duLieuCamBien.cropId);
    final giaiDoan = cayTrong?.getStageById(duLieuCamBien.stageId);

    final tenCayTrong = cayTrong?.cropName ?? 'Cây trồng';
    final tenGiaiDoan = giaiDoan?.stageName ?? 'Giai đoạn sinh trưởng';

    // 1. Khoảng tối ưu từ Preset
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

    // 2. Tính độ lệch cho các cảm biến đang hoạt động
    final danhSachDoLechThamSo = <String, MapEntry<double, String>>{};
    final danhSachLoiKhuyen = <String>[];

    if (duLieuCamBien.hasPh) {
      danhSachDoLechThamSo['ph'] = _tinhDoLechThamSo(duLieuCamBien.ph, phToiThieu, phToiDa);
    }
    if (duLieuCamBien.hasTemperature) {
      danhSachDoLechThamSo['temperature'] = _tinhDoLechThamSo(duLieuCamBien.temperature, nhietDoToiThieu, nhietDoToiDa);
    }
    if (duLieuCamBien.hasHumidity) {
      danhSachDoLechThamSo['humidity'] = _tinhDoLechThamSo(duLieuCamBien.humidity, doAmKhongKhiToiThieu, doAmKhongKhiToiDa);
    }
    if (duLieuCamBien.hasSoil) {
      danhSachDoLechThamSo['soil'] = _tinhDoLechThamSo(duLieuCamBien.soil, doAmDatToiThieu, doAmDatToiDa);
    }
    if (duLieuCamBien.hasLight) {
      danhSachDoLechThamSo['light'] = _tinhDoLechThamSo(duLieuCamBien.light, anhSangToiThieu, anhSangToiDa);
    }

    final trangThaiCacThamSo = <String, String>{};
    double tongTrongSoOnline = 0.0;
    for (final k in danhSachDoLechThamSo.keys) {
      tongTrongSoOnline += _trongSoThamSo[k] ?? 0.2;
    }
    if (tongTrongSoOnline <= 0.0) tongTrongSoOnline = 1.0;



    // 3. Khởi tạo lưới 200 điểm cho Risk Grid / Lưới Nguy cơ (0 - 100)
    const soBuocChia = 200;
    final luoiNguyCo = List<double>.generate(soBuocChia, (i) => i * (100.0 / (soBuocChia - 1)));
    final tapNguyCoTongHop = List<double>.filled(soBuocChia, 0.0);

    // Mẫu tập mờ đầu ra Nguy cơ: Thấp [0, 0, 20, 35], Trung bình [25, 50, 75], Cao [65, 80, 100, 100]
    final hamMoNguyCoThap = List<double>.generate(soBuocChia, (i) => _hamMoHinhThang(luoiNguyCo[i], 0, 0, 20, 35));
    final hamMoNguyCoTrungBinh = List<double>.generate(soBuocChia, (i) => _hamMoTamGiac(luoiNguyCo[i], 25, 50, 75));
    final hamMoNguyCoCao = List<double>.generate(soBuocChia, (i) => _hamMoHinhThang(luoiNguyCo[i], 65, 80, 100, 100));

    // 4. SUY DIỄN MỜ MAMDANI (Mamdani Min Implication & Max Aggregation)
    danhSachDoLechThamSo.forEach((tenThamSo, mucDoLech) {
      final doLech = mucDoLech.key;
      final tapMo = _moHoa(doLech);
      // Chuẩn hóa trọng số theo số lượng cảm biến đang online
      final trongSo = (_trongSoThamSo[tenThamSo] ?? 0.2) / tongTrongSoOnline;

      final doKichHoatThap = tapMo['binh_thuong']! * trongSo;
      final doKichHoatTrungBinh = tapMo['canh_bao']! * trongSo;
      final doKichHoatCao = tapMo['nguy_hiem']! * trongSo;

      for (int i = 0; i < soBuocChia; i++) {
        final catNguyCoThap = math.min(doKichHoatThap, hamMoNguyCoThap[i]);
        final catNguyCoTrungBinh = math.min(doKichHoatTrungBinh, hamMoNguyCoTrungBinh[i]);
        final catNguyCoCao = math.min(doKichHoatCao, hamMoNguyCoCao[i]);

        final nguyCoCucDaiThamSo = math.max(catNguyCoThap, math.max(catNguyCoTrungBinh, catNguyCoCao));
        tapNguyCoTongHop[i] = math.max(tapNguyCoTongHop[i], nguyCoCucDaiThamSo);
      }

      // Phân loại trạng thái riêng cho tham số
      if (tapMo['nguy_hiem']! >= math.max(tapMo['binh_thuong']!, tapMo['canh_bao']!) && doLech >= 0.55) {
        trangThaiCacThamSo[tenThamSo] = 'danger';
      } else if (tapMo['canh_bao']! > tapMo['binh_thuong']! || doLech >= 0.30) {
        trangThaiCacThamSo[tenThamSo] = 'warning';
      } else {
        trangThaiCacThamSo[tenThamSo] = 'normal';
      }
    });

    // 5. Sinh Lời khuyên Nông học (Advice Generator)
    if (duLieuCamBien.hasPh && danhSachDoLechThamSo.containsKey('ph')) {
      final doLechPh = danhSachDoLechThamSo['ph']!;
      if (doLechPh.value == 'thap') {
        danhSachLoiKhuyen.add('Đất bị chua (pH = ${duLieuCamBien.ph.toStringAsFixed(1)} < $phToiThieu). Khuyến nghị bón vôi nông nghiệp (CaCO3) để nâng pH.');
      } else if (doLechPh.value == 'cao') {
        danhSachLoiKhuyen.add('Đất bị kiềm hóa (pH = ${duLieuCamBien.ph.toStringAsFixed(1)} > $phToiDa). Bổ sung phân hữu cơ hoai mục để hạ pH.');
      }
    }

    if (duLieuCamBien.hasTemperature && danhSachDoLechThamSo.containsKey('temperature')) {
      final doLechNhietDo = danhSachDoLechThamSo['temperature']!;
      if (doLechNhietDo.value == 'cao') {
        danhSachLoiKhuyen.add('Nhiệt độ (${duLieuCamBien.temperature.toStringAsFixed(1)}°C) cao hơn ngưỡng tối ưu ($nhietDoToiDa°C). Bật hệ thống phun sương làm mát.');
      } else if (doLechNhietDo.value == 'thap') {
        danhSachLoiKhuyen.add('Nhiệt độ (${duLieuCamBien.temperature.toStringAsFixed(1)}°C) thấp hơn mức sinh trưởng ($nhietDoToiThieu°C). Cần che chắn gió cho cây.');
      }
    }

    if (duLieuCamBien.hasSoil && danhSachDoLechThamSo.containsKey('soil')) {
      final doLechDoAmDat = danhSachDoLechThamSo['soil']!;
      if (doLechDoAmDat.value == 'thap') {
        danhSachLoiKhuyen.add('Độ ẩm đất (${duLieuCamBien.soil.toStringAsFixed(1)}%) quá khô so với nhu cầu giai đoạn này ($doAmDatToiThieu%). Kích hoạt tưới nước tự động.');
      } else if (doLechDoAmDat.value == 'cao' && duLieuCamBien.soil > 90.0) {
        danhSachLoiKhuyen.add('Đất đang bị úng nước (${duLieuCamBien.soil.toStringAsFixed(1)}% > $doAmDatToiDa%). Tạm ngưng tưới và mở rãnh thoát nước ngay.');
      }
    }

    if (duLieuCamBien.hasHumidity && danhSachDoLechThamSo.containsKey('humidity')) {
      final doLechDoAmKhongKhi = danhSachDoLechThamSo['humidity']!;
      if (doLechDoAmKhongKhi.value == 'thap') {
        danhSachLoiKhuyen.add('Độ ẩm không khí (${duLieuCamBien.humidity.toStringAsFixed(1)}%) quá khô. Tăng cường phun sương tạo ẩm môi trường.');
      } else if (doLechDoAmKhongKhi.value == 'cao' && duLieuCamBien.humidity > 90.0) {
        danhSachLoiKhuyen.add('Ẩm độ không khí quá cao (${duLieuCamBien.humidity.toStringAsFixed(1)}%). Chú ý thông thoáng vườn tránh nấm bệnh phát triển.');
      }
    }

    if (duLieuCamBien.hasLight && danhSachDoLechThamSo.containsKey('light')) {
      final doLechAnhSang = danhSachDoLechThamSo['light']!;
      if (doLechAnhSang.value == 'thap') {
        danhSachLoiKhuyen.add('Cường độ ánh sáng (${duLieuCamBien.light.toStringAsFixed(0)} lux) chưa đủ ($anhSangToiThieu lux). Tỉa bớt cành rậm hoặc tháo bạt che.');
      } else if (doLechAnhSang.value == 'cao') {
        danhSachLoiKhuyen.add('Nắng quá gắt (${duLieuCamBien.light.toStringAsFixed(0)} lux > $anhSangToiDa lux). Kéo lưới che nắng bảo vệ bộ lá.');
      }
    }

    if (danhSachLoiKhuyen.isEmpty) {
      danhSachLoiKhuyen.add('Tất cả chỉ số cảm biến đang ở trạng thái tối ưu cho giai đoạn \'$tenGiaiDoan\'.');
    }


    // 6. DEFUZZIFICATION / GIẢI MỜ (Centroid - Trọng tâm)
    double tuSo = 0.0;
    double mauSo = 0.0;
    for (int i = 0; i < soBuocChia; i++) {
      tuSo += luoiNguyCo[i] * tapNguyCoTongHop[i];
      mauSo += tapNguyCoTongHop[i];
    }

    double diemNguyCo = 0.0;
    if (mauSo > 0) {
      diemNguyCo = tuSo / mauSo;
    }
    diemNguyCo = (diemNguyCo.clamp(0.0, 100.0) * 10).roundToDouble() / 10;

    StatusLevel trangThaiTongThe;
    bool coKichHoatCanhBao = false;

    if (trangThaiCacThamSo.containsValue('danger') || diemNguyCo >= 50.0) {
      trangThaiTongThe = StatusLevel.danger;
      coKichHoatCanhBao = true;
    } else if (trangThaiCacThamSo.containsValue('warning') || diemNguyCo >= 25.0) {
      trangThaiTongThe = StatusLevel.warning;
      coKichHoatCanhBao = true;
    } else {
      trangThaiTongThe = StatusLevel.normal;
      coKichHoatCanhBao = false;
    }

    StatusLevel giaiMaTrangThai(String? s) {
      if (s == 'danger') return StatusLevel.danger;
      if (s == 'warning') return StatusLevel.warning;
      return StatusLevel.normal;
    }

    final anhXaTrangThaiThamSo = <String, StatusLevel>{};
    if (duLieuCamBien.hasTemperature) {
      anhXaTrangThaiThamSo['temperature'] = giaiMaTrangThai(trangThaiCacThamSo['temperature']);
    }
    if (duLieuCamBien.hasHumidity) {
      anhXaTrangThaiThamSo['humidity'] = giaiMaTrangThai(trangThaiCacThamSo['humidity']);
    }
    if (duLieuCamBien.hasSoil) {
      anhXaTrangThaiThamSo['soil'] = giaiMaTrangThai(trangThaiCacThamSo['soil']);
    }
    if (duLieuCamBien.hasLight) {
      anhXaTrangThaiThamSo['light'] = giaiMaTrangThai(trangThaiCacThamSo['light']);
    }
    if (duLieuCamBien.hasPh) {
      anhXaTrangThaiThamSo['ph'] = giaiMaTrangThai(trangThaiCacThamSo['ph']);
    }


    return AiEvaluationResult(
      riskScore: diemNguyCo,
      overallStatus: trangThaiTongThe,
      isAlertTriggered: coKichHoatCanhBao,
      paramStatuses: anhXaTrangThaiThamSo,
      adviceList: danhSachLoiKhuyen,
      cropName: tenCayTrong,
      stageName: tenGiaiDoan,
      isOfflineFallback: false,
    );
  }
}