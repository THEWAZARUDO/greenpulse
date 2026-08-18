import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/crop_preset_model.dart';
import '../models/plant_preset_manager.dart';
import '../services/rtdb_service.dart';

class PlantPresetDropdown extends StatelessWidget {
  final String farmId;
  final String sensorId;
  final String? currentCropId;
  final int currentStageId;
  final bool compact;

  const PlantPresetDropdown({
    super.key,
    required this.farmId,
    required this.sensorId,
    this.currentCropId,
    this.currentStageId = 1,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final crops = PlantPresetManager.crops;
    if (crops.isEmpty) {
      return const Text('Chưa có cây');
    }

    CropModel currentCrop = PlantPresetManager.getCropById(currentCropId) ?? crops.first;
    GrowthStage currentStage = currentCrop.getStageById(currentStageId);

    final screenWidth = MediaQuery.of(context).size.width;
    final maxCropWidth = (screenWidth * 0.42).clamp(130.0, 180.0);
    final maxStageWidth = (screenWidth * 0.45).clamp(140.0, 200.0);

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Dropdown chọn loại cây
        Container(
          height: 30,
          constraints: BoxConstraints(maxWidth: maxCropWidth),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isDense: true,
              isExpanded: true,
              value: currentCrop.cropId,
              icon: const Icon(
                Icons.arrow_drop_down,
                size: 18,
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
                  child: Text(
                    crop.cropName,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (String? newCropId) async {
                if (newCropId != null) {
                  final selectedCrop = PlantPresetManager.getCropById(newCropId);
                  if (selectedCrop != null) {
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    if (uid != null) {
                      await RTDBService().updateSensorCropAndStage(
                        uid,
                        farmId,
                        sensorId,
                        selectedCrop.cropId,
                        stageId: 1, // Reset sang giai đoạn 1 của cây mới
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Đã cập nhật $sensorId: ${selectedCrop.cropName}',
                            ),
                            backgroundColor: const Color(0xFF1B5E20),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    }
                  }
                }
              },
            ),
          ),
        ),

        // Dropdown chọn giai đoạn sinh trưởng
        Container(
          height: 30,
          constraints: BoxConstraints(maxWidth: maxStageWidth),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFA5D6A7)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              isDense: true,
              isExpanded: true,
              value: currentStage.stageId,
              icon: const Icon(
                Icons.alt_route_outlined,
                size: 14,
                color: Color(0xFF2E7D32),
              ),
              style: TextStyle(
                fontSize: compact ? 10.5 : 11.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1B5E20),
              ),
              items: currentCrop.growthStages.map((stage) {
                return DropdownMenuItem<int>(
                  value: stage.stageId,
                  child: Text(
                    'GĐ ${stage.stageId}: ${stage.stageName}',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (int? newStageId) async {
                if (newStageId != null) {
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  if (uid != null) {
                    await RTDBService().updateSensorCropAndStage(
                      uid,
                      farmId,
                      sensorId,
                      currentCrop.cropId,
                      stageId: newStageId,
                    );
                    if (context.mounted) {
                      final newStage = currentCrop.getStageById(newStageId);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Chuyển $sensorId sang: ${newStage.stageName}',
                          ),
                          backgroundColor: const Color(0xFF2E7D32),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
