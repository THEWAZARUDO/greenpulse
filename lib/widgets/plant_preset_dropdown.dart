import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/plant_preset_manager.dart';
import '../services/rtdb_service.dart';

class PlantPresetDropdown extends StatelessWidget {
  final String farmId;
  final String sensorId;
  final String? currentPlantName;
  final bool compact;

  const PlantPresetDropdown({
    super.key,
    required this.farmId,
    required this.sensorId,
    this.currentPlantName,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: Builder(
          builder: (context) {
            final presets = PlantPresetManager.presets;
            final presetNames = presets
                .map((p) => p.plantName)
                .toSet()
                .toList();

            String? currentValue = currentPlantName;
            if (currentValue == null || !presetNames.contains(currentValue)) {
              currentValue = presetNames.isNotEmpty ? presetNames.first : null;
            }

            return DropdownButton<String>(
              value: currentValue,
              icon: const Icon(
                Icons.arrow_drop_down,
                size: 20,
                color: Color(0xFF2E7D32),
              ),
              style: TextStyle(
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1B5E20),
              ),
              items: presetNames.map((name) {
                return DropdownMenuItem<String>(value: name, child: Text(name));
              }).toList(),
              onChanged: (String? newValue) async {
                if (newValue != null) {
                  final selectedPreset = PlantPresetManager.getPresetByName(
                    newValue,
                  );
                  if (selectedPreset != null) {
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    if (uid != null) {
                      await RTDBService().updateSensorThresholds(
                        uid,
                        farmId,
                        sensorId,
                        selectedPreset,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Đã chuyển mạch $sensorId sang cấu hình: $newValue',
                            ),
                            backgroundColor: const Color(0xFF1B5E20),
                          ),
                        );
                      }
                    }
                  }
                }
              },
            );
          },
        ),
      ),
    );
  }
}
