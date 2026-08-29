import 'package:flutter/material.dart';
import '../../models/weather_model.dart';

class WeatherDailyForecast extends StatefulWidget {
  final List<DailyForecast> daily;

  const WeatherDailyForecast({super.key, required this.daily});

  @override
  State<WeatherDailyForecast> createState() => _WeatherDailyForecastState();
}

class _WeatherDailyForecastState extends State<WeatherDailyForecast> {
  bool _is7DaysExpanded = false;

  String _formatDayName(DateTime dt, int index) {
    if (index == 0) return 'Hôm nay';
    if (index == 1) return 'Ngày mai';
    switch (dt.weekday) {
      case 1:
        return 'Thứ Hai';
      case 2:
        return 'Thứ Ba';
      case 3:
        return 'Thứ Tư';
      case 4:
        return 'Thứ Năm';
      case 5:
        return 'Thứ Sáu';
      case 6:
        return 'Thứ Bảy';
      case 7:
        return 'Chủ Nhật';
      default:
        return '${dt.day}/${dt.month}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
          child: InkWell(
            onTap: () {
              setState(() => _is7DaysExpanded = !_is7DaysExpanded);
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.calendar_month_outlined, size: 14, color: Color(0xFF2E7D32)),
                      SizedBox(width: 6),
                      Text(
                        'Dự báo 7 ngày tới',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        _is7DaysExpanded ? 'Thu gọn' : 'Xem chi tiết',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(
                        _is7DaysExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 16,
                        color: const Color(0xFF2E7D32),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_is7DaysExpanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
            child: Column(
              children: widget.daily.asMap().entries.map((e) {
                final index = e.key;
                final d = e.value;
                final dInfo = WmoWeatherCode.getInfo(d.weatherCode, true);

                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: index == 0 ? const Color(0xFFF1F8F1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 75,
                        child: Text(
                          _formatDayName(d.date, index),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: index == 0 ? FontWeight.bold : FontWeight.w500,
                            color: index == 0 ? const Color(0xFF1B5E20) : Colors.black87,
                          ),
                        ),
                      ),
                      Icon(dInfo.icon, size: 18, color: dInfo.iconColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          dInfo.description,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (d.precipitationProbabilityMax > 0)
                        Row(
                          children: [
                            const Icon(Icons.water_drop, size: 10, color: Color(0xFF0288D1)),
                            const SizedBox(width: 2),
                            Text(
                              '${d.precipitationProbabilityMax}%',
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: Color(0xFF0288D1),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ),
                      Text(
                        '${d.tempMin.toStringAsFixed(0)}° - ${d.tempMax.toStringAsFixed(0)}°C',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          )
        else
          const SizedBox(height: 6),
      ],
    );
  }
}
