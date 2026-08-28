import 'package:flutter/material.dart';

/// Đại diện cho một địa điểm dự báo thời tiết
class WeatherLocation {
  final String name;
  final String? admin1; // Tỉnh / Thành phố
  final String? country;
  final double latitude;
  final double longitude;

  const WeatherLocation({
    required this.name,
    this.admin1,
    this.country,
    required this.latitude,
    required this.longitude,
  });

  String get displayName {
    if (admin1 != null && admin1!.isNotEmpty && admin1 != name) {
      return '$name, $admin1';
    }
    return name;
  }

  factory WeatherLocation.fromJson(Map<String, dynamic> json) {
    return WeatherLocation(
      name: json['name'] as String? ?? 'Không xác định',
      admin1: json['admin1'] as String?,
      country: json['country'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'admin1': admin1,
        'country': country,
        'latitude': latitude,
        'longitude': longitude,
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WeatherLocation &&
        other.name.toLowerCase() == name.toLowerCase() &&
        (other.latitude - latitude).abs() < 0.01 &&
        (other.longitude - longitude).abs() < 0.01;
  }

  @override
  int get hashCode =>
      name.toLowerCase().hashCode ^
      (latitude * 100).round().hashCode ^
      (longitude * 100).round().hashCode;
}


/// Thông tin thời tiết hiện tại
class CurrentWeather {
  final double temperature;
  final double apparentTemperature; // Cảm giác như
  final double humidity;
  final double precipitation;
  final int weatherCode;
  final double windSpeed;
  final double pressure;
  final bool isDay;
  final double uvIndex;

  const CurrentWeather({
    required this.temperature,
    required this.apparentTemperature,
    required this.humidity,
    required this.precipitation,
    required this.weatherCode,
    required this.windSpeed,
    required this.pressure,
    required this.isDay,
    this.uvIndex = 0.0,
  });

  factory CurrentWeather.fromOpenMeteo(
    Map<String, dynamic> current,
    Map<String, dynamic>? hourly,
  ) {
    // Lấy UV index hiện tại từ current hoặc hourly nếu có
    double currentUv = (current['uv_index'] as num?)?.toDouble() ?? 0.0;
    if (currentUv == 0.0 && hourly != null && hourly['uv_index'] is List) {
      final List uvList = hourly['uv_index'];
      final nowHour = DateTime.now().hour;
      if (uvList.length > nowHour) {
        currentUv = (uvList[nowHour] as num?)?.toDouble() ?? 0.0;
      } else if (uvList.isNotEmpty) {
        currentUv = (uvList.first as num?)?.toDouble() ?? 0.0;
      }
    }

    return CurrentWeather(
      temperature: (current['temperature_2m'] as num?)?.toDouble() ?? 0.0,
      apparentTemperature:
          (current['apparent_temperature'] as num?)?.toDouble() ??
              (current['temperature_2m'] as num?)?.toDouble() ??
              0.0,
      humidity: (current['relative_humidity_2m'] as num?)?.toDouble() ?? 0.0,
      precipitation: (current['precipitation'] as num?)?.toDouble() ?? 0.0,
      weatherCode: (current['weather_code'] as num?)?.toInt() ?? 0,
      windSpeed: (current['wind_speed_10m'] as num?)?.toDouble() ?? 0.0,
      pressure: (current['surface_pressure'] as num?)?.toDouble() ?? 1013.25,
      isDay: (current['is_day'] as num?)?.toInt() == 1,
      uvIndex: currentUv,
    );
  }
}

/// Dự báo thời tiết theo từng giờ
class HourlyForecast {
  final DateTime time;
  final double temperature;
  final double humidity;
  final int precipitationProbability;
  final int weatherCode;
  final bool isDay;
  final double uvIndex;

  const HourlyForecast({
    required this.time,
    required this.temperature,
    required this.humidity,
    required this.precipitationProbability,
    required this.weatherCode,
    required this.isDay,
    required this.uvIndex,
  });
}

/// Dự báo thời tiết theo từng ngày (7 ngày)
class DailyForecast {
  final DateTime date;
  final double tempMin;
  final double tempMax;
  final int precipitationProbabilityMax;
  final int weatherCode;
  final double uvIndexMax;

  const DailyForecast({
    required this.date,
    required this.tempMin,
    required this.tempMax,
    required this.precipitationProbabilityMax,
    required this.weatherCode,
    required this.uvIndexMax,
  });
}

/// Bộ chuyển đổi mã WMO Weather Code
class WmoWeatherCode {
  final String description;
  final IconData icon;
  final Color iconColor;
  final List<Color> gradientColors;

  const WmoWeatherCode({
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.gradientColors,
  });

  static WmoWeatherCode getInfo(int code, bool isDay) {
    switch (code) {
      case 0:
        return WmoWeatherCode(
          description: isDay ? 'Trời quang đãng' : 'Đêm quang đãng',
          icon: isDay ? Icons.wb_sunny_rounded : Icons.nightlight_round,
          iconColor: isDay ? const Color(0xFFFFB300) : const Color(0xFFFFD54F),
          gradientColors: isDay
              ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32)]
              : [const Color(0xFF0D251A), const Color(0xFF1B4332)],
        );
      case 1:
      case 2:
        return WmoWeatherCode(
          description: isDay ? 'Nắng có mây' : 'Mây rải rác',
          icon: isDay ? Icons.wb_cloudy_rounded : Icons.nights_stay_rounded,
          iconColor: isDay ? const Color(0xFFFFCA28) : const Color(0xFFB0BEC5),
          gradientColors: isDay
              ? [const Color(0xFF2E7D32), const Color(0xFF388E3C)]
              : [const Color(0xFF1A3026), const Color(0xFF264653)],
        );
      case 3:
        return const WmoWeatherCode(
          description: 'Trời nhiều mây',
          icon: Icons.cloud_rounded,
          iconColor: Color(0xFF90A4AE),
          gradientColors: [Color(0xFF37474F), Color(0xFF455A64)],
        );
      case 45:
      case 48:
        return const WmoWeatherCode(
          description: 'Sương mù',
          icon: Icons.blur_on_rounded,
          iconColor: Color(0xFFB0BEC5),
          gradientColors: [Color(0xFF455A64), Color(0xFF546E7A)],
        );
      case 51:
      case 53:
      case 55:
        return const WmoWeatherCode(
          description: 'Mưa phùn nhẹ',
          icon: Icons.grain_rounded,
          iconColor: Color(0xFF81D4FA),
          gradientColors: [Color(0xFF1E3D34), Color(0xFF2B5346)],
        );
      case 61:
      case 63:
        return const WmoWeatherCode(
          description: 'Mưa rào',
          icon: Icons.water_drop_rounded,
          iconColor: Color(0xFF4FC3F7),
          gradientColors: [Color(0xFF154338), Color(0xFF1D5A4C)],
        );
      case 65:
        return const WmoWeatherCode(
          description: 'Mưa rất to',
          icon: Icons.thunderstorm_rounded,
          iconColor: Color(0xFF29B6F6),
          gradientColors: [Color(0xFF0E2F27), Color(0xFF1A4D40)],
        );
      case 80:
      case 81:
      case 82:
        return const WmoWeatherCode(
          description: 'Mưa dông từng cơn',
          icon: Icons.umbrella_rounded,
          iconColor: Color(0xFF4FC3F7),
          gradientColors: [Color(0xFF154338), Color(0xFF206354)],
        );
      case 95:
      case 96:
      case 99:
        return const WmoWeatherCode(
          description: 'Dông sét mạnh',
          icon: Icons.flash_on_rounded,
          iconColor: Color(0xFFFFD54F),
          gradientColors: [Color(0xFF311B92), Color(0xFF1A237E)],
        );
      default:
        return WmoWeatherCode(
          description: 'Thời tiết ổn định',
          icon: Icons.cloud_queue_rounded,
          iconColor: const Color(0xFF81C784),
          gradientColors: [const Color(0xFF1B5E20), const Color(0xFF2E7D32)],
        );
    }
  }
}

