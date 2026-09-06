import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/main_tab_screen.dart';
import 'screens/verify_email_screen.dart';

import 'services/notification_service.dart';
import 'services/weather_service.dart';
import 'models/plant_preset_manager.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'presets/presets.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 1. Kích hoạt lưu trữ bộ nhớ đệm ngoại tuyến (Offline Persistence)
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    FirebaseDatabase.instance.setPersistenceEnabled(true);

    // 2. Global Error Handler: Bắt và ghi nhận các lỗi về Firebase Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // 3. Đăng ký Handler xử lý tin nhắn FCM chạy nền 24/7 khi đóng app
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('⚠️ [Init Warning] Firebase startup error: $e');
  }

  try {
    await NotificationService().init();
  } catch (e) {
    debugPrint('⚠️ [Init Warning] NotificationService error: $e');
  }

  try {
    await PlantPresetManager.loadPresets();
  } catch (e) {
    debugPrint('⚠️ [Init Warning] PlantPresetManager error: $e');
  }

  try {
    await WeatherService.instance.init();
  } catch (e) {
    debugPrint('⚠️ [Init Warning] WeatherService error: $e');
  }

  runApp(const MyApp());
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GreenPulse',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      builder: (context, child) =>
          AppAccessibility.applyToApp(context, child ?? const SizedBox.shrink()),
      home: const AuthGate(),
    );
  }
}

/// Widget trung gian: Lắng nghe trạng thái đăng nhập tự động
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
            ),
          );
        }
        if (snapshot.hasData) {
          final user = snapshot.data!;
          if (user.emailVerified) {
            return const MainTabScreen();
          } else {
            return const VerifyEmailScreen();
          }
        }
        return const LoginScreen();
      },
    );
  }
}
