import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';
import 'location_picker_dialog.dart';

class WeatherCard extends StatefulWidget {
  final WeatherLocation? initialLocation;

  const WeatherCard({super.key, this.initialLocation});

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
  final WeatherService _weatherService = WeatherService.instance;
  late Future<WeatherData> _weatherFuture;
  bool _is7DaysExpanded = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _weatherService.setCurrentLocation(widget.initialLocation!);
    }
    _loadWeather(forceRefresh: false);

    _weatherService.currentLocationNotifier.addListener(_onLocationChanged);
  }

  @override
  void dispose() {
    _weatherService.currentLocationNotifier.removeListener(_onLocationChanged);
    super.dispose();
  }

  void _onLocationChanged() {
    if (mounted) {
      _loadWeather(forceRefresh: false);
    }
  }

  void _loadWeather({bool forceRefresh = false}) {
    setState(() {
      _weatherFuture = _weatherService.getForecast(
        location: _weatherService.currentLocation,
        forceRefresh: forceRefresh,
      );
    });
  }

  Future<void> _openLocationPicker() async {
    final selected = await LocationPickerDialog.show(
      context,
      currentLocation: _weatherService.currentLocation,
    );
    if (selected != null) {
      _weatherService.setCurrentLocation(selected);
      _loadWeather(forceRefresh: true);
    }
  }

  String _formatHour(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:00';
  }

  String _formatDayName(DateTime dt, int index) {
    if (index == 0) return 'Hôm nay';
    if (index == 1) return 'Ngày mai';
    switch (dt.weekday) {
      case 1:
        return 'Thứ Hai';
      case 2:
        return 'Thứ Ba';
      case 3:
        return 'Thứ Tư';
      case 4:
        return 'Thứ Năm';
      case 5:
        return 'Thứ Sáu';
      case 6:
        return 'Thứ Bảy';
      case 7:
        return 'Chủ Nhật';
      default:
        return '${dt.day}/${dt.month}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B5E20).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: FutureBuilder<WeatherData>(
        future: _weatherFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return _buildErrorState(snapshot.error?.toString() ?? 'Lỗi tải thời tiết');
          }

          final data = snapshot.data!;
          final current = data.current;
          final weatherInfo = WmoWeatherCode.getInfo(current.weatherCode, current.isDay);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: Location & Switch Button ────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: weatherInfo.gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Semantics(
                            label: 'Vị trí hiện tại: ${data.location.displayName}. Nhấn để đổi vùng nông nghiệp.',
                            button: true,
                            child: GestureDetector(
                              onTap: _openLocationPicker,
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      data.location.displayName,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Nút đổi vị trí
                        Semantics(
                          label: 'Đổi vùng nông nghiệp',
                          button: true,
                          child: InkWell(
                            onTap: _openLocationPicker,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.tune, color: Colors.white, size: 12),
                                  SizedBox(width: 4),
                                  Text(
                                    'Đổi vùng',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Nút refresh
                        Semantics(
                          label: 'Làm mới thời tiết',
                          button: true,
                          child: InkWell(
                            onTap: () => _loadWeather(forceRefresh: true),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.refresh, color: Colors.white, size: 15),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),


                    // ── Main Temp & Weather Status ────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  current.temperature.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    height: 1.0,
                                  ),
                                ),
                                const Text(
                                  '°C',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Cảm giác như ${current.apparentTemperature.toStringAsFixed(1)}°C',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Icon(
                              weatherInfo.icon,
                              size: 44,
                              color: weatherInfo.iconColor,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              weatherInfo.description,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── 4 Quick Metrics ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                child: Row(
                  children: [
                    _buildMetricItem(
                      icon: Icons.water_drop_outlined,
                      label: 'Độ ẩm KK',
                      value: '${current.humidity.toStringAsFixed(0)}%',
                      iconColor: const Color(0xFF0288D1),
                    ),
                    _buildDivider(),
                    _buildMetricItem(
                      icon: Icons.umbrella_outlined,
                      label: 'Mưa hiện tại',
                      value: '${current.precipitation.toStringAsFixed(1)} mm',
                      iconColor: const Color(0xFF00ACC1),
                    ),
                    _buildDivider(),
                    _buildMetricItem(
                      icon: Icons.air_outlined,
                      label: 'Tốc độ gió',
                      value: '${current.windSpeed.toStringAsFixed(1)} km/h',
                      iconColor: const Color(0xFF5E35B1),
                    ),
                    _buildDivider(),
                    _buildMetricItem(
                      icon: Icons.wb_sunny_outlined,
                      label: 'Chỉ số UV',
                      value: current.uvIndex.toStringAsFixed(1),
                      iconColor: const Color(0xFFF57C00),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: Color(0xFFEEEEEE)),

              // ── Agriculture Advice Box ──────────────────────────────────
              if (data.agriTips.isNotEmpty)
                Padding(
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
                        ...data.agriTips.map(
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
                ),

              // ── 24-Hour Forecast Timeline ───────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Dự báo 24 giờ tới',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    Text(
                      'Cập nhật lúc ${_formatHour(data.updatedAt)}:${data.updatedAt.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: data.hourly.length,
                  itemBuilder: (context, index) {
                    final h = data.hourly[index];
                    final isNow = index == 0;
                    final hInfo = WmoWeatherCode.getInfo(h.weatherCode, h.isDay);

                    return Container(
                      width: 58,
                      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: isNow ? const Color(0xFFE8F5E9) : const Color(0xFFF9F9F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isNow ? const Color(0xFF81C784) : const Color(0xFFE0E0E0),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isNow ? 'Bây giờ' : _formatHour(h.time),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isNow ? FontWeight.bold : FontWeight.w500,
                              color: isNow ? const Color(0xFF1B5E20) : Colors.grey.shade700,
                            ),
                          ),
                          Icon(hInfo.icon, size: 20, color: hInfo.iconColor),
                          Text(
                            '${h.temperature.toStringAsFixed(0)}°',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (h.precipitationProbability > 0)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.water_drop,
                                  size: 8,
                                  color: Color(0xFF0288D1),
                                ),
                                Text(
                                  '${h.precipitationProbability}%',
                                  style: const TextStyle(
                                    fontSize: 8.5,
                                    color: Color(0xFF0288D1),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          else
                            const SizedBox(height: 10),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // ── 7-Day Forecast Section ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
                child: InkWell(
                  onTap: () {
                    setState(() => _is7DaysExpanded = !_is7DaysExpanded);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.calendar_month_outlined, size: 14, color: Color(0xFF2E7D32)),
                            SizedBox(width: 6),
                            Text(
                              'Dự báo 7 ngày tới',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              _is7DaysExpanded ? 'Thu gọn' : 'Xem chi tiết',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF2E7D32),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Icon(
                              _is7DaysExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              size: 16,
                              color: const Color(0xFF2E7D32),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (_is7DaysExpanded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
                  child: Column(
                    children: data.daily.asMap().entries.map((e) {
                      final index = e.key;
                      final d = e.value;
                      final dInfo = WmoWeatherCode.getInfo(d.weatherCode, true);

                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: index == 0 ? const Color(0xFFF1F8F1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 75,
                              child: Text(
                                _formatDayName(d.date, index),
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: index == 0 ? FontWeight.bold : FontWeight.w500,
                                  color: index == 0 ? const Color(0xFF1B5E20) : Colors.black87,
                                ),
                              ),
                            ),
                            Icon(dInfo.icon, size: 18, color: dInfo.iconColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                dInfo.description,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (d.precipitationProbabilityMax > 0)
                              Row(
                                children: [
                                  const Icon(Icons.water_drop, size: 10, color: Color(0xFF0288D1)),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${d.precipitationProbabilityMax}%',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: Color(0xFF0288D1),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ),
                            Text(
                              '${d.tempMin.toStringAsFixed(0)}° - ${d.tempMax.toStringAsFixed(0)}°C',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                )
              else
                const SizedBox(height: 6),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 26,
      color: const Color(0xFFEEEEEE),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(20),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Color(0xFF2E7D32),
            ),
            SizedBox(height: 12),
            Text(
              'Đang tải dữ liệu thời tiết...',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.cloud_off, color: Colors.orange, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Không thể cập nhật dự báo thời tiết',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                Text(
                  error,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF2E7D32)),
            onPressed: () => _loadWeather(forceRefresh: true),
          ),
        ],
      ),
    );
  }
}
