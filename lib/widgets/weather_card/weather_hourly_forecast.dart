import 'package:flutter/material.dart';
import '../../models/weather_model.dart';

class WeatherHourlyForecast extends StatelessWidget {
  final List<HourlyForecast> hourly;
  final DateTime updatedAt;

  const WeatherHourlyForecast({
    super.key,
    required this.hourly,
    required this.updatedAt,
  });

  String _formatHour(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:00';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Dự báo 24 giờ tới',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
              Text(
                'Cập nhật lúc ${_formatHour(updatedAt)}:${updatedAt.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 10.5,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: hourly.length,
            itemBuilder: (context, index) {
              final h = hourly[index];
              final isNow = index == 0;
              final hInfo = WmoWeatherCode.getInfo(h.weatherCode, h.isDay);

              return Container(
                width: 58,
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: isNow ? const Color(0xFFE8F5E9) : const Color(0xFFF9F9F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isNow ? const Color(0xFF81C784) : const Color(0xFFE0E0E0),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isNow ? 'Bây giờ' : _formatHour(h.time),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isNow ? FontWeight.bold : FontWeight.w500,
                        color: isNow ? const Color(0xFF1B5E20) : Colors.grey.shade700,
                      ),
                    ),
                    Icon(hInfo.icon, size: 20, color: hInfo.iconColor),
                    Text(
                      '${h.temperature.toStringAsFixed(0)}°',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (h.precipitationProbability > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.water_drop,
                            size: 8,
                            color: Color(0xFF0288D1),
                          ),
                          Text(
                            '${h.precipitationProbability}%',
                            style: const TextStyle(
                              fontSize: 8.5,
                              color: Color(0xFF0288D1),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    else
                      const SizedBox(height: 10),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
