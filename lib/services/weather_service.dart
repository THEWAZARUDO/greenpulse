import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weather_model.dart';
import 'weather_service/weather_cache.dart';
import 'weather_service/weather_location_presets.dart';
import 'weather_service/weather_string_utils.dart';

export 'weather_service/weather_cache.dart';
export 'weather_service/weather_location_presets.dart';
export 'weather_service/weather_string_utils.dart';

class WeatherService {
  WeatherService._internal();
  static final WeatherService instance = WeatherService._internal();
  factory WeatherService() => instance;

  // SharedPreferences Keys & Limits
  static const String _keyCurrentLocation = 'weather_current_location';
  static const String _keyRecentLocations = 'weather_recent_locations';
  static const int maxRecentLocations = 10;

  // Cache theo key: "lat_lng"
  final Map<String, WeatherCacheEntry> _cache = {};

  /// Địa điểm mặc định (Ea Kar - Đắk Lắk)
  static const WeatherLocation defaultLocation = WeatherLocationPresets.defaultLocation;

  /// Danh sách các vùng nông nghiệp trọng điểm & đô thị lớn tại Việt Nam
  static const List<WeatherLocation> presetLocations = WeatherLocationPresets.presetLocations;

  // ValueNotifier lưu địa điểm hiện đang được chọn
  final ValueNotifier<WeatherLocation> currentLocationNotifier =
      ValueNotifier<WeatherLocation>(defaultLocation);

  // ValueNotifier lưu lịch sử các địa danh đã chọn gần nhất (tối đa 10)
  final ValueNotifier<List<WeatherLocation>> recentLocationsNotifier =
      ValueNotifier<List<WeatherLocation>>([]);

  WeatherLocation get currentLocation => currentLocationNotifier.value;
  List<WeatherLocation> get recentLocations => recentLocationsNotifier.value;

  bool _isInitialized = false;

  /// Khởi tạo và nạp dữ liệu đã lưu từ SharedPreferences
  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Nạp vị trí hiện tại đã lưu
      final currentLocJson = prefs.getString(_keyCurrentLocation);
      if (currentLocJson != null && currentLocJson.isNotEmpty) {
        final decoded = json.decode(currentLocJson) as Map<String, dynamic>;
        currentLocationNotifier.value = WeatherLocation.fromJson(decoded);
      }

