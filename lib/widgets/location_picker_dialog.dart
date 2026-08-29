import 'dart:async';
import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';
import 'location_picker_dialog/recent_and_presets_view.dart';
import 'location_picker_dialog/search_results_view.dart';

export 'location_picker_dialog/location_tile.dart';
export 'location_picker_dialog/recent_and_presets_view.dart';
export 'location_picker_dialog/search_results_view.dart';

class LocationPickerDialog extends StatefulWidget {
  final WeatherLocation? currentLocation;

  const LocationPickerDialog({super.key, this.currentLocation});

  static Future<WeatherLocation?> show(
    BuildContext context, {
    WeatherLocation? currentLocation,
  }) {
    return showModalBottomSheet<WeatherLocation>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LocationPickerDialog(currentLocation: currentLocation),
    );
  }

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  final WeatherService _weatherService = WeatherService.instance;

  List<WeatherLocation> _searchResults = [];
  bool _isLoading = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _weatherService.recentLocationsNotifier.addListener(_onRecentChanged);
  }

  @override
  void dispose() {
    _weatherService.recentLocationsNotifier.removeListener(_onRecentChanged);
    _searchCtrl.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onRecentChanged() {
    if (mounted && _searchCtrl.text.trim().isEmpty) {
      setState(() {});
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      final results = await _weatherService.searchLocations(trimmed);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    });
  }

  void _selectLocation(WeatherLocation loc) {
    _weatherService.addRecentLocation(loc);
    Navigator.of(context).pop(loc);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isSearching = _searchCtrl.text.trim().isNotEmpty;
    final recentList = _weatherService.recentLocations;
    final presets = WeatherService.presetLocations;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: Color(0xFF2E7D32),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Chọn Vùng Nông Nghiệp / Tỉnh Thành',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Search Field
          TextField(
            controller: _searchCtrl,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Tìm vị trí: Ea Kar, Đắk Lắk, Đà Lạt...',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF2E7D32), size: 20),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF1F8F1),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Content body
          Flexible(
            child: isSearching
                ? SearchResultsView(
                    isLoading: _isLoading,
                    searchResults: _searchResults,
                    currentLocation: widget.currentLocation,
                    onSelect: _selectLocation,
                  )
                : RecentAndPresetsView(
                    recentList: recentList,
                    presets: presets,
                    currentLocation: widget.currentLocation,
                    onSelect: _selectLocation,
                    onRemoveRecent: (loc) => _weatherService.removeRecentLocation(loc),
                    onClearRecents: () => _weatherService.clearRecentLocations(),
                  ),
          ),
        ],
      ),
    );
  }
}
