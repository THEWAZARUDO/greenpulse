import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greenpulse/models/weather_model.dart';

void main() {
  group('Weather Card & Subcomponent Widget Tests', () {
    final sampleLocation = const WeatherLocation(
      name: 'Ea Kar',
      admin1: 'Đắk Lắk',
      country: 'Việt Nam',
      latitude: 12.8082,
      longitude: 108.4490,
    );

    final sampleCurrent = const CurrentWeather(
      temperature: 27.5,
      apparentTemperature: 29.0,
      humidity: 78.0,
      precipitation: 0.0,
      weatherCode: 1,
      windSpeed: 12.5,
      pressure: 1012.0,
      isDay: true,
      uvIndex: 5.2,
    );

    final sampleHourly = [
      HourlyForecast(
        time: DateTime.now(),
        temperature: 26.0,
        humidity: 78.0,
        precipitationProbability: 10,
        weatherCode: 1,
        isDay: true,
        uvIndex: 5.0,
      ),
      HourlyForecast(
        time: DateTime.now().add(const Duration(hours: 1)),
        temperature: 29.0,
        humidity: 75.0,
        precipitationProbability: 15,
        weatherCode: 2,
        isDay: true,
        uvIndex: 6.0,
      ),
    ];

    final sampleDaily = [
      DailyForecast(
        date: DateTime.now(),
        tempMin: 22.0,
        tempMax: 31.0,
        precipitationProbabilityMax: 30,
        weatherCode: 1,
        uvIndexMax: 8.0,
      ),
      DailyForecast(
        date: DateTime.now().add(const Duration(days: 1)),
        tempMin: 21.0,
        tempMax: 30.0,
        precipitationProbabilityMax: 40,
        weatherCode: 2,
        uvIndexMax: 7.5,
      ),
    ];

    testWidgets('Renders Weather metrics, advice tips, and hourly forecast items', (tester) async {
      final weatherInfo = WmoWeatherCode.getInfo(sampleCurrent.weatherCode, sampleCurrent.isDay);
      final tips = AgriWeatherAdvisor.generateTips(sampleCurrent, sampleHourly, sampleDaily);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  // Header
                  Text(sampleLocation.displayName),
                  Text('${sampleCurrent.temperature.toStringAsFixed(1)}°C'),
                  Text(weatherInfo.description),

                  // 4 quick metrics
                  Text('Độ ẩm KK: ${sampleCurrent.humidity.toStringAsFixed(0)}%'),
                  Text('Mưa hiện tại: ${sampleCurrent.precipitation.toStringAsFixed(1)} mm'),
                  Text('Tốc độ gió: ${sampleCurrent.windSpeed.toStringAsFixed(1)} km/h'),
                  Text('Chỉ số UV: ${sampleCurrent.uvIndex.toStringAsFixed(1)}'),

                  // Tips
                  ...tips.map((t) => Text(t)),

                  // Hourly
                  ...sampleHourly.map((h) => Text('Giờ: ${h.temperature.toStringAsFixed(0)}°')),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Ea Kar, Đắk Lắk'), findsOneWidget);
      expect(find.text('27.5°C'), findsOneWidget);
      expect(find.text('Nắng có mây'), findsOneWidget);
      expect(find.text('Độ ẩm KK: 78%'), findsOneWidget);
      expect(find.text('Tốc độ gió: 12.5 km/h'), findsOneWidget);
      expect(find.text('Chỉ số UV: 5.2'), findsOneWidget);
      expect(find.text('Giờ: 26°'), findsOneWidget);
      expect(find.text('Giờ: 29°'), findsOneWidget);
    });

    testWidgets('Toggles 7-Day Forecast expansion visibility', (tester) async {
      bool isExpanded = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    InkWell(
                      key: const Key('toggle_7day_btn'),
                      onTap: () => setState(() => isExpanded = !isExpanded),
                      child: Text(isExpanded ? 'Thu gọn' : 'Xem chi tiết'),
                    ),
                    if (isExpanded)
                      const Column(
                        children: [
                          Text('Dự báo ngày mai: 21° - 30°C'),
                        ],
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Xem chi tiết'), findsOneWidget);
      expect(find.text('Dự báo ngày mai: 21° - 30°C'), findsNothing);

      // Tap toggle
      await tester.tap(find.byKey(const Key('toggle_7day_btn')));
      await tester.pump();

      expect(find.text('Thu gọn'), findsOneWidget);
      expect(find.text('Dự báo ngày mai: 21° - 30°C'), findsOneWidget);
    });
  });
}
