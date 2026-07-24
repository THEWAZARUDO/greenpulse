import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/crop_preset_model.dart';
import '../models/plant_preset_manager.dart';
import '../services/rtdb_service.dart';

class PlantPresetDropdown extends StatelessWidget {
  final String farmId;
  final String sensorId;
  final String? currentCropId;
  final bool compact;

  const PlantPresetDropdown({
    super.key,
    required this.farmId,
    required this.sensorId,
    this.currentCropId,
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
            final crops = PlantPresetManager.crops;
            if (crops.isEmpty) {
              return const Text('Chưa có cây');
            }

            CropModel? currentCrop = PlantPresetManager.getCropById(currentCropId);
            currentCrop ??= crops.first;

            return DropdownButton<String>(
              isDense: true,
              value: currentCrop.cropId,
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
              items: crops.map((crop) {
                return DropdownMenuItem<String>(
                  value: crop.cropId,
                  child: Text(crop.cropName),
                );
              }).toList(),
              onChanged: (String? newValue) async {
                if (newValue != null) {
                  final selectedCrop = PlantPresetManager.getCropById(newValue);
                  if (selectedCrop != null) {
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    if (uid != null) {
                      await RTDBService().updateSensorCropAndStage(
                        uid,
                        farmId,
                        sensorId,
                        selectedCrop.cropId,
                        stageId: 1,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Đã chuyển cảm biến $sensorId sang cây: ${selectedCrop.cropName}',
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
