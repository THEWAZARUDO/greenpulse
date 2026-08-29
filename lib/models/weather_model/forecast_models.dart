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