/// Bộ phân tích và sinh khuyến nghị nông học thông minh dựa trên dự báo thời tiết
class AgriWeatherAdvisor {
  static List<String> generateTips(
    CurrentWeather current,
    List<HourlyForecast> hourly,
    List<DailyForecast> daily,
  ) {
    final List<String> tips = [];

    // 1. Kiểm tra mưa trong 6 giờ tới
    final next6Hours = hourly.take(6).toList();
    final maxRainChance6h = next6Hours.fold<int>(
      0,
      (max, h) => h.precipitationProbability > max ? h.precipitationProbability : max,
    );

    if (maxRainChance6h >= 70) {
      tips.add('🌧️ Khả năng mưa cao ($maxRainChance6h%) trong 6 giờ tới: Tạm hoãn tưới nước và không phun thuốc BVTV/phân bón lá để tránh bị rửa trôi.');
    } else if (maxRainChance6h >= 40) {
      tips.add('🌦️ Dự báo có thể có mưa ($maxRainChance6h%): Cân nhắc giảm lượng nước tưới tự động.');
    }

    // 2. Kiểm tra nhiệt độ và nắng gắt
    if (current.temperature >= 35) {
      tips.add('🔥 Nắng gắt nhiệt độ cao (${current.temperature.toStringAsFixed(1)}°C): Cần tăng cường che lưới mát cho vườn ươm/cây con và tưới ẩm vào sáng sớm hoặc chiều mát.');
    } else if (current.temperature <= 16) {
      tips.add('❄️ Nhiệt độ lạnh (${current.temperature.toStringAsFixed(1)}°C): Chú ý ủ gốc giữ ấm, hạn chế tưới đẫm vào chiều tối đề phòng sương muối/rét đậm.');
    }

    // 3. Kiểm tra chỉ số UV
    final maxUvToday = daily.isNotEmpty ? daily.first.uvIndexMax : current.uvIndex;
    if (maxUvToday >= 8) {
      tips.add('☀️ Chỉ số UV đạt mức cao (${maxUvToday.toStringAsFixed(1)}): Tránh làm việc ngoài trời nắng gắt giữa trưa; che chắn bề mặt đất để giảm bốc thoát hơi nước.');
    }

    // 4. Kiểm tra độ ẩm không khí cao
    if (current.humidity >= 88) {
      tips.add('💧 Độ ẩm không khí rất cao (${current.humidity.toStringAsFixed(0)}%): Điều kiện thuận lợi cho nấm bệnh (thán thư, rỉ sắt, nấm hồng) phát triển, cần tỉa cành thông thoáng.');
    }

    // 5. Kiểm tra gió mạnh
    if (current.windSpeed >= 28) {
      tips.add('💨 Gió mạnh (${current.windSpeed.toStringAsFixed(1)} km/h): Cần chằng chống cành cây ăn quả, che chắn vườn chắn gió để tránh gãy cành/rụng hoa.');
    }

    // Lời khuyên mặc định nếu thời tiết thuận lợi
    if (tips.isEmpty) {
      tips.add('🌱 Thời tiết rất thuận lợi: Thích hợp cho việc bón phân dinh dưỡng định kỳ, tỉa cành và chăm sóc cây trồng.');
    }

    return tips;
  }
}

