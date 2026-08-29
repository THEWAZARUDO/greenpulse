import '../../models/weather_model.dart';

class WeatherCacheEntry {
  final WeatherData data;
  final DateTime timestamp;

  WeatherCacheEntry({required this.data, required this.timestamp});

  bool get isValid => DateTime.now().difference(timestamp).inMinutes < 15;
}