      // 2. Nạp danh sách lịch sử địa danh đã chọn gần đây (tối đa 10)
      final recentListJson = prefs.getStringList(_keyRecentLocations);
      if (recentListJson != null && recentListJson.isNotEmpty) {
        final loadedRecents = <WeatherLocation>[];
        for (final itemStr in recentListJson) {
          try {
            final decoded = json.decode(itemStr) as Map<String, dynamic>;
            loadedRecents.add(WeatherLocation.fromJson(decoded));
          } catch (_) {}
        }
        recentLocationsNotifier.value = List.unmodifiable(loadedRecents);
      }
    } catch (e) {
      debugPrint('Lỗi khởi tạo WeatherService SharedPreferences: $e');
    }
  }

  /// Cập nhật vị trí hiện tại và tự động thêm vào lịch sử gần đây
  Future<void> setCurrentLocation(WeatherLocation loc) async {
    currentLocationNotifier.value = loc;

    // Lưu vào SharedPreferences & cập nhật danh sách recent
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyCurrentLocation, json.encode(loc.toJson()));
    } catch (e) {
      debugPrint('Lỗi lưu currentLocation: $e');
    }

    await addRecentLocation(loc);
  }

  /// Thêm một địa danh vào danh sách đã chọn gần nhất (tối đa 10 địa danh)
  Future<void> addRecentLocation(WeatherLocation loc) async {
    try {
      final currentList = List<WeatherLocation>.from(recentLocationsNotifier.value);

      // Loại bỏ nếu đã tồn tại trước đó
      currentList.removeWhere((item) =>
          item.name.toLowerCase() == loc.name.toLowerCase() &&
          (item.latitude - loc.latitude).abs() < 0.02 &&
          (item.longitude - loc.longitude).abs() < 0.02);

      // Thêm lên đầu danh sách
      currentList.insert(0, loc);

      // Giữ tối đa 10 địa danh
      if (currentList.length > maxRecentLocations) {
        currentList.removeRange(maxRecentLocations, currentList.length);
      }

      recentLocationsNotifier.value = List.unmodifiable(currentList);

      // Lưu lại vào SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final stringList = currentList.map((item) => json.encode(item.toJson())).toList();
      await prefs.setStringList(_keyRecentLocations, stringList);
    } catch (e) {
      debugPrint('Lỗi lưu recentLocations: $e');
    }
  }

  /// Xóa một địa danh cụ thể khỏi lịch sử gần đây
  Future<void> removeRecentLocation(WeatherLocation loc) async {
    try {
      final currentList = List<WeatherLocation>.from(recentLocationsNotifier.value);
      currentList.removeWhere((item) =>
          item.name.toLowerCase() == loc.name.toLowerCase() &&
          (item.latitude - loc.latitude).abs() < 0.02 &&
          (item.longitude - loc.longitude).abs() < 0.02);

      recentLocationsNotifier.value = List.unmodifiable(currentList);

      final prefs = await SharedPreferences.getInstance();
      final stringList = currentList.map((item) => json.encode(item.toJson())).toList();
      await prefs.setStringList(_keyRecentLocations, stringList);
    } catch (e) {
      debugPrint('Lỗi xóa recentLocation: $e');
    }
  }

  /// Xóa toàn bộ lịch sử địa danh gần đây
  Future<void> clearRecentLocations() async {
    try {
      recentLocationsNotifier.value = const [];
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyRecentLocations);
    } catch (e) {
      debugPrint('Lỗi xóa toàn bộ recentLocations: $e');
    }
  }

  /// Hàm loại bỏ dấu tiếng Việt để so sánh tìm kiếm thông minh
  static String removeDiacritics(String str, {bool toLowerCase = false}) {
    return WeatherStringUtils.removeDiacritics(str, toLowerCase: toLowerCase);
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
      '&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,weather_code,wind_speed_10m,surface_pressure,uv_index'
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

        _cache[cacheKey] = WeatherCacheEntry(
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

  /// Tìm kiếm địa điểm thông minh qua Preset, Recent & Open-Meteo Geocoding API
  Future<List<WeatherLocation>> searchLocations(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return presetLocations;
    }

    // 1. Tách chuỗi theo các ký tự phân cách thông dụng: /, -, ,, _, |
    final rawTokens = trimmed
        .split(RegExp(r'[/,\-_|]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final primaryToken = rawTokens.isNotEmpty ? rawTokens.first : trimmed;
    final secondaryToken = rawTokens.length > 1 ? rawTokens[1] : null;

    final primaryClean = primaryToken.toLowerCase();
    final primaryUnaccented = removeDiacritics(primaryClean).replaceAll(' ', '');

    // 2. Tra cứu Alias / Từ điển tên chuẩn hóa
    final aliasMatch = WeatherLocationPresets.locationAliases[primaryClean] ??
        WeatherLocationPresets.locationAliases[primaryUnaccented] ??
        WeatherLocationPresets.locationAliases[removeDiacritics(primaryClean)];

    final searchNames = <String>{};
    if (aliasMatch != null) {
      searchNames.add(aliasMatch);
    }
    searchNames.add(primaryToken);
    if (secondaryToken != null) {
      final secClean = secondaryToken.toLowerCase();
      final secUnaccented = removeDiacritics(secClean).replaceAll(' ', '');
      final secAlias = WeatherLocationPresets.locationAliases[secClean] ??
          WeatherLocationPresets.locationAliases[secUnaccented];
      if (secAlias != null) {
        searchNames.add(secAlias);
      } else {
        searchNames.add(secondaryToken);
      }
    }

    // 3. Tìm kiếm trong Recent & Preset (Local Matches)
    final localCandidates = <WeatherLocation>[
      ...recentLocations,
      ...presetLocations,
    ];

    final localMatches = <WeatherLocation>[];
    for (final loc in localCandidates) {
      final locName = loc.name.toLowerCase();
      final locAdmin = (loc.admin1 ?? '').toLowerCase();
      final locNameNoMark = removeDiacritics(locName);
      final locAdminNoMark = removeDiacritics(locAdmin);

      bool isMatch = false;
      for (final sName in searchNames) {
        final sClean = sName.toLowerCase();
        final sNoMark = removeDiacritics(sClean);

        if (locName.contains(sClean) ||
            locNameNoMark.contains(sNoMark) ||
            locAdmin.contains(sClean) ||
            locAdminNoMark.contains(sNoMark) ||
            locNameNoMark.replaceAll(' ', '').contains(sNoMark.replaceAll(' ', ''))) {
          isMatch = true;
          break;
        }
      }

      if (isMatch && !localMatches.any((m) => m == loc)) {
        localMatches.add(loc);
      }
    }

    // 4. Tìm kiếm qua Open-Meteo Geocoding API cho các từ khóa hợp lệ
    final apiMatches = <WeatherLocation>[];
    final apiQueries = searchNames.take(2).toList();

    for (final queryStr in apiQueries) {
      try {
        final uri = Uri.parse(
          'https://geocoding-api.open-meteo.com/v1/search'
          '?name=${Uri.encodeComponent(queryStr)}'
          '&count=10'
          '&language=vi'
          '&format=json',
        );

        final response = await http.get(uri).timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) {
          final Map<String, dynamic> data =
              json.decode(utf8.decode(response.bodyBytes));
          final List results = (data['results'] as List?) ?? [];

          for (final item in results) {
            final loc = WeatherLocation.fromJson(Map<String, dynamic>.from(item as Map));
            final isDup = apiMatches.any((existing) =>
                existing.name.toLowerCase() == loc.name.toLowerCase() &&
                (existing.latitude - loc.latitude).abs() < 0.05 &&
                (existing.longitude - loc.longitude).abs() < 0.05);

            if (!isDup) {
              apiMatches.add(loc);
            }
          }
        }
      } catch (e) {
        debugPrint('Lỗi Geocoding search với "$queryStr": $e');
      }
    }

    // 5. Kết hợp & Sắp xếp thứ tự ưu tiên
    final combined = <WeatherLocation>[...localMatches];
    for (final apiLoc in apiMatches) {
      final isDup = combined.any((item) =>
          item.name.toLowerCase() == apiLoc.name.toLowerCase() &&
          (item.latitude - apiLoc.latitude).abs() < 0.05 &&
          (item.longitude - apiLoc.longitude).abs() < 0.05);

      if (!isDup) {
        combined.add(apiLoc);
      }
    }

    // Nếu người dùng nhập thêm tỉnh/thành phụ (ví dụ Eakar/Đắk Lắk), ưu tiên kết quả khớp cả 2 lên đầu
    if (secondaryToken != null && secondaryToken.isNotEmpty) {
      final secNoMark = removeDiacritics(secondaryToken.toLowerCase());
      combined.sort((a, b) {
        final aAdminNoMark = removeDiacritics((a.admin1 ?? '').toLowerCase());
        final bAdminNoMark = removeDiacritics((b.admin1 ?? '').toLowerCase());
        final aMatches = aAdminNoMark.contains(secNoMark);
        final bMatches = bAdminNoMark.contains(secNoMark);
        if (aMatches && !bMatches) return -1;
        if (!aMatches && bMatches) return 1;
        return 0;
      });
    }

    return combined;
  }
}
