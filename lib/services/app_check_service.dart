import 'package:flutter/foundation.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

/// Dịch vụ quản lý và khởi tạo Firebase App Check
/// 
/// Giúp bảo vệ tài nguyên Firebase (Realtime Database, Firestore, Auth) 
/// khỏi bot, các đoạn mã độc hại và truy cập giả mạo.
class AppCheckService {
  AppCheckService._();
  static final AppCheckService instance = AppCheckService._();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Kích hoạt Firebase App Check với các Provider phù hợp cho từng môi trường
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      if (kDebugMode) {
        // Môi trường Debug: Dùng Debug Provider để test trên Emulator / Thiết bị thật
        // ignore: deprecated_member_use
        await FirebaseAppCheck.instance.activate(
          // ignore: deprecated_member_use
          androidProvider: AndroidProvider.debug,
          // ignore: deprecated_member_use
          appleProvider: AppleProvider.debug,
        );
        debugPrint('🛡️ Firebase App Check: Kích hoạt thành công chế độ DEBUG.');
      } else {
        // Môi trường Production: Dùng Google Play Integrity cho Android và DeviceCheck cho iOS
        // ignore: deprecated_member_use
        await FirebaseAppCheck.instance.activate(
          // ignore: deprecated_member_use
          androidProvider: AndroidProvider.playIntegrity,
          // ignore: deprecated_member_use
          appleProvider: AppleProvider.deviceCheck,
        );
        debugPrint('🛡️ Firebase App Check: Kích hoạt thành công chế độ PRODUCTION (Play Integrity / DeviceCheck).');
      }




      _isInitialized = true;
    } catch (e) {
      debugPrint('⚠️ Cảnh báo khởi tạo Firebase App Check: $e');
    }
  }

  /// Lấy mã Token App Check hiện tại (nếu cần gửi kèm Custom Backend REST)
  Future<String?> getToken({bool forceRefresh = false}) async {
    try {
      return await FirebaseAppCheck.instance.getToken(forceRefresh);
    } catch (e) {
      debugPrint('Lỗi lấy App Check Token: $e');
      return null;
    }
  }
}
