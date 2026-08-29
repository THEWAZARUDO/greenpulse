import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/farm_model.dart';
import '../../../models/plant_preset_manager.dart';
import '../../../services/rtdb_service.dart';
import 'section_card.dart';
import 'threshold_row.dart';

class ThresholdReferenceCard extends StatefulWidget {
  const ThresholdReferenceCard({super.key});

  @override
  State<ThresholdReferenceCard> createState() => _ThresholdReferenceCardState();
}

class _ThresholdReferenceCardState extends State<ThresholdReferenceCard> {
  String? _selectedSensorId;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox();

    return StreamBuilder<List<SensorData>>(
      stream: RTDBService().watchAllSensors(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SectionCard(
            title: 'Ngưỡng an toàn cây trồng',
            icon: Icons.tune_outlined,
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ],
          );
        }

        final sensors = snapshot.data!;
        if (sensors.isEmpty) {
          return const SectionCard(
            title: 'Ngưỡng an toàn cây trồng',
            icon: Icons.tune_outlined,
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text('Bạn chưa có mạch/cảm biến nào.'),
              ),
            ],
          );
        }

        // Đảm bảo selectedSensorId hợp lệ
        if (_selectedSensorId == null ||
            !sensors.any((s) => s.id == _selectedSensorId)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _selectedSensorId = sensors.first.id);
          });
        }

        final safeSensorId = _selectedSensorId ?? sensors.first.id;
        final selectedSensor = sensors.firstWhere(
          (s) => s.id == safeSensorId,
          orElse: () => sensors.first,
        );

        final crop = PlantPresetManager.getCropById(selectedSensor.cropId);
        final stage = crop?.getStageById(selectedSensor.stageId);

        return SectionCard(
          title: 'Ngưỡng an toàn cho cây trồng.',
          icon: Icons.tune_outlined,
          titleTrailing: Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isDense: true,
                value: safeSensorId,
                icon: const Icon(
                  Icons.arrow_drop_down,
                  size: 16,
                  color: Color(0xFF2E7D32),
                ),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
                items: sensors.map((sensor) {
                  String display = sensor.id;
                  if (display.length > 10) {
                    display = '${display.substring(0, 10)}...';
                  }
                  return DropdownMenuItem<String>(
                    value: sensor.id,
                    child: Text(display),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedSensorId = val);
                },
              ),
            ),
          ),
          children: (crop == null || stage == null)
              ? [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Không có dữ liệu loại cây'),
                  ),
                ]
              : [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      'Cây: ${crop.cropName} • Giai đoạn: ${stage.stageName}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                  ),
                  ThresholdRow(
                    icon: Icons.science_outlined,
                    label: 'Độ pH đất an toàn',
                    value: '${crop.soilPhMin} – ${crop.soilPhMax} pH',
                    color: const Color(0xFF8E24AA),
                  ),
                  ThresholdRow(
                    icon: Icons.thermostat_outlined,
                    label: 'Nhiệt độ tối ưu',
                    value: '${stage.tempMin} – ${stage.tempMax} °C',
                    color: const Color(0xFFEF5350),
                  ),
                  ThresholdRow(
                    icon: Icons.water_drop_outlined,
                    label: 'Độ ẩm không khí',
                    value: '${stage.airHumidityMin} – ${stage.airHumidityMax} %',
                    color: const Color(0xFF42A5F5),
                  ),
                  ThresholdRow(
                    icon: Icons.grass_outlined,
                    label: 'Độ ẩm đất tối ưu',
                    value: '${stage.soilMoistureMin} – ${stage.soilMoistureMax} %',
                    color: const Color(0xFF8D6E63),
                  ),
                  ThresholdRow(
                    icon: Icons.wb_sunny_outlined,
                    label: 'Ánh sáng tối ưu',
                    value: '${stage.luxMin} – ${stage.luxMax} lux',
                    color: const Color(0xFFFFA726),
                  ),
                ],
        );
      },
    );
  }
}
