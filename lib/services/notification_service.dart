import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/farm_model.dart';

/// Notification Service: Quản lý thông báo đẩy cục bộ trên điện thoại & thiết bị.
/// Hỗ trợ cấu hình tần suất thông báo linh hoạt (1 đến 10 phút/lần).
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  final Map<String, DateTime> _lastNotificationPerSensor = {};
  DateTime? _lastGlobalNotificationTime;
  int _alertFrequencyMinutes = 1;

  static const String channelId = 'greenpulse_alerts_channel';
  static const String channelName = 'Cảnh báo Nông nghiệp GreenPulse';
  static const String channelDescription =
      'Kênh thông báo cảnh báo thông số nhiệt độ, độ ẩm và môi trường nông nghiệp';

  /// Tần suất thông báo cảnh báo (1 đến 10 phút)
  int get alertFrequencyMinutes => _alertFrequencyMinutes;

  void setAlertFrequencyMinutes(int minutes) {
    if (minutes < 1) {
      _alertFrequencyMinutes = 1;
    } else if (minutes > 10) {
      _alertFrequencyMinutes = 10;
    } else {
      _alertFrequencyMinutes = minutes;
    }
  }

  /// Khởi tạo kênh thông báo
  Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    try {
      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('Đã bấm vào thông báo: ${details.payload}');
        },
      );

      // Cấu hình Kênh thông báo trên Android (bắt buộc từ Android 8.0+)
      final androidPlatform = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlatform != null) {
        // Xin quyền thông báo trên Android 13+ (TIRAMISU / API 33+)
        await androidPlatform.requestNotificationsPermission();

        const channel = AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDescription,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        );
        await androidPlatform.createNotificationChannel(channel);
      }

      _initialized = true;
    } catch (e) {
      debugPrint('Lỗi khởi tạo NotificationService: $e');
    }
  }

  /// Gửi thông báo đẩy lên điện thoại
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    int? notificationId,
  }) async {
    if (!_initialized) {
      await init();
    }

    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      // Đảm bảo ID thông báo là số nguyên 32-bit an toàn tránh lỗi integer overflow
      final id = notificationId ??
          DateTime.now().millisecondsSinceEpoch.remainder(100000);

      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Lỗi hiển thị thông báo: $e');
    }
  }

  /// Kiểm tra và phát thông báo nếu vượt ngưỡng (Tần suất theo alertFrequencyMinutes)
  void processSensorAlerts(String farmName, SensorData sensor) {
    // Chỉ xử lý nếu trạng thái là Cảnh báo hoặc Nguy hiểm
    if (sensor.overallStatus == StatusLevel.normal) return;

    final now = DateTime.now();
    final sensorKey = '${farmName}_${sensor.id}';

    // Kiểm tra Cooldown theo cài đặt người dùng (1 - 10 phút)
    final lastTime = _lastNotificationPerSensor[sensorKey] ?? _lastGlobalNotificationTime;
    if (lastTime != null) {
      final difference = now.difference(lastTime);
      if (difference.inSeconds < _alertFrequencyMinutes * 60) {
        // Chưa đủ thời gian giãn cách theo thiết lập -> bỏ qua
        return;
      }
    }

    // Cập nhật mốc thời gian đã gửi thông báo
    _lastNotificationPerSensor[sensorKey] = now;
    _lastGlobalNotificationTime = now;

    final iconHeader = sensor.overallStatus == StatusLevel.danger
        ? '🚨 [NGUY HIỂM]'
        : '⚠️ [CẢNH BÁO]';
    final advice = sensor.adviceList.isNotEmpty
        ? sensor.adviceList.first
        : 'Vui lòng kiểm tra trang trại ngay!';

    final title = '$iconHeader $farmName';
    final body =
        'Cảm biến "${sensor.id}" [${sensor.overallStatus.label}]: Nhiệt ${sensor.temperature}°C, Đất ${sensor.soil}%, Ẩm ${sensor.humidity}%. $advice';

    showNotification(
      title: title,
      body: body,
      payload: 'farm_${farmName}_${sensor.id}',
    );
  }
}
