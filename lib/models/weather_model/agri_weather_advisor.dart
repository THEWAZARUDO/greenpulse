import 'current_weather.dart';
import 'forecast_models.dart';

/// Bộ phân tích và sinh khuyến nghị nông học thông minh dựa trên dự báo thời tiết
class AgriWeatherAdvisor {
  static List<String> generateTips(
    CurrentWeather current,
    List<HourlyForecast> hourly,
    List<DailyForecast> daily,
  ) {
    final List<String> tips = [];

    // 1. Kiểm tra mưa trong 6 giờ tới
    final next6Hours = hourly.take(6).toList();
    final maxRainChance6h = next6Hours.fold<int>(
      0,
      (max, h) => h.precipitationProbability > max ? h.precipitationProbability : max,
    );

    if (maxRainChance6h >= 70) {
      tips.add('🌧️ Khả năng mưa cao ($maxRainChance6h%) trong 6 giờ tới: Tạm hoãn tưới nước và không phun thuốc BVTV/phân bón lá để tránh bị rửa trôi.');
    } else if (maxRainChance6h >= 40) {
      tips.add('🌦️ Dự báo có thể có mưa ($maxRainChance6h%): Cân nhắc giảm lượng nước tưới tự động.');
    }

    // 2. Kiểm tra nhiệt độ và nắng gắt
    if (current.temperature >= 35) {
      tips.add('🔥 Nắng gắt nhiệt độ cao (${current.temperature.toStringAsFixed(1)}°C): Cần tăng cường che lưới mát cho vườn ươm/cây con và tưới ẩm vào sáng sớm hoặc chiều mát.');
    } else if (current.temperature <= 16) {
      tips.add('❄️ Nhiệt độ lạnh (${current.temperature.toStringAsFixed(1)}°C): Chú ý ủ gốc giữ ấm, hạn chế tưới đẫm vào chiều tối đề phòng sương muối/rét đậm.');
    }

    // 3. Kiểm tra chỉ số UV
    final maxUvToday = daily.isNotEmpty ? daily.first.uvIndexMax : current.uvIndex;
    if (maxUvToday >= 8) {
      tips.add('☀️ Chỉ số UV đạt mức cao (${maxUvToday.toStringAsFixed(1)}): Tránh làm việc ngoài trời nắng gắt giữa trưa; che chắn bề mặt đất để giảm bốc thoát hơi nước.');
    }

    // 4. Kiểm tra độ ẩm không khí cao
    if (current.humidity >= 88) {
      tips.add('💧 Độ ẩm không khí rất cao (${current.humidity.toStringAsFixed(0)}%): Điều kiện thuận lợi cho nấm bệnh (thán thư, rỉ sắt, nấm hồng) phát triển, cần tỉa cành thông thoáng.');
    }

    // 5. Kiểm tra gió mạnh
    if (current.windSpeed >= 28) {
      tips.add('💨 Gió mạnh (${current.windSpeed.toStringAsFixed(1)} km/h): Cần chằng chống cành cây ăn quả, che chắn vườn chắn gió để tránh gãy cành/rụng hoa.');
    }

    // Lời khuyên mặc định nếu thời tiết thuận lợi
    if (tips.isEmpty) {
      tips.add('🌱 Thời tiết rất thuận lợi: Thích hợp cho việc bón phân dinh dưỡng định kỳ, tỉa cành và chăm sóc cây trồng.');
    }

    return tips;
  }
}
