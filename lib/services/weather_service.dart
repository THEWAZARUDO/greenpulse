import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

class _WeatherCacheEntry {
  final WeatherData data;
  final DateTime timestamp;

  _WeatherCacheEntry({required this.data, required this.timestamp});

  bool get isValid => DateTime.now().difference(timestamp).inMinutes < 15;
}

class WeatherService {
  WeatherService._internal();
  static final WeatherService instance = WeatherService._internal();
  factory WeatherService() => instance;

  // Cache theo key: "lat_lng"
  final Map<String, _WeatherCacheEntry> _cache = {};

  /// Địa điểm mặc định (Đà Lạt - Trung tâm nông nghiệp công nghệ cao)
  static const WeatherLocation defaultLocation = WeatherLocation(
    name: 'Đà Lạt',
    admin1: 'Lâm Đồng',
    country: 'Việt Nam',
    latitude: 11.9404,
    longitude: 108.4583,
  );

  /// Danh sách các vùng nông nghiệp trọng điểm & đô thị lớn tại Việt Nam
  static const List<WeatherLocation> presetLocations = [
    WeatherLocation(
      name: 'Đà Lạt',
      admin1: 'Lâm Đồng',
      country: 'Việt Nam',
      latitude: 11.9404,
      longitude: 108.4583,
    ),
    WeatherLocation(
      name: 'Buôn Ma Thuột',
      admin1: 'Đắk Lắk',
      country: 'Việt Nam',
      latitude: 12.6667,
      longitude: 108.0500,
    ),
    WeatherLocation(
      name: 'Pleiku',
      admin1: 'Gia Lai',
      country: 'Việt Nam',
      latitude: 13.9833,
      longitude: 108.0000,
    ),
    WeatherLocation(
      name: 'Gia Nghĩa',
      admin1: 'Đắk Nông',
      country: 'Việt Nam',
      latitude: 12.0031,
      longitude: 107.6894,
    ),
    WeatherLocation(
      name: 'Đồng Xoài',
      admin1: 'Bình Phước',
      country: 'Việt Nam',
      latitude: 11.5333,
      longitude: 106.8833,
    ),
    WeatherLocation(
      name: 'Bảo Lộc',
      admin1: 'Lâm Đồng',
      country: 'Việt Nam',
      latitude: 11.5478,
      longitude: 107.8083,
    ),
    WeatherLocation(
      name: 'Long Khánh',
      admin1: 'Đồng Nai',
      country: 'Việt Nam',
      latitude: 10.9333,
      longitude: 107.2333,
    ),
    WeatherLocation(
      name: 'Mộc Châu',
      admin1: 'Sơn La',
      country: 'Việt Nam',
      latitude: 20.8400,
      longitude: 104.6400,
    ),
    WeatherLocation(
      name: 'TP. Hồ Chí Minh',
      admin1: 'Hồ Chí Minh',
      country: 'Việt Nam',
      latitude: 10.8231,
      longitude: 106.6297,
    ),
    WeatherLocation(
      name: 'Hà Nội',
      admin1: 'Hà Nội',
      country: 'Việt Nam',
      latitude: 21.0285,
      longitude: 105.8542,
    ),
    WeatherLocation(
      name: 'Cần Thơ',
      admin1: 'Cần Thơ',
      country: 'Việt Nam',
      latitude: 10.0452,
      longitude: 105.7469,
    ),
    WeatherLocation(
      name: 'Mỹ Tho',
      admin1: 'Tiền Giang',
      country: 'Việt Nam',
      latitude: 10.3544,
      longitude: 106.3653,
    ),
  ];

  // ValueNotifier lưu địa điểm hiện đang được chọn
  final ValueNotifier<WeatherLocation> currentLocationNotifier =
      ValueNotifier<WeatherLocation>(defaultLocation);

  WeatherLocation get currentLocation => currentLocationNotifier.value;

  void setCurrentLocation(WeatherLocation loc) {
    currentLocationNotifier.value = loc;
  }

  /// Lấy dự báo thời tiết từ Open-Meteo API
  Future<WeatherData> getForecast({
    WeatherLocation? location,
    bool forceRefresh = false,
  }) async {
    final targetLoc = location ?? currentLocation;
    final cacheKey =
        '${targetLoc.latitude.toStringAsFixed(3)}_${targetLoc.longitude.toStringAsFixed(3)}';

    if (!forceRefresh &&
        _cache.containsKey(cacheKey) &&
        _cache[cacheKey]!.isValid) {
      return _cache[cacheKey]!.data;
    }

    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=${targetLoc.latitude}'
      '&longitude=${targetLoc.longitude}'
      '&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,weather_code,wind_speed_10m,surface_pressure'
      '&hourly=temperature_2m,relative_humidity_2m,precipitation_probability,weather_code,is_day,uv_index'
      '&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,uv_index_max'
      '&timezone=auto',
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        final weatherData = WeatherData.fromOpenMeteo(
          location: targetLoc,
          json: data,
        );

        _cache[cacheKey] = _WeatherCacheEntry(
          data: weatherData,
          timestamp: DateTime.now(),
        );

        return weatherData;
      } else {
        throw Exception('Lỗi Open-Meteo Server (Mã ${response.statusCode})');
      }
    } catch (e) {
      // Nếu có cache cũ dù hết hạn thì vẫn trả về cache cũ khi mất mạng
      if (_cache.containsKey(cacheKey)) {
        return _cache[cacheKey]!.data;
      }
      debugPrint('Lỗi khi lấy dữ liệu thời tiết: $e');
      rethrow;
    }
  }

  /// Tìm kiếm địa điểm qua Open-Meteo Geocoding API
  Future<List<WeatherLocation>> searchLocations(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    // Tìm kiếm trong preset trước
    final localMatches = presetLocations.where((loc) {
      final q = trimmed.toLowerCase();
      return loc.name.toLowerCase().contains(q) ||
          (loc.admin1?.toLowerCase().contains(q) ?? false);
    }).toList();

    try {
      final uri = Uri.parse(
        'https://geocoding-api.open-meteo.com/v1/search'
        '?name=${Uri.encodeComponent(trimmed)}'
        '&count=10'
        '&language=vi'
        '&format=json',
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        final List results = (data['results'] as List?) ?? [];

        final apiMatches = results.map((item) {
          return WeatherLocation.fromJson(Map<String, dynamic>.from(item as Map));
        }).toList();

        // Kết hợp và loại bỏ trùng lặp
        final combined = <WeatherLocation>[...localMatches];
        for (var apiLoc in apiMatches) {
          final isDup = combined.any((item) =>
              item.name.toLowerCase() == apiLoc.name.toLowerCase() &&
              (item.latitude - apiLoc.latitude).abs() < 0.1 &&
              (item.longitude - apiLoc.longitude).abs() < 0.1);
          if (!isDup) {
            combined.add(apiLoc);
          }
        }
        return combined;
      }
    } catch (e) {
      debugPrint('Lỗi Geocoding search: $e');
    }

    return localMatches;
  }
}
