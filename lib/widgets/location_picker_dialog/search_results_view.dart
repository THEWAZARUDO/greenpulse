import 'package:flutter/material.dart';
import '../../models/weather_model.dart';
import 'location_tile.dart';

class SearchResultsView extends StatelessWidget {
  final bool isLoading;
  final List<WeatherLocation> searchResults;
  final WeatherLocation? currentLocation;
  final ValueChanged<WeatherLocation> onSelect;

  const SearchResultsView({
    super.key,
    required this.isLoading,
    required this.searchResults,
    this.currentLocation,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF2E7D32)),
              SizedBox(height: 12),
              Text('Đang tìm kiếm địa điểm...', style: TextStyle(fontSize: 12.5, color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    if (searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_off_outlined, size: 40, color: Colors.grey.shade400),
              const SizedBox(height: 10),
              Text(
                'Không tìm thấy địa điểm phù hợp.\nHãy thử tìm tên không dấu (VD: Ea Kar, Dak Lak)...',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kết quả tìm kiếm (${searchResults.length}):',
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            itemCount: searchResults.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
            itemBuilder: (context, index) {
              final loc = searchResults[index];
              return LocationTile(
                loc: loc,
                currentLocation: currentLocation,
                onSelect: onSelect,
              );
            },
          ),
        ),
      ],
    );
  }
}
