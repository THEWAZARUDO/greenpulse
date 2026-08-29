import 'package:flutter/material.dart';
import '../../models/weather_model.dart';

class LocationTile extends StatelessWidget {
  final WeatherLocation loc;
  final WeatherLocation? currentLocation;
  final bool isRecent;
  final ValueChanged<WeatherLocation> onSelect;
  final ValueChanged<WeatherLocation>? onRemoveRecent;

  const LocationTile({
    super.key,
    required this.loc,
    this.currentLocation,
    this.isRecent = false,
    required this.onSelect,
    this.onRemoveRecent,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentLocation != null &&
        (currentLocation!.name.toLowerCase() == loc.name.toLowerCase() ||
            ((currentLocation!.latitude - loc.latitude).abs() < 0.05 &&
                (currentLocation!.longitude - loc.longitude).abs() < 0.05));

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2E7D32)
              : (isRecent ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9)),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isRecent ? Icons.history : Icons.place,
          size: 16,
          color: isSelected
              ? Colors.white
              : (isRecent ? const Color(0xFFE65100) : const Color(0xFF2E7D32)),
        ),
      ),
      title: Text(
        loc.name,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          fontSize: 13.5,
          color: isSelected ? const Color(0xFF1B5E20) : Colors.black87,
        ),
      ),
      subtitle: Text(
        loc.admin1 != null && loc.admin1!.isNotEmpty
            ? '${loc.admin1}, ${loc.country ?? 'Việt Nam'}'
            : (loc.country ?? 'Việt Nam'),
        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSelected)
            const Padding(
              padding: EdgeInsets.only(right: 6),
              child: Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 18),
            ),
          if (isRecent && onRemoveRecent != null)
            IconButton(
              icon: const Icon(Icons.close, size: 16, color: Colors.grey),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              splashRadius: 16,
              onPressed: () => onRemoveRecent!(loc),
            ),
        ],
      ),
      onTap: () => onSelect(loc),
    );
  }
}
