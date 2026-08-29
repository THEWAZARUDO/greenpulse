import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greenpulse/models/crop_preset_model.dart';

void main() {
  group('PlantPresetDropdown & Crop Presets Widget Tests', () {
    final sampleCrops = [
      const CropModel(
        cropId: 'sau_rieng',
        cropName: 'Sầu riêng',
        soilPhMin: 5.5,
        soilPhMax: 6.5,
        growthStages: [
          GrowthStage(
            stageId: 1,
            stageName: 'Cây con (1-3 năm)',
            tempMin: 24.0,
            tempMax: 30.0,
            soilMoistureMin: 65.0,
            soilMoistureMax: 80.0,
            airHumidityMin: 75.0,
            airHumidityMax: 85.0,
            luxMin: 40000.0,
            luxMax: 70000.0,
          ),
          GrowthStage(
            stageId: 2,
            stageName: 'Ra hoa & Nuôi quả',
            tempMin: 25.0,
            tempMax: 32.0,
            soilMoistureMin: 55.0,
            soilMoistureMax: 70.0,
            airHumidityMin: 65.0,
            airHumidityMax: 75.0,
            luxMin: 60000.0,
            luxMax: 90000.0,
          ),
        ],
      ),
      const CropModel(
        cropId: 'ca_phe',
        cropName: 'Cà phê Robusta',
        soilPhMin: 5.0,
        soilPhMax: 6.0,
        growthStages: [
          GrowthStage(
            stageId: 1,
            stageName: 'Kiến thiết cơ bản',
            tempMin: 22.0,
            tempMax: 28.0,
            soilMoistureMin: 60.0,
            soilMoistureMax: 75.0,
            airHumidityMin: 70.0,
            airHumidityMax: 80.0,
            luxMin: 45000.0,
            luxMax: 75000.0,
          ),
        ],
      ),
    ];

    testWidgets('Renders Crop and Stage Dropdowns with expected options and updates selection', (tester) async {
      CropModel selectedCrop = sampleCrops.first;
      GrowthStage selectedStage = selectedCrop.growthStages.first;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    DropdownButton<String>(
                      key: const Key('crop_dropdown'),
                      value: selectedCrop.cropId,
                      items: sampleCrops.map((c) {
                        return DropdownMenuItem<String>(
                          value: c.cropId,
                          child: Text(c.cropName),
                        );
                      }).toList(),
                      onChanged: (newId) {
                        if (newId != null) {
                          setState(() {
                            selectedCrop = sampleCrops.firstWhere((c) => c.cropId == newId);
                            selectedStage = selectedCrop.growthStages.first;
                          });
                        }
                      },
                    ),
                    DropdownButton<int>(
                      key: const Key('stage_dropdown'),
                      value: selectedStage.stageId,
                      items: selectedCrop.growthStages.map((s) {
                        return DropdownMenuItem<int>(
                          value: s.stageId,
                          child: Text(s.stageName),
                        );
                      }).toList(),
                      onChanged: (newStageId) {
                        if (newStageId != null) {
                          setState(() {
                            selectedStage = selectedCrop.getStageById(newStageId);
                          });
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // Verify initial selection
      expect(find.byKey(const Key('crop_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('stage_dropdown')), findsOneWidget);
      expect(find.text('Sầu riêng'), findsOneWidget);
      expect(find.text('Cây con (1-3 năm)'), findsOneWidget);

      // Change crop
      await tester.tap(find.byKey(const Key('crop_dropdown')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cà phê Robusta').last);
      await tester.pumpAndSettle();

      expect(find.text('Cà phê Robusta'), findsOneWidget);
      expect(find.text('Kiến thiết cơ bản'), findsOneWidget);
    });

    test('GrowthStage getStageById returns fallback if not found', () {
      final crop = sampleCrops.first;
      final stage = crop.getStageById(999);
      expect(stage, isNotNull);
      expect(stage.stageId, equals(1));
    });
  });
}
