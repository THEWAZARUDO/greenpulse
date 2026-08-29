import 'package:flutter/material.dart';
import '../../models/weather_model.dart';

class WeatherMetricsRow extends StatelessWidget {
  final CurrentWeather current;

  const WeatherMetricsRow({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Row(
        children: [
          _buildMetricItem(
            icon: Icons.water_drop_outlined,
            label: 'Độ ẩm KK',
            value: '${current.humidity.toStringAsFixed(0)}%',
            iconColor: const Color(0xFF0288D1),
          ),
          _buildDivider(),
          _buildMetricItem(
            icon: Icons.umbrella_outlined,
            label: 'Mưa hiện tại',
            value: '${current.precipitation.toStringAsFixed(1)} mm',
            iconColor: const Color(0xFF00ACC1),
          ),
          _buildDivider(),
          _buildMetricItem(
            icon: Icons.air_outlined,
            label: 'Tốc độ gió',
            value: '${current.windSpeed.toStringAsFixed(1)} km/h',
            iconColor: const Color(0xFF5E35B1),
          ),
          _buildDivider(),
          _buildMetricItem(
            icon: Icons.wb_sunny_outlined,
            label: 'Chỉ số UV',
            value: current.uvIndex.toStringAsFixed(1),
            iconColor: const Color(0xFFF57C00),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 26,
      color: const Color(0xFFEEEEEE),
    );
  }
}
