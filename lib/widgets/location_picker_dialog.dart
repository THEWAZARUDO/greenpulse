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
  final WeatherService _weatherService = WeatherService();

  List<WeatherLocation> _searchResults = [];
  bool _isLoading = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchResults = WeatherService.presetLocations;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = WeatherService.presetLocations;
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      final results = await _weatherService.searchLocations(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
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
              hintText: 'Nhập tên tỉnh, thành phố (VD: Lâm Đồng, Đà Lạt...)',
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

          // Quick presets label
          Text(
            _searchCtrl.text.isEmpty
                ? 'Khu vực nông nghiệp trọng điểm:'
                : 'Kết quả tìm kiếm (${_searchResults.length}):',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 10),

          // Results list
          Flexible(
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  )
                : _searchResults.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Không tìm thấy địa điểm phù hợp.\nHãy thử tìm kiếm tên không dấu hoặc tỉnh lân cận.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
                        itemBuilder: (context, index) {
                          final loc = _searchResults[index];
                          final isSelected = widget.currentLocation != null &&
                              (widget.currentLocation!.name == loc.name ||
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
                                    : const Color(0xFFE8F5E9),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.place,
                                size: 16,
                                color: isSelected ? Colors.white : const Color(0xFF2E7D32),
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
                            trailing: isSelected
                                ? const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 18)
                                : null,
                            onTap: () {
                              Navigator.of(context).pop(loc);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
