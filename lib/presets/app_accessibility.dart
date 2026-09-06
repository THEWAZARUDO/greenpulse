import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Tiện ích và cấu hình Trợ năng (Accessibility - A11y) cho GreenPulse.
///
/// Tuân thủ nguyên tắc WCAG 2.1 AA:
/// 1. Giới hạn tỷ lệ phóng to chữ an toàn (Text Scaler Clamping) chống tràn viền.
/// 2. Kích thước vùng chạm tối thiểu 48x48 px (Minimum Touch Target).
/// 3. Hỗ trợ gắn nhãn ngữ nghĩa (Semantics) cho trình đọc màn hình (TalkBack/VoiceOver).
class AppAccessibility {
  AppAccessibility._();

  // ==========================================
  // 1. KÍCH THƯỚC CHẠM TỐI THIỂU (WCAG MIN TOUCH TARGET)
  // ==========================================
  /// Chuẩn tương tác WCAG 2.1: Chiều cao và chiều rộng tối thiểu của nút chạm là 48px
  static const double minTouchTargetSize = 48.0;

  // ==========================================
  // 2. GIỚI HẠN PHÓNG TO CHỮ (TEXT SCALER CLAMPING)
  // ==========================================
  /// Giới hạn Text Scaler trong khoảng an toàn (0.85x - 1.35x).
  ///
  /// Giúp người dùng khiếm thị khi bật cỡ chữ lớn trong cài đặt điện thoại
  /// vẫn đọc rõ nội dung mà không gây lỗi tràn màn hình (RenderFlex Overflow).
  static Widget applyToApp(BuildContext context, Widget child) {
    final mediaQueryData = MediaQuery.of(context);
    final textScaler = mediaQueryData.textScaler;

    // Giới hạn tỉ lệ co giãn chữ từ 0.85x đến tối đa 1.35x
    final clampedTextScaler = textScaler.clamp(
      minScaleFactor: 0.85,
      maxScaleFactor: 1.35,
    );

    return MediaQuery(
      data: mediaQueryData.copyWith(
        textScaler: clampedTextScaler,
      ),
      child: child,
    );
  }

  // ==========================================
  // 3. THÔNG BÁO CHO SCREEN READER (VOICEOVER / TALKBACK)
  // ==========================================
  /// Đọc to một thông điệp trạng thái cho người khiếm thị (Ví dụ: "Đã bật máy bơm")
  static void announce(BuildContext context, String message) {
    SemanticsService.sendAnnouncement(
      View.of(context),
      message,
      TextDirection.ltr,
    );
  }
}

/// Widget đảm bảo vùng chạm tương tác (Touch Target) luôn đạt tối thiểu 48x48 px.
class AccessibleTouchTarget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final String? semanticHint;

  const AccessibleTouchTarget({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.semanticHint,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: AppAccessibility.minTouchTargetSize,
        minHeight: AppAccessibility.minTouchTargetSize,
      ),
      child: Center(child: child),
    );

    if (semanticLabel != null) {
      content = Semantics(
        label: semanticLabel,
        hint: semanticHint,
        button: onTap != null,
        child: content,
      );
    }

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: content,
      );
    }

    return content;
  }
}

/// Helper bọc thông tin cảm biến kèm nhãn ngữ nghĩa rõ ràng cho người khiếm thị.
class AccessibleSensorValue extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Widget child;

  const AccessibleSensorValue({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value $unit',
      readOnly: true,
      excludeSemantics: true,
      child: child,
    );
  }
}
