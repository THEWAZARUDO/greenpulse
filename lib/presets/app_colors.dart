import 'package:flutter/material.dart';

/// Bảng mã màu chuẩn (Design System Color Palette) cho GreenPulse.
///
/// Hướng tới phong cách nông nghiệp công nghệ cao, sinh thái và thân thiện.
class AppColors {
  AppColors._();

  // --- Brand / Primary Colors ---
  static const Color primary = Color(0xFF2E7D32); // Xanh lá cây đậm chủ đạo
  static const Color primaryDark = Color(0xFF1B5E20); // Xanh rừng rậm (AppBar, Header)
  static const Color primaryLight = Color(0xFF43A047); // Xanh sáng (Nút nhấn, Điểm nhấn)
  static const Color primaryExtraLight = Color(0xFFE8F5E9); // Nền nhẹ cho item được chọn
  static const Color accentMint = Color(0xFFC8E6C9); // Màu mint pastel nhẹ nhàng

  // --- Secondary / Earth / Nature Colors ---
  static const Color secondary = Color(0xFF388E3C);
  static const Color earthBrown = Color(0xFF6D4C41);
  static const Color leafGreen = Color(0xFF66BB6A);

  // --- Background & Surface Colors ---
  static const Color background = Color(0xFFF0F7F0); // Nền Scaffold tông xanh sữa rất nhẹ
  static const Color surface = Colors.white; // Nền Card, Dialog, BottomSheet
  static const Color surfaceVariant = Color(0xFFF5F9F5); // Nền phụ phân tách
  static const Color scaffoldBackground = Color(0xFFF0F7F0);

  // --- Text Colors (Tối ưu độ tương phản WCAG AA) ---
  static const Color textPrimary = Color(0xFF1C1B1F); // Chữ chính, đen dịu mắt
  static const Color textSecondary = Color(0xFF49454F); // Chữ phụ, mô tả
  static const Color textTertiary = Color(0xFF79747E); // Chữ mờ, timestamp
  static const Color textHint = Color(0xFF9E9E9E); // Placeholder ô nhập liệu
  static const Color textOnPrimary = Colors.white; // Chữ trên nền xanh

  // --- Status & Feedback Colors ---
  static const Color success = Color(0xFF2E7D32); // Thành công / Tốt
  static const Color warning = Color(0xFFE65100); // Cảnh báo / Cần lưu ý
  static const Color error = Color(0xFFD32F2F); // Báo lỗi / Nguy hiểm
  static const Color info = Color(0xFF0288D1); // Thông tin / Thời tiết

  // --- Border & Divider Colors ---
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderFocused = Color(0xFF2E7D32);
  static const Color divider = Color(0xFFEEEEEE);

  // --- IoT & Hardware State Colors ---
  static const Color pumpActive = Color(0xFF0288D1); // Màu máy bơm nước đang chạy
  static const Color pumpInactive = Color(0xFF9E9E9E); // Máy bơm tắt
  static const Color sensorNormal = Color(0xFF2E7D32); // Cảm biến ngưỡng an toàn
  static const Color sensorAlert = Color(0xFFD32F2F); // Cảm biến ngưỡng báo động
  static const Color soilMoisture = Color(0xFF5D4037); // Đất ẩm
  static const Color batteryGood = Color(0xFF43A047); // Pin khỏe
  static const Color batteryLow = Color(0xFFE65100); // Pin yếu
}
