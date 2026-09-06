import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Giải pháp Responsive toàn diện cho GreenPulse:
/// 1. Tự động tính toán kích thước co giãn theo màn hình thực tế (thay vì cố định px).
/// 2. Hỗ trợ hiển thị tối ưu cho cả Điện thoại (Phone) và Máy tính bảng (Tablet/Desktop).
/// 3. Cung cấp Breakpoints, Extension trên BuildContext và Widget bọc giới hạn độ rộng.
class AppResponsive {
  AppResponsive._();

  // 1. breakpoint
  static const double phoneMaxWidth = 600.0;
  static const double tabletMaxWidth = 1024.0;

  // Kích thước màn hình tham chiếu chuẩn (Standard Reference: 390 x 844 dp)
  static const double baseReferenceWidth = 390.0;
  static const double baseReferenceHeight = 844.0;

  // Độ rộng nội dung tối đa khuyến nghị trên Tablet để tránh bị kéo dãn quá bè
  static const double maxContentWidthTablet = 680.0;


  // 2. kiểm tra loại thiết bị
  static bool isPhone(BuildContext context) =>
      MediaQuery.sizeOf(context).width < phoneMaxWidth;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= phoneMaxWidth && width <= tabletMaxWidth;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width > tabletMaxWidth;

  static bool isLandscape(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.landscape;

  static bool isPortrait(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.portrait;

  // 3. tính toán kích thước động

  /// Tự động tính toán kích thước (padding, icon size, height, width)
  /// theo tỉ lệ màn hình thực tế thay vì fix cứng px.
  ///
  /// Có cơ chế kẹp giới hạn (clamp) [minFactor] và [maxFactor] để:
  /// - Không bị thu quá nhỏ trên màn hình cũ (320-360dp).
  /// - Không bị phình quá to trên màn hình lớn hoặc Tablet.
  static double scale(
    BuildContext context,
    double baseSize, {
    double minFactor = 0.85,
    double maxFactor = 1.30,
  }) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    // Nếu là tablet/desktop, tính scale dựa trên content width hợp lý thay vì toàn bộ màn hình
    final effectiveWidth = isTablet(context) || isDesktop(context)
        ? math.min(screenWidth, maxContentWidthTablet)
        : screenWidth;

    final ratio = effectiveWidth / baseReferenceWidth;
    final clampedRatio = ratio.clamp(minFactor, maxFactor);
    return (baseSize * clampedRatio).roundToDouble();
  }

  /// Tự động tính toán cỡ chữ (font size) co giãn mượt mà theo kích thước thực tế.
  static double sp(
    BuildContext context,
    double baseFontSize, {
    double minFactor = 0.85,
    double maxFactor = 1.25,
  }) {
    return scale(
      context,
      baseFontSize,
      minFactor: minFactor,
      maxFactor: maxFactor,
    );
  }

  /// Lấy chiều rộng theo tỉ lệ phần trăm màn hình (0 -> 100)
  static double widthPercent(BuildContext context, double percent) {
    return MediaQuery.sizeOf(context).width * (percent / 100.0);
  }

  /// Lấy chiều cao theo tỉ lệ phần trăm màn hình (0 -> 100)
  static double heightPercent(BuildContext context, double percent) {
    return MediaQuery.sizeOf(context).height * (percent / 100.0);
  }

  /// Chọn giá trị linh hoạt theo thiết bị
  static T value<T>(
    BuildContext context, {
    required T phone,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) return desktop ?? tablet ?? phone;
    if (isTablet(context)) return tablet ?? phone;
    return phone;
  }
}

  //4. Extension build context
extension ResponsiveContextX on BuildContext {
  /// Kích thước chiều rộng màn hình hiện tại
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// Kích thước chiều cao màn hình hiện tại
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// Đang chạy trên điện thoại (< 600dp)
  bool get isPhone => AppResponsive.isPhone(this);

  /// Đang chạy trên Tablet (600dp - 1024dp)
  bool get isTablet => AppResponsive.isTablet(this);

  /// Đang chạy trên màn hình lớn Desktop (> 1024dp)
  bool get isDesktop => AppResponsive.isDesktop(this);

  /// Màn hình đang xoay ngang
  bool get isLandscape => AppResponsive.isLandscape(this);

  /// Màn hình đang đặt dọc
  bool get isPortrait => AppResponsive.isPortrait(this);

  /// Tính kích thước co giãn theo màn hình thực tế (tránh dùng số cứng)
  /// Ví dụ: `context.scale(24)` thay vì `24`
  double scale(double baseSize, {double minFactor = 0.85, double maxFactor = 1.30}) =>
      AppResponsive.scale(this, baseSize, minFactor: minFactor, maxFactor: maxFactor);

  /// Tính cỡ chữ co giãn theo màn hình thực tế
  /// Ví dụ: `fontSize: context.sp(16)`
  double sp(double baseFontSize, {double minFactor = 0.85, double maxFactor = 1.25}) =>
      AppResponsive.sp(this, baseFontSize, minFactor: minFactor, maxFactor: maxFactor);

  /// Chiều rộng theo phần trăm màn hình (ví dụ: `context.w(50)` = 50% màn hình)
  double w(double percent) => AppResponsive.widthPercent(this, percent);

  /// Chiều cao theo phần trăm màn hình (ví dụ: `context.h(25)` = 25% màn hình)
  double h(double percent) => AppResponsive.heightPercent(this, percent);

  /// Trả về giá trị phù hợp theo Phone / Tablet / Desktop
  T responsive<T>({required T phone, T? tablet, T? desktop}) =>
      AppResponsive.value(this, phone: phone, tablet: tablet, desktop: desktop);
}

// 5. Widget bọc giao diện

/// Widget bọc vùng hiển thị (Content Wrapper) cho Tablet:
/// Tự động giới hạn chiều rộng tối đa (maxWidth) và căn giữa trang
/// để giao diện trên iPad / Tablet không bị kéo giãn quá bè ngang.
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = AppResponsive.maxContentWidthTablet,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: child,
        ),
      ),
    );
  }
}

/// Widget xây dựng Layout theo từng loại thiết bị
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (context.isDesktop && desktop != null) return desktop!;
    if (context.isTablet && tablet != null) return tablet!;
    return mobile;
  }
}
