import 'package:flutter/material.dart';
import '../../../models/farm_model.dart';
import '../../../widgets/plant_preset_dropdown.dart';
import '../dashboard_tab/status_badge.dart';

class AlertCard extends StatelessWidget {
  final SensorData sensor;
  final String farmId;

  const AlertCard({
    super.key,
    required this.sensor,
    required this.farmId,
  });

  @override
  Widget build(BuildContext context) {
    final status = sensor.overallStatus;
    final adviceList = sensor.adviceList;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: status.color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: status.color.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Icon(status.icon, color: status.color, size: 18),
                const SizedBox(width: 8),
                Text(
                  sensor.id,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: status.color,
                  ),
                ),
                const Spacer(),
                StatusBadge(status: status),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick metrics summary
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _MetricChip(
                        label: 'Nhiệt độ',
                        value: '${sensor.temperature}°C',
                        status: sensor.tempStatus,
                      ),
                      _MetricChip(
                        label: 'Độ ẩm KK',
                        value: '${sensor.humidity}%',
                        status: sensor.humidityStatus,
                      ),
                      _MetricChip(
                        label: 'Độ ẩm đất',
                        value: '${sensor.soil}%',
                        status: sensor.soilStatus,
                      ),
                      _MetricChip(
                        label: 'Ánh sáng',
                        value: '${sensor.light.toStringAsFixed(0)} lx',
                        status: sensor.lightStatus,
                      ),
                      _MetricChip(
                        label: 'pH',
                        value: '${sensor.ph}',
                        status: sensor.phStatus,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Plant Preset Dropdown selector
                PlantPresetDropdown(
                  farmId: farmId,
                  sensorId: sensor.id,
                  currentCropId: sensor.cropId,
                  currentStageId: sensor.stageId,
                ),
                const SizedBox(height: 12),

                // AI Advice list
                const Text(
                  'Khuyến nghị xử lý:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                const SizedBox(height: 6),
                ...adviceList.map(
                  (a) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '• ',
                          style: TextStyle(
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            a,
                            style: const TextStyle(
                              fontSize: 12.5,
                              height: 1.4,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final StatusLevel status;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: status.color,
          ),
        ),
      ],
    );
  }
}
