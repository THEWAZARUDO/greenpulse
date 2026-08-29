import 'package:flutter/material.dart';
import '../../models/weather_model.dart';
import 'location_tile.dart';

class RecentAndPresetsView extends StatelessWidget {
  final List<WeatherLocation> recentList;
  final List<WeatherLocation> presets;
  final WeatherLocation? currentLocation;
  final ValueChanged<WeatherLocation> onSelect;
  final ValueChanged<WeatherLocation> onRemoveRecent;
  final VoidCallback onClearRecents;

  const RecentAndPresetsView({
    super.key,
    required this.recentList,
    required this.presets,
    this.currentLocation,
    required this.onSelect,
    required this.onRemoveRecent,
    required this.onClearRecents,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        // 1. Phần Lịch sử đã chọn gần đây (Lưu trữ tối đa 10)
        if (recentList.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.history, size: 16, color: Color(0xFF2E7D32)),
                  const SizedBox(width: 6),
                  Text(
                    'Đã chọn gần đây (${recentList.length}/10):',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: onClearRecents,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Xóa lịch sử',
                  style: TextStyle(fontSize: 11.5, color: Colors.redAccent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...recentList.map((loc) => LocationTile(
                loc: loc,
                currentLocation: currentLocation,
                isRecent: true,
                onSelect: onSelect,
                onRemoveRecent: onRemoveRecent,
              )),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
          const SizedBox(height: 12),
        ],

        // 2. Khu vực nông nghiệp trọng điểm (Presets)
        Row(
          children: [
            const Icon(Icons.eco_outlined, size: 16, color: Color(0xFF2E7D32)),
            const SizedBox(width: 6),
            Text(
              'Khu vực nông nghiệp trọng điểm (${presets.length}):',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ...presets.map((loc) => LocationTile(
              loc: loc,
              currentLocation: currentLocation,
              isRecent: false,
              onSelect: onSelect,
            )),
      ],
    );
  }
}
