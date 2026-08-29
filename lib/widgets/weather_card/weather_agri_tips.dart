import 'package:flutter/material.dart';

class WeatherAgriTips extends StatelessWidget {
  final List<String> tips;

  const WeatherAgriTips({super.key, required this.tips});

  @override
  Widget build(BuildContext context) {
    if (tips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F8F1),
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
                  Icons.spa_outlined,
                  size: 15,
                  color: Color(0xFF2E7D32),
                ),
                SizedBox(width: 6),
                Text(
                  'Khuyến nghị Nông học theo Thời tiết',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...tips.map(
              (tip) => Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  tip,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Colors.black87,
                    height: 1.35,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
