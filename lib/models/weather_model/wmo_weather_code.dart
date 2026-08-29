import 'package:flutter/material.dart';

/// Bộ chuyển đổi mã WMO Weather Code
class WmoWeatherCode {
  final String description;
  final IconData icon;
  final Color iconColor;
  final List<Color> gradientColors;

  const WmoWeatherCode({
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.gradientColors,
  });

  static WmoWeatherCode getInfo(int code, bool isDay) {
    switch (code) {
      case 0:
        return WmoWeatherCode(
          description: isDay ? 'Trời quang đãng' : 'Đêm quang đãng',
          icon: isDay ? Icons.wb_sunny_rounded : Icons.nightlight_round,
          iconColor: isDay ? const Color(0xFFFFB300) : const Color(0xFFFFD54F),
          gradientColors: isDay
              ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32)]
              : [const Color(0xFF0D251A), const Color(0xFF1B4332)],
        );
      case 1:
      case 2:
        return WmoWeatherCode(
          description: isDay ? 'Nắng có mây' : 'Mây rải rác',
          icon: isDay ? Icons.wb_cloudy_rounded : Icons.nights_stay_rounded,
          iconColor: isDay ? const Color(0xFFFFCA28) : const Color(0xFFB0BEC5),
          gradientColors: isDay
              ? [const Color(0xFF2E7D32), const Color(0xFF388E3C)]
              : [const Color(0xFF1A3026), const Color(0xFF264653)],
        );
      case 3:
        return const WmoWeatherCode(
          description: 'Trời nhiều mây',
          icon: Icons.cloud_rounded,
          iconColor: Color(0xFF90A4AE),
          gradientColors: [Color(0xFF37474F), Color(0xFF455A64)],
        );
      case 45:
      case 48:
        return const WmoWeatherCode(
          description: 'Sương mù',
          icon: Icons.blur_on_rounded,
          iconColor: Color(0xFFB0BEC5),
          gradientColors: [Color(0xFF455A64), Color(0xFF546E7A)],
        );
      case 51:
      case 53:
      case 55:
        return const WmoWeatherCode(
          description: 'Mưa phùn nhẹ',
          icon: Icons.grain_rounded,
          iconColor: Color(0xFF81D4FA),
          gradientColors: [Color(0xFF1E3D34), Color(0xFF2B5346)],
        );
      case 61:
      case 63:
        return const WmoWeatherCode(
          description: 'Mưa rào',
          icon: Icons.water_drop_rounded,
          iconColor: Color(0xFF4FC3F7),
          gradientColors: [Color(0xFF154338), Color(0xFF1D5A4C)],
        );
      case 65:
        return const WmoWeatherCode(
          description: 'Mưa rất to',
          icon: Icons.thunderstorm_rounded,
          iconColor: Color(0xFF29B6F6),
          gradientColors: [Color(0xFF0E2F27), Color(0xFF1A4D40)],
        );
      case 80:
      case 81:
      case 82:
        return const WmoWeatherCode(
          description: 'Mưa dông từng cơn',
          icon: Icons.umbrella_rounded,
          iconColor: Color(0xFF4FC3F7),
          gradientColors: [Color(0xFF154338), Color(0xFF206354)],
        );
      case 95:
      case 96:
      case 99:
        return const WmoWeatherCode(
          description: 'Dông sét mạnh',
          icon: Icons.flash_on_rounded,
          iconColor: Color(0xFFFFD54F),
          gradientColors: [Color(0xFF311B92), Color(0xFF1A237E)],
        );
      default:
        return WmoWeatherCode(
          description: 'Thời tiết ổn định',
          icon: Icons.cloud_queue_rounded,
          iconColor: const Color(0xFF81C784),
          gradientColors: [const Color(0xFF1B5E20), const Color(0xFF2E7D32)],
        );
    }
  }
}
