import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:greenpulse/models/weather_model.dart';
import 'package:greenpulse/services/weather_service.dart';

void main() {
  group('WeatherLocation Tests', () {
    test('displayName formats properly with admin1 and name', () {
      const loc1 = WeatherLocation(
        name: 'Đà Lạt',
        admin1: 'Lâm Đồng',
        country: 'Việt Nam',
        latitude: 11.9404,
        longitude: 108.4583,
      );
      expect(loc1.displayName, equals('Đà Lạt, Lâm Đồng'));

      const loc2 = WeatherLocation(
        name: 'Hà Nội',
        admin1: 'Hà Nội',
        country: 'Việt Nam',
        latitude: 21.0285,
        longitude: 105.8542,
      );
      expect(loc2.displayName, equals('Hà Nội'));
    });
  });

  group('WmoWeatherCode Tests', () {
    test('Translates WMO codes to Vietnamese labels and icons', () {
      final sunny = WmoWeatherCode.getInfo(0, true);
      expect(sunny.description, contains('Trời quang đãng'));

      final nightClear = WmoWeatherCode.getInfo(0, false);
      expect(nightClear.description, contains('Đêm quang đãng'));

      final rain = WmoWeatherCode.getInfo(61, true);
      expect(rain.description, equals('Mưa rào'));

      final thunder = WmoWeatherCode.getInfo(95, true);
      expect(thunder.description, equals('Dông sét mạnh'));
    });
  });

  group('WeatherData Parsing Tests', () {
    test('Parses Open-Meteo payload successfully', () {
      const location = WeatherLocation(
        name: 'Buôn Ma Thuột',
        admin1: 'Đắk Lắk',
        country: 'Việt Nam',
        latitude: 12.6667,
        longitude: 108.0500,
      );

      final nowIso = DateTime.now().toIso8601String();
      final mockJson = {
        'current': {
          'temperature_2m': 28.5,
          'apparent_temperature': 31.0,
          'relative_humidity_2m': 82.0,
          'precipitation': 1.5,
          'weather_code': 61,
          'wind_speed_10m': 14.5,
          'surface_pressure': 1012.0,
          'is_day': 1,
        },
        'hourly': {
          'time': [nowIso, DateTime.now().add(const Duration(hours: 1)).toIso8601String()],
          'temperature_2m': [28.5, 27.0],
          'relative_humidity_2m': [82.0, 85.0],
          'precipitation_probability': [75, 80],
          'weather_code': [61, 61],
          'is_day': [1, 1],
          'uv_index': [4.5, 3.0],
        },
        'daily': {
          'time': [nowIso],
          'weather_code': [61],
          'temperature_2m_max': [30.0],
          'temperature_2m_min': [22.0],
          'precipitation_probability_max': [85],
          'uv_index_max': [6.0],
        }
      };

      final weatherData = WeatherData.fromOpenMeteo(
        location: location,
        json: mockJson,
      );

      expect(weatherData.location.name, equals('Buôn Ma Thuột'));
      expect(weatherData.current.temperature, equals(28.5));
      expect(weatherData.current.apparentTemperature, equals(31.0));
      expect(weatherData.current.humidity, equals(82.0));
      expect(weatherData.current.weatherCode, equals(61));
      expect(weatherData.hourly.isNotEmpty, isTrue);
      expect(weatherData.daily.isNotEmpty, isTrue);
      expect(weatherData.agriTips.isNotEmpty, isTrue);
      // Because max rain chance is 80%, should include rain recommendation
      expect(weatherData.agriTips.any((t) => t.contains('mưa')), isTrue);
    });
  });

  group('AgriWeatherAdvisor Tests', () {
    test('Generates rain alert when high precipitation probability', () {
      const current = CurrentWeather(
        temperature: 25.0,
        apparentTemperature: 26.0,
        humidity: 75.0,
        precipitation: 0.0,
        weatherCode: 2,
        windSpeed: 10.0,
        pressure: 1013.0,
        isDay: true,
        uvIndex: 4.0,
      );

      final hourly = [
        HourlyForecast(
          time: DateTime.now(),
          temperature: 25.0,
          humidity: 80.0,
          precipitationProbability: 85,
          weatherCode: 61,
          isDay: true,
          uvIndex: 2.0,
        ),
      ];

      final tips = AgriWeatherAdvisor.generateTips(current, hourly, []);
      expect(tips.any((t) => t.contains('Khả năng mưa cao')), isTrue);
      expect(tips.any((t) => t.contains('Tạm hoãn tưới nước')), isTrue);
    });

    test('Generates heat alert when temperature >= 35', () {
      const current = CurrentWeather(
        temperature: 36.5,
        apparentTemperature: 41.0,
        humidity: 60.0,
        precipitation: 0.0,
        weatherCode: 0,
        windSpeed: 8.0,
        pressure: 1010.0,
        isDay: true,
        uvIndex: 9.0,
      );

      final tips = AgriWeatherAdvisor.generateTips(current, [], []);
      expect(tips.any((t) => t.contains('Nắng gắt nhiệt độ cao')), isTrue);
    });
  });

  group('WeatherService Smart Search & Persistence Tests', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
    });

    test('removeDiacritics strips accents accurately and supports toLowerCase', () {
      expect(WeatherService.removeDiacritics('Đắk Lắk'), equals('Dak Lak'));
      expect(WeatherService.removeDiacritics('ĐẮK LẮK', toLowerCase: true), equals('dak lak'));
      expect(WeatherService.removeDiacritics('Buôn Ma Thuột'), equals('Buon Ma Thuot'));
      expect(WeatherService.removeDiacritics('BUÔN MA THUỘT', toLowerCase: true), equals('buon ma thuot'));
      expect(WeatherService.removeDiacritics('Krông Pắc'), equals('Krong Pac'));
      expect(WeatherService.removeDiacritics('Ea H\'leo'), equals('Ea H\'leo'));
    });

    test('searchLocations finds Ea Kar when typing "Eakar", "Eakar/Đắk Lắk", or "EAKAR/DAKLAK"', () async {
      final results1 = await WeatherService.instance.searchLocations('Eakar');
      expect(results1.any((loc) => loc.name.toLowerCase().contains('ea kar')), isTrue);

      final results2 = await WeatherService.instance.searchLocations('Eakar/Đắk Lắk');
      expect(results2.any((loc) => loc.name.toLowerCase().contains('ea kar')), isTrue);

      final results3 = await WeatherService.instance.searchLocations('EAKAR/DAKLAK');
      expect(results3.any((loc) => loc.name.toLowerCase().contains('ea kar')), isTrue);
    });

    test('addRecentLocation maintains max 10 entries and moves newest to top', () async {
      final service = WeatherService.instance;
      await service.clearRecentLocations();
      expect(service.recentLocations.isEmpty, isTrue);

      for (int i = 1; i <= 12; i++) {
        await service.addRecentLocation(
          WeatherLocation(
            name: 'Địa điểm $i',
            admin1: 'Tỉnh $i',
            latitude: 10.0 + i * 0.1,
            longitude: 105.0 + i * 0.1,
          ),
        );
      }

      expect(service.recentLocations.length, equals(10));
      expect(service.recentLocations.first.name, equals('Địa điểm 12'));

      // Test removing an item
      final toRemove = service.recentLocations.first;
      await service.removeRecentLocation(toRemove);
      expect(service.recentLocations.length, equals(9));
      expect(service.recentLocations.any((loc) => loc.name == 'Địa điểm 12'), isFalse);
    });
  });
}

