import 'package:flutter/material.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';
import 'location_picker_dialog.dart';
import 'weather_card/weather_header.dart';
import 'weather_card/weather_metrics_row.dart';
import 'weather_card/weather_agri_tips.dart';
import 'weather_card/weather_hourly_forecast.dart';
import 'weather_card/weather_daily_forecast.dart';
import 'weather_card/weather_state_views.dart';

export 'weather_card/weather_header.dart';
export 'weather_card/weather_metrics_row.dart';
export 'weather_card/weather_agri_tips.dart';
export 'weather_card/weather_hourly_forecast.dart';
export 'weather_card/weather_daily_forecast.dart';
export 'weather_card/weather_state_views.dart';

class WeatherCard extends StatefulWidget {
  final WeatherLocation? initialLocation;

  const WeatherCard({super.key, this.initialLocation});

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
  final WeatherService _weatherService = WeatherService.instance;
  late Future<WeatherData> _weatherFuture;

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
            return const WeatherLoadingView();
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return WeatherErrorView(
              error: snapshot.error?.toString() ?? 'Lỗi tải thời tiết',
              onRetry: () => _loadWeather(forceRefresh: true),
            );
          }

          final data = snapshot.data!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WeatherHeader(
                data: data,
                onOpenLocationPicker: _openLocationPicker,
                onRefresh: () => _loadWeather(forceRefresh: true),
              ),
              WeatherMetricsRow(current: data.current),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              WeatherAgriTips(tips: data.agriTips),
              WeatherHourlyForecast(
                hourly: data.hourly,
                updatedAt: data.updatedAt,
              ),
              WeatherDailyForecast(daily: data.daily),
            ],
          );
        },
      ),
    );
  }
}
