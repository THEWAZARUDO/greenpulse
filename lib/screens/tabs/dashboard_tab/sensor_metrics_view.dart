import 'package:flutter/material.dart';
import '../../../models/farm_model.dart';
import '../../../models/plant_preset_manager.dart';
import 'status_badge.dart';
import 'metric_tile.dart';

class SensorMetricsView extends StatelessWidget {
  final String farmId;
  final SensorData sensor;

  const SensorMetricsView({
    super.key,
    required this.farmId,
    required this.sensor,
  });

  @override
  Widget build(BuildContext context) {
    final overall = sensor.overallStatus;
    final adviceList = sensor.adviceList;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sensor header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.sensors,
                      size: 13,
                      color: Color(0xFF2E7D32),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      sensor.id,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              StatusBadge(status: overall),
            ],
          ),
          const SizedBox(height: 14),

          // 5 Metric Grid
          Builder(
            builder: (context) {
              final crop = PlantPresetManager.getCropById(sensor.cropId);
              final stage = crop?.getStageById(sensor.stageId);
              final maxLux = (stage?.luxMax ?? 100000.0) <= 0 ? 100000.0 : stage!.luxMax;
              final screenWidth = MediaQuery.of(context).size.width;
              final dynamicRatio = screenWidth < 380 ? 1.58 : 1.70;

              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: dynamicRatio,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  MetricTile(
                    label: 'Nhiệt độ',
                    value: '${sensor.temperature.toStringAsFixed(1)}°C',
                    icon: Icons.thermostat_outlined,
                    status: sensor.tempStatus,
                    progress: ((sensor.temperature - 12) / (35 - 12)).clamp(
                      0.0,
                      1.0,
                    ),
                  ),
                  MetricTile(
                    label: 'Độ ẩm KK',
                    value: '${sensor.humidity.toStringAsFixed(1)}%',
                    icon: Icons.water_drop_outlined,
                    status: sensor.humidityStatus,
                    progress: (sensor.humidity / 100).clamp(0.0, 1.0),
                  ),
                  MetricTile(
                    label: 'Độ ẩm đất',
                    value: '${sensor.soil.toStringAsFixed(1)}%',
                    icon: Icons.grass_outlined,
                    status: sensor.soilStatus,
                    progress: (sensor.soil / 100).clamp(0.0, 1.0),
                  ),
                  MetricTile(
                    label: 'Ánh sáng',
                    value: '${sensor.light.toStringAsFixed(0)} lux',
                    icon: Icons.wb_sunny_outlined,
                    status: sensor.lightStatus,
                    progress: (sensor.light / maxLux).clamp(0.0, 1.0),
                  ),
                  MetricTile(
                    label: 'pH Đất',
                    value: '${sensor.ph.toStringAsFixed(1)} pH',
                    icon: Icons.science_outlined,
                    status: sensor.phStatus,
                    progress: (sensor.ph / 14.0).clamp(0.0, 1.0),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),

          // AI advice box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1B5E20).withValues(alpha: 0.06),
                  const Color(0xFF2E7D32).withValues(alpha: 0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.psychology_outlined,
                      size: 16,
                      color: Color(0xFF2E7D32),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Đánh giá & Khuyến nghị AI',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...adviceList.map(
                  (a) => Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      a,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
        ],
      ),
    );
  }
}
