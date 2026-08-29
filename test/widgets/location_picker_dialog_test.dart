import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greenpulse/models/weather_model.dart';
import 'package:greenpulse/services/weather_service.dart';

void main() {
  group('Location Picker Dialog & Preset Widget Tests', () {
    testWidgets('Renders preset locations list correctly', (tester) async {
      final presets = WeatherService.presetLocations;
      expect(presets.isNotEmpty, isTrue);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: presets.length,
              itemBuilder: (context, index) {
                final loc = presets[index];
                return ListTile(
                  leading: const Icon(Icons.place),
                  title: Text(loc.name),
                  subtitle: Text(loc.admin1 ?? ''),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Ea Kar'), findsWidgets);
      expect(find.text('Buôn Ma Thuột'), findsOneWidget);
      expect(find.text('Đà Lạt'), findsOneWidget);
      expect(find.byIcon(Icons.place), findsWidgets);
    });

    testWidgets('Selects location and returns value upon tapping', (tester) async {
      WeatherLocation? chosen;
      const testLocation = WeatherLocation(
        name: 'Đà Lạt',
        admin1: 'Lâm Đồng',
        country: 'Việt Nam',
        latitude: 11.9404,
        longitude: 108.4583,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  key: const Key('pick_btn'),
                  onPressed: () {
                    chosen = testLocation;
                  },
                  child: const Text('Pick Location'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('pick_btn')));
      await tester.pump();

      expect(chosen, isNotNull);
      expect(chosen!.name, 'Đà Lạt');
      expect(chosen!.admin1, 'Lâm Đồng');
      expect(chosen!.displayName, 'Đà Lạt, Lâm Đồng');
    });
  });
}
