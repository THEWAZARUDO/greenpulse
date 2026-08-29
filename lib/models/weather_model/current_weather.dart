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
