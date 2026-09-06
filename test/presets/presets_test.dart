import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:greenpulse/presets/presets.dart';

void main() {
  setUpAll(() {
    // Tắt tải font từ internet trong môi trường test
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('AppSpacing Tests', () {
    test('Hằng số cơ sở phải là 8.0px và các bội số đúng tỷ lệ', () {
      expect(AppSpacing.unit, equals(8.0));
      expect(AppSpacing.xxs, equals(2.0));
      expect(AppSpacing.xs, equals(4.0));
      expect(AppSpacing.s, equals(8.0));
      expect(AppSpacing.sm, equals(12.0));
      expect(AppSpacing.m, equals(16.0));
      expect(AppSpacing.lg, equals(24.0));
      expect(AppSpacing.xl, equals(32.0));
      expect(AppSpacing.xxl, equals(40.0));
      expect(AppSpacing.xxxl, equals(48.0));
    });

    test('EdgeInsets và Radius tuân theo hệ 8px', () {
      expect(AppSpacing.pAllS, equals(const EdgeInsets.all(8.0)));
      expect(AppSpacing.pAllM, equals(const EdgeInsets.all(16.0)));
      expect(AppSpacing.screen, equals(const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0)));
      expect(AppSpacing.radiusS, equals(8.0));
      expect(AppSpacing.radiusM, equals(12.0));
      expect(AppSpacing.radiusLg, equals(16.0));
    });
  });

  group('AppTheme & Font Tests', () {
    test('AppTheme định nghĩa đúng phông chữ Be Vietnam Pro và bảng màu', () {
      expect(AppTheme.fontFamily, equals('Be Vietnam Pro'));

      final theme = AppTheme.buildTheme(
        customFontFamily: 'BeVietnamPro',
        customTextTheme: const TextTheme(
          bodyLarge: TextStyle(fontFamily: 'BeVietnamPro'),
        ),
      );

      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.primary, equals(AppColors.primary));
      expect(theme.scaffoldBackgroundColor, equals(AppColors.scaffoldBackground));
      expect(theme.appBarTheme.backgroundColor, equals(AppColors.primaryDark));
      expect(theme.textTheme.bodyLarge?.fontFamily, contains('BeVietnamPro'));
    });
  });

  group('AppResponsive Tests', () {
    testWidgets('Kiểm tra Breakpoint Phone', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool isPhoneResult = false;
      bool isTabletResult = true;
      double scaleResult = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              isPhoneResult = context.isPhone;
              isTabletResult = context.isTablet;
              scaleResult = context.scale(100);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(isPhoneResult, isTrue);
      expect(isTabletResult, isFalse);
      expect(scaleResult, equals(100.0));
    });

    testWidgets('Kiểm tra Breakpoint Tablet', (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool isPhoneResult = true;
      bool isTabletResult = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              isPhoneResult = context.isPhone;
              isTabletResult = context.isTablet;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(isTabletResult, isTrue);
      expect(isPhoneResult, isFalse);
    });
  });

  group('AppAccessibility Tests', () {
    test('Kích thước tương tác tối thiểu phải đạt chuẩn 48px', () {
      expect(AppAccessibility.minTouchTargetSize, equals(48.0));
    });

    testWidgets('AppAccessibility giới hạn TextScaler trong ngưỡng an toàn', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => AppAccessibility.applyToApp(context, child!),
          home: Builder(
            builder: (context) {
              final scaler = MediaQuery.textScalerOf(context);
              final scaledFontSize = scaler.scale(10.0);
              expect(scaledFontSize, greaterThanOrEqualTo(8.5));
              expect(scaledFontSize, lessThanOrEqualTo(13.5));
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });
}
