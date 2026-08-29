import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:greenpulse/models/weather_model.dart';
import 'package:greenpulse/services/weather_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Weather Service & Agri-Advisor Integration Flow Tests', () {
    testWidgets('Full weather forecast parsing, agronomy tip inference, and smart location matching flow', (tester) async {
      final weatherService = WeatherService.instance;

      // 1. Test smart search with accent removal & alias lookup
      final bmtResults = await weatherService.searchLocations('BMT');
      expect(bmtResults.any((loc) => loc.name.contains('Buôn Ma Thuột')), isTrue);

      final dalatResults = await weatherService.searchLocations('dalat');
      expect(dalatResults.any((loc) => loc.name.contains('Đà Lạt')), isTrue);

      final eakarResults = await weatherService.searchLocations('eakar/daklak');
      expect(eakarResults.any((loc) => loc.name.contains('Ea Kar')), isTrue);

      // 2. Test mock weather payload parsing end-to-end
      final mockPayload = {
        'current': {
          'temperature_2m': 36.5,
          'relative_humidity_2m': 45.0,
          'apparent_temperature': 39.0,
          'precipitation': 0.0,
          'weather_code': 0,
          'wind_speed_10m': 14.0,
          'surface_pressure': 1010.0,
          'is_day': 1,
          'uv_index': 9.5,
        },
        'hourly': {
          'time': List.generate(24, (i) => DateTime.now().add(Duration(hours: i)).toIso8601String()),
          'temperature_2m': List.generate(24, (i) => 25.0 + i * 0.4),
          'relative_humidity_2m': List.generate(24, (i) => 60.0 - i * 0.5),
          'precipitation_probability': List.generate(24, (i) => (i == 3 ? 80 : 10)),
          'weather_code': List.generate(24, (i) => 1),
          'is_day': List.generate(24, (i) => 1),
          'uv_index': List.generate(24, (i) => 8.0),
        },
        'daily': {
          'time': List.generate(7, (i) => DateTime.now().add(Duration(days: i)).toIso8601String()),
          'temperature_2m_max': [37.0, 36.0, 35.0, 34.0, 33.0, 32.0, 31.0],
          'temperature_2m_min': [24.0, 23.0, 23.0, 22.0, 22.0, 21.0, 20.0],
          'precipitation_probability_max': [80, 70, 30, 20, 10, 10, 5],
          'weather_code': [80, 61, 1, 0, 0, 0, 0],
          'uv_index_max': [9.5, 9.0, 8.5, 8.0, 7.5, 7.0, 6.5],
        },
      };

      final parsedData = WeatherData.fromOpenMeteo(
        location: WeatherService.defaultLocation,
        json: mockPayload,
      );

      expect(parsedData.current.temperature, 36.5);
      expect(parsedData.hourly.length, 24);
      expect(parsedData.daily.length, 7);

      // Verify Agri tips generated accurately for heat & rain
      expect(parsedData.agriTips.any((tip) => tip.contains('Nhiệt độ cao') || tip.contains('Nắng gắt') || tip.contains('36.5')), isTrue);
      expect(parsedData.agriTips.any((tip) => tip.contains('mưa') || tip.contains('80%')), isTrue);
      expect(parsedData.agriTips.any((tip) => tip.contains('UV')), isTrue);
    });
  });
}
