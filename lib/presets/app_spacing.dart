import 'package:flutter/material.dart';

/// Hệ thống Spacing, Inset và Radius chuẩn của GreenPulse.
///
/// Hằng số cơ sở (Base Spacing Unit) được thiết lập là 8px.
/// Tất cả các khoảng cách, lề, padding đều được tính toán dựa trên bội số của 8px
/// để đảm bảo sự cân đối, hài hòa và nhất quán trên toàn bộ giao diện.
class AppSpacing {
  AppSpacing._();

  // ==========================================
  // 1. HẰNG SỐ CƠ SỞ (BASE UNIT = 8.0px)
  // ==========================================
  static const double unit = 8.0;

  // Bội số khoảng cách chuẩn (8px grid system)
  static const double xxs = 2.0;    // 0.25x
  static const double xs = 4.0;     // 0.5x
  static const double s = 8.0;      // 1.0x (Base)
  static const double sm = 12.0;    // 1.5x
  static const double m = 16.0;     // 2.0x
  static const double lg = 24.0;    // 3.0x
  static const double xl = 32.0;    // 4.0x
  static const double xxl = 40.0;   // 5.0x
  static const double xxxl = 48.0;  // 6.0x

  // ==========================================
  // 2. PRESET EDGEINSETS (PADDING & MARGIN)
  // ==========================================

  // Padding All
  static const EdgeInsets pAllZero = EdgeInsets.zero;
  static const EdgeInsets pAllXxs = EdgeInsets.all(xxs);
  static const EdgeInsets pAllXs = EdgeInsets.all(xs);
  static const EdgeInsets pAllS = EdgeInsets.all(s);
  static const EdgeInsets pAllSm = EdgeInsets.all(sm);
  static const EdgeInsets pAllM = EdgeInsets.all(m);
  static const EdgeInsets pAllLg = EdgeInsets.all(lg);
  static const EdgeInsets pAllXl = EdgeInsets.all(xl);

  // Padding Horizontal
  static const EdgeInsets pHorizXs = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets pHorizS = EdgeInsets.symmetric(horizontal: s);
  static const EdgeInsets pHorizSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets pHorizM = EdgeInsets.symmetric(horizontal: m);
  static const EdgeInsets pHorizLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets pHorizXl = EdgeInsets.symmetric(horizontal: xl);

  // Padding Vertical
  static const EdgeInsets pVertXs = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets pVertS = EdgeInsets.symmetric(vertical: s);
  static const EdgeInsets pVertSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets pVertM = EdgeInsets.symmetric(vertical: m);
  static const EdgeInsets pVertLg = EdgeInsets.symmetric(vertical: lg);

  // Padding theo ngữ cảnh UI
  /// Padding tiêu chuẩn cho toàn màn hình (Horizontal: 16px, Vertical: 12px)
  static const EdgeInsets screen = EdgeInsets.symmetric(horizontal: m, vertical: sm);

  /// Padding tiêu chuẩn bên trong Card (16px)
  static const EdgeInsets card = EdgeInsets.all(m);

  /// Padding tiêu chuẩn bên trong Dialog
  static const EdgeInsets dialog = EdgeInsets.all(lg);

  /// Content padding chuẩn cho TextFormField
  static const EdgeInsets inputField = EdgeInsets.symmetric(horizontal: m, vertical: sm);

  /// Padding cho Button (Horizontal: 24px, Vertical: 12px)
  static const EdgeInsets button = EdgeInsets.symmetric(horizontal: lg, vertical: sm);

  // ==========================================
  // 3. PRESET SIZEDBOX (SPACERS)
  // ==========================================

  // Chiều dọc (Vertical Spacers)
  static const SizedBox vSpaceXxs = SizedBox(height: xxs);
  static const SizedBox vSpaceXs = SizedBox(height: xs);
  static const SizedBox vSpaceS = SizedBox(height: s);
  static const SizedBox vSpaceSm = SizedBox(height: sm);
  static const SizedBox vSpaceM = SizedBox(height: m);
  static const SizedBox vSpaceLg = SizedBox(height: lg);
  static const SizedBox vSpaceXl = SizedBox(height: xl);
  static const SizedBox vSpaceXxl = SizedBox(height: xxl);

  // Chiều ngang (Horizontal Spacers)
  static const SizedBox hSpaceXxs = SizedBox(width: xxs);
  static const SizedBox hSpaceXs = SizedBox(width: xs);
  static const SizedBox hSpaceS = SizedBox(width: s);
  static const SizedBox hSpaceSm = SizedBox(width: sm);
  static const SizedBox hSpaceM = SizedBox(width: m);
  static const SizedBox hSpaceLg = SizedBox(width: lg);
  static const SizedBox hSpaceXl = SizedBox(width: xl);

  // ==========================================
  // 4. PRESET BORDERRADIUS (BO GÓC)
  // ==========================================
  static const double radiusXs = 4.0;
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusCircular = 999.0;

  static final BorderRadius roundedXs = BorderRadius.circular(radiusXs);
  static final BorderRadius roundedS = BorderRadius.circular(radiusS);
  static final BorderRadius roundedM = BorderRadius.circular(radiusM);
  static final BorderRadius roundedLg = BorderRadius.circular(radiusLg);
  static final BorderRadius roundedXl = BorderRadius.circular(radiusXl);
  static final BorderRadius roundedCircular = BorderRadius.circular(radiusCircular);
}
