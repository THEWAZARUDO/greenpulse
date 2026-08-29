import 'weather_location.dart';
import 'current_weather.dart';
import 'forecast_models.dart';
import 'agri_weather_advisor.dart';

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
