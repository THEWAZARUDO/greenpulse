import 'package:flutter/material.dart';
import '../../../models/farm_model.dart';
import '../../../widgets/plant_preset_dropdown.dart';

class SensorRow extends StatelessWidget {
  final String farmId;
  final SensorData sensor;
  final bool isLast;
  final VoidCallback onDelete;

  const SensorRow({
    super.key,
    required this.farmId,
    required this.sensor,
    required this.isLast,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final status = sensor.overallStatus;

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: status.color, width: 3)),
      ),
      child: Row(
        children: [
          Icon(Icons.sensors, size: 16, color: status.color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sensor.id,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'pH ${sensor.ph}  •  ${sensor.temperature}°C  •  ${sensor.humidity}%  •  ${sensor.soil}%  •  ${sensor.light.toStringAsFixed(0)} lux',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 6),
                PlantPresetDropdown(
                  farmId: farmId,
                  sensorId: sensor.id,
                  currentCropId: sensor.cropId,
                  currentStageId: sensor.stageId,
                  compact: true,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: status.color,
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.close, size: 16, color: Colors.red.shade400),
            onPressed: onDelete,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
            tooltip: 'Gỡ cảm biến',
          ),
        ],
      ),
    );
  }
}
