/// Đại diện cho một địa điểm dự báo thời tiết
class WeatherLocation {
  final String name;
  final String? admin1; // Tỉnh / Thành phố
  final String? country;
  final double latitude;
  final double longitude;

  const WeatherLocation({
    required this.name,
    this.admin1,
    this.country,
    required this.latitude,
    required this.longitude,
  });

  String get displayName {
    if (admin1 != null && admin1!.isNotEmpty && admin1 != name) {
      return '$name, $admin1';
    }
    return name;
  }

  factory WeatherLocation.fromJson(Map<String, dynamic> json) {
    return WeatherLocation(
      name: json['name'] as String? ?? 'Không xác định',
      admin1: json['admin1'] as String?,
      country: json['country'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'admin1': admin1,
        'country': country,
        'latitude': latitude,
        'longitude': longitude,
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WeatherLocation &&
        other.name.toLowerCase() == name.toLowerCase() &&
        (other.latitude - latitude).abs() < 0.01 &&
        (other.longitude - longitude).abs() < 0.01;
  }

  @override
  int get hashCode =>
      name.toLowerCase().hashCode ^
      (latitude * 100).round().hashCode ^
      (longitude * 100).round().hashCode;
}
