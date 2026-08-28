import 'dart:async';
import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';

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
                ? _buildSearchResults()
                : _buildRecentAndPresets(recentList, presets),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
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

    if (_searchResults.isEmpty) {
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
          'Kết quả tìm kiếm (${_searchResults.length}):',
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            itemCount: _searchResults.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
            itemBuilder: (context, index) {
              final loc = _searchResults[index];
              return _buildLocationTile(loc);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentAndPresets(List<WeatherLocation> recentList, List<WeatherLocation> presets) {
    return ListView(
      children: [
        // ── 1. Phần Lịch sử đã chọn gần đây (Lưu trữ tối đa 10) ───────────
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
                onPressed: () => _weatherService.clearRecentLocations(),
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
          ...recentList.map((loc) => _buildLocationTile(loc, isRecent: true)),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
          const SizedBox(height: 12),
        ],

        // ── 2. Khu vực nông nghiệp trọng điểm (Presets) ───────────────────
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
        ...presets.map((loc) => _buildLocationTile(loc)),
      ],
    );
  }

  Widget _buildLocationTile(WeatherLocation loc, {bool isRecent = false}) {
    final isSelected = widget.currentLocation != null &&
        (widget.currentLocation!.name.toLowerCase() == loc.name.toLowerCase() ||
            ((widget.currentLocation!.latitude - loc.latitude).abs() < 0.05 &&
                (widget.currentLocation!.longitude - loc.longitude).abs() < 0.05));

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
          if (isRecent)
            IconButton(
              icon: const Icon(Icons.close, size: 16, color: Colors.grey),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              splashRadius: 16,
              onPressed: () => _weatherService.removeRecentLocation(loc),
            ),
        ],
      ),
      onTap: () => _selectLocation(loc),
    );
  }
}

