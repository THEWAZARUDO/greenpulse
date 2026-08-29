import 'package:flutter/material.dart';
import '../../models/weather_model.dart';

class WeatherHeader extends StatelessWidget {
  final WeatherData data;
  final VoidCallback onOpenLocationPicker;
  final VoidCallback onRefresh;

  const WeatherHeader({
    super.key,
    required this.data,
    required this.onOpenLocationPicker,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final current = data.current;
    final weatherInfo = WmoWeatherCode.getInfo(current.weatherCode, current.isDay);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: weatherInfo.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Semantics(
                  label: 'Vị trí hiện tại: ${data.location.displayName}. Nhấn để đổi vùng nông nghiệp.',
                  button: true,
                  child: GestureDetector(
                    onTap: onOpenLocationPicker,
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            data.location.displayName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
              // Nút đổi vị trí
              Semantics(
                label: 'Đổi vùng nông nghiệp',
                button: true,
                child: InkWell(
                  onTap: onOpenLocationPicker,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.tune, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'Đổi vùng',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Nút refresh
              Semantics(
                label: 'Làm mới thời tiết',
                button: true,
                child: InkWell(
                  onTap: onRefresh,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.refresh, color: Colors.white, size: 15),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Main Temp & Weather Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        current.temperature.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                      const Text(
                        '°C',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cảm giác như ${current.apparentTemperature.toStringAsFixed(1)}°C',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(
                    weatherInfo.icon,
                    size: 44,
                    color: weatherInfo.iconColor,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    weatherInfo.description,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