/// Đối tượng WeatherData tổng hợp
class WeatherData {
  final WeatherLocation location;
  final CurrentWeather current;
  final List<HourlyForecast> hourly;
  final List<DailyForecast> daily;
  final List<String> agriTips;
  final DateTime updatedAt;

  const WeatherData({
    required this.location,
    required this.current,
    required this.hourly,
    required this.daily,
    required this.agriTips,
    required this.updatedAt,
  });

  factory WeatherData.fromOpenMeteo({
    required WeatherLocation location,
    required Map<String, dynamic> json,
  }) {
    final currentMap = json['current'] as Map<String, dynamic>? ?? {};
    final hourlyMap = json['hourly'] as Map<String, dynamic>? ?? {};
    final dailyMap = json['daily'] as Map<String, dynamic>? ?? {};

    // 1. Phân tích Current
    final current = CurrentWeather.fromOpenMeteo(currentMap, hourlyMap);

    // 2. Phân tích Hourly (Lấy 24 giờ tiếp theo)
    final List<HourlyForecast> hourlyList = [];
    final hourlyTimes = (hourlyMap['time'] as List?) ?? [];
    final hourlyTemps = (hourlyMap['temperature_2m'] as List?) ?? [];
    final hourlyHumids = (hourlyMap['relative_humidity_2m'] as List?) ?? [];
    final hourlyRainProbs = (hourlyMap['precipitation_probability'] as List?) ?? [];
    final hourlyCodes = (hourlyMap['weather_code'] as List?) ?? [];
    final hourlyIsDay = (hourlyMap['is_day'] as List?) ?? [];
    final hourlyUv = (hourlyMap['uv_index'] as List?) ?? [];

    final now = DateTime.now();
    int count = 0;
    for (int i = 0; i < hourlyTimes.length; i++) {
      final t = DateTime.tryParse(hourlyTimes[i].toString());
      if (t == null) continue;
      // Bỏ qua các giờ đã trôi qua trong quá khứ quá 1 tiếng
      if (t.isBefore(now.subtract(const Duration(hours: 1)))) continue;

      hourlyList.add(
        HourlyForecast(
          time: t,
          temperature: (i < hourlyTemps.length ? hourlyTemps[i] as num? : 0)?.toDouble() ?? 0.0,
          humidity: (i < hourlyHumids.length ? hourlyHumids[i] as num? : 0)?.toDouble() ?? 0.0,
          precipitationProbability: (i < hourlyRainProbs.length ? hourlyRainProbs[i] as num? : 0)?.toInt() ?? 0,
          weatherCode: (i < hourlyCodes.length ? hourlyCodes[i] as num? : 0)?.toInt() ?? 0,
          isDay: (i < hourlyIsDay.length ? (hourlyIsDay[i] as num?)?.toInt() == 1 : true),
          uvIndex: (i < hourlyUv.length ? hourlyUv[i] as num? : 0)?.toDouble() ?? 0.0,
        ),
      );
      count++;
      if (count >= 24) break; // Giữ 24 giờ
    }

    // 3. Phân tích Daily (7 ngày)
    final List<DailyForecast> dailyList = [];
    final dailyTimes = (dailyMap['time'] as List?) ?? [];
    final dailyCodes = (dailyMap['weather_code'] as List?) ?? [];
    final dailyMaxTemps = (dailyMap['temperature_2m_max'] as List?) ?? [];
    final dailyMinTemps = (dailyMap['temperature_2m_min'] as List?) ?? [];
    final dailyRainMax = (dailyMap['precipitation_probability_max'] as List?) ?? [];
    final dailyUvMax = (dailyMap['uv_index_max'] as List?) ?? [];

    for (int i = 0; i < dailyTimes.length && i < 7; i++) {
      final d = DateTime.tryParse(dailyTimes[i].toString()) ?? now.add(Duration(days: i));
      dailyList.add(
        DailyForecast(
          date: d,
          tempMin: (i < dailyMinTemps.length ? dailyMinTemps[i] as num? : 0)?.toDouble() ?? 0.0,
          tempMax: (i < dailyMaxTemps.length ? dailyMaxTemps[i] as num? : 0)?.toDouble() ?? 0.0,
          precipitationProbabilityMax: (i < dailyRainMax.length ? dailyRainMax[i] as num? : 0)?.toInt() ?? 0,
          weatherCode: (i < dailyCodes.length ? dailyCodes[i] as num? : 0)?.toInt() ?? 0,
          uvIndexMax: (i < dailyUvMax.length ? dailyUvMax[i] as num? : 0)?.toDouble() ?? 0.0,
        ),
      );
    }

    // 4. Sinh lời khuyên nông nghiệp
    final tips = AgriWeatherAdvisor.generateTips(current, hourlyList, dailyList);

    return WeatherData(
      location: location,
      current: current,
      hourly: hourlyList,
      daily: dailyList,
      agriTips: tips,
      updatedAt: DateTime.now(),
    );
  }
}
