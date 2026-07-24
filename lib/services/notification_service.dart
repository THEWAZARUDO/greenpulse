import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/farm_model.dart';

/// Notification Service: Quản lý thông báo đẩy cục bộ trên điện thoại & thiết bị.
/// Tần suất thông báo: 1 phút / 1 lần khi phát hiện cảnh báo nguy hiểm hoặc bất thường.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  DateTime? _lastNotificationTime;

  /// Khởi tạo kênh thông báo
  Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
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
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('Đã bấm vào thông báo: ${details.payload}');
        },
      );

      // Xin quyền thông báo trên Android 13+
      final androidPlatform = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlatform != null) {
        await androidPlatform.requestNotificationsPermission();
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
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'greenpulse_alerts_channel',
      'Cảnh báo Nông nghiệp GreenPulse',
      channelDescription:
          'Kênh thông báo cảnh báo thông số nhiệt độ, độ ẩm và môi trường nông nghiệp',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
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
      await _notificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Lỗi hiển thị thông báo: $e');
    }
  }

  /// Kiểm tra và phát thông báo nếu vượt ngưỡng (Tần suất đúng 1 phút / 1 lần)
  void processSensorAlerts(String farmName, SensorData sensor) {
    // Chỉ xử lý nếu trạng thái là Cảnh báo hoặc Nguy hiểm
    if (sensor.overallStatus == StatusLevel.normal) return;

    final now = DateTime.now();

    // Kiểm tra Cooldown 1 phút (60 giây)
    if (_lastNotificationTime != null) {
      final difference = now.difference(_lastNotificationTime!);
      if (difference.inSeconds < 60) {
        // Chưa đủ 1 phút từ lần thông báo trước -> bỏ qua
        return;
      }
    }

    // Cập nhật mốc thời gian đã gửi thông báo
    _lastNotificationTime = now;

    final iconHeader = '⚠️ [CẢNH BÁO NGUY HIỂM]';
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
