import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_accessibility.dart';

/// Cấu hình Theme tổng thể cho toàn bộ ứng dụng GreenPulse.
///
/// Tích hợp:
/// 1. Bảng mã màu chuẩn [AppColors].
/// 2. Hệ thống khoảng cách [AppSpacing] (Base unit = 8px).
/// 3. Phông chữ **Be Vietnam Pro** (`GoogleFonts.beVietnamPro`).
/// 4. Đảm bảo chuẩn Trợ năng Accessibility (Kích thước nút chạm >= 48px, độ tương phản cao).
class AppTheme {
  AppTheme._();

  /// Tên họ phông chữ chính
  static const String fontFamily = 'Be Vietnam Pro';

  /// Cấu hình ThemeData chuẩn giao diện Sáng (Light Theme)
  static ThemeData get lightTheme => buildTheme();

  /// Khởi tạo ThemeData với khả năng tùy biến (hữu ích cho unit/widget test offline)
  static ThemeData buildTheme({TextTheme? customTextTheme, String? customFontFamily}) {
    final effectiveFontFamily = customFontFamily ?? GoogleFonts.beVietnamPro().fontFamily;
    final baseTextTheme = customTextTheme ?? GoogleFonts.beVietnamProTextTheme();

    TextStyle font({FontWeight? fontWeight, double? fontSize, Color? color}) {
      if (customFontFamily != null) {
        return TextStyle(
          fontFamily: effectiveFontFamily,
          fontWeight: fontWeight,
          fontSize: fontSize,
          color: color,
        );
      }
      return GoogleFonts.beVietnamPro(
        fontWeight: fontWeight,
        fontSize: fontSize,
        color: color,
      );
    }

    return ThemeData(
      useMaterial3: true,
      fontFamily: effectiveFontFamily,
      scaffoldBackgroundColor: AppColors.scaffoldBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        onPrimary: AppColors.textOnPrimary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
      ),

      // Text Theme với Be Vietnam Pro
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: AppColors.textPrimary,
          fontSize: 15,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
          fontSize: 13.5,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        centerTitle: false,
        titleTextStyle: font(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.roundedLg,
        ),
        color: AppColors.surface,
        margin: EdgeInsets.zero,
      ),

      // Input Decoration Theme (Ô nhập dữ liệu)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: AppSpacing.inputField,
        border: OutlineInputBorder(
          borderRadius: AppSpacing.roundedM,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.roundedM,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.roundedM,
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.roundedM,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: font(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        hintStyle: font(
          color: AppColors.textHint,
          fontSize: 14,
        ),
      ),

      // Filled Button Theme (Tối ưu Accessibility: Min height 48px)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, AppAccessibility.minTouchTargetSize),
          padding: AppSpacing.button,
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.roundedM,
          ),
          textStyle: font(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(64, AppAccessibility.minTouchTargetSize),
          padding: AppSpacing.button,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: AppSpacing.roundedM,
          ),
          textStyle: font(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(48, AppAccessibility.minTouchTargetSize),
          textStyle: font(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),

      // Navigation Bar Theme (Thanh chuyển tab dưới cùng)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 8,
        shadowColor: Colors.black26,
        indicatorColor: AppColors.accentMint,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return font(
              fontWeight: FontWeight.bold,
              fontSize: 11.5,
              color: AppColors.primaryDark,
            );
          }
          return font(
            fontSize: 11.5,
            color: Colors.grey.shade600,
          );
        }),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.roundedXl,
        ),
        elevation: 8,
      ),

      // SnackBar Theme
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.roundedM,
        ),
        backgroundColor: AppColors.primaryDark,
        contentTextStyle: font(
          color: Colors.white,
          fontSize: 13.5,
        ),
      ),
    );
  }
}
